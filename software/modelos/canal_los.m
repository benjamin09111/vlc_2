function [H, d] = canal_los(tx, rx, cfg)
%CANAL_LOS  Ganancia en continua del enlace con linea de vista (LOS).
%
%   [H, d] = CANAL_LOS(tx, rx, cfg)
%
%   Entradas
%     tx   Posicion de la luminaria [x y z] (m). Apunta hacia abajo (-z).
%     rx   Posicion del fotodetector [x y z] (m). Apunta hacia arriba (+z).
%     cfg  Estructura de parametros (ver parametros.m).
%
%   Salidas
%     H    Ganancia de canal (adimensional); 0 si el receptor queda fuera
%          del campo de vision o detras del plano de emision.
%     d    Distancia luminaria-receptor (m).
%
%   Modelo lambertiano de [PJ2020], ecs. (1)-(5):
%     m = -ln2 / ln(cos(phiHalf))
%     H = (m+1) Apd / (2 pi d^2) * cos^m(phi) * cos(psi) * g
%   con phi el angulo de emision y psi el de incidencia.
v = rx - tx;
d = norm(v);
if d <= 0
    error('canal_los:coincidencia', 'La luminaria y el receptor coinciden.');
end
cosTx = dot(v/d, [0 0 -1]);
cosRx = dot(-v/d, [0 0 1]);
if cosTx <= 0 || cosRx <= 0 || acosd(min(1, max(-1, cosRx))) > cfg.FOV
    H = 0;
    return;
end
m = -log(2) / log(cosd(cfg.phiHalf));
H = ((m+1) * cfg.Apd / (2*pi*d^2)) * cosTx^m * cosRx * ...
    cfg.filterGain * cfg.concentratorGain;
end
