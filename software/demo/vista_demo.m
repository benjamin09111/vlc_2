function h = vista_demo(accion, varargin)
%VISTA_DEMO  Dibujo comun de la demostracion (ventana interactiva y video).
%
%   h = VISTA_DEMO('crear', axG, axB, axP, axC, cfg, conLeyenda)   (conLeyenda: leyenda bajo la galeria)
%     axG  Eje de la galeria (vista superior).
%     axB  Eje de la BER acumulada.   axP  Eje del Goodput en ventana.
%     axC  Eje de barras del Goodput acumulado de las seis arquitecturas.
%   VISTA_DEMO('actualizar', h, tr, d, k, arq, cfg)
%     tr   Traza del ciclo (simular_ciclo), d = metricas_traza(tr, cfg),
%     k    paquete actual, arq  arquitectura mostrada (1 a 6).
%   Colores de la paleta del proyecto: 1 LED gris, 2 fijos azul, ideal azul
%   claro, practico naranjo, Wi-Fi verde, hibrido negro.
switch accion
    case 'crear', h = crear(varargin{:});
    case 'actualizar', actualizar(varargin{:}); h = [];
    otherwise, error('Accion desconocida: %s', accion);
end
end

function h = crear(axG, axB, axP, axC, cfg, conLeyenda)
if nargin < 6, conLeyenda = false; end
est = estilo_figura();
txt = textos_demo();
h.est = est; h.txt = txt;
h.col = {est.col.gris, est.col.azul, est.col.azulClaro, est.col.naranjo, ...
         est.col.verde, est.col.negro};
h.axG = axG; h.axB = axB; h.axP = axP; h.axC = axC;
K = cfg.nSnapshots;
h.K = K;
h.tiempo = (1:K) * cfg.Tmotion / K;

% --- galeria ---------------------------------------------------------------------
cla(axG); hold(axG, 'on');
est.aplicar(axG); set(axG, 'XGrid', 'off', 'YGrid', 'off');
rectangle(axG, 'Position', [0 0 cfg.sala(1) cfg.sala(2)], 'EdgeColor', 'k', 'LineWidth', 1);
tx = [cfg.tx1; cfg.tx2];
% zona de linea de vista directa de cada luminaria (hasta 5.5 m de distancia horizontal)
th = linspace(0, 2*pi, 80);
for i = 1:2
    patch(axG, tx(i,1) + 5.5*cos(th), min(cfg.sala(2), max(0, tx(i,2) + 5.5*sin(th))), est.col.azulClaro, ...
        'FaceAlpha', 0.10, 'EdgeColor', 'none');
end
h.obs = gobjects(1, 120);
for i = 1:120
    h.obs(i) = rectangle(axG, 'Position', [0 0 1 1], 'Curvature', [1 1], ...
        'FaceColor', [0.78 0.78 0.78], 'EdgeColor', [0.35 0.35 0.35], 'Visible', 'off');
