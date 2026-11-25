function out = ejecutar_simulacion(varargin)
%EJECUTAR_SIMULACION  Punto de entrada del simulador VLC en galeria minera.
%
%   out = EJECUTAR_SIMULACION() ejecuta la simulacion completa de la galeria
%   (perfil 'mina') con los parametros de config/parametros.m, escribe los
%   resultados en ../resultados/datos/ y devuelve una estructura con las tablas.
%
%   Opciones
%     'Guardar'  true (por defecto) escribe los CSV; false solo calcula.
%     'Perfil'   'mina' (por defecto): modelo de la Fase 4 con reflexiones,
%                sombra de Poisson, polvo, temperatura y ruido fisico.
%                'v3': modelo heredado de la version v3, solo para la prueba
%                de no regresion P-01.
%     'Cfg'      Configuracion propia (reemplaza a parametros(perfil)).
%
%   Requiere MATLAB R2021a o posterior. No usa toolboxes adicionales.
p = inputParser;
addParameter(p, 'Guardar', true, @islogical);
addParameter(p, 'Perfil', 'mina', @ischar);
addParameter(p, 'Cfg', [], @(x) isempty(x) || isstruct(x));
parse(p, varargin{:});

raiz = fileparts(mfilename('fullpath'));
addpath(genpath(raiz));

cfg = p.Results.Cfg;
if isempty(cfg), cfg = parametros(p.Results.Perfil); end
rng(cfg.semilla, 'twister');
t0 = tic;

if strcmp(p.Results.Perfil, 'v3')
    maq = maquinaria(cfg);
    [rep, tActualiza] = generar_replicas(cfg, maq);
    out = ejecutar_escenarios(cfg, rep, tActualiza);
    prefijo = 'v3_';
else
    can = canal_galeria(cfg);
    [rep, tActualiza] = generar_replicas_mina(cfg);
    esc = definir_escenarios(cfg);
    out = ejecutar_escenarios_mina(cfg, can, rep, tActualiza, esc);
    out.canal = can;
    prefijo = '';
end
out.cfg = cfg;
out.duracion_s = toc(t0);

fprintf('Simulacion (perfil %s) completada en %.1f s\n', p.Results.Perfil, out.duracion_s);
fprintf('Replicas: %d; paquetes por replica: %d; filas de resultados: %d\n', ...
    cfg.nRuns, cfg.nSnapshots, height(out.resultados));

if p.Results.Guardar
    destino = fullfile(raiz, '..', 'resultados', 'datos');
    if ~exist(destino, 'dir'), mkdir(destino); end
    writetable(out.resultados, fullfile(destino, [prefijo 'resultados.csv']));
    if strcmp(p.Results.Perfil, 'v3')
        writetable(out.diagBloqueo, fullfile(destino, 'v3_diagnostico_bloqueo.csv'));
        writetable(out.diagSelector, fullfile(destino, 'v3_diagnostico_selector.csv'));
    else
        writetable(out.escenarios, fullfile(destino, 'escenarios.csv'));
    end
    fprintf('Resultados escritos en %s\n', destino);
end
end
