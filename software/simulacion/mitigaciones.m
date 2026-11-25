function T = mitigaciones(varargin)
%MITIGACIONES  Experimentos de mitigacion sobre BER y Goodput (Fase 5).
%
%   T = MITIGACIONES() ejecuta cuatro experimentos, escribe
%   resultados/datos/mitigaciones.csv y devuelve la tabla.
%
%   A  Selector practico: aisla por que su BER supera a la del selector ideal
%      (umbral con amplitud desactualizada, error y retardo de la informacion
%      de canal, histeresis, sobrecarga de pilotos). Escenarios E4 y E6.
%   B  Limpieza de lentes con polvo denso (1200 mg/m^3).
%   C  Tasa adaptativa: tasa de bits 10, 5 y 2.5 Mb/s con polvo denso
%      (1500 mg/m^3) y en el escenario combinado.
%   D  Esquema hibrido: umbral de conmutacion Q (ver cfg.hibrido.umbralQ).
%   La gestion termica ya se mide en los grupos E3 y E7 de ejecutar_simulacion.
%
%   Opcion 'Guardar' (true por defecto).
p = inputParser;
addParameter(p, 'Guardar', true, @islogical);
parse(p, varargin{:});
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));

cfg0 = parametros('mina');
escTodos = definir_escenarios(cfg0);
buscar = @(n) escTodos(strcmp({escTodos.nombre}, n));
base = escTodos(1);

T = table();
% --- A: selector practico ----------------------------------------------------------
escA = [buscar('E4_obstruc_20'), buscar('E4_obstruc_40'), buscar('E6_combinado')];
var = {
    'base',                         struct()
    'umbral con pilotos',           struct('umbralPiloto', true)
    'sin error de estimacion',      struct('csiRelativeNoise', 0)
    'sin retardo de informacion',   struct('feedbackDelay_s', 0)
    'sin error ni retardo',         struct('csiRelativeNoise', 0, 'feedbackDelay_s', 0)
    'histeresis 0 %',               struct('hysteresis', 0)
    'histeresis 15 %',              struct('hysteresis', 0.15)
    'sin sobrecarga adicional',     struct('adaptExtraPilotBits', 0)
    'pilotos y sin error ni retardo', struct('umbralPiloto', true, 'csiRelativeNoise', 0, 'feedbackDelay_s', 0)};
for v = 1:size(var, 1)
    T = [T; correr(cfg0, var{v, 2}, escA, 'A_selector', var{v, 1})]; %#ok<AGROW>
end

% --- B: limpieza de lentes con polvo denso -------------------------------------------
escB = base; escB.conc = 1200; escB.grupo = 'B';
escB = repmat(escB, 1, 4);
lentes = [1 0.8 0.6 0.4];
for k = 1:4
    escB(k).lente = lentes(k);
    escB(k).nombre = sprintf('polvo1200_lente_%.1f', escB(k).lente);
end
T = [T; correr(cfg0, struct(), escB, 'B_lentes', 'transmitancia')];

% --- C: tasa adaptativa -----------------------------------------------------------------
escC = [buscar('E1_polvo_1500'), buscar('E1_polvo_2000'), buscar('E6_combinado')];
for Rb = [10 5 2.5]
    T = [T; correr(cfg0, struct('Rb', Rb * 1e6), escC, 'C_tasa', sprintf('%.1f Mb/s', Rb))]; %#ok<AGROW>
end

% --- D: umbral del esquema hibrido ----------------------------------------------------------
escD = [buscar('E4_obstruc_40'), buscar('E6_combinado'), buscar('E9_polvo1500_emi40_obstruc10')];
for q = [4 8 12 20 40]
    T = [T; correr(cfg0, struct('hibrido', struct('umbralQ', q)), escD, 'D_hibrido', sprintf('Q = %d', q))]; %#ok<AGROW>
end

if p.Results.Guardar
    destino = fullfile(raiz, '..', 'resultados', 'datos');
    writetable(T, fullfile(destino, 'mitigaciones.csv'));
    fprintf('Mitigaciones: %d filas escritas en %s\n', height(T), destino);
end
end

function T = correr(cfg0, cambios, esc, experimento, variante)
cfg = cfg0;
f = fieldnames(cambios);
for i = 1:numel(f), cfg.(f{i}) = cambios.(f{i}); end
rng(cfg.semilla, 'twister');
can = canal_galeria(cfg);
[rep, tAct] = generar_replicas_mina(cfg);
out = ejecutar_escenarios_mina(cfg, can, rep, tAct, esc);
r = out.resultados;
n = height(r);
Experimento = repmat({experimento}, n, 1);
Variante = repmat({variante}, n, 1);
T = [table(Experimento, Variante), r(:, {'Escenario','Sistema','BER','BER_IC95_inf','BER_IC95_sup', ...
    'Goodput_Mbps','Goodput_IC95_inf','Goodput_IC95_sup'})];
end
