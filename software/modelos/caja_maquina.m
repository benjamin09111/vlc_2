function [bmin, bmax] = caja_maquina(m, t, fase)
%CAJA_MAQUINA  Caja envolvente de una maquina en el instante t.
%
%   [bmin, bmax] = CAJA_MAQUINA(m, t, fase)
%     m     Estructura de una maquina (ver maquinaria.m).
%     t     Instante (s).
%     fase  Fase de la oscilacion (rad).
%   Devuelve las esquinas inferior y superior [x y z] (m).
yc = m.yc + m.amplitud * sin(2*pi*t/m.periodo + fase);
bmin = [m.xc - m.sx/2, yc - m.sy/2, 0];
bmax = [m.xc + m.sx/2, yc + m.sy/2, m.alto];
end
