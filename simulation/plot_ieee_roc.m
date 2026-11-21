% PLOT_IEEE_ROC Generates publication-ready 4-panel IEEE-formatted ROC curves
%
% Usage:
%   plot_ieee_roc(all_results, cfg)

function plot_ieee_roc(all_results, cfg)
noise_models = {'GN', 'LN', 'IN', 'SaSN'};
titles = { ...
    '(a) Gaussian Noise (AWGN)', ...
    '(b) Laplacian Noise (LN, \lambda=1.5)', ...
    '(c) Impulsive Noise (IN, p=0.1, \eta=10)', ...
    '(d) Symmetric \alpha-Stable Noise (S\alphaSN, \alpha=1.8, \gamma=1.0)' ...
    };

% -------------------------------------------------------------
% Distinct Color Palette & Marker Styles for all 6 Detectors
% -------------------------------------------------------------
styles = struct( ...
    'ed_std',    struct('color', [0.850, 0.150, 0.150], 'ls', '-',  'marker', 'o', 'name', 'ED (Std)'), ...
    'ed_rob',    struct('color', [0.929, 0.550, 0.100], 'ls', '--', 'marker', 's', 'name', 'Robust ED (RED)'), ...
    'slrt1_std', struct('color', [0.000, 0.447, 0.741], 'ls', '-',  'marker', '^', 'name', 'SLRTD1 (Std)'), ...
    'slrt1_rob', struct('color', [0.100, 0.700, 0.850], 'ls', '--', 'marker', 'd', 'name', 'Robust SLRTD1'), ...
    'slrt2_std', struct('color', [0.150, 0.600, 0.250], 'ls', '-',  'marker', 'v', 'name', 'SLRTD2 (Std)'), ...
    'slrt2_rob', struct('color', [0.494, 0.184, 0.556], 'ls', '--', 'marker', 'x', 'name', 'Robust SLRTD2') ...
    );

% Create publication figure
fig = figure('Name', 'IEEE Replicated ROC Curves', ...
    'Units', 'inches', 'Position', [1, 1, 11, 7.5], ...
    'Color', [1 1 1], 'InvertHardcopy', 'off');

for m = 1:4
    mod = noise_models{m};
    res = all_results.(mod);
    snr = res.snr_grid;

    ax = subplot(2, 2, m);
    hold(ax, 'on');

    % Plot curves with spaced markers for clarity
    p_ed_std  = plot(snr, res.pd_ed_std,    'Color', styles.ed_std.color,    'LineStyle', styles.ed_std.ls,    'LineWidth', 1.8, 'Marker', styles.ed_std.marker,    'MarkerSize', 5, 'MarkerIndices', 1:2:length(snr), 'DisplayName', styles.ed_std.name);
    p_ed_rob  = plot(snr, res.pd_ed_rob,    'Color', styles.ed_rob.color,    'LineStyle', styles.ed_rob.ls,    'LineWidth', 1.8, 'Marker', styles.ed_rob.marker,    'MarkerSize', 5, 'MarkerIndices', 2:2:length(snr), 'DisplayName', styles.ed_rob.name);
    p_s1_std  = plot(snr, res.pd_slrt1_std, 'Color', styles.slrt1_std.color, 'LineStyle', styles.slrt1_std.ls, 'LineWidth', 1.8, 'Marker', styles.slrt1_std.marker, 'MarkerSize', 5, 'MarkerIndices', 1:2:length(snr), 'DisplayName', styles.slrt1_std.name);
    p_s1_rob  = plot(snr, res.pd_slrt1_rob, 'Color', styles.slrt1_rob.color, 'LineStyle', styles.slrt1_rob.ls, 'LineWidth', 1.8, 'Marker', styles.slrt1_rob.marker, 'MarkerSize', 5, 'MarkerIndices', 2:2:length(snr), 'DisplayName', styles.slrt1_rob.name);
    p_s2_std  = plot(snr, res.pd_slrt2_std, 'Color', styles.slrt2_std.color, 'LineStyle', styles.slrt2_std.ls, 'LineWidth', 1.8, 'Marker', styles.slrt2_std.marker, 'MarkerSize', 5, 'MarkerIndices', 1:2:length(snr), 'DisplayName', styles.slrt2_std.name);
    p_s2_rob  = plot(snr, res.pd_slrt2_rob, 'Color', styles.slrt2_rob.color, 'LineStyle', styles.slrt2_rob.ls, 'LineWidth', 1.8, 'Marker', styles.slrt2_rob.marker, 'MarkerSize', 6, 'MarkerIndices', 2:2:length(snr), 'DisplayName', styles.slrt2_rob.name);

    % Target Pd = 0.90 reference line
    yline(0.90, 'k:', 'LineWidth', 1.2, 'Alpha', 0.7, 'DisplayName', 'Target P_d = 0.90');

    % Axes limits
    xlim([-20, 5]);
    ylim([0, 1.02]);

    % IEEE Axis Typography and Clean Light Styling
    set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, ...
        'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
        'Color', [1 1 1], 'LineWidth', 1.1, ...
        'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', ...
        'GridLineStyle', ':', 'GridAlpha', 0.4, 'GridColor', [0.5 0.5 0.5]);

    xlabel(ax, 'SNR / GSNR (dB)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(ax, 'Probability of Detection (P_d)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(ax, titles{m}, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0 0]);

    % Legend styling
    if m == 1
        lgd = legend([p_ed_std, p_ed_rob, p_s1_std, p_s1_rob, p_s2_std, p_s2_rob], ...
            'Location', 'northwest', 'FontName', 'Times New Roman', 'FontSize', 8);
        set(lgd, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7], 'Box', 'on');
    else
        lgd = legend([p_ed_std, p_ed_rob, p_s1_std, p_s1_rob, p_s2_std, p_s2_rob], ...
            'Location', 'southeast', 'FontName', 'Times New Roman', 'FontSize', 8);
        set(lgd, 'Color', [1 1 1], 'EdgeColor', [0.7 0.7 0.7], 'Box', 'on');
    end

    % Inside plot_ieee_roc.m loop:
    if m == 4
        xlabel(ax, 'GSNR (dB)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
    else
        xlabel(ax, 'SNR (dB)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0 0 0]);
    end
end

% Optional high-res export
% exportgraphics(fig, 'replicated_roc_curves_ieee.png', 'Resolution', 300);
% fprintf('[INFO] High-resolution IEEE figure exported to replicated_roc_curves_ieee.png\n');
end