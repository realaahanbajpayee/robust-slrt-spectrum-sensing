% GEN_NOISE Synthesizes calibrated noise across all four channel distributions
%
% Usage:
%   w = gen_noise(noise_type, K, sigma2_w, cfg)
%   w = gen_noise(noise_type, K, sigma2_w, cfg, num_trials)
%
% Inputs:
%   noise_type - 'GN'   : Additive White Gaussian Noise
%                'LN'   : Laplacian Noise
%                'IN'   : Bernoulli-Gaussian Impulsive Noise
%                'SaSN' : Symmetric alpha-Stable Noise (CMS algorithm)
%   K          - Window length (samples per snapshot)
%   sigma2_w   - Calibrated total noise variance (or dispersion for SaSN)
%   cfg        - Configuration struct containing distribution parameters
%   num_trials - Number of parallel snapshots (default: 1)
%
% Output:
%   w - (K x num_trials) complex noise matrix

function w = gen_noise(noise_type, K, sigma2_w, cfg, num_trials)
    if nargin < 5 || isempty(num_trials), num_trials = 1; end
    
    switch upper(noise_type)
        case 'GN'
            % Standard Complex White Gaussian Noise: CN(0, sigma2_w)
            w = sqrt(sigma2_w / 2) * (randn(K, num_trials) + 1j * randn(K, num_trials));
    
        case 'LN'
            % Complex Laplacian Noise: independent Laplacians for real and imag
            % Variance per component = sigma2_w / 2.
            % Laplace scale b = sqrt(sigma_comp^2 / 2) = sqrt(sigma2_w / 4).
            b = sqrt(sigma2_w / 4);
    
            % Inverse CDF transformation: x = -b * sgn(u - 0.5) * ln(1 - 2*|u - 0.5|)
            u_r = rand(K, num_trials);
            u_i = rand(K, num_trials);
    
            w_r = -b * sign(u_r - 0.5) .* log(1 - 2 * abs(u_r - 0.5));
            w_i = -b * sign(u_i - 0.5) .* log(1 - 2 * abs(u_i - 0.5));
            w = w_r + 1j * w_i;
    
        case 'IN'
            % Bernoulli-Gaussian Impulsive Noise: w = w_g + b_n * w_I
            pr  = cfg.noise.IN_pr;   % Burst probability (default: 0.10)
            eta = cfg.noise.IN_eta;  % Impulsive power ratio (default: 10)
    
            % Nominal background Gaussian variance calibrated to yield total variance sigma2_w:
            % E[|w|^2] = sigma2_g * (1 + pr * eta) = sigma2_w
            sigma2_g = sigma2_w / (1 + pr * eta);
            sigma2_I = eta * sigma2_g;
    
            % Background Gaussian
            w_g = sqrt(sigma2_g / 2) * (randn(K, num_trials) + 1j * randn(K, num_trials));
    
            % Impulsive burst component
            w_I = sqrt(sigma2_I / 2) * (randn(K, num_trials) + 1j * randn(K, num_trials));
    
            % Independent Bernoulli arrival switch
            b_n = rand(K, num_trials) < pr;
    
            w = w_g + b_n .* w_I;
    
        case 'SASN'
            % Symmetric alpha-Stable Noise via Chambers-Mallows-Stuck (CMS) algorithm
            alpha = cfg.noise.SaS_a; % Characteristic exponent (default: 1.8)
            gamma = sigma2_w;        % Dispersion parameter tied to GSNR
    
            % CMS synthesis for real component
            V_r = (rand(K, num_trials) - 0.5) * pi;
            W_r = -log(rand(K, num_trials)); % Exponential(1)
            w_r = (gamma^(1/alpha)) * (sin(alpha * V_r) ./ (cos(V_r).^(1/alpha))) .* ...
                ((cos(V_r - alpha * V_r) ./ W_r).^((1 - alpha) / alpha));
    
            % CMS synthesis for imaginary component
            V_i = (rand(K, num_trials) - 0.5) * pi;
            W_i = -log(rand(K, num_trials)); % Exponential(1)
            w_i = (gamma^(1/alpha)) * (sin(alpha * V_i) ./ (cos(V_i).^(1/alpha))) .* ...
                ((cos(V_i - alpha * V_i) ./ W_i).^((1 - alpha) / alpha));
    
            w = (w_r + 1j * w_i) / sqrt(2);
    
        otherwise
            error('Unknown noise type: %s. Choose GN, LN, IN, or SaSN.', noise_type);
    end
end