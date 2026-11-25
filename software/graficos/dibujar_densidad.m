function dibujar_densidad(ax1, ax2, T, enTile)
%DIBUJAR_DENSIDAD  Cobertura y Goodput segun el numero de luminarias.
%   DIBUJAR_DENSIDAD(ax1, ax2, T) dibuja en ax1 el porcentaje de cobertura y en
%   ax2 el Goodput estatico (tabla T de densidad_luminarias.m), con una serie por
%   combinacion de polvo y obstrucciones. Se usa en el paper y en la demostracion.
if nargin < 4, enTile = false; end      % true: leyenda en una fila propia de un tiledlayout
est = estilo_figura();
Ns = unique(T.Luminarias)';
combos = [0 10; 0 40; 600 10; 600 40];
col = {est.col.azul, est.col.azulClaro, est.col.naranjo, est.col.gris};
nombres = {'Limpio, 10 obstr./min', 'Limpio, 40 obstr./min', ...
           'Polvo 600, 10 obstr./min', 'Polvo 600, 40 obstr./min'};
campos = {'Cobertura_pct', 'Goodput_Mbps'};
ejes = {ax1, ax2};
for k = 1:2
    ax = ejes{k}; cla(ax); hold(ax, 'on'); est.aplicar(ax);
    Y = zeros(numel(Ns), 4);
    for c = 1:4
        for n = 1:numel(Ns)
            f = T.Luminarias == Ns(n) & T.Polvo_mg_m3 == combos(c, 1) & T.Obstrucciones_por_min == combos(c, 2);
            Y(n, c) = T.(campos{k})(f);
        end
    end
    b = bar(ax, 1:numel(Ns), Y, 'grouped', 'EdgeColor', 'none');
    for c = 1:4, b(c).FaceColor = col{c}; end
    set(ax, 'XTick', 1:numel(Ns), 'XTickLabel', arrayfun(@num2str, Ns, 'UniformOutput', false), 'XGrid', 'off');
    xlabel(ax, ['N' char(250) 'mero de luminarias (misma potencia '  char(243) 'ptica total)']);
    if k == 1
        ylabel(ax, 'Cobertura (%)'); ylim(ax, [0 105]);
        if enTile
            lg = legend(ax, nombres, 'NumColumns', 2, 'Box', 'off', 'FontSize', 7, 'TextColor', 'k');
            lg.Layout.Tile = 'north';
        else
            legend(ax, nombres, 'Location', 'northoutside', 'NumColumns', 4, 'Box', 'off', 'FontSize', 8, 'TextColor', 'k');
        end
    else
        ylabel(ax, ['Goodput est' char(225) 'tico (Mb/s)']); ylim(ax, [0 10.5]);
    end
end
end
