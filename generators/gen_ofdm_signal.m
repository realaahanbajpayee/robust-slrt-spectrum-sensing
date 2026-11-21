% GEN_OFDM_SIGNAL Generates a complex baseband CP-OFDM snapshot
%
% Usage:
%   x = gen_ofdm_signal(K, cfg)
%   x = gen_ofdm_signal(K, cfg, num_trials)
%
% Inputs:
%   K          - Number of subcarriers (snapshot length, default: cfg.K)
%   cfg        - Configuration struct
%   num_trials - Number of snapshots to generate in parallel (default: 1)
%
% Output:
%   x - (K x num_trials) complex baseband signal with E[|x|^2] = 1.0

function x = gen_ofdm_signal(K, cfg, num_trials)
    if nargin < 1 || isempty(K), K = cfg.K; end
    if nargin < 3 || isempty(num_trials), num_trials = 1; end
    
    % 1. Generate independent QPSK constellation symbols on subcarriers
    % Bits: 00 -> (1+j)/sqrt(2), 01 -> (-1+j)/sqrt(2), etc.
    qpsk_symbols = ( (2*(rand(K, num_trials) > 0.5) - 1) + ...
        1j*(2*(rand(K, num_trials) > 0.5) - 1) ) / sqrt(2);
    
    % 2. Synthesize time-domain OFDM symbol via unitary IFFT
    % Normalizing by sqrt(K) maintains exact average sample power E[|x|^2] = 1.0
    x = sqrt(K) * ifft(qpsk_symbols, K, 1);
end