function est = estilo_figura()
%ESTILO_FIGURA  Paleta y formato comunes de todas las figuras del proyecto.
%
%   est = ESTILO_FIGURA() devuelve una estructura con
%     est.col       Colores (gris, azul, azulClaro, naranjo, verde, negro)
%     est.aplicar   Funcion est.aplicar(ax) que da formato al eje ax
%     est.nueva     Funcion est.nueva(ancho_cm, alto_cm) que crea la figura
%     est.exportar  Funcion est.exportar(fig, nombre) que guarda PDF y PNG en
%                   resultados/figuras y copia el PDF a paper/figuras
%
%   Estilo: fondo blanco, texto negro, Arial 8 pt, rejilla tenue y colores
%   sobrios. Un color por arquitectura, igual en todas las figuras.
est.col.gris      = [64 64 64] / 255;
est.col.azul      = [31 78 121] / 255;
est.col.azulClaro = [91 155 213] / 255;
est.col.naranjo   = [197 90 17] / 255;
est.col.verde     = [55 86 35] / 255;
est.col.negro     = [0 0 0];

est.nueva = @(ancho, alto) figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2 2 ancho alto], 'PaperUnits', 'centimeters', ...
    'PaperSize', [ancho alto], 'InvertHardcopy', 'off');

est.aplicar = @aplicar;
est.exportar = @exportar;
end

function aplicar(ax)
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'FontName', 'Arial', ...
    'FontSize', 8, 'Box', 'on', 'LineWidth', 0.6, 'TickDir', 'in', ...
    'XGrid', 'on', 'YGrid', 'on', 'GridColor', [0.8 0.8 0.8], ...
    'GridAlpha', 0.6, 'Layer', 'top', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end

function exportar(fig, nombre)
raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));   % proyecto
dirRes = fullfile(raiz, 'resultados', 'figuras');
dirPaper = fullfile(raiz, 'paper', 'figuras');
if ~exist(dirRes, 'dir'), mkdir(dirRes); end
if ~exist(dirPaper, 'dir'), mkdir(dirPaper); end
pdf = fullfile(dirRes, [nombre '.pdf']);
png = fullfile(dirRes, [nombre '.png']);
exportgraphics(fig, pdf, 'ContentType', 'vector', 'BackgroundColor', 'w');
exportgraphics(fig, png, 'Resolution', 300, 'BackgroundColor', 'w');
copyfile(pdf, fullfile(dirPaper, [nombre '.pdf']));
end
