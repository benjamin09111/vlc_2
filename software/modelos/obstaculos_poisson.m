function obs = obstaculos_poisson(cfg, T, flujo)
%OBSTACULOS_POISSON  Realizacion de obstaculos que entran y salen de la galeria.
%
%   obs = OBSTACULOS_POISSON(cfg, T, flujo)
%     cfg    Parametros (campos sala y sombra, ver parametros.m).
%     T      Duracion de la ventana de observacion (s).
%     flujo  RandStream a usar; vacio para el generador global.
%
%   Modelo de [PJ2020]: las obstrucciones llegan segun un proceso de Poisson
%   de intensidad epsilon; cada una tiene ancho w, alto h y posicion (x,y)
%   independientes y uniformes. Como el articulo no define la salida de las
%   obstrucciones, se agrega una permanencia exponencial de media Td (supuesto).
%   Con ello el numero de obstrucciones presentes es Poisson(epsilon Td) y la
%   probabilidad de que el enlace quede libre en regimen estacionario es
%     P = exp(-epsilon * Td * E[p])
%   que es la funcion de ponderacion de [PJ2020], ec. (15), con t = Td.
%   Se simula un periodo previo de 5 Td para partir en regimen estacionario.
%
%   Salida: estructura con vectores fila ta, td (llegada y salida, s), x, y,
%   w, h (m); solo incluye obstrucciones presentes en algun instante de [0,T].
if nargin < 3 || isempty(flujo), flujo = RandStream.getGlobalStream; end
lambda = cfg.sombra.epsilon_min / 60;          % llegadas por segundo
Td = cfg.sombra.permanencia_s;
previo = 5 * Td;
ventana = T + previo;
n = poissrnd_simple(lambda * ventana, flujo);
ta = -previo + ventana * sort(rand(flujo, 1, n));
td = ta + (-Td) * log(rand(flujo, 1, n));
x = cfg.sala(1) * rand(flujo, 1, n);
y = cfg.sala(2) * rand(flujo, 1, n);
w = cfg.sombra.ancho_m(1) + diff(cfg.sombra.ancho_m) * rand(flujo, 1, n);
h = cfg.sombra.alto_m(1) + diff(cfg.sombra.alto_m) * rand(flujo, 1, n);
presente = td > 0;
obs.ta = ta(presente);
obs.td = td(presente);
obs.x = x(presente);
obs.y = y(presente);
obs.w = w(presente);
obs.h = h(presente);
end

function n = poissrnd_simple(media, flujo)
% Muestreo de Poisson por tiempos entre llegadas (sin Statistics Toolbox).
n = 0;
acum = -log(rand(flujo));
while acum < media
    n = n + 1;
    acum = acum - log(rand(flujo));
end
end
