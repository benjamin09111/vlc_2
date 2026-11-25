function r = escenario_referencia(resolucion, varargin)
%ESCENARIO_REFERENCIA  Escenario de referencia de Palacios Jativa et al. (2020).
%
%   r = ESCENARIO_REFERENCIA(resolucion) calcula la respuesta al impulso del
%   escenario de referencia de [PJ2020] (Tabla 2): tunel de 6 x 3 x 5 m,
%   luminaria en (3, 0.5, 4.5) apuntando hacia abajo, receptor en
%   (3, 1, 1.8) apuntando hacia arriba (posicion 1), paredes laterales
%   planas con reflectividad 0.6, sin sombra ni dispersion.
%   Parametros opticos de la Tabla 3 (perfil 'mina').
%
%   resolucion   Lado maximo del elemento reflectante (m).
%   Opcion 'SinFactorPi' (false): ver canal_nlos.m.
%
%   Salida: estructura con t (s), h, hLos, hNlos (respuesta al impulso con
%   resolucion temporal de 0.25 ns), gLos, tauLos, gNlos (por elemento),
%   tauNlos, drms (s), mu (s) y la relacion entre el maximo de la respuesta
%   reflejada y la de linea de vista (razonLosNlos).
p = inputParser;
addParameter(p, 'SinFactorPi', false, @islogical);
parse(p, varargin{:});
cfg = parametros('mina');
tx = [3 0.5 4.5];
rx = [3 1 1.8];
ejeTx = [0 0 -1];
ejeRx = [0 0 1];
paredes = paredes_caja([6 3 5], 0.6, {'y0', 'y1'});
c = 299792458;
[gLos, d] = canal_los(tx, rx, cfg);
tauLos = d / c;
[gNlos, tauNlos] = canal_nlos(tx, ejeTx, rx, ejeRx, paredes, cfg, ...
    resolucion, 'SinFactorPi', p.Results.SinFactorPi);
[t, h, res] = respuesta_impulso(gLos, tauLos, gNlos, tauNlos, 0.25e-9, 60e-9);
r.t = t;
r.h = h;
r.hLos = res.hLos;
r.hNlos = res.hNlos;
r.gLos = gLos;
r.tauLos = tauLos;
r.gNlos = gNlos;
r.tauNlos = tauNlos;
r.drms = res.drms;
r.mu = res.mu;
r.distancia = d;
r.razonLosNlos = max(res.hNlos) / gLos;
end
