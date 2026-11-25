function [t, h, resumen] = respuesta_impulso(gLos, tauLos, gNlos, tauNlos, dt, tMax)
%RESPUESTA_IMPULSO  Respuesta al impulso discretizada y retardo RMS.
%
%   [t, h, resumen] = RESPUESTA_IMPULSO(gLos, tauLos, gNlos, tauNlos, dt, tMax)
%
%   Entradas
%     gLos, tauLos    Ganancia y retardo del trayecto directo (escalares o vectores).
%     gNlos, tauNlos  Ganancias y retardos de las reflexiones (vectores).
%     dt              Resolucion temporal (s).
%     tMax            Duracion de la ventana (s).
%
%   Salidas
%     t        Instantes de las muestras (s).
%     h        Respuesta total: cada trayecto se acumula en su muestra.
%     resumen  Estructura con
%                hLos, hNlos   Respuestas parciales (mismas muestras)
%                drms          Retardo RMS (s), ecuacion (35) de [PJ2020]
%                mu            Retardo medio (s), ecuacion (36)
%                gananciaDC    Suma de todas las ganancias (adimensional)
%                tasaMax       Tasa maxima sin ISI importante, 1/(10 drms) (bit/s)
n = round(tMax / dt) + 1;
t = (0:n-1)' * dt;
hLos = zeros(n, 1);
hNlos = zeros(n, 1);
ib = @(tau) min(n, max(1, round(tau / dt) + 1));
if ~isempty(gLos)
    hLos = accumarray(ib(tauLos(:)), gLos(:), [n 1]);
end
if ~isempty(gNlos)
    hNlos = accumarray(ib(tauNlos(:)), gNlos(:), [n 1]);
end
h = hLos + hNlos;
p2 = h.^2;
if sum(p2) > 0
    mu = sum(t .* p2) / sum(p2);
    drms = sqrt(sum((t - mu).^2 .* p2) / sum(p2));
else
    mu = NaN;
    drms = NaN;
end
resumen.hLos = hLos;
resumen.hNlos = hNlos;
resumen.drms = drms;
resumen.mu = mu;
resumen.gananciaDC = sum(h);
resumen.tasaMax = 1 / (10 * drms);
end