end
h.pAP = [cfg.rf.ap(1) cfg.rf.ap(2) + 1.0];
h.pRX = cfg.rx(1:2);
h.lnk(1) = plot(axG, [tx(1,1) h.pRX(1)], [tx(1,2) h.pRX(2)], '-');
h.lnk(2) = plot(axG, [tx(2,1) h.pRX(1)], [tx(2,2) h.pRX(2)], '-');
h.lnk(3) = plot(axG, [h.pAP(1) h.pRX(1)], [h.pAP(2) h.pRX(2)], '-');
plot(axG, tx(:,1), tx(:,2), '^', 'MarkerSize', 8, 'MarkerFaceColor', 'w', 'Color', 'k');
plot(axG, h.pAP(1), h.pAP(2), 's', 'MarkerSize', 7, 'MarkerFaceColor', est.col.verde, 'Color', 'k');
plot(axG, h.pRX(1), h.pRX(2), 's', 'MarkerSize', 7, 'MarkerFaceColor', 'k', 'Color', 'k');
text(axG, tx(1,1), tx(1,2) - 0.6, txt.lum1, 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
text(axG, tx(2,1), tx(2,2) - 0.6, txt.lum2, 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
text(axG, h.pAP(1), h.pAP(2) + 0.6, txt.ap, 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
text(axG, h.pRX(1), h.pRX(2) - 0.6, txt.rxCasco, 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
h.tAviso = text(axG, cfg.sala(1) - 0.3, cfg.sala(2) - 0.4, '', 'HorizontalAlignment', 'right', ...
    'FontSize', 9, 'Color', 'k', 'BackgroundColor', 'w', 'Margin', 2);
axis(axG, 'equal'); xlim(axG, [0 cfg.sala(1)]); ylim(axG, [0 cfg.sala(2)]);
xlabel(axG, txt.x_m); ylabel(axG, txt.y_m);
if conLeyenda
    p1 = plot(axG, NaN, NaN, '-', 'Color', est.col.azul, 'LineWidth', 2.5);
    p2 = plot(axG, NaN, NaN, '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 2.5);
    p3 = plot(axG, NaN, NaN, '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 1);
    p4 = plot(axG, NaN, NaN, '-', 'Color', est.col.verde, 'LineWidth', 2.5);
    p5 = plot(axG, NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.78 0.78 0.78], 'Color', [0.35 0.35 0.35]);
    p6 = patch(axG, NaN, NaN, est.col.azulClaro, 'FaceAlpha', 0.10, 'EdgeColor', 'none');
    lg = legend(axG, [p1 p2 p3 p4 p5 p6], txt.leyenda, 'Location', 'southoutside', 'NumColumns', 3, ...
        'Box', 'off', 'FontSize', 9, 'TextColor', 'k');
    h.leyenda = lg;
end

% --- BER y Goodput en el tiempo --------------------------------------------------------
cla(axB); hold(axB, 'on'); est.aplicar(axB);
h.lB = plot(axB, NaN, NaN, '-', 'LineWidth', 1.4);
set(axB, 'YScale', 'log'); ylim(axB, [1e-5 1]); xlim(axB, [0 cfg.Tmotion]);
ylabel(axB, txt.ber); set(axB, 'XTickLabel', []);
h.tBER = text(axB, 0.4, 0.35, '', 'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'w', 'Margin', 2);
cla(axP); hold(axP, 'on'); est.aplicar(axP);
h.lP = plot(axP, NaN, NaN, '-', 'LineWidth', 1.4);
ylim(axP, [0 10.5]); xlim(axP, [0 cfg.Tmotion]);
h.gmax = cfg.Rb / 1e6 * cfg.packetBits / (cfg.packetBits + cfg.basePilotBits);
yline(axP, h.gmax, '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.9);
text(axP, 0.4, h.gmax + 0.55, sprintf('%s: %.2f Mb/s', txt.maximo, h.gmax), 'FontSize', 9, 'Color', [0.35 0.35 0.35]);
ylabel(axP, txt.gpMov); xlabel(axP, [txt.tiempo ' (s)']);

% --- barras del Goodput acumulado --------------------------------------------------------
cla(axC); hold(axC, 'on'); est.aplicar(axC); set(axC, 'YGrid', 'off');
h.bar = barh(axC, zeros(6, 1), 'FaceColor', 'flat', 'EdgeColor', 'none');
for q = 1:6, h.bar.CData(q, :) = h.col{q}; end
set(axC, 'YTick', 1:6, 'YTickLabel', txt.sis, 'YDir', 'reverse');
xlim(axC, [0 10.5]); ylim(axC, [0.4 6.6]); xlabel(axC, txt.gpAcum);
xline(axC, h.gmax, '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.9);
title(axC, txt.tituloBarras, 'FontWeight', 'normal', 'FontSize', 10, 'Color', 'k');
h.txtBar = gobjects(1, 6);
for q = 1:6
    h.txtBar(q) = text(axC, 0.1, q, '', 'FontSize', 8, 'Color', 'w', ...
        'VerticalAlignment', 'middle');
end
end

function actualizar(h, tr, d, k, arq, cfg)
est = h.est; txt = h.txt;
% obstrucciones presentes
pres = find(tr.presente(k, :));
n = min(numel(pres), numel(h.obs));
set(h.obs, 'Visible', 'off');
for i = 1:n
    j = pres(i);
    set(h.obs(i), 'Position', [tr.obs.x(j) - tr.obs.w(j)/2, tr.obs.y(j) - tr.obs.w(j)/2, ...
        tr.obs.w(j), tr.obs.w(j)], 'Visible', 'on');
end
% enlaces activos segun la arquitectura
[act, bloq, wifiCaido] = enlaces_demo(tr, k, arq);
colAct = {est.col.azul, est.col.azul, est.col.verde};
for i = 1:3
    if ~act(i)
        set(h.lnk(i), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.75, 'LineStyle', '-');
    elseif (i == 3 && wifiCaido) || bloq(i)
        set(h.lnk(i), 'Color', [0.45 0.45 0.45], 'LineWidth', 2.5, 'LineStyle', '--');
    else
        set(h.lnk(i), 'Color', colAct{i}, 'LineWidth', 2.5, 'LineStyle', '-');
    end
end
aviso = '';
if act(3) && wifiCaido, aviso = txt.enlaceCaido; end
set(h.tAviso, 'String', aviso);
% curvas
set(h.lB, 'XData', h.tiempo(1:k), 'YData', max(d.ber(arq, 1:k), 1e-5), 'Color', h.col{arq});
set(h.lP, 'XData', h.tiempo(1:k), 'YData', d.gpMov(arq, 1:k), 'Color', h.col{arq});
set(h.bar, 'YData', d.gpAcum(:, k));
for q = 1:6
    set(h.txtBar(q), 'String', sprintf('%.2f', d.gpAcum(q, k)), ...
        'Position', [max(0.1, d.gpAcum(q, k) - 0.1) q 0], 'HorizontalAlignment', 'right');
    if d.gpAcum(q, k) < 1.2
        set(h.txtBar(q), 'Position', [d.gpAcum(q, k) + 0.1 q 0], 'HorizontalAlignment', 'left', 'Color', 'k');
    else
        set(h.txtBar(q), 'Color', 'w');
    end
end
if d.ber(arq, k) <= 0
    set(h.tBER, 'String', txt.sinErrores);
else
    set(h.tBER, 'String', sprintf('%s %.1e', txt.berActual, d.ber(arq, k)));
end
title(h.axG, sprintf('%s: %.1f s de 24 s', txt.tiempo, h.tiempo(k)), 'FontWeight', 'normal', 'FontSize', 10, 'Color', 'k');
end
