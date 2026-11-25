function T = densidad_luminarias(varargin)
%DENSIDAD_LUMINARIAS  Cobertura de la galeria segun el numero de luminarias.
%
%   T = DENSIDAD_LUMINARIAS() evalua N = 2, 3, 4 y 6 luminarias repartidas de
%   forma uniforme sobre el eje de la galeria (una por tramo de 26/N m, a 3.8 m
%   de altura), con la MISMA potencia optica total dividida en partes iguales,
%   y escribe resultados/datos/densidad.csv.
%
%   Para cada N, polvo y llegada de obstrucciones, se toman instantaneas
%   independientes de las obstrucciones (Poisson, con la permanencia media del
%   modelo) y, para cada posicion del receptor a lo largo del eje, se calcula
%   la corriente de senal de las N luminarias fijas, con las reflexiones
%   ponderadas por su sombra esperada. Con el ruido del receptor se obtiene
%   en cada caso el margen de enlace y la BER teorica con umbral a mitad de
%   amplitud (la misma expresion de la prueba V-04), y el Goodput estatico
%   R_b L/(L+n_p) (1-BER)^L.
%
%   Metricas de salida
%     Cobertura_pct       Porcentaje de (posicion, instantanea) con margen >= 21.6 dB
%                         (BER del orden de 1e-9).
%     Peor_posicion_pct   Idem en la peor posicion del receptor.
%     BER_media           BER teorica promedio.
%     Goodput_Mbps        Goodput estatico promedio.
%   No incluye el selector ni la dinamica temporal: es una comparacion de
%   diseno, no sustituye a la simulacion Monte Carlo de ejecutar_simulacion.
%
%   Opciones: 'Instantaneas' (400), 'Guardar' (true).
p = inputParser;
addParameter(p, 'Instantaneas', 400, @isnumeric);
addParameter(p, 'Guardar', true, @islogical);
parse(p, varargin{:});
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));
cfg = parametros('mina');
L = cfg.sala(1); alturaTx = cfg.tx1(3);
Ns = [2 3 4 6];
polvos = [0 600];
epsilons = [10 40];
xs = (0.5:0.5:25.5)';
nx = numel(xs);
rxs = [xs, cfg.rx(2) * ones(nx, 1), cfg.rx(3) * ones(nx, 1)];
M = p.Results.Instantaneas;
umbral_dB = 21.6;
Lp = cfg.packetBits;

% --- instantaneas de obstrucciones (comunes a todos los N y al polvo) -------------------
flujo = RandStream('mt19937ar', 'Seed', cfg.semilla + 5);
inst = cell(numel(epsilons), M);
for e = 1:numel(epsilons)
    media = epsilons(e) / 60 * cfg.sombra.permanencia_s;     % obstrucciones presentes
    for m = 1:M
        n = poisson(media, flujo);
        inst{e, m} = struct( ...
            'x', cfg.sala(1) * rand(flujo, 1, n), 'y', cfg.sala(2) * rand(flujo, 1, n), ...
            'w', cfg.sombra.ancho_m(1) + diff(cfg.sombra.ancho_m) * rand(flujo, 1, n), ...
            'h', cfg.sombra.alto_m(1) + diff(cfg.sombra.alto_m) * rand(flujo, 1, n));
    end
end

% --- canal estatico por posicion de luminaria (se calcula una vez por posicion) -----------
pos = unique(round(cell2mat(arrayfun(@(N) ((1:N) - 0.5) * L / N, Ns, 'UniformOutput', false)) * 1e6) / 1e6);
fprintf('Calculando canal estatico de %d posiciones de luminaria...\n', numel(pos));
canal = cell(numel(pos), nx);
for i = 1:numel(pos)
    c = cfg; c.tx1 = [pos(i) cfg.tx1(2) alturaTx]; c.tx2 = c.tx1;
    parfor ix = 1:nx
        canal{i, ix} = canal_galeria(c, rxs(ix, :));
    end
end

% --- bloqueo de la linea de vista de cada luminaria en cada instantanea ---------------------
bloq = cell(numel(epsilons), numel(pos));         % nx x M logico
for e = 1:numel(epsilons)
    for i = 1:numel(pos)
        b = false(nx, M);
        A = [pos(i) cfg.tx1(2) alturaTx];
        for m = 1:M
            o = inst{e, m};
            if ~isempty(o.x), b(:, m) = any(bloquea_cilindro(A, rxs, o.x, o.y, o.w, o.h), 2); end
        end
        bloq{e, i} = b;
    end
end

% --- metricas ---------------------------------------------------------------------------------
filas = {};
for iN = 1:numel(Ns)
    N = Ns(iN);
    posN = ((1:N) - 0.5) * L / N;
    idx = arrayfun(@(q) find(abs(pos - q) < 1e-6), posN);
    for ip = 1:numel(polvos)
        for e = 1:numel(epsilons)
            esc = struct('conc', polvos(ip), 'lente', 1, 'eps', epsilons(e));
            losG = zeros(N, nx); nlosG = zeros(N, nx);
            for j = 1:N
                for ix = 1:nx
                    g = ganancias_escenario(canal{idx(j), ix}, esc, cfg);
                    losG(j, ix) = g.los(1); nlosG(j, ix) = g.nlos(1);
                end
            end
            marg = zeros(nx, M); ber = zeros(nx, M);
            for ix = 1:nx
                libre = zeros(1, M);
                for j = 1:N
                    libre = libre + losG(j, ix) * double(~bloq{e, idx(j)}(ix, :));
                end
                P = (cfg.Ptotal / N) * (libre + sum(nlosG(:, ix)));
                I = cfg.R * P;
                [s0, s1] = ruido_receptor(P, cfg.ruido.Ibg, 25, cfg);
                marg(ix, :) = 20 * log10(I ./ s1);
                ber(ix, :) = 0.25 * erfc((I/2) ./ (sqrt(2) * s0)) + 0.25 * erfc((I/2) ./ (sqrt(2) * s1));
            end
            cubre = marg >= umbral_dB;
            gp = (cfg.Rb / 1e6) * Lp / (Lp + cfg.basePilotBits) * (1 - ber).^Lp;
            filas(end+1, :) = {N, polvos(ip), epsilons(e), 100 * mean(cubre(:)), ...
                100 * min(mean(cubre, 2)), mean(ber(:)), mean(gp(:))}; %#ok<AGROW>
        end
    end
end
T = cell2table(filas, 'VariableNames', {'Luminarias', 'Polvo_mg_m3', 'Obstrucciones_por_min', ...
    'Cobertura_pct', 'Peor_posicion_pct', 'BER_media', 'Goodput_Mbps'});
if p.Results.Guardar
    destino = fullfile(raiz, '..', 'resultados', 'datos');
    writetable(T, fullfile(destino, 'densidad.csv'));
    fprintf('Densidad: %d filas escritas en %s\n', height(T), destino);
end
end

function n = poisson(media, flujo)
% Poisson por el metodo de Knuth (media moderada) con el flujo dado.
Lk = exp(-media); k = 0; pr = 1;
while true
    pr = pr * rand(flujo);
    if pr <= Lk, break; end
    k = k + 1;
end
n = k;
end
