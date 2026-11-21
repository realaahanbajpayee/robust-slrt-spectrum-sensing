% TB_GENERATORS Unit testbench for OFDM signal and all 4 noise engines
clear; clc; close all;
setup_project;

fprintf('====================================================\n');
fprintf('  TESTBENCH 3: Signal & Noise Engine Verification\n');
fprintf('====================================================\n');

rng(42); % Fixed seed for deterministic repeatability
cfg = config_params();

%% 1. Verify CP-OFDM Signal Power Normalization
num_test_trials = 5000;
x_sig = gen_ofdm_signal(cfg.K, cfg, num_test_trials);

measured_power = mean(abs(x_sig(:)).^2);
rel_err_sig = abs(measured_power - 1.0) / 1.0;

fprintf('[TEST 1] CP-OFDM Signal Power Normalization:\n');
fprintf('         Target Power:    1.0000\n');
fprintf('         Measured Power:  %.4f (Error: %.2f%%)\n', measured_power, rel_err_sig * 100);
assert(rel_err_sig < 0.015, 'Error: OFDM signal power deviates by >1.5% from unit power');
fprintf('[PASS] OFDM transmitter power normalized to unit energy.\n\n');

%% 2. Verify Variances for Finite-Variance Noise Models (GN, LN, IN)
target_sigma2 = 0.5; % Test noise power
N_large = 1e6;

% A. Gaussian Noise
w_gn = gen_noise('GN', N_large, target_sigma2, cfg);
var_gn = mean(abs(w_gn).^2);
err_gn = abs(var_gn - target_sigma2) / target_sigma2;
fprintf('[TEST 2A] Gaussian Noise Power Calibration:\n');
fprintf('          Target: %.4f | Measured: %.4f (Error: %.2f%%)\n', target_sigma2, var_gn, err_gn * 100);
assert(err_gn < 0.01, 'Error: Gaussian noise variance miscalibrated');
fprintf('[PASS] GN engine verified.\n\n');

% B. Laplacian Noise
w_ln = gen_noise('LN', N_large, target_sigma2, cfg);
var_ln = mean(abs(w_ln).^2);
err_ln = abs(var_ln - target_sigma2) / target_sigma2;
fprintf('[TEST 2B] Laplacian Noise Power Calibration:\n');
fprintf('          Target: %.4f | Measured: %.4f (Error: %.2f%%)\n', target_sigma2, var_ln, err_ln * 100);
assert(err_ln < 0.01, 'Error: Laplacian noise variance miscalibrated');
fprintf('[PASS] LN engine verified.\n\n');

% C. Bernoulli-Gaussian Impulsive Noise
w_in = gen_noise('IN', N_large, target_sigma2, cfg);
var_in = mean(abs(w_in).^2);
err_in = abs(var_in - target_sigma2) / target_sigma2;
fprintf('[TEST 2C] Impulsive Noise Power Calibration (pr=%.2f, eta=%d):\n', ...
        cfg.noise.IN_pr, cfg.noise.IN_eta);
fprintf('          Target: %.4f | Measured: %.4f (Error: %.2f%%)\n', target_sigma2, var_in, err_in * 100);
assert(err_in < 0.015, 'Error: Impulsive noise variance miscalibrated');
fprintf('[PASS] IN engine verified.\n\n');

%% 3. Dynamic Theoretical Kurtosis Checks (Zero Hardcoded Magic Numbers)
pr  = cfg.noise.IN_pr;
eta = cfg.noise.IN_eta;

% Theoretical values:
% Gaussian kurtosis = 3.0
% Laplacian kurtosis = 6.0
% Bernoulli-Gaussian kurtosis = 3 * (1 + 2*pr*eta + pr*eta^2) / (1 + pr*eta)^2
kurt_theory_gn = 3.0;
kurt_theory_ln = 6.0;
kurt_theory_in = 3.0 * (1 + 2*pr*eta + pr*(eta^2)) / ((1 + pr*eta)^2);

kurt_gn = kurtosis(real(w_gn));
kurt_ln = kurtosis(real(w_ln));
kurt_in = kurtosis(real(w_in));

fprintf('[TEST 3] Tail Heaviness (Real Component Kurtosis):\n');
fprintf('         GN Kurtosis: %.2f (Theoretical: %.2f)\n', kurt_gn, kurt_theory_gn);
fprintf('         LN Kurtosis: %.2f (Theoretical: %.2f)\n', kurt_ln, kurt_theory_ln);
fprintf('         IN Kurtosis: %.2f (Theoretical: %.2f)\n', kurt_in, kurt_theory_in);

