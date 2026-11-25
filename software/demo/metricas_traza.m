function d = metricas_traza(tr, cfg)
%METRICAS_TRAZA  BER y Goodput acumulados de cada arquitectura a lo largo del ciclo.
%   d.ber(q,k)    BER acumulada hasta el paquete k (ponderada por disponibilidad).
%   d.gpMov(q,k)  Goodput en una ventana de 100 paquetes (5 s).
%   d.gpAcum(q,k) Goodput promedio desde el inicio del ciclo.
L = cfg.packetBits;
[nS, K] = size(tr.err);
num = cumsum(tr.disp .* (tr.err / L), 2);
den = cumsum(tr.disp, 2);
d.ber = zeros(nS, K);
ok = den > 0;
d.ber(ok) = num(ok) ./ den(ok);
inst = tr.disp .* tr.ok .* tr.tasa;
d.gpMov = zeros(nS, K);
for q = 1:nS
    d.gpMov(q, :) = movmean(inst(q, :), [99 0], 'Endpoints', 'shrink');
end
d.gpAcum = cumsum(inst, 2) ./ (1:K);
end
