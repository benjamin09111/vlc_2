function malla = canal_malla(cfg)
%CANAL_MALLA  Canal estatico en una malla de posiciones del receptor (con cache).
%
%   malla = CANAL_MALLA(cfg) calcula canal_galeria en x = 0:1:26 m e
%   y = 0.5, 1.5, 2.5, 3.5, 4.5 m a la altura del casco, aprovechando la
%   simetria respecto del eje de la galeria (solo y = 0.5, 1.5 y 2.5 m).
%   El resultado depende solo de la geometria y de las reflexiones, no del
%   polvo, la temperatura ni los lentes, por lo que se guarda en un archivo de
%   cache (software/demo/cache_canal.mat, no versionado) y se reutiliza.
%   Campos: xs, ys, can{iy, ix} (iy sobre ys completo).
ruta = fullfile(fileparts(mfilename('fullpath')), 'cache_canal.mat');
firma = [cfg.sala cfg.tx1 cfg.tx2 cfg.rx(3) cfg.nlos.rho cfg.nlos.resolucion_m cfg.phiHalf cfg.FOV];
if exist(ruta, 'file')
    d = load(ruta);
    if isequal(d.firma, firma), malla = d.malla; return; end
end
xs = 0:1:cfg.sala(1);
ys = [0.5 1.5 2.5 3.5 4.5];
mitad = [0.5 1.5 2.5];
canMitad = cell(numel(mitad), numel(xs));
for iy = 1:numel(mitad)
    parfor ix = 1:numel(xs)
        canMitad{iy, ix} = canal_galeria(cfg, [xs(ix) mitad(iy) cfg.rx(3)]);
    end
end
can = cell(numel(ys), numel(xs));
espejo = [1 2 3 2 1];
for iy = 1:numel(ys), can(iy, :) = canMitad(espejo(iy), :); end
malla = struct('xs', xs, 'ys', ys, 'can', {can});
save(ruta, 'malla', 'firma');
end
