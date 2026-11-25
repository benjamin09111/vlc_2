function [mu, lo, hi] = media_intervalo(valores, minv, maxv)
%MEDIA_INTERVALO  Media e intervalo de confianza del 95 % entre replicas.
%
%   [mu, lo, hi] = MEDIA_INTERVALO(valores, minv, maxv)
%     valores    Un valor por replica independiente.
%     minv, maxv Cotas fisicas de la magnitud (el intervalo se recorta a ellas).
%
%   Aproximacion normal (z = 1.96) sobre las replicas, que son la unidad
%   experimental. Si no hay variacion entre replicas, se usa la cota de
%   Hoeffding para no declarar un intervalo de ancho cero.
valores = valores(:);
n = numel(valores);
mu = mean(valores);
mitad = 1.95996398454 * std(valores) / sqrt(n);
if mitad < 1e-15 && maxv > minv
    mitad = (maxv - minv) * sqrt(log(2/0.05) / (2*n));
end
lo = max(minv, mu - mitad);
hi = min(maxv, mu + mitad);
end
