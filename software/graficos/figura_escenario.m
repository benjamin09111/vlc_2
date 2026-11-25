function figura_escenario()
%FIGURA_ESCENARIO  Esquema lateral y en planta de la galeria minera simulada.
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));
est = estilo_figura();
cfg = parametros('mina');

fig = est.nueva(8.9, 8.2);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Panel superior: corte longitudinal (X-Z) ---
ax1 = nexttile(tl);
hold(ax1, 'on');
% Galeria 26 x 4 m
rectangle(ax1, 'Position', [0 0 26 4], 'EdgeColor', 'k', 'LineWidth', 1.0, ...
    'FaceColor', [0.97 0.97 0.97]);
% Luminarias y AP Wi-Fi
plot(ax1, [cfg.tx1(1) cfg.tx2(1)], [cfg.tx1(3) cfg.tx2(3)], 'v', ...
    'MarkerSize', 7, 'MarkerFaceColor', est.col.azul, 'MarkerEdgeColor', 'k');
plot(ax1, cfg.rf.ap(1) + 0.5, cfg.rf.ap(3), 's', ...
    'MarkerSize', 5, 'MarkerFaceColor', est.col.verde, 'MarkerEdgeColor', 'k');
% Receptor (casco)
plot(ax1, cfg.rx(1), cfg.rx(3), '^', ...
    'MarkerSize', 6, 'MarkerFaceColor', est.col.naranjo, 'MarkerEdgeColor', 'k');
% Rayos LOS y Wi-Fi
plot(ax1, [cfg.tx1(1) cfg.rx(1)], [cfg.tx1(3) cfg.rx(3)], '-', ...
    'Color', est.col.azul, 'LineWidth', 1.0);
plot(ax1, [cfg.tx2(1) cfg.rx(1)], [cfg.tx2(3) cfg.rx(3)], '-', ...
    'Color', est.col.azul, 'LineWidth', 1.0);
plot(ax1, [cfg.rf.ap(1)+0.5 cfg.rx(1)], [cfg.rf.ap(3) cfg.rx(3)], '--', ...
    'Color', est.col.verde, 'LineWidth', 0.9);
% Cono FOV 70 grados desde el receptor
dx = 2.2 * tand(cfg.FOV);
plot(ax1, [cfg.rx(1)-dx cfg.rx(1) cfg.rx(1)+dx], [4.0 cfg.rx(3) 4.0], ':', ...
    'Color', est.col.gris, 'LineWidth', 0.8);
% Obstruccion cilindrica de ejemplo
rectangle(ax1, 'Position', [9.8 0 1.4 3.0], 'FaceColor', [0.75 0.75 0.75], ...
    'EdgeColor', est.col.gris, 'LineWidth', 0.8);
text(ax1, 10.5, 1.3, 'Maq.', 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'k');

% Anotaciones
text(ax1, cfg.tx1(1), 3.45, 'LED 1 + AP Wi-Fi', 'FontSize', 7, ...
    'HorizontalAlignment', 'center', 'Color', 'k');
text(ax1, cfg.tx2(1), 3.45, 'LED 2', 'FontSize', 7, ...
    'HorizontalAlignment', 'center', 'Color', 'k');
text(ax1, cfg.rx(1), 1.25, ['Rx (1.8 m, FOV 70' char(176) ')'], 'FontSize', 7, ...
    'HorizontalAlignment', 'center', 'Color', 'k');
text(ax1, 15.8, 3.0, ['\psi \approx 68' char(176)], 'FontSize', 7, 'Color', est.col.azul);

xlim(ax1, [-0.5 26.5]); ylim(ax1, [-0.2 4.3]);
ylabel(ax1, 'Altura z (m)');
set(ax1, 'XTickLabel', []);
est.aplicar(ax1);
set(ax1, 'XGrid', 'off', 'YGrid', 'off');
title(ax1, 'Corte longitudinal (y = 2.5 m)', 'FontSize', 8, 'FontWeight', 'normal');

% --- Panel inferior: vista en planta (X-Y) ---
ax2 = nexttile(tl);
hold(ax2, 'on');
rectangle(ax2, 'Position', [0 0 26 5], 'EdgeColor', 'k', 'LineWidth', 1.0, ...
    'FaceColor', [0.97 0.97 0.97]);
% Cilindro de ejemplo en planta
rectangle(ax2, 'Position', [9.8 1.8 1.4 1.4], 'Curvature', [1 1], ...
    'FaceColor', [0.75 0.75 0.75], 'EdgeColor', est.col.gris, 'LineWidth', 0.8);
plot(ax2, [cfg.tx1(1) cfg.rx(1)], [cfg.tx1(2) cfg.rx(2)], '-', ...
    'Color', est.col.azul, 'LineWidth', 1.0);
plot(ax2, [cfg.tx2(1) cfg.rx(1)], [cfg.tx2(2) cfg.rx(2)], '-', ...
    'Color', est.col.azul, 'LineWidth', 1.0);
plot(ax2, [cfg.tx1(1) cfg.tx2(1)], [cfg.tx1(2) cfg.tx2(2)], 'v', ...
    'MarkerSize', 6, 'MarkerFaceColor', est.col.azul, 'MarkerEdgeColor', 'k');
plot(ax2, cfg.rf.ap(1) + 0.5, cfg.rf.ap(2), 's', ...
    'MarkerSize', 5, 'MarkerFaceColor', est.col.verde, 'MarkerEdgeColor', 'k');
plot(ax2, cfg.rx(1), cfg.rx(2), '^', ...
    'MarkerSize', 6, 'MarkerFaceColor', est.col.naranjo, 'MarkerEdgeColor', 'k');

xlim(ax2, [-0.5 26.5]); ylim(ax2, [-0.3 5.3]);
xlabel(ax2, ['Posici' char(243) 'n a lo largo de la galer' char(237) 'a x (m)']);
ylabel(ax2, 'Ancho y (m)');
est.aplicar(ax2);
set(ax2, 'XGrid', 'off', 'YGrid', 'off');
title(ax2, ['Vista en planta (26 \times 5 \times 4 m)'], 'FontSize', 8, 'FontWeight', 'normal');

est.exportar(fig, 'fig_escenario');
close(fig);
fprintf('fig_escenario generada.\n');
end
