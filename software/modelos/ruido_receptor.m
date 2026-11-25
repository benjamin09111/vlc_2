function [sigma0, sigma1] = ruido_receptor(Pr, Ibg, Ta, cfg)
%RUIDO_RECEPTOR  Ruido del receptor (disparo y termico) segun [PJ2020] y Komine.
%
%   [sigma0, sigma1] = RUIDO_RECEPTOR(Pr, Ibg, Ta, cfg)
%     Pr   Potencia optica recibida con el LED encendido (W), escalar o vector.
%     Ibg  Corriente de fondo por luz ambiente (A), escalar o del mismo tamano.
%     Ta   Temperatura del receptor (C).
%     cfg  Parametros (campo ruido, ver parametros.m).
%   Devuelve la desviacion tipica del ruido (A RMS) en el simbolo 0
%   (sin senal) y en el simbolo 1 (con senal).
%
%   Varianzas, con ancho de banda de ruido B = tasa de bits Rb:
%     disparo de senal   2 q R Pr B                                 [PJ2020, 38]
%     disparo de fondo   2 q (Ibg + Id) I2 B                        [PJ2020, 38]
%     termico            8 pi kB Tk/G * Cpd Ap I2 B^2
%                      + 16 pi^2 kB Tk Gamma/gm * (Cpd Ap)^2 I3 B^3  [PJ2020, 39]
%   La corriente oscura Id se duplica cada 10 K (hipotesis) y Tk = Ta + 273.15.
r = cfg.ruido;
B = cfg.Rb;
Tk = Ta + 273.15;
Id = r.Id0 * 2^((Ta - 25) / 10);
CA = r.Cpd * cfg.Apd;
disparoFondo = 2 * r.q * (Ibg + Id) * r.I2 * B;
termico = 8*pi*r.kB*Tk / r.G * CA * r.I2 * B^2 + ...
          16*pi^2 * r.kB * Tk * r.Gamma / r.gm * CA^2 * r.I3 * B^3;
disparoSenal = 2 * r.q * cfg.R * Pr * B;
sigma0 = sqrt(disparoFondo + termico);
sigma1 = sqrt(disparoFondo + termico + disparoSenal);
end
