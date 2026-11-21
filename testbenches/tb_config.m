% TB_CONFIG Testbench to verify configuration integrity & analytical thresholds
clear; clc; close all;
setup_project;

fprintf('====================================================\n');
fprintf('  TESTBENCH 1: Configuration & Threshold Verification\n');
fprintf('====================================================\n');

cfg = config_params();

% Check snapshot dimensions
assert(cfg.K == 512, 'Error: K must be 512');
assert(cfg.N == 512, 'Error: N must be 512');
fprintf('[PASS] Snapshot parameters: K = %d, N = %d\n', cfg.K, cfg.N);

% Verify SLRTD1 Threshold
% Analytical approximation: lambda_1 ~ -K * U^2 = -512 * 9e-6 = -0.004608
approx_lambda1 = -cfg.K * (cfg.U_tol^2);
diff_lambda1 = abs(cfg.lambda_slrt1 - approx_lambda1);
fprintf('[INFO] SLRTD1 Exact Threshold:      %e\n', cfg.lambda_slrt1);
fprintf('[INFO] SLRTD1 2nd-Order Approx:     %e\n', approx_lambda1);
assert(cfg.lambda_slrt1 < 0, 'Error: SLRTD1 threshold must be negative!');
assert(diff_lambda1 < 1e-6, 'Error: Exact and approx SLRTD1 thresholds diverge significantly');
fprintf('[PASS] SLRTD1 Threshold verified (Strictly Negative, T1 <= lambda1)\n');

% Verify SLRTD2 Threshold
% Analytical approximation: lambda_2 ~ (K/8) * U^2 = (512/8) * 9e-6 = +5.76e-4
approx_lambda2 = (cfg.K / 8) * (cfg.U_tol^2);
diff_lambda2 = abs(cfg.lambda_slrt2 - approx_lambda2);
fprintf('[INFO] SLRTD2 Exact Threshold:      %e\n', cfg.lambda_slrt2);
fprintf('[INFO] SLRTD2 2nd-Order Approx:     %e\n', approx_lambda2);
assert(cfg.lambda_slrt2 > 0, 'Error: SLRTD2 threshold must be positive!');
assert(diff_lambda2 < 1e-5, 'Error: Exact and approx SLRTD2 thresholds diverge significantly');
fprintf('[PASS] SLRTD2 Threshold verified (Strictly Positive, T2 >= lambda2)\n');

fprintf('====================================================\n');
fprintf('  ALL CONFIGURATION TESTS PASSED SUCCESSFULLY!\n');
fprintf('====================================================\n');