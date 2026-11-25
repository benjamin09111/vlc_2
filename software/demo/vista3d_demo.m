function h = vista3d_demo(accion, varargin)
%VISTA3D_DEMO  Vista tridimensional de la galeria para la demostracion.
%
%   h = VISTA3D_DEMO('crear', ax, cfg)
%   VISTA3D_DEMO('actualizar', h, tr, k, arq)
%   Muestra la galeria, los conos de emision de las luminarias, el casco del
%   minero, las obstrucciones presentes (cilindros de su ancho y alto reales) y
%   los enlaces con el mismo codigo de la vista superior: continuo libre,
%   discontinuo bloqueado, claro no usado.
switch accion
    case 'crear', h = crear(varargin{:});
    case 'actualizar', actualizar(varargin{:}); h = [];
    otherwise, error('Accion desconocida: %s', accion);
end
end

function h = crear(ax, cfg)
est = estilo_figura();
cla(ax); hold(ax, 'on');
est.aplicar(ax);
h.ax = ax; h.est = est;
S = cfg.sala;
% estructura de la galeria
v = [0 0 0; S(1) 0 0; S(1) S(2) 0; 0 S(2) 0; 0 0 S(3); S(1) 0 S(3); S(1) S(2) S(3); 0 S(2) S(3)];
aristas = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
for i = 1:size(aristas, 1)
    plot3(ax, v(aristas(i, :), 1), v(aristas(i, :), 2), v(aristas(i, :), 3), '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
end
% piso
patch(ax, [0 S(1) S(1) 0], [0 0 S(2) S(2)], [0 0 0 0], [0.96 0.96 0.96], 'EdgeColor', 'none', 'FaceAlpha', 0.9);
% luminarias y conos de emision hasta la altura del casco
tx = [cfg.tx1; cfg.tx2];
altura = cfg.tx1(3) - cfg.rx(3);
radio = altura * tand(cfg.phiHalf);
[Xc, Yc, Zc] = cylinder([0 radio], 28);
for i = 1:2
    surf(ax, tx(i,1) + Xc, tx(i,2) + Yc, cfg.tx1(3) - altura * Zc, 'FaceColor', est.col.azulClaro, ...
        'FaceAlpha', 0.10, 'EdgeColor', 'none');
    plot3(ax, tx(i,1), tx(i,2), tx(i,3), 's', 'MarkerSize', 9, 'MarkerFaceColor', 'w', 'Color', 'k', 'LineWidth', 1.2);
end
h.pAP = [cfg.rf.ap(1) cfg.rf.ap(2) + 1.0 cfg.rf.ap(3)];
plot3(ax, h.pAP(1), h.pAP(2), h.pAP(3), 's', 'MarkerSize', 8, 'MarkerFaceColor', est.col.verde, 'Color', 'k');
h.pRX = cfg.rx;
plot3(ax, h.pRX(1), h.pRX(2), h.pRX(3), 'o', 'MarkerSize', 9, 'MarkerFaceColor', 'k', 'Color', 'k');
% enlaces
h.lnk(1) = plot3(ax, [tx(1,1) h.pRX(1)], [tx(1,2) h.pRX(2)], [tx(1,3) h.pRX(3)], '-');
h.lnk(2) = plot3(ax, [tx(2,1) h.pRX(1)], [tx(2,2) h.pRX(2)], [tx(2,3) h.pRX(3)], '-');
h.lnk(3) = plot3(ax, [h.pAP(1) h.pRX(1)], [h.pAP(2) h.pRX(2)], [h.pAP(3) h.pRX(3)], '-');
% obstrucciones (reserva de cilindros)
[Xo, Yo, Zo] = cylinder(1, 20);
h.Xo = Xo; h.Yo = Yo; h.Zo = Zo;
h.obs = gobjects(1, 80);
for i = 1:80
    h.obs(i) = surf(ax, Xo, Yo, Zo, 'FaceColor', [0.55 0.55 0.55], 'FaceAlpha', 0.75, ...
        'EdgeColor', 'none', 'Visible', 'off');
end
axis(ax, 'equal'); xlim(ax, [0 S(1)]); ylim(ax, [0 S(2)]); zlim(ax, [0 S(3)]);
view(ax, [-32 24]); camlight(ax, 'headlight'); lighting(ax, 'gouraud');
xlabel(ax, 'x (m)'); ylabel(ax, 'y (m)'); zlabel(ax, 'z (m)');
set(ax, 'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off');
end

function actualizar(h, tr, k, arq)
est = h.est;
pres = find(tr.presente(k, :));
n = min(numel(pres), numel(h.obs));
set(h.obs, 'Visible', 'off');
for i = 1:n
    j = pres(i); r = tr.obs.w(j) / 2;
    set(h.obs(i), 'XData', tr.obs.x(j) + r * h.Xo, 'YData', tr.obs.y(j) + r * h.Yo, ...
        'ZData', tr.obs.h(j) * h.Zo, 'Visible', 'on');
end
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
end
