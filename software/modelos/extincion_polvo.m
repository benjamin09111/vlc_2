function [k, alpha] = extincion_polvo(cfg)
%EXTINCION_POLVO  Coeficiente de extincion por polvo en suspension.
%
%   [k, alpha] = EXTINCION_POLVO(cfg)
%
%   Salidas
%     k      Extincion especifica (1/m por mg/m^3).
%     alpha  Coeficiente de extincion (1/m) para cada concentracion de
%            cfg.polvo.concentraciones_mgm3.
%
%   Modelo monodisperso de particulas esfericas (Beer-Lambert):
%     alpha = 3 Qext C / (4 rho r)
%   con C la concentracion en kg/m^3. La transmision a lo largo de una
%   distancia d es exp(-alpha d). Qext y r segun [Li2024]; la densidad es una
%   hipotesis. No es un modelo de Mie espectral.
k = (3 * cfg.polvo.Qext * 1e-6) / ...
    (4 * cfg.polvo.densidad_kgm3 * cfg.polvo.radio_m);
alpha = k * cfg.polvo.concentraciones_mgm3;
end
