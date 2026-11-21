% DETECT_SLRTD1 Vectorized Standard and Robust SLRTD1 (Semi-Blind)
function [dec_std, dec_rob, T_std, T_rob] = detect_slrtd1(y, w_ref, sigma0_sq, cfg)
    K = cfg.K;
    mu0 = cfg.mu0;

    % 1. Standard SLRTD1 (Sample Mean & Sample Variance)
    y_bar = mean(y, 1);
    U_std = (abs(y_bar - mu0).^2) / sigma0_sq;
    s2_std = var(y, 1, 1);
    V_std  = s2_std / sigma0_sq;
    T_std  = K * (log(V_std) + 1 - U_std - V_std);

    % 2. Robust SLRTD1 (Median Location & MAD Scale)
    mu_rob = median(real(y), 1) + 1j * median(imag(y), 1);
    s_y_rob = compute_mad(y, 1);
    s_w_rob = compute_mad(w_ref, 1);
    
    V_rob = (s_y_rob.^2) ./ (s_w_rob.^2);
    U_rob = (abs(mu_rob - mu0).^2) ./ (s_w_rob.^2);
    T_rob = K * (log(V_rob) + 1 - U_rob - V_rob);

    % Decisions (T <= lambda)
    dec_std = (T_std <= cfg.lambda_slrt1_std);
    dec_rob = (T_rob <= cfg.lambda_slrt1_rob);
end