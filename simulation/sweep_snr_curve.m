% SWEEP_SNR_CURVE Runs vectorized Monte Carlo trials across an SNR grid
function results = sweep_snr_curve(noise_type, snr_grid, cfg)
num_snr = length(snr_grid);
MCS = cfg.MCS;
K = cfg.K;
N = cfg.N;

% Calibrate decision thresholds specifically for this noise regime under H0
cfg = calibrate_thresholds(cfg, noise_type);

results.snr_grid     = snr_grid;
results.noise_type   = noise_type;
results.pd_ed_std    = zeros(1, num_snr);
results.pd_ed_rob    = zeros(1, num_snr);
results.pd_slrt1_std = zeros(1, num_snr);
results.pd_slrt1_rob = zeros(1, num_snr);
results.pd_slrt2_std = zeros(1, num_snr);
results.pd_slrt2_rob = zeros(1, num_snr);

fprintf('\n>>> Sweeping %s Noise across [%d to %d dB] (%d SNR points, %d trials each)...\n', ...
    upper(noise_type), snr_grid(1), snr_grid(end), num_snr, MCS);

t_start = tic;

for idx = 1:num_snr
    % Inside sweep_snr_curve.m loop:
    snr_val = snr_grid(idx);
    
    if strcmp(noise_type, 'SaSN')
        gamma_val = 1.0 / (10^(snr_val / 10));
        w_active = gen_noise(noise_type, K, gamma_val, cfg, MCS);
        w_ref    = gen_noise(noise_type, N, gamma_val, cfg, MCS);
        
        % Finite-sample power scale follows gamma^(2/alpha)
        scale_factor = gamma_val^(2 / cfg.noise.SaS_a);
        norm_disp = gamma_val;
    else
        sigma2_w = 1.0 / (10^(snr_val / 10));
        w_active = gen_noise(noise_type, K, sigma2_w, cfg, MCS);
        w_ref    = gen_noise(noise_type, N, sigma2_w, cfg, MCS);
        scale_factor = sigma2_w;
        norm_disp = sigma2_w;
    end
    
    x_sig = gen_ofdm_signal(K, cfg, MCS);
    y_rx  = x_sig + w_active;
    
    % 1. Energy Detectors
    T_ed = sum(abs(y_rx).^2, 1);
    s_mad_ref = compute_mad(w_ref, 1);
    dec_ed_std = (T_ed >= (scale_factor * cfg.lambda_ed_std));
    dec_ed_rob = (T_ed >= (cfg.lambda_ed_rob * (s_mad_ref.^2)));
    
    % 2. SLRTD1 (Semi-Blind)
    [dec_s1_std, dec_s1_rob, ~, ~] = detect_slrtd1(y_rx, w_ref, norm_disp, cfg);
    
    % 3. SLRTD2 (Exact Pooled Blind)
    [dec_s2_std, dec_s2_rob, ~, ~] = detect_slrtd2(y_rx, w_ref, cfg);

    % Log empirical detection probabilities
    results.pd_ed_std(idx)    = mean(dec_ed_std);
    results.pd_ed_rob(idx)    = mean(dec_ed_rob);
    results.pd_slrt1_std(idx) = mean(dec_s1_std);
    results.pd_slrt1_rob(idx) = mean(dec_s1_rob);
    results.pd_slrt2_std(idx) = mean(dec_s2_std);
    results.pd_slrt2_rob(idx) = mean(dec_s2_rob);

    fprintf('    SNR = %+3d dB | SLRTD1: Std=%.3f, Rob=%.3f | SLRTD2: Std=%.3f, Rob=%.3f | ED: Std=%.3f, Rob=%.3f\n', ...
        snr_val, results.pd_slrt1_std(idx), results.pd_slrt1_rob(idx), ...
        results.pd_slrt2_std(idx), results.pd_slrt2_rob(idx), ...
        results.pd_ed_std(idx), results.pd_ed_rob(idx));
end

elapsed = toc(t_start);
fprintf('>>> Completed %s sweep in %.2f seconds.\n', upper(noise_type), elapsed);
end