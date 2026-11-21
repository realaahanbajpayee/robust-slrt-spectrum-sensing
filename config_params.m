% CONFIG_PARAMS Central parameters matching paper specifications
function cfg = config_params()
    % Snapshot dimensions
    cfg.K = 512;          % Active sensing window length (samples)
    cfg.N = 512;          % Reference noise window length for SLRTD2 (samples)
    
    % Detection performance targets
    cfg.Pfa_target = 0.003; % Target false alarm rate under H0
    cfg.U_tol      = 0.003; % Baseline noise tolerance drift parameter (Upsilon)
    cfg.mu0        = 0;     % Nominal noise mean (complex baseband)
    
    % Monte Carlo parameters
    cfg.MCS = 10000;        % Number of Monte Carlo runs per SNR point
    cfg.snr_grid = -20:1:5; % SNR sweep range in dB
    
    % Noise model parameters
    cfg.noise.IN_pr   = 0.1;  % Impulsive burst probability
    cfg.noise.IN_eta  = 10;   % Impulsive noise power ratio
    cfg.noise.LN_lam  = 1.5;  % Laplacian scale parameter
    cfg.noise.SaS_a   = 1.8;  % Symmetric alpha-Stable characteristic exponent
    cfg.noise.SaS_gam = 1.0;  % Symmetric alpha-Stable dispersion (gamma)
    
    % Closed-form Analytical Thresholds (derived from hand calculations)
    % SLRTD1: lambda = K * [ln(1 - U^2) - 2*U^2*mu0^2/sigma0^2] -> K * ln(1 - U^2)
    cfg.lambda_slrt1 = cfg.K * log(1 - cfg.U_tol^2);
    
    % SLRTD2: For K = N = 512, symmetric expansion gives lambda ~ (K/8) * U^2
    % Exact closed-form formulation from paper Eq. (51):
    K = cfg.K; N = cfg.N; U = cfg.U_tol;
    cfg.lambda_slrt2 = (K/2)*log(1 + (K*U)/(K+N)) + ...
                       (N/2)*log((1/(1+U)) + (K*U)/((K+N)*(1+U)));
end