% DETECT_SLRTD2 Vectorized Standard and Robust SLRTD2 (Fully Blind)
%
% Usage:
%   [dec_std, dec_rob, T_std, T_rob] = detect_slrtd2(y, w, cfg)
%
% Inputs:
%   y       - (K x M) Active sensing snapshot matrix
%   w       - (N x M) Reference noise snapshot matrix (quiet slot)
%   cfg     - Configuration struct (contains K, N, lambda_slrt2)
%
% Outputs:
%   dec_std - (1 x M) Logical decision vector for Standard SLRTD2
%   dec_rob - (1 x M) Logical decision vector for Robust SLRTD2
%   T_std   - (1 x M) Standard test statistic vector
%   T_rob   - (1 x M) Robust test statistic vector

% DETECT_SLRTD2 Vectorized Standard and Robust SLRTD2 (Fully Blind)
% Implements exact pooled MLE variance including the between-group mean difference.

function [dec_std, dec_rob, T_std, T_rob] = detect_slrtd2(y, w, cfg)
    K = cfg.K;
    N = cfg.N;

    % -------------------------------------------------------------
    % 1. Standard SLRTD2 (Exact Sample Moments)
    % -------------------------------------------------------------
    y_bar = mean(y, 1);
    w_bar = mean(w, 1);
    
    s2_y = var(y, 1, 1);
    s2_w = var(w, 1, 1);
    
    % Exact pooled variance from paper Eq. (40) and handwritten derivations:
    % s_z^2 = [K*s_y^2 + N*s_w^2 + (K*N / (K+N)) * |y_bar - w_bar|^2] / (K + N)
    mean_diff_sq = abs(y_bar - w_bar).^2;
    s2_z = (K * s2_y + N * s2_w + (K * N / (K + N)) * mean_diff_sq) / (K + N);
    
    s_y_std = sqrt(s2_y);
    s_w_std = sqrt(s2_w);
    s_z_std = sqrt(s2_z);

    % Test Statistic (T >= lambda)
    T_std = K * log(s_z_std ./ s_y_std) + N * log(s_z_std ./ s_w_std);

    % -------------------------------------------------------------
    % 2. Robust SLRTD2 (MAD Scale + Robust Median Difference)
    % -------------------------------------------------------------
    mu_y_rob = median(real(y), 1) + 1j * median(imag(y), 1);
    mu_w_rob = median(real(w), 1) + 1j * median(imag(w), 1);
    
    s_y_rob = compute_mad(y, 1);
    s_w_rob = compute_mad(w, 1);
    
    rob_mean_diff_sq = abs(mu_y_rob - mu_w_rob).^2;
    s2_z_rob = (K * (s_y_rob.^2) + N * (s_w_rob.^2) + (K * N / (K + N)) * rob_mean_diff_sq) / (K + N);
    s_z_rob = sqrt(s2_z_rob);

    T_rob = K * log(s_z_rob ./ s_y_rob) + N * log(s_z_rob ./ s_w_rob);

    % Decision Rules (Upper-tail critical region)
    dec_std = (T_std >= cfg.lambda_slrt2_std);
    dec_rob = (T_rob >= cfg.lambda_slrt2_rob);
end