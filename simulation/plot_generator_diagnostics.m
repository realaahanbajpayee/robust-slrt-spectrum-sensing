% PLOT_GENERATOR_DIAGNOSTICS Exports publication-ready IEEE figures for Slides 4 & 6
clear; clc; close all;
setup_project;
rng(2026);

cfg = config_params();
K = cfg.K;
MCS = cfg.MCS;

%% ========================================================================
%  FIGURE 1: OFDM Time-Domain Snapshot & Averaged PSD (For Slide 4)
%  ========================================================================
X_ofdm = gen_ofdm_signal(K, cfg, MCS);
meas_power = mean(abs(X_ofdm(:)).^2);

% Compute ensemble-averaged Power Spectral Density across all 10^4 snapshots
psd_linear = mean(abs(fft(X_ofdm, K, 1) / sqrt(K)).^2, 2);
psd_db = 10 * log10(fftshift(psd_linear));
freq_bins = (-K/2 : K/2 - 1);

fig1 = figure('Name', 'OFDM Verification', 'Units', 'inches', 'Position', [1, 1, 10.5, 4.0], ...
              'Color', [1 1 1], 'InvertHardcopy', 'off');

% Panel (a): Time-Domain Real & Imaginary Components (Single Snapshot)
ax1 = subplot(1, 2, 1); hold(ax1, 'on');
plot(0:K-1, real(X_ofdm(:, 1)), 'Color', [0.000, 0.447, 0.741], 'LineWidth', 1.1, 'DisplayName', 'In-Phase Re\{x(n)\}');
plot(0:K-1, imag(X_ofdm(:, 1)), 'Color', [0.850, 0.325, 0.098], 'LineWidth', 1.0, 'LineStyle', '--', 'DisplayName', 'Quadrature Im\{x(n)\}');
xlim([0, K-1]); ylim([-3.5, 3.5]);
set(ax1, 'FontName', 'Times New Roman', 'FontSize', 10, 'Color', [1 1 1], ...
         'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], 'Box', 'on', ...
         'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.4);
xlabel(ax1, 'Sample Index (n)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
ylabel(ax1, 'Amplitude', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
title(ax1, sprintf('(a) Time-Domain OFDM Snapshot (Mean Power = %.3f)', meas_power), ...
      'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
lgd1 = legend(ax1, 'Location', 'northeast', 'FontName', 'Times New Roman', 'FontSize', 8.5);
set(lgd1, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7]);

% Panel (b): Ensemble-Averaged Power Spectral Density
ax2 = subplot(1, 2, 2); hold(ax2, 'on');
plot(freq_bins, psd_db, 'Color', [0.150, 0.600, 0.250], 'LineWidth', 1.5, 'DisplayName', 'Simulated OFDM PSD');
yline(0, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Theoretical Unit PSD (0 dB)');
xlim([-K/2, K/2 - 1]); ylim([-3, 3]);
set(ax2, 'FontName', 'Times New Roman', 'FontSize', 10, 'Color', [1 1 1], ...
         'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], 'Box', 'on', ...
         'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.4);
xlabel(ax2, 'Subcarrier Index (k)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
ylabel(ax2, 'Normalized PSD (dB)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
title(ax2, '(b) Averaged Power Spectral Density (512 Subcarriers)', ...
      'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
lgd2 = legend(ax2, 'Location', 'southeast', 'FontName', 'Times New Roman', 'FontSize', 8.5);
set(lgd2, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7]);

exportgraphics(fig1, 'ofdm_diagnostics_ieee.png', 'Resolution', 300);
fprintf('[INFO] Exported ofdm_diagnostics_ieee.png\n');

%% ========================================================================
%  FIGURE 2: 4-Regime Noise Time Traces & Heavy-Tail PDFs (For Slide 6)
%  ========================================================================
models = {'GN', 'LN', 'IN', 'SaSN'};
titles_t = { ...
    '(a) Gaussian (GN): \sigma^2 = 1.00', ...
    '(b) Laplacian (LN): \sigma^2 = 1.00', ...
    '(c) Impulsive (IN, p=0.1, \eta=10): \sigma^2 = 1.00', ...
    '(d) S\alphaSN (\alpha=1.8, \gamma=1.0): \sigma^2 = \infty' ...
};
colors = { ...
    [0.000, 0.447, 0.741], ... % Navy Blue
    [0.150, 0.600, 0.250], ... % Forest Green
    [0.850, 0.150, 0.150], ... % Crimson Red
    [0.494, 0.184, 0.556]  ... % Royal Purple
};

fig2 = figure('Name', 'Noise Models Verification', 'Units', 'inches', 'Position', [1, 1, 12, 6.2], ...
              'Color', [1 1 1], 'InvertHardcopy', 'off');

% Reference Gaussian PDF for real part: N(0, 0.5) since complex variance = 1.0
x_grid = linspace(-8, 8, 400);
pdf_gauss_ref = (1 / sqrt(2 * pi * 0.5)) * exp(-(x_grid.^2) / (2 * 0.5));

for m = 1:4
    W = gen_noise(models{m}, K, 1.0, cfg, MCS);
    w_real = real(W(:));
    
    % Top Row: 512-sample time-domain trace (Real part)
    ax_t = subplot(2, 4, m); hold(ax_t, 'on');
    plot(0:K-1, real(W(:, 1)), 'Color', colors{m}, 'LineWidth', 0.9);
    xlim([0, K-1]); ylim([-10, 10]);
    set(ax_t, 'FontName', 'Times New Roman', 'FontSize', 9, 'Color', [1 1 1], ...
              'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], 'Box', 'on', ...
              'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.4);
    xlabel(ax_t, 'Sample Index (n)', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
    if m == 1
        ylabel(ax_t, 'Re\{w(n)\} Amplitude', 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0]);
    end
    title(ax_t, titles_t{m}, 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0]);
    
    % Bottom Row: Empirical Semi-Log PDF vs. Gaussian Baseline
    ax_p = subplot(2, 4, m + 4); hold(ax_p, 'on');
    edges = linspace(-8, 8, 121);
    [counts, ~] = histcounts(w_real(abs(w_real) <= 8), edges, 'Normalization', 'pdf');
    centers = 0.5 * (edges(1:end-1) + edges(2:end));
    
    semilogy(ax_p, x_grid, pdf_gauss_ref, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Gaussian Ref');
    semilogy(ax_p, centers, max(counts, 1e-5), 'Color', colors{m}, 'LineWidth', 1.6, 'DisplayName', models{m});
    set(ax_p, 'YScale', 'log');
    xlim([-8, 8]); ylim([1e-4, 2]);
    set(ax_p, 'FontName', 'Times New Roman', 'FontSize', 9, 'Color', [1 1 1], ...
              'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], 'Box', 'on', ...
              'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.4);
    xlabel(ax_p, 'Amplitude', 'FontName', 'Times New Roman', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0 0 0]);
    if m == 1
        ylabel(ax_p, 'Log Probability Density', 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0]);
    end
    lgd = legend(ax_p, 'Location', 'south', 'FontName', 'Times New Roman', 'FontSize', 7.5);
    set(lgd, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7]);
end

exportgraphics(fig2, 'noise_diagnostics_ieee.png', 'Resolution', 300);
fprintf('[INFO] Exported noise_diagnostics_ieee.png\n');