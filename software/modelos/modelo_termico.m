function [factor, Tj] = modelo_termico(Ta, Rth, cfg)
%MODELO_TERMICO  Efecto de la temperatura ambiente sobre la potencia optica del LED.
%
%   [factor, Tj] = MODELO_TERMICO(Ta, Rth, cfg)
%     Ta   Temperatura ambiente (C), escalar o vector.
%     Rth  Resistencia termica juntura-ambiente de la luminaria (K/W).
%     cfg  Parametros (campo termico, ver parametros.m).
%   Devuelve
%     factor  Potencia optica relativa a la de las condiciones de referencia
%             (Ta = 25 C con disipador estandar), adimensional.
%     Tj      Temperatura de juntura (C).
%
%   Modelo (hipotesis de hoja de datos de LED de potencia):
%     eta(Tj)  = etaOpt0 (1 - kT (Tj - 25))      eficiencia optica
%     Pelec    = Popt_nom / etaOpt0              potencia electrica constante
%     Tj       = Ta + Rth (Pelec - eta(Tj) Pelec)  calor disipado
%   La ecuacion de Tj se resuelve por punto fijo (converge porque
%   Rth etaOpt0 Pelec kT < 1). La potencia optica es eta(Tj) Pelec, y el
%   factor se normaliza a la de las condiciones de referencia, de modo que
%   Popt_nom corresponde a la potencia de [PJ2020] en esas condiciones.
t = cfg.termico;
Pelec = cfg.Ptotal / t.etaOpt0;
resolver = @(Ta_, Rth_) puntoFijo(Ta_, Rth_, Pelec, t);
TjRef = resolver(t.Tref_C, t.Rth_std);
Tj = zeros(size(Ta));
for q = 1:numel(Ta)
    Tj(q) = resolver(Ta(q), Rth);
end
etaRel = @(T) 1 - t.kT * (T - t.Tref_C);
factor = etaRel(Tj) ./ etaRel(TjRef);
end

function Tj = puntoFijo(Ta, Rth, Pelec, t)
Tj = Ta;
for k = 1:200
    eta = t.etaOpt0 * (1 - t.kT * (Tj - t.Tref_C));
    nuevo = Ta + Rth * Pelec * (1 - eta);
    if abs(nuevo - Tj) < 1e-12, Tj = nuevo; return; end
    Tj = nuevo;
end
end
