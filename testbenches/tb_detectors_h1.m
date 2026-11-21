% TB_DETECTORS_H1 Evaluates H1 detection under high SNR (0 dB)
clear; clc; close all;
setup_project;

fprintf('====================================================\n');
fprintf('  TESTBENCH 5: H1 Signal Sensitivity Sanity Check\n');
fprintf('====================================================\n');

rng(101);
cfg = config_params();

% Calibrate operational thresholds
cfg = calibrate_thresholds(cfg);

MCS = cfg.MCS;
snr_test_db = 0; % 0 dB SNR: Signal and Noise have equal average power (P_x = 1.0, sigma2_w = 1.0)
sigma0_sq = 10^(-snr_test_db / 10);

fprintf('[INFO] Synthesizing %d trials under H1 (CP-OFDM + AWGN at SNR = %d dB)...\n', MCS, snr_test_db);

% Generate signal and noise
x_sig    = gen_ofdm_signal(cfg.K, cfg, MCS);
w_active = gen_noise('GN', cfg.K, sigma0_sq, cfg, MCS);
w_ref    = gen_noise('GN', cfg.N, sigma0_sq, cfg, MCS);

% Received active snapshot: y = x + w (flat channel h = 1)
y_rx = x_sig + w_active;

%% 1. Energy Detectors
[ed_std, ed_rob, ~] = detect_ed(y_rx, w_ref, sigma0_sq, cfg);
pd_ed_std = mean(ed_std);
pd_ed_rob = mean(ed_rob);

%% 2. SLRTD1
[slrt1_std, slrt1_rob, ~, ~] = detect_slrtd1(y_rx, w_ref, sigma0_sq, cfg);
pd_slrt1_std = mean(slrt1_std);
pd_slrt1_rob = mean(slrt1_rob);

%% 3. SLRTD2
[slrt2_std, slrt2_rob, ~, ~] = detect_slrtd2(y_rx, w_ref, cfg);
pd_slrt2_std = mean(slrt2_std);
pd_slrt2_rob = mean(slrt2_rob);

fprintf('\n--- Empirical Detection Verification at 0 dB (Target: Pd = 1.0000) ---\n');
fprintf('    Standard ED Pd:     %.4f (Count: %d / %d)\n', pd_ed_std, sum(ed_std), MCS);
fprintf('    Robust ED Pd:       %.4f (Count: %d / %d)\n', pd_ed_rob, sum(ed_rob), MCS);
fprintf('    Standard SLRTD1 Pd: %.4f (Count: %d / %d)\n', pd_ed_std, sum(slrt1_std), MCS);
fprintf('    Robust SLRTD1 Pd:   %.4f (Count: %d / %d)\n', pd_slrt1_rob, sum(slrt1_rob), MCS);
fprintf('    Standard SLRTD2 Pd: %.4f (Count: %d / %d)\n', pd_slrt2_std, sum(slrt2_std), MCS);
fprintf('    Robust SLRTD2 Pd:   %.4f (Count: %d / %d)\n', pd_slrt2_rob, sum(slrt2_rob), MCS);

% All detectors must achieve 100% detection at 0 dB SNR
assert(pd_ed_std == 1.0, 'Error: Standard ED failed to detect 0 dB signal');
assert(pd_ed_rob == 1.0, 'Error: Robust ED failed to detect 0 dB signal');
assert(pd_slrt1_std == 1.0, 'Error: Standard SLRTD1 failed to detect 0 dB signal');
assert(pd_slrt1_rob == 1.0, 'Error: Robust SLRTD1 failed to detect 0 dB signal');
assert(pd_slrt2_std == 1.0, 'Error: Standard SLRTD2 failed to detect 0 dB signal');
assert(pd_slrt2_rob == 1.0, 'Error: Robust SLRTD2 failed to detect 0 dB signal');

fprintf('\n====================================================\n');
fprintf('  ALL 6 DETECTORS ACHIEVED 100%% DETECTION AT 0 dB!\n');
fprintf('====================================================\n');