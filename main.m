% MAIN Master Script: Replicating Published Results and Complexity Benchmarks
clear; clc; close all;
setup_project;

fprintf('====================================================================\n');
fprintf('  REPLICATING SLRT SPECTRUM SENSING: MONTE CARLO & RUNTIME SUITE    \n');
fprintf('====================================================================\n');

rng(2026);
cfg = config_params();
noise_models = {'GN', 'LN', 'IN', 'SaSN'};
all_results = struct();

%% 1. Task 1 & 2: SNR Sweeps
total_time = tic;
for m = 1:length(noise_models)
    model = noise_models{m};
    all_results.(model) = sweep_snr_curve(model, cfg.snr_grid, cfg);
end
fprintf('\n>>> Monte Carlo Waterfall Sweeps completed in %.2f minutes.\n', toc(total_time) / 60);

%% 2. Display Table II (Target SNR for Pd >= 0.90)
fprintf('\n========================================================================\n');
fprintf('           REPRODUCED TABLE II: TARGET SNR (dB) AT Pd >= 0.90           \n');
fprintf('\n========================================================================\n');
fprintf('           EVALUATED OFDM SENSING RESULTS                                \n');
fprintf('========================================================================\n');
fprintf(' %-18s |  Gaussian (GN) | Laplacian (LN) | Impulsive (IN) | SaS (SaSN) \n', 'Detector Variant');
fprintf('------------------------------------------------------------------------\n');

% 6 rows ordered from ED down to Robust SLRTD2
row_labels = { ...
    'ED', ...
    'Robust ED', ...
    'SLRTD1', ...
    'Robust SLRTD1', ...
    'SLRTD2', ...
    'Robust SLRTD2' ...
};

row_fields = { ...
    'pd_ed_std', ...
    'pd_ed_rob', ...
    'pd_slrt1_std', ...
    'pd_slrt1_rob', ...
    'pd_slrt2_std', ...
    'pd_slrt2_rob' ...
};

for r = 1:6
    lbl = row_labels{r};
    fld = row_fields{r};
    
    val = zeros(1, 4);
    for m = 1:4
        mod = noise_models{m};
        res = all_results.(mod);
        val(m) = extract_target_snr(res.snr_grid, res.(fld), 0.90);
    end
    
    fprintf(' %-18s |     %+5.1f dB   |     %+5.1f dB   |     %+5.1f dB   |   %+5.1f dB \n', ...
            lbl, val(1), val(2), val(3), val(4));
end
fprintf('========================================================================\n');

%% 3. Task 3: Table III Profiling
runtimes_us = compute_runtimes(cfg);

fprintf('\n========================================================================================\n');
fprintf('                     REPRODUCED TABLE III: AVERAGE EXECUTION RUNTIME (microseconds)     \n');
fprintf('========================================================================================\n');
fprintf(' Detector Variant   |    Gaussian (GN)  |   Laplacian (LN)  |   Impulsive (IN)  |    SaS (SaSN) \n');
fprintf('----------------------------------------------------------------------------------------\n');
det_profile_names = {'SLRTD1 (Std)', 'SLRTD1 (Rob)', 'SLRTD2 (Std)', 'SLRTD2 (Rob)', 'ED (Std)', 'ED (Rob)'};
for d = 1:6
    fprintf(' %-18s |       %5.1f us    |       %5.1f us    |       %5.1f us    |       %5.1f us   \n', ...
            det_profile_names{d}, runtimes_us(d, 1), runtimes_us(d, 2), runtimes_us(d, 3), runtimes_us(d, 4));
end
fprintf('========================================================================================\n');

%% 4. Plot Waterfall ROC Curves
% figure('Name', 'Monte Carlo Replication: Pd vs SNR Curves', 'Position', [100, 100, 1200, 800], 'Color', 'w');
% for m = 1:4
%     mod = noise_models{m};
%     res = all_results.(mod);
% 
%     subplot(2, 2, m);
%     plot(res.snr_grid, res.pd_slrt1_std, 'b-',  'LineWidth', 1.8, 'DisplayName', 'SLRTD1 (Std)'); hold on;
%     plot(res.snr_grid, res.pd_slrt1_rob, 'b--', 'LineWidth', 1.8, 'DisplayName', 'SLRTD1 (Rob)');
%     plot(res.snr_grid, res.pd_slrt2_std, 'k-',  'LineWidth', 1.8, 'DisplayName', 'SLRTD2 (Std)');
%     plot(res.snr_grid, res.pd_slrt2_rob, 'k--', 'LineWidth', 1.8, 'DisplayName', 'SLRTD2 (Rob)');
%     plot(res.snr_grid, res.pd_ed_std,    'r-',  'LineWidth', 1.8, 'DisplayName', 'ED (Std)');
%     plot(res.snr_grid, res.pd_ed_rob,    'r--', 'LineWidth', 1.8, 'DisplayName', 'ED (Rob)');
% 
%     grid on; box on;
%     xlim([-20, 5]); ylim([0, 1.02]);
%     yline(0.90, 'k:', 'LineWidth', 1.2, 'DisplayName', 'P_d = 0.90 Target');
%     xlabel('SNR / GSNR (dB)'); ylabel('Probability of Detection (P_d)');
%     title(sprintf('Noise Regime: %s', mod));
%     legend('Location', 'southeast', 'FontSize', 8);
% end

%% 4. Plot Replicated IEEE-Formatted ROC Curves
plot_ieee_roc(all_results, cfg);

% Local Helper
function snr_target = extract_target_snr(snr_grid, pd_vec, target_pd)
    cross_idx = find(pd_vec >= target_pd, 1, 'first');
    if isempty(cross_idx)
        snr_target = NaN;
    elseif cross_idx == 1
        snr_target = snr_grid(1);
    else
        p1 = pd_vec(cross_idx - 1); p2 = pd_vec(cross_idx);
        s1 = snr_grid(cross_idx - 1); s2 = snr_grid(cross_idx);
        snr_target = s1 + (target_pd - p1) * (s2 - s1) / (p2 - p1);
    end
end