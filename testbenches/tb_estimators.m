% TB_ESTIMATORS Rigorous Unit Testbench for compute_mad
clear; clc; close all;
setup_project;

fprintf('====================================================\n');
fprintf('  TESTBENCH 2: Robust Estimator Verification\n');
fprintf('====================================================\n');

rng(42); % Fixed seed for deterministic repeatability

%% 1. Asymptotic Consistency on Clean Gaussian Data
N_samples = 1e6;
true_sigma = 2.5;
x_gauss = true_sigma * randn(N_samples, 1);

s_std = std(x_gauss);
s_mad = compute_mad(x_gauss);

err_mad = abs(s_mad - true_sigma) / true_sigma;
fprintf('[TEST 1] Clean Gaussian Consistency (true sigma = %.2f):\n', true_sigma);
fprintf('         Standard Std Dev: %.4f\n', s_std);
fprintf('         Robust MAD:       %.4f (Relative Error: %.2f%%)\n', s_mad, err_mad * 100);
assert(err_mad < 0.01, 'Error: MAD failed asymptotic Gaussian consistency check (<1%% error)');
fprintf('[PASS] Consistency factor Cn = 1.4826 verified.\n\n');

%% 2. Outlier Magnitude Invariance (True Proof of 50% Breakdown)
% Under breakdown immunity, scaling outlier magnitude by 100x must NOT change MAD,
% whereas standard deviation must scale linearly with outlier magnitude.
K = 512;
num_trials = 1000;
clean_noise = randn(K, num_trials);
corrupt_ratio = 0.35; % 35% contamination (< 50% breakdown threshold)
num_spikes = round(corrupt_ratio * K);

% Case A: Outliers with amplitude = 500
noise_500 = clean_noise;
% Case B: Outliers with amplitude = 50,000 (100x larger!)
noise_50000 = clean_noise;

for col = 1:num_trials
    spike_idx = randperm(K, num_spikes);
    signs = 2 * (rand(num_spikes, 1) > 0.5) - 1;
    noise_500(spike_idx, col)   = 500   * signs;
    noise_50000(spike_idx, col) = 50000 * signs;
end

std_500   = mean(std(noise_500, 0, 1));
std_50000 = mean(std(noise_50000, 0, 1));

mad_500   = mean(compute_mad(noise_500, 1));
mad_50000 = mean(compute_mad(noise_50000, 1));

fprintf('[TEST 2] Outlier Magnitude Invariance (35%% contamination):\n');
fprintf('         Std Dev at spike = 500:   %.2f\n', std_500);
fprintf('         Std Dev at spike = 50000: %.2f (scaled by %.1fx!)\n', std_50000, std_50000 / std_500);
fprintf('         MAD at spike = 500:       %.4f\n', mad_500);
fprintf('         MAD at spike = 50000:     %.4f\n', mad_50000);

% Assertion A: Standard deviation is completely broken (scaled by ~100x)
assert(std_50000 / std_500 > 80, 'Error: Standard deviation did not exhibit expected unbounded scaling');

% Assertion B: MAD is invariant to outlier magnitude (relative change < 0.1%)
mad_divergence = abs(mad_50000 - mad_500) / mad_500;
fprintf('         MAD Relative Change under 100x spike: %.4f%%\n', mad_divergence * 100);
assert(mad_divergence < 0.001, 'Error: MAD scale shifted with outlier magnitude; breakdown immunity failed');
fprintf('[PASS] Breakdown immunity verified: MAD is invariant to spike amplitude.\n\n');

%% 3. Dynamic Theoretical Quantile Match
% Compute expected scale analytically from normal order statistics:
p_inlier = 0.50 / (1 - corrupt_ratio);
expected_mad = 1.4826 * norminv(0.5 + p_inlier / 2);

err_theory = abs(mad_500 - expected_mad) / expected_mad;
fprintf('[TEST 3] Dynamic Theoretical Comparison:\n');
fprintf('         Analytically Derived MAD: %.4f\n', expected_mad);
fprintf('         Simulated MAD:            %.4f\n', mad_500);
fprintf('         Relative Discrepancy:     %.2f%%\n', err_theory * 100);
assert(err_theory < 0.02, 'Error: Simulated MAD deviates from analytically derived folded normal quantile');
fprintf('[PASS] MAD matches first-principles order statistics within 2%% Monte Carlo variance.\n\n');

%% 4. Matrix Vectorization
matrix_input = randn(512, 100);
s_matrix = compute_mad(matrix_input, 1);
assert(isequal(size(s_matrix), [1, 100]), 'Error: Output dimension mismatch in 2D evaluation');
fprintf('[PASS] 2D matrix vectorization along dimension 1 verified.\n');

fprintf('====================================================\n');
fprintf('  ALL ESTIMATOR TESTS PASSED WITH STRICT RIGOR!\n');
fprintf('====================================================\n');