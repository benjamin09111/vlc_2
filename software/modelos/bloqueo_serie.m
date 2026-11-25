function bloqueado = bloqueo_serie(obs, A, B, t)
%BLOQUEO_SERIE  Estado de bloqueo de un enlace en una serie de instantes.
%
%   bloqueado = BLOQUEO_SERIE(obs, A, B, t)
%     obs  Obstrucciones (ver obstaculos_poisson.m).
%     A,B  Extremos del enlace [x y z] (m), 1x3.
%     t    Instantes (s), vector fila 1 x K.
%   Devuelve un vector logico 1 x K: true si alguna obstruccion presente en
%   ese instante atraviesa el enlace. Las obstrucciones son estaticas mientras
%   permanecen en la galeria, por lo que la geometria se evalua una sola vez.
if isempty(obs.x)
    bloqueado = false(size(t));
    return;
end
bloquea = bloquea_cilindro(A, B, obs.x, obs.y, obs.w, obs.h);   % 1 x M
presente = (t(:) >= obs.ta) & (t(:) < obs.td);                  % K x M
bloqueado = (presente * double(bloquea(:))) > 0;
bloqueado = bloqueado(:)';
end
