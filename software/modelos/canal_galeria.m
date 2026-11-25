function can = canal_galeria(cfg, rx)
%CANAL_GALERIA  Canal estatico de la galeria para un receptor dado.
%
%   can = CANAL_GALERIA(cfg) usa cfg.rx; can = CANAL_GALERIA(cfg, rx) usa rx.
%
%   Para cada luminaria calcula la ganancia LOS sin atenuacion y, para cada
%   elemento reflectante de las superficies de la galeria que contribuye, la
%   ganancia, la longitud del trayecto y la probabilidad esperada de bloqueo
%   de los dos tramos (luminaria-pared y pared-receptor). Estas magnitudes
%   no dependen del polvo, de la temperatura ni de la lente, que se aplican
%   despues en ganancias_escenario.m.
%
%   Campos de la salida
%     rx           Posicion del receptor (m).
%     los(i)       Ganancia LOS de la luminaria i.
%     d(i)         Distancia luminaria-receptor (m).
%     nlos(i).g    Ganancias de los elementos reflectantes (solo g > 0).
%     nlos(i).path Longitud luminaria-pared-receptor de cada elemento (m).
%     nlos(i).Ep   Suma de las probabilidades esperadas de bloqueo de los dos
%                  tramos, E[p_iw] + E[p_wj].
%     drms(i)      Retardo RMS del enlace i con LOS y reflexiones (s).
if nargin < 2, rx = cfg.rx; end
c = 299792458;
tx = [cfg.tx1; cfg.tx2];
paredes = paredes_caja(cfg.sala, cfg.nlos.rho);
can.rx = rx;
for i = 1:2
    [can.los(i), can.d(i)] = canal_los(tx(i,:), rx, cfg);
    [g, tau, centros] = canal_nlos(tx(i,:), [0 0 -1], rx, [0 0 1], ...
        paredes, cfg, cfg.nlos.resolucion_m);
    ok = g > 0;
    g = g(ok); tau = tau(ok); centros = centros(ok, :);
    [~, ep1] = peso_sombra(tx(i,:), centros, cfg, 2000);
    [~, ep2] = peso_sombra(rx, centros, cfg, 2000);
    can.nlos(i).g = g;
    can.nlos(i).path = tau * c;
    can.nlos(i).Ep = ep1 + ep2;
    [~, ~, res] = respuesta_impulso(can.los(i), can.d(i)/c, g, tau, 0.25e-9, 400e-9);
    can.drms(i) = res.drms;
end
end
