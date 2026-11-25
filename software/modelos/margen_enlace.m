function m = margen_enlace(can, c, cfg)
%MARGEN_ENLACE  Margen de enlace (dB) de dos luminarias fijas, sin obstrucciones dinamicas.
%
%   m = MARGEN_ENLACE(can, c, cfg)
%     can  Canal estatico de un punto (canal_galeria).
%     c    Condiciones: conc (mg/m^3), lente, eps (por minuto), Ta (C); el
%          disipador es el estandar.
%     cfg  Parametros.
%   Margen = 20 log10(corriente de senal / desviacion del ruido en el simbolo 1).
%   Con 2 LEDs fijos la potencia optica total se divide en partes iguales y se
%   suman los aportes (LOS y reflejado) de ambas luminarias. Un margen de
%   21.6 dB equivale a corriente = 12 sigma, es decir, BER del orden de 1e-9.
esc = struct('conc', c.conc, 'lente', c.lente, 'eps', c.eps);
G = ganancias_escenario(can, esc, cfg);
fT = modelo_termico(c.Ta, cfg.termico.Rth_std, cfg);
P = (cfg.Ptotal * fT / 2) * (G.los(1) + G.nlos(1) + G.los(2) + G.nlos(2));
[~, s1] = ruido_receptor(P, cfg.ruido.Ibg, c.Ta, cfg);
m = 20 * log10(cfg.R * P / s1);
end
