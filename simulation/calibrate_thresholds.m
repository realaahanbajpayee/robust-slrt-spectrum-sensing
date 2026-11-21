% CALIBRATE_THRESHOLDS Calibrates empirical decision thresholds for Pfa = 0.003
function cfg = calibrate_thresholds(cfg, noise_type)
    if nargin < 2 || isempty(noise_type), noise_type = 'GN'; end

    N_calib = 100000;
    sigma0_sq = 1.0;

    w_act = gen_noise(noise_type, cfg.K, sigma0_sq, cfg, N_calib);
    w_ref = gen_noise(noise_type, cfg.N, sigma0_sq, cfg, N_calib);

    % 1. Energy Detectors
    T_ed = sum(abs(w_act).^2, 1);
    s_mad_ref = compute_mad(w_ref, 1);
    cfg.lambda_ed_std = quantile(T_ed, 1 - cfg.Pfa_target);
    ratio_ed_rob      = T_ed ./ (s_mad_ref.^2);
    cfg.lambda_ed_rob = quantile(ratio_ed_rob, 1 - cfg.Pfa_target);

    % 2. SLRTD1 (Semi-Blind)
    y_bar  = mean(w_act, 1);
    U_std  = (abs(y_bar - cfg.mu0).^2) / sigma0_sq;
    s2_std = var(w_act, 1, 1);
    V_std  = s2_std / sigma0_sq;
    T1_std = cfg.K * (log(V_std) + 1 - U_std - V_std);

    mu_rob = median(real(w_act), 1) + 1j * median(imag(w_act), 1);
    s_y_rob = compute_mad(w_act, 1);
    s_w_rob = compute_mad(w_ref, 1);
    V_rob   = (s_y_rob.^2) ./ (s_w_rob.^2);
    U_rob   = (abs(mu_rob - cfg.mu0).^2) ./ (s_w_rob.^2);
    T1_rob  = cfg.K * (log(V_rob) + 1 - U_rob - V_rob);

    cfg.lambda_slrt1_std = quantile(T1_std, cfg.Pfa_target);
    cfg.lambda_slrt1_rob = quantile(T1_rob, cfg.Pfa_target);

    % 3. SLRTD2 (Exact Pooled MLE Variance)
    w_bar = mean(w_ref, 1);
    s2_y = var(w_act, 1, 1);
    s2_w = var(w_ref, 1, 1);
    s2_z = (cfg.K * s2_y + cfg.N * s2_w + (cfg.K * cfg.N / (cfg.K + cfg.N)) * abs(y_bar - w_bar).^2) / (cfg.K + cfg.N);
    T2_std = cfg.K * log(sqrt(s2_z) ./ sqrt(s2_y)) + cfg.N * log(sqrt(s2_z) ./ sqrt(s2_w));

    mu_w_rob = median(real(w_ref), 1) + 1j * median(imag(w_ref), 1);
    s2_z_rob = (cfg.K * (s_y_rob.^2) + cfg.N * (s_w_rob.^2) + ...
               (cfg.K * cfg.N / (cfg.K + cfg.N)) * abs(mu_rob - mu_w_rob).^2) / (cfg.K + cfg.N);
    T2_rob = cfg.K * log(sqrt(s2_z_rob) ./ s_y_rob) + cfg.N * log(sqrt(s2_z_rob) ./ s_w_rob);

    cfg.lambda_slrt2_std = quantile(T2_std, 1 - cfg.Pfa_target);
    cfg.lambda_slrt2_rob = quantile(T2_rob, 1 - cfg.Pfa_target);
end