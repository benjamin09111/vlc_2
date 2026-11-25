function archivo = demo_grabar(varargin)
%DEMO_GRABAR  Graba un video MP4 de respaldo de la demostracion.
%
%   archivo = DEMO_GRABAR() graba resultados/video/demo_vlc.mp4 con cuatro
%   escenarios (referencia limpia, obstrucciones intensas, polvo denso y fallas
%   simultaneas), usando las mismas funciones y la misma vista que demo_vlc.
%   Para cada escenario se elige, entre las primeras semillas, una replica
%   representativa (ver seleccion mas abajo) para que el video muestre el
%   comportamiento tipico y no un caso extremo.
%
%   Opciones: 'Velocidad' (paquetes por cuadro, 4), 'FPS' (15),
%             'Salida' (ruta del archivo).
p = inputParser;
addParameter(p, 'Velocidad', 4, @isnumeric);
addParameter(p, 'FPS', 15, @isnumeric);
addParameter(p, 'Salida', '', @ischar);
parse(p, varargin{:});
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));
dirV = fullfile(raiz, '..', 'resultados', 'video');
if ~exist(dirV, 'dir'), mkdir(dirV); end
archivo = p.Results.Salida;
if isempty(archivo), archivo = fullfile(dirV, 'demo_vlc.mp4'); end

cfg = parametros('mina');
can = canal_galeria(cfg);
txt = textos_demo();
o = char(243); a = char(225); i_ = char(237); e = char(233);
base = struct('conc', 0, 'lente', 1, 'Ta', 25, 'disip', 'estandar', 'eps', 0, ...
              'interf', false, 'emi', 0);
guion = struct('nombre', {}, 'cond', {}, 'arq', {}, 'texto', {}, 'criterio', {});
c = base;
guion(1) = struct('nombre', 'limpio', 'cond', c, 'arq', 4, ...
    'texto', ['Condiciones limpias: el enlace '  o 'ptico tiene un margen de 46 dB'], 'criterio', @(t) true);
c = base; c.eps = 40;
guion(2) = struct('nombre', 'obstrucciones', 'cond', c, 'arq', 4, ...
    'texto', ['40 obstrucciones por minuto: el selector cambia de luminaria al bloquearse el enlace'], ...
    'criterio', @(t) mean(t.bloqueo(1, :)) > 0.2 && mean(t.bloqueo(1, :)) < 0.5);
c = base; c.conc = 1200;
guion(3) = struct('nombre', 'polvo', 'cond', c, 'arq', 1, ...
    'texto', ['Polvo denso (1200 mg/m^3): la atenuaci' o 'n reduce el margen y aparecen errores'], 'criterio', @(t) true);
c = base; c.conc = 1500; c.eps = 10; c.emi = 40;
guion(4) = struct('nombre', 'fallas', 'cond', c, 'arq', 6, ...
    'texto', ['Fallas simult' a 'neas (polvo 1500 mg/m^3, interferencia de 40 dB, obstrucciones): el h' i_ 'brido usa cada enlace cuando el otro falla'], ...
    'criterio', @(t) mean(t.wifiDisponible) > 0.4 && mean(t.wifiDisponible) < 0.95 && mean(t.usaWifi) > 0.2);

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [0 0 1280 720], ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Visible', 'off', 'InvertHardcopy', 'off');
axG = axes(fig, 'Position', [0.07 0.63 0.90 0.28]);
axB = axes(fig, 'Position', [0.07 0.35 0.52 0.19]);
axP = axes(fig, 'Position', [0.07 0.11 0.52 0.19]);
axC = axes(fig, 'Position', [0.74 0.11 0.23 0.42]);
vista = vista_demo('crear', axG, axB, axP, axC, cfg);
leyenda = annotation(fig, 'textbox', [0.02 0.93 0.96 0.05], 'String', '', 'LineStyle', 'none', ...
    'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k', 'VerticalAlignment', 'middle');
nom = annotation(fig, 'textbox', [0.62 0.55 0.35 0.04], 'String', '', 'LineStyle', 'none', ...
    'FontName', 'Arial', 'FontSize', 10, 'Color', 'k', 'VerticalAlignment', 'middle');

vw = VideoWriter(archivo, 'MPEG-4');
vw.FrameRate = p.Results.FPS; vw.Quality = 90;
open(vw);
tam = [];
K = cfg.nSnapshots;
for g = 1:numel(guion)
    % replica representativa: primera semilla que cumple el criterio
    ok = false;
    for sem = 20261124 + (0:200)
        tr = simular_ciclo(cfg, can, guion(g).cond, sem);
        if guion(g).criterio(tr), ok = true; break; end
    end
    assert(ok, 'Ninguna semilla cumple el criterio del escenario %s', guion(g).nombre);
    fprintf('Escenario %s: semilla %d\n', guion(g).nombre, sem);
    d = metricas_traza(tr, cfg);
    set(leyenda, 'String', guion(g).texto);
    set(nom, 'String', ['Arquitectura mostrada: ' txt.sis{guion(g).arq}]);
    for k = [1:p.Results.Velocidad:K, K]
        vista_demo('actualizar', vista, tr, d, k, guion(g).arq, cfg);
        drawnow;
        tmp = [tempname '.png'];
        exportgraphics(fig, tmp, 'Resolution', 96, 'BackgroundColor', 'w');
        im = imread(tmp); delete(tmp);
        if isempty(tam), tam = size(im); end
        im = im(1:min(end, tam(1)), 1:min(end, tam(2)), :);
        if any(size(im) ~= tam), im(tam(1), tam(2), 3) = 0; end
        writeVideo(vw, im);
    end
    for r = 1:round(p.Results.FPS)      % 1 s de pausa al final del escenario
        writeVideo(vw, im);
    end
end
close(vw);
close(fig);
fprintf('Video escrito en %s\n', archivo);
end
