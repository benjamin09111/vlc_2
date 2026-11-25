function maq = maquinaria(cfg)
%MAQUINARIA  Construye la lista de maquinas moviles de la galeria.
%
%   maq = MAQUINARIA(cfg) devuelve un arreglo de estructuras con campos
%   xc, yc, sx, sy, alto, amplitud y periodo (unidades SI). Cada maquina se
%   representa como una caja alineada con los ejes que oscila en Y:
%     yc(t) = yc0 + amplitud * sin(2 pi t / periodo + fase)
%   La fase es aleatoria por replica (ver generar_replicas.m).
T = cfg.maquinas.tabla;
n = size(T, 1);
maq = repmat(struct('xc',0,'yc',0,'sx',0,'sy',0,'alto',0, ...
                    'amplitud',0,'periodo',0), 1, n);
for q = 1:n
    maq(q).xc = T(q,1);
    maq(q).yc = cfg.maquinas.yc;
    maq(q).sx = T(q,2);
    maq(q).sy = T(q,3);
    maq(q).alto = T(q,4);
    maq(q).amplitud = T(q,5);
    maq(q).periodo = T(q,6);
    % La trayectoria completa debe permanecer dentro de la galeria.
    assert(maq(q).xc - maq(q).sx/2 >= 0 && ...
           maq(q).xc + maq(q).sx/2 <= cfg.sala(1), 'Maquina fuera del eje X');
    assert(maq(q).alto > 0 && maq(q).alto <= cfg.sala(3), ...
           'Altura de maquina fuera de la galeria');
    assert(maq(q).yc - maq(q).amplitud - maq(q).sy/2 >= 0 && ...
           maq(q).yc + maq(q).amplitud + maq(q).sy/2 <= cfg.sala(2), ...
           'Trayectoria de maquina fuera del eje Y');
end
end