assert(abs(kurt_gn - kurt_theory_gn) / kurt_theory_gn < 0.02, 'Error: GN kurtosis mismatch');
assert(abs(kurt_ln - kurt_theory_ln) / kurt_theory_ln < 0.03, 'Error: LN kurtosis mismatch');
assert(abs(kurt_in - kurt_theory_in) / kurt_theory_in < 0.03, 'Error: IN kurtosis mismatch');
fprintf('[PASS] Kurtosis values match exact first-principles theoretical derivations.\n\n');

%% 4. Generate S-alpha-S Noise & Visual Inspection (Time & PDF)
w_sas = gen_noise('SaSN', N_large, target_sigma2, cfg);

% Ensure no numerical NaNs/Infs occurred in CMS generator
assert(~any(isnan(w_sas(:))) && ~any(isinf(w_sas(:))), 'Error: CMS generator produced NaN/Inf');
fprintf('[PASS] CMS S-alpha-S generator completed with numerical stability.\n\n');

% % Set up combined Figure
% figure('Name', 'Noise Engines: Time Domain & Semi-Log PDF Verification', ...
%        'Position', [100, 100, 1100, 750], 'Color', 'w');
% 
% % --- TOP HALF: Time-Domain Waveforms (First 256 samples) ---
% N_vis = 256;
% t = 1:N_vis;
% 
% subplot(2, 4, 1);
% plot(t, real(w_gn(1:N_vis)), 'b', 'LineWidth', 1.0);
% title('1. Gaussian (AWGN)'); xlabel('Sample Index n'); ylabel('Real Amplitude');
% grid on; ylim([-3.5, 3.5]);
% 
% subplot(2, 4, 2);
% plot(t, real(w_ln(1:N_vis)), 'Color', [0 0.5 0], 'LineWidth', 1.0);
% title('2. Laplacian (\lambda=1.5)'); xlabel('Sample Index n');
% grid on; ylim([-4.5, 4.5]);
% 
% subplot(2, 4, 3);
% plot(t, real(w_in(1:N_vis)), 'r', 'LineWidth', 1.0);
% title(sprintf('3. Impulsive (p_r=%.1f, \\eta=%d)', pr, eta));
% xlabel('Sample Index n'); grid on;
% 
% subplot(2, 4, 4);
% plot(t, real(w_sas(1:N_vis)), 'm', 'LineWidth', 1.0);
% title('4. S\alphaS (\alpha=1.8)'); xlabel('Sample Index n');
% grid on;
% 
% % --- BOTTOM HALF: Semi-Log PDF Verification ---
% subplot(2, 1, 2);
% bins = linspace(-6, 6, 201);
% 
% [pdf_gn, ~] = histcounts(real(w_gn) / std(real(w_gn)), bins, 'Normalization', 'pdf');
% [pdf_ln, ~] = histcounts(real(w_ln) / std(real(w_ln)), bins, 'Normalization', 'pdf');
% [pdf_in, ~] = histcounts(real(w_in) / std(real(w_in)), bins, 'Normalization', 'pdf');
% 
% % For SaSN normalize by interquartile range (IQR / 1.349) since variance is infinite
% sas_scale = iqr(real(w_sas)) / 1.349;
% [pdf_sas, ~] = histcounts(real(w_sas) / sas_scale, bins, 'Normalization', 'pdf');
% 
% bin_centers = 0.5 * (bins(1:end-1) + bins(2:end));
% 
% semilogy(bin_centers, pdf_gn,  'b-',  'LineWidth', 1.8, 'DisplayName', 'Gaussian (AWGN)'); hold on;
% semilogy(bin_centers, pdf_ln,  'g--', 'LineWidth', 1.8, 'DisplayName', 'Laplacian (\lambda=1.5)');
% semilogy(bin_centers, pdf_in,  'r-.', 'LineWidth', 1.8, 'DisplayName', 'Impulsive (p_r=0.1, \eta=10)');
% semilogy(bin_centers, pdf_sas, 'm:',  'LineWidth', 2.0, 'DisplayName', 'S\alphaS (\alpha=1.8)');
% 
% grid on; box on;
% xlim([-5, 5]); ylim([1e-4, 1]);
% xlabel('Normalized Amplitude (x / \sigma)');
% ylabel('Probability Density Function (log-scale)');
% title('Empirical Noise Distributions: Heavy-Tail Profile Verification');
% legend('Location', 'south');
% 
% fprintf('[PASS] Waveforms and semi-log PDF figures generated successfully.\n');
% fprintf('====================================================\n');
% fprintf('  ALL GENERATOR TESTS PASSED WITH STRICT RIGOR!\n');
% fprintf('====================================================\n');

% Set up IEEE-formatted white-background Figure
fig = figure('Name', 'Noise Engines: Time Domain & Semi-Log PDF Verification', ...
    'Units', 'inches', 'Position', [1, 1, 11, 6.2], ...
    'Color', [1 1 1], 'InvertHardcopy', 'off');

