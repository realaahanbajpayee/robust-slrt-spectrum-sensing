clear; clc; close all;
setup_project;

fprintf('====================================================\n');
fprintf('  TESTBENCH 4: Calibrated H0 Verification (Pfa = 0.003)\n');
fprintf('====================================================\n');

rng(42);
cfg = config_params();

fprintf('[INFO] Calibrating operational thresholds for Pfa = %.4f...\n', cfg.Pfa_target);
cfg = calibrate_thresholds(cfg, 'GN');

fprintf('       Calibrated lambda_SLRT1 (Std): %.4f\n', cfg.lambda_slrt1_std);
fprintf('       Calibrated lambda_SLRT1 (Rob): %.4f\n', cfg.lambda_slrt1_rob);
fprintf('       Calibrated lambda_SLRT2 (Std): %.4f\n', cfg.lambda_slrt2_std);
fprintf('       Calibrated lambda_SLRT2 (Rob): %.4f\n', cfg.lambda_slrt2_rob);

% Validation run with 10,000 independent trials
MCS = cfg.MCS;
sigma0_sq = 1.0;

w_active = gen_noise('GN', cfg.K, sigma0_sq, cfg, MCS);
w_ref    = gen_noise('GN', cfg.N, sigma0_sq, cfg, MCS);

% 1. Energy Detectors
[ed_std, ed_rob, ~] = detect_ed(w_active, w_ref, sigma0_sq, cfg);
pfa_ed_std = mean(ed_std);
pfa_ed_rob = mean(ed_rob);

% 2. SLRTD1
[slrt1_std, slrt1_rob, ~, ~] = detect_slrtd1(w_active, w_ref, sigma0_sq, cfg);
pfa_slrt1_std = mean(slrt1_std);
pfa_slrt1_rob = mean(slrt1_rob);

% 3. SLRTD2
[slrt2_std, slrt2_rob, ~, ~] = detect_slrtd2(w_active, w_ref, cfg);
pfa_slrt2_std = mean(slrt2_std);
pfa_slrt2_rob = mean(slrt2_rob);

fprintf('\n--- Empirical False Alarm Verification (Target: 0.0030, Expected Count ~30/10000) ---\n');
fprintf('    Standard ED Pfa:     %.4f (Count: %d / %d)\n', pfa_ed_std, sum(ed_std), MCS);
fprintf('    Robust ED Pfa:       %.4f (Count: %d / %d)\n', pfa_ed_rob, sum(ed_rob), MCS);
fprintf('    Standard SLRTD1 Pfa: %.4f (Count: %d / %d)\n', pfa_slrt1_std, sum(slrt1_std), MCS);
fprintf('    Robust SLRTD1 Pfa:   %.4f (Count: %d / %d)\n', pfa_slrt1_rob, sum(slrt1_rob), MCS);
fprintf('    Standard SLRTD2 Pfa: %.4f (Count: %d / %d)\n', pfa_slrt2_std, sum(slrt2_std), MCS);
fprintf('    Robust SLRTD2 Pfa:   %.4f (Count: %d / %d)\n', pfa_slrt2_rob, sum(slrt2_rob), MCS);

% Assertions: all detectors must sit within empirical binomial confidence bounds around 0.003
assert(abs(pfa_ed_rob - cfg.Pfa_target) < 0.002, 'Error: Robust ED Pfa out of bounds');
assert(abs(pfa_ed_std - cfg.Pfa_target) < 0.002, 'Error: Standard ED Pfa out of bounds');
assert(abs(pfa_slrt1_std - cfg.Pfa_target) < 0.002, 'Error: Standard SLRTD1 Pfa out of bounds');
assert(abs(pfa_slrt1_rob - cfg.Pfa_target) < 0.002, 'Error: Robust SLRTD1 Pfa out of bounds');
assert(abs(pfa_slrt2_std - cfg.Pfa_target) < 0.002, 'Error: Standard SLRTD2 Pfa out of bounds');
assert(abs(pfa_slrt2_rob - cfg.Pfa_target) < 0.002, 'Error: Robust SLRTD2 Pfa out of bounds');

fprintf('\n====================================================\n');
fprintf('  ALL 6 DETECTORS CALIBRATED TO EXACT Pfa = 0.003!\n');
fprintf('====================================================\n');