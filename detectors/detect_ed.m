% DETECT_ED Vectorized Standard and Robust (MAD) Energy Detectors
%
% Usage:
%   [dec_std, dec_rob, T_ed] = detect_ed(y, sigma2_w, cfg)
%
% Inputs:
%   y        - (K x M) Received sample matrix
%   sigma2_w - Nominal noise variance
%   cfg      - Configuration struct (contains K and Pfa_target)
%
% Outputs:
%   dec_std  - (1 x M) Logical decision vector for Standard ED (1 = H1, 0 = H0)
%   dec_rob  - (1 x M) Logical decision vector for Robust ED (1 = H1, 0 = H0)
%   T_ed     - (1 x M) Test statistic: sum of squared magnitudes

% DETECT_ED Vectorized Standard and Robust Energy Detectors
% function [dec_std, dec_rob, T_ed] = detect_ed(y, w_ref, sigma2_w, cfg)
%     K = cfg.K;
%     Pfa = cfg.Pfa_target;
% 
%     % Test Statistic: Active snapshot energy
%     T_ed = sum(abs(y).^2, 1);
% 
%     % 1. Standard ED (Analytical threshold using known sigma2_w)
%     lambda_std = (sigma2_w / 2) * chi2inv(1 - Pfa, 2 * K);
%     dec_std = (T_ed >= lambda_std);
% 
%     % 2. Robust ED (Using scale estimated from quiet reference slot w_ref)
%     if isfield(cfg, 'lambda_ed_rob_mult')
%         s_mad_ref = compute_mad(w_ref, 1);
%         lambda_rob = cfg.lambda_ed_rob_mult * (s_mad_ref.^2);
%     else
%         % Fallback to Gaussian formula using estimated scale
%         s_mad_ref = compute_mad(w_ref, 1);
%         lambda_rob = ((s_mad_ref.^2) / 2) * chi2inv(1 - Pfa, 2 * K);
%     end
%     dec_rob = (T_ed >= lambda_rob);
% end

% DETECT_ED Vectorized Standard and Robust Energy Detection
function [dec_std, dec_rob, T_ed, ratio_rob] = detect_ed(y, w_ref, sigma0_sq, cfg)
    T_ed = sum(abs(y).^2, 1);
    s_mad_ref = compute_mad(w_ref, 1);
    ratio_rob = T_ed ./ (s_mad_ref.^2);
    
    dec_std = (T_ed >= (sigma0_sq * cfg.lambda_ed_std));
    dec_rob = (ratio_rob >= cfg.lambda_ed_rob);
end