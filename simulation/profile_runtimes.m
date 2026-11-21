% PROFILE_RUNTIMES Measures execution latency per snapshot in microseconds
% Replicates Table III to quantify the computational overhead of MAD sorting.

clear; clc; close all;
setup_project;

fprintf('====================================================================\n');
fprintf('  TASK 3: EXECUTION RUNTIME PROFILING (TABLE III REPLICATION)       \n');
fprintf('====================================================================\n');

cfg = config_params();
noise_models = {'GN', 'LN', 'IN', 'SaSN'};
N_profile = 10000; % 10^4 independent single-snapshot runs as in Table III
K = cfg.K;
N = cfg.N;
sigma0_sq = 1.0;

% Storage matrix: [Detector x Noise Model] in microseconds
% Rows: 1: SLRTD1 (Std), 2: SLRTD1 (Rob), 3: SLRTD2 (Std), 4: SLRTD2 (Rob), 5: ED (Std), 6: ED (Rob)
det_names = {'SLRTD1 (Std)', 'SLRTD1 (Rob)', 'SLRTD2 (Std)', 'SLRTD2 (Rob)', 'ED (Std)', 'ED (Rob)'};
runtimes_us = zeros(6, 4);

fprintf('[INFO] Profiling %d single snapshots per detector across 4 noise regimes...\n', N_profile);

for m = 1:length(noise_models)
    model = noise_models{m};
    fprintf('\n>>> Benchmarking %s Noise Regime...\n', model);
    
    % Calibrate static threshold for this regime
    cfg = calibrate_thresholds(cfg, model);
    
    % Pre-synthesize N_profile individual snapshots to isolate detector compute time from RNG
    w_act = gen_noise(model, K, sigma0_sq, cfg, N_profile);
    w_ref = gen_noise(model, N, sigma0_sq, cfg, N_profile);
    
    % -------------------------------------------------------------
    % Warm-up JIT compiler
    % -------------------------------------------------------------
    for i = 1:500
        y_warm = w_act(:, i);
        w_warm = w_ref(:, i);
        [~, ~] = detect_ed(y_warm, w_warm, sigma0_sq, cfg);
        [~, ~] = detect_slrtd1(y_warm, w_warm, sigma0_sq, cfg);
        [~, ~] = detect_slrtd2(y_warm, w_warm, cfg);
    end
    
    % -------------------------------------------------------------
    % 1. Standard ED: O(K) complexity
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        T_ed = sum(abs(y).^2);
        dec = (T_ed >= (sigma0_sq * cfg.lambda_ed_std));
    end
    runtimes_us(5, m) = (toc(t_start) / N_profile) * 1e6;
    
    % -------------------------------------------------------------
    % 2. Robust ED: MAD scale + O(K) energy
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        w = w_ref(:, i);
        T_ed = sum(abs(y).^2);
        s_mad = compute_mad(w, 1);
        dec = (T_ed >= (cfg.lambda_ed_rob * (s_mad^2)));
    end
    runtimes_us(6, m) = (toc(t_start) / N_profile) * 1e6;
    
    % -------------------------------------------------------------
    % 3. Standard SLRTD1: O(K) sample variance & mean
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        y_bar = mean(y);
        U = (abs(y_bar - cfg.mu0)^2) / sigma0_sq;
        V = var(y, 1) / sigma0_sq;
        T1 = K * (log(V) + 1 - U - V);
        dec = (T1 <= cfg.lambda_slrt1_std);
    end
    runtimes_us(1, m) = (toc(t_start) / N_profile) * 1e6;
    
    % -------------------------------------------------------------
    % 4. Robust SLRTD1: MAD scale + median location + log
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        w = w_ref(:, i);
        mu_rob = median(real(y)) + 1j * median(imag(y));
        s_y = compute_mad(y, 1);
        s_w = compute_mad(w, 1);
        V = (s_y^2) / (s_w^2);
        U = (abs(mu_rob - cfg.mu0)^2) / (s_w^2);
        T1_rob = K * (log(V) + 1 - U - V);
        dec = (T1_rob <= cfg.lambda_slrt1_rob);
    end
    runtimes_us(2, m) = (toc(t_start) / N_profile) * 1e6;
    
    % -------------------------------------------------------------
    % 5. Standard SLRTD2: Sample variances + logs
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        w = w_ref(:, i);
        s_y = std(y, 1);
        s_w = std(w, 1);
        s_z = sqrt((K*(s_y^2) + N*(s_w^2)) / (K + N));
        T2 = K * log(s_z / s_y) + N * log(s_z / s_w);
        dec = (T2 >= cfg.lambda_slrt2_std);
    end
    runtimes_us(3, m) = (toc(t_start) / N_profile) * 1e6;
    
    % -------------------------------------------------------------
    % 6. Robust SLRTD2: 2x MAD scale + logs
    % -------------------------------------------------------------
    t_start = tic;
    for i = 1:N_profile
        y = w_act(:, i);
        w = w_ref(:, i);
        s_y = compute_mad(y, 1);
        s_w = compute_mad(w, 1);
        s_z = sqrt((K*(s_y^2) + N*(s_w^2)) / (K + N));
        T2_rob = K * log(s_z / s_y) + N * log(s_z / s_w);
        dec = (T2_rob >= cfg.lambda_slrt2_rob);
    end
    runtimes_us(4, m) = (toc(t_start) / N_profile) * 1e6;
    
    fprintf('    Completed: ED(Std)=%.1f us, ED(Rob)=%.1f us | SLRT1(Std)=%.1f us, SLRT1(Rob)=%.1f us | SLRT2(Std)=%.1f us, SLRT2(Rob)=%.1f us\n', ...
            runtimes_us(5, m), runtimes_us(6, m), runtimes_us(1, m), runtimes_us(2, m), runtimes_us(3, m), runtimes_us(4, m));
end

%% Format Summary Table
fprintf('\n========================================================================================\n');
fprintf('                     TABLE III: AVERAGE EXECUTION RUNTIME (microseconds)                \n');
fprintf('========================================================================================\n');
fprintf(' Detector Variant   |    Gaussian (GN)  |   Laplacian (LN)  |   Impulsive (IN)  |    SaS (SaSN) \n');
fprintf('----------------------------------------------------------------------------------------\n');
for d = 1:6
    fprintf(' %-18s |       %5.1f us    |       %5.1f us    |       %5.1f us    |       %5.1f us   \n', ...
            det_names{d}, runtimes_us(d, 1), runtimes_us(d, 2), runtimes_us(d, 3), runtimes_us(d, 4));
end
fprintf('========================================================================================\n');

%% Visual Bar Chart Comparison
figure('Name', 'Execution Runtime Breakdown', 'Position', [150, 150, 900, 500], 'Color', 'w');
bar_data = [runtimes_us(5, :); runtimes_us(6, :); runtimes_us(1, :); runtimes_us(2, :); runtimes_us(3, :); runtimes_us(4, :)]';
b = bar(bar_data);
grid on; box on;
set(gca, 'XTickLabel', noise_models);
xlabel('Noise Regime');
ylabel('Average Execution Time per Snapshot (\mu s)');
title('Computational Overhead Comparison (K = 512 Samples)');
legend({'ED (Std)', 'ED (Rob)', 'SLRTD1 (Std)', 'SLRTD1 (Rob)', 'SLRTD2 (Std)', 'SLRTD2 (Rob)'}, ...
       'Location', 'northwest', 'FontSize', 9);