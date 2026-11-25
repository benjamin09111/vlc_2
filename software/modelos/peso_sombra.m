function [P, ep] = peso_sombra(A, B, cfg, nMuestras)
%PESO_SOMBRA  Probabilidad de que un enlace este libre de obstrucciones.
%
%   [P, ep] = PESO_SOMBRA(A, B, cfg, nMuestras)
%     A          Extremo comun [x y z] (m), 1x3.
%     B          Otros extremos, nB x 3 (m).
%     cfg        Parametros (campos sala y sombra).
%     nMuestras  Obstrucciones aleatorias usadas para estimar E[p] (4000).
%
%   Funcion de ponderacion de [PJ2020], ec. (15):
%     P = exp(-epsilon * Td * E[p])
%   con E[p] la probabilidad de que una obstruccion aleatoria (ancho, alto y
%   posicion uniformes) bloquee el enlace, estimada por Monte Carlo con un
%   generador propio y fijo, de modo que no altera el generador global ni la
%   reproducibilidad del resto de la simulacion.
%   Se usa como ponderacion esperada de las reflexiones (P_iw * P_wj, ec. 21).
if nargin < 4, nMuestras = 4000; end
flujo = RandStream('mt19937ar', 'Seed', 20201013);
x = cfg.sala(1) * rand(flujo, 1, nMuestras);
y = cfg.sala(2) * rand(flujo, 1, nMuestras);
w = cfg.sombra.ancho_m(1) + diff(cfg.sombra.ancho_m) * rand(flujo, 1, nMuestras);
h = cfg.sombra.alto_m(1) + diff(cfg.sombra.alto_m) * rand(flujo, 1, nMuestras);
nB = size(B, 1);
ep = zeros(nB, 1);
paso = 400;                                    % limita la memoria por bloque
for i = 1:paso:nB
    j = min(nB, i + paso - 1);
    ep(i:j) = mean(bloquea_cilindro(A, B(i:j, :), x, y, w, h), 2);
end
P = exp(-(cfg.sombra.epsilon_min/60) * cfg.sombra.permanencia_s * ep);
end
