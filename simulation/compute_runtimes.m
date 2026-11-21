% COMPUTE_RUNTIMES Measures single-snapshot decision latency in microseconds
%
% Usage:
%   runtimes_us = compute_runtimes(cfg)
%
% Output:
%   runtimes_us - (6 x 4) matrix of execution latencies in microseconds
%                 Rows: [SLRTD1(Std), SLRTD1(Rob), SLRTD2(Std), SLRTD2(Rob), ED(Std), ED(Rob)]
%                 Cols: [GN, LN, IN, SaSN]

function runtimes_us = compute_runtimes(cfg)
    noise_models = {'GN', 'LN', 'IN', 'SaSN'};
    N_profile = 10000; % 10^4 independent single-snapshot runs (Table III standard)
    K = cfg.K;
    N = cfg.N;
    sigma0_sq = 1.0;

    runtimes_us = zeros(6, 4);
    fprintf('\n>>> Executing Table III Profiler (%d single snapshots per detector)...\n', N_profile);

    for m = 1:length(noise_models)
        model = noise_models{m};
        cfg_m = calibrate_thresholds(cfg, model);

        % Pre-synthesize snapshots to isolate detector compute time from RNG
        w_act = gen_noise(model, K, sigma0_sq, cfg_m, N_profile);
        w_ref = gen_noise(model, N, sigma0_sq, cfg_m, N_profile);

        % JIT warm-up
        for i = 1:200
            y = w_act(:, i); w = w_ref(:, i);
            [~, ~] = detect_ed(y, w, sigma0_sq, cfg_m);
            [~, ~] = detect_slrtd1(y, w, sigma0_sq, cfg_m);
            [~, ~] = detect_slrtd2(y, w, cfg_m);
        end

        % 1. Standard ED
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i);
            T_ed = sum(abs(y).^2);
            dec = (T_ed >= (sigma0_sq * cfg_m.lambda_ed_std));
        end
        runtimes_us(5, m) = (toc(t_start) / N_profile) * 1e6;

        % 2. Robust ED
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i); w = w_ref(:, i);
            T_ed = sum(abs(y).^2);
            s_mad = compute_mad(w, 1);
            dec = (T_ed >= (cfg_m.lambda_ed_rob * (s_mad^2)));
        end
        runtimes_us(6, m) = (toc(t_start) / N_profile) * 1e6;

        % 3. Standard SLRTD1
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i);
            y_bar = mean(y);
            U = (abs(y_bar - cfg_m.mu0)^2) / sigma0_sq;
            V = var(y, 1) / sigma0_sq;
            T1 = K * (log(V) + 1 - U - V);
            dec = (T1 <= cfg_m.lambda_slrt1_std);
        end
        runtimes_us(1, m) = (toc(t_start) / N_profile) * 1e6;

        % 4. Robust SLRTD1
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i); w = w_ref(:, i);
            mu_rob = median(real(y)) + 1j * median(imag(y));
            s_y = compute_mad(y, 1);
            s_w = compute_mad(w, 1);
            V = (s_y^2) / (s_w^2);
            U = (abs(mu_rob - cfg_m.mu0)^2) / (s_w^2);
            T1_rob = K * (log(V) + 1 - U - V);
            dec = (T1_rob <= cfg_m.lambda_slrt1_rob);
        end
        runtimes_us(2, m) = (toc(t_start) / N_profile) * 1e6;

        % 5. Standard SLRTD2
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i); w = w_ref(:, i);
            s_y = std(y, 1);
            s_w = std(w, 1);
            s_z = sqrt((K*(s_y^2) + N*(s_w^2)) / (K + N));
            T2 = K * log(s_z / s_y) + N * log(s_z / s_w);
            dec = (T2 >= cfg_m.lambda_slrt2_std);
        end
        runtimes_us(3, m) = (toc(t_start) / N_profile) * 1e6;

        % 6. Robust SLRTD2
        t_start = tic;
        for i = 1:N_profile
            y = w_act(:, i); w = w_ref(:, i);
            s_y = compute_mad(y, 1);
            s_w = compute_mad(w, 1);
            s_z = sqrt((K*(s_y^2) + N*(s_w^2)) / (K + N));
            T2_rob = K * log(s_z / s_y) + N * log(s_z / s_w);
            dec = (T2_rob >= cfg_m.lambda_slrt2_rob);
        end
        runtimes_us(4, m) = (toc(t_start) / N_profile) * 1e6;

        fprintf('    [%s Done] ED(Std)=%.1f us | SLRT1(Std)=%.1f us, Rob=%.1f us | SLRT2(Std)=%.1f us, Rob=%.1f us\n', ...
                model, runtimes_us(5, m), runtimes_us(1, m), runtimes_us(2, m), runtimes_us(3, m), runtimes_us(4, m));
    end
end