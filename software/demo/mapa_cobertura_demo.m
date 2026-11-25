function h = mapa_cobertura_demo(accion, varargin)
%MAPA_COBERTURA_DEMO  Mapa de margen de enlace que reacciona a las condiciones.
%
%   h = MAPA_COBERTURA_DEMO('crear', axMapa, axPerfil, cfg)
%   h = MAPA_COBERTURA_DEMO('actualizar', h, malla, cond, cfg)   (devuelve h actualizado)
%     malla  Canal en la malla de posiciones (canal_malla).
%     cond   Condiciones: conc, lente, Ta, eps.
%   Margen de enlace de dos luminarias fijas (ver margen_enlace.m); el contorno
%   naranjo marca 21.6 dB (BER del orden de 1e-9) y el perfil muestra el eje de
%   la galeria. Las obstrucciones entran solo a traves de la ponderacion
%   esperada de las reflexiones (el bloqueo de la linea de vista es dinamico y
%   se ve en las otras pestanas).
switch accion
    case 'crear', h = crear(varargin{:});
    case 'actualizar', h = actualizar(varargin{:});
    otherwise, error('Accion desconocida: %s', accion);
end
end

function h = crear(axM, axP, cfg)
est = estilo_figura();
h.est = est; h.axM = axM; h.axP = axP;
cla(axM); hold(axM, 'on'); est.aplicar(axM); set(axM, 'XGrid', 'off', 'YGrid', 'off');
mapa = [linspace(1, est.col.azul(1), 64)', linspace(1, est.col.azul(2), 64)', linspace(1, est.col.azul(3), 64)'];
colormap(axM, mapa);
h.xq = 0:0.25:cfg.sala(1); h.yq = 0:0.25:cfg.sala(2);
h.img = imagesc(axM, h.xq, h.yq, zeros(numel(h.yq), numel(h.xq)), [0 50]);
set(axM, 'YDir', 'normal');
h.cont = [];
tx = [cfg.tx1; cfg.tx2];
plot(axM, tx(:,1), tx(:,2), '^', 'MarkerSize', 8, 'MarkerFaceColor', 'w', 'Color', 'k');
plot(axM, cfg.rx(1), cfg.rx(2), 's', 'MarkerFaceColor', 'k', 'Color', 'k', 'MarkerSize', 6);
axis(axM, 'equal'); xlim(axM, [0 cfg.sala(1)]); ylim(axM, [0 cfg.sala(2)]);
xlabel(axM, ['Largo de la galer' char(237) 'a (m)']); ylabel(axM, 'Ancho (m)');
cb = colorbar(axM, 'eastoutside'); cb.Label.String = 'Margen de enlace (dB)'; cb.Color = 'k';
cla(axP); hold(axP, 'on'); est.aplicar(axP);
yline(axP, 21.6, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
h.lP = plot(axP, NaN, NaN, '-', 'Color', est.col.azul, 'LineWidth', 1.6);
h.txtCob = text(axP, 0.4, -16, '', 'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'w', 'Margin', 2);
xlim(axP, [0 cfg.sala(1)]); ylim(axP, [-20 60]);
xlabel(axP, ['Largo de la galer' char(237) 'a (m)']); ylabel(axP, 'Margen en el eje (dB)');
end

function h = actualizar(h, malla, cond, cfg)
nx = numel(malla.xs); ny = numel(malla.ys);
Z = zeros(ny, nx);
for iy = 1:ny
    for ix = 1:nx
        Z(iy, ix) = margen_enlace(malla.can{iy, ix}, cond, cfg);
    end
end
Zq = interp2(malla.xs, malla.ys, Z, h.xq, h.yq(:), 'linear', NaN);
% fuera de la malla (bordes), extrapolacion por el valor mas cercano
Zq = fillmissing(Zq, 'nearest', 1);
Zq = fillmissing(Zq, 'nearest', 2);
set(h.img, 'CData', Zq);
if ~isempty(h.cont) && all(isgraphics(h.cont)), delete(h.cont); end
[~, h.cont] = contour(h.axM, h.xq, h.yq, Zq, [21.6 21.6], 'Color', h.est.col.naranjo, 'LineWidth', 1.6);
perfil = Zq(abs(h.yq - cfg.rx(2)) < 1e-9, :);
set(h.lP, 'XData', h.xq, 'YData', perfil);
cubierto = mean(perfil >= 21.6) * cfg.sala(1);
set(h.txtCob, 'String', sprintf(['Cobertura sobre 21.6 dB en el eje: %.1f de %.0f m;  margen en el punto de operaci' char(243) 'n: %.1f dB'], ...
    cubierto, cfg.sala(1), interp1(h.xq, perfil, cfg.rx(1))));
end