% Colorblind-safe IEEE palette
c_gn  = [0.000, 0.447, 0.741]; % Navy Blue
c_ln  = [0.150, 0.600, 0.250]; % Forest Green
c_in  = [0.850, 0.150, 0.150]; % Crimson Red
c_sas = [0.494, 0.184, 0.556]; % Royal Purple

% --- TOP HALF: Time-Domain Waveforms (First 256 samples) ---
N_vis = 256;
t = 1:N_vis;

ax1 = subplot(2, 4, 1);
plot(t, real(w_gn(1:N_vis)), 'Color', c_gn, 'LineWidth', 1.0);
title('(a) Gaussian (AWGN)', 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlabel('Sample Index n', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
ylabel('Real Amplitude', 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlim([1, N_vis]); ylim([-4, 4]);

ax2 = subplot(2, 4, 2);
plot(t, real(w_ln(1:N_vis)), 'Color', c_ln, 'LineWidth', 1.0);
title('(b) Laplacian (\sigma^2 = 0.5)', 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlabel('Sample Index n', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlim([1, N_vis]); ylim([-4, 4]);

ax3 = subplot(2, 4, 3);
plot(t, real(w_in(1:N_vis)), 'Color', c_in, 'LineWidth', 1.0);
title(sprintf('(c) Impulsive (p_r=%.1f, \\eta=%d)', pr, eta), 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlabel('Sample Index n', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlim([1, N_vis]); ylim([-4, 4]);

ax4 = subplot(2, 4, 4);
plot(t, real(w_sas(1:N_vis)), 'Color', c_sas, 'LineWidth', 1.0);
title('(d) S\alphaSN (\alpha=1.8)', 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlabel('Sample Index n', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
xlim([1, N_vis]); ylim([-4, 4]);

% --- BOTTOM HALF: Semi-Log PDF Verification ---
ax5 = subplot(2, 1, 2);
bins = linspace(-6, 6, 201);

[pdf_gn, ~] = histcounts(real(w_gn) / std(real(w_gn)), bins, 'Normalization', 'pdf');
[pdf_ln, ~] = histcounts(real(w_ln) / std(real(w_ln)), bins, 'Normalization', 'pdf');
[pdf_in, ~] = histcounts(real(w_in) / std(real(w_in)), bins, 'Normalization', 'pdf');

% Normalize SaSN by interquartile range (IQR / 1.349) since variance is infinite
sas_scale = iqr(real(w_sas)) / 1.349;
[pdf_sas, ~] = histcounts(real(w_sas) / sas_scale, bins, 'Normalization', 'pdf');

bin_centers = 0.5 * (bins(1:end-1) + bins(2:end));

semilogy(ax5, bin_centers, pdf_gn,  '-',  'Color', c_gn,  'LineWidth', 1.8, 'DisplayName', 'Gaussian (AWGN)'); hold(ax5, 'on');
semilogy(ax5, bin_centers, pdf_ln,  '--', 'Color', c_ln,  'LineWidth', 1.8, 'DisplayName', 'Laplacian (\sigma^2 = 0.5)');
semilogy(ax5, bin_centers, pdf_in,  '-.', 'Color', c_in,  'LineWidth', 1.8, 'DisplayName', 'Impulsive (p_r=0.1, \eta=10)');
semilogy(ax5, bin_centers, pdf_sas, ':',  'Color', c_sas, 'LineWidth', 2.2, 'DisplayName', 'S\alphaSN (\alpha=1.8)');

xlim(ax5, [-5, 5]); ylim(ax5, [1e-4, 1.2]);
xlabel(ax5, 'Normalized Amplitude (x / \sigma)', 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
ylabel(ax5, 'Probability Density (log-scale)', 'FontName', 'Times New Roman', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
title(ax5, '(e) Empirical Noise Distributions: Heavy-Tail Profile Verification (10^6 Samples)', ...
    'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);

lgd = legend(ax5, 'Location', 'south', 'NumColumns', 2, 'FontName', 'Times New Roman', 'FontSize', 9);
set(lgd, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7]);

% Apply uniform light-mode IEEE styling across all 5 subplots
all_axes = [ax1, ax2, ax3, ax4, ax5];
for k = 1:length(all_axes)
    set(all_axes(k), 'FontName', 'Times New Roman', 'FontSize', 9.5, ...
        'Color', [1 1 1], 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
        'Box', 'on', 'LineWidth', 1.0, ...
        'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.4);
end

exportgraphics(fig, 'tb_generators_ieee.png', 'Resolution', 300);
fprintf('[PASS] IEEE-formatted figure exported to tb_generators_ieee.png\n');