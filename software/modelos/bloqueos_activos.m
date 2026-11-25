function [b1, b2] = bloqueos_activos(mat, nActivas, K)
%BLOQUEOS_ACTIVOS  Estado de bloqueo de cada luminaria con n maquinas activas.
%
%   [b1, b2] = BLOQUEOS_ACTIVOS(mat, nActivas, K)
%     mat       Arreglo logico [maquina x instante x luminaria].
%     nActivas  Numero de maquinas presentes (se usan las primeras).
%     K         Numero de instantes.
%   b1, b2 son vectores logicos 1xK: true si alguna maquina activa bloquea
%   la linea de vista de la luminaria correspondiente.
if nActivas == 0
    b1 = false(1, K);
    b2 = false(1, K);
else
    b1 = any(mat(1:nActivas, :, 1), 1);
    b2 = any(mat(1:nActivas, :, 2), 1);
end
end
