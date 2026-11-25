function [eleccion, gananciaEstimada, fraccionInterrupcion, nCambios, mala] = ...
    selector_practico_mina(a, bCSI, bPkt, G, cfg, tActualiza)
%SELECTOR_PRACTICO_MINA  Selector de luminaria con informacion de canal imperfecta.
%
%   Misma logica del selector de la version v3 (estimacion retrasada y ruidosa,
%   histeresis, corte al conmutar), pero con ganancias que incluyen la
%   componente reflejada: un enlace bloqueado conserva la ganancia reflejada.
%
%   Entradas
%     a           Replica (ver generar_replicas_mina.m).
%     bCSI        Bloqueo observado por el selector, 2 x nU (logico).
%     bPkt        Bloqueo real en cada paquete, 2 x K (logico).
%     G           Ganancias del escenario: G.los(i) y G.nlos(i).
%     cfg         Parametros.
%     tActualiza  Instantes de actualizacion de la informacion de canal (s).
%   Salidas: ver selector_practico.m.
nU = numel(tActualiza);
G0 = G.los + G.nlos;                                   % ganancia sin bloqueo
eleccionU = ones(1, nU);
estU = zeros(2, nU);
for u = 1:nU
    real = G.los(:) .* double(~bCSI(:, u)) + G.nlos(:);
    est = max(0, real + cfg.csiRelativeNoise * G0(:) .* a.ruidoCSI(:, u));
    estU(:, u) = est;
    if u == 1, previa = 1; else, previa = eleccionU(u-1); end
    if previa == 1
        if est(2) > (1 + cfg.hysteresis) * est(1), eleccionU(u) = 2; else, eleccionU(u) = 1; end
    else
        if est(1) > (1 + cfg.hysteresis) * est(2), eleccionU(u) = 1; else, eleccionU(u) = 2; end
    end
end
indices = min(nU, floor(a.t / cfg.csiUpdate_s) + 1);
eleccion = eleccionU(indices);
gananciaEstimada = estU(sub2ind([2 nU], eleccion, indices));

cambio = [false diff(eleccionU) ~= 0];
nCambios = sum(cambio);
tCambio = tActualiza(cambio);
fraccionInterrupcion = zeros(1, numel(a.t));
izq = a.bordes(1:end-1);
der = a.bordes(2:end);
for u = 1:numel(tCambio)
    t0 = tCambio(u);
    t1 = min(cfg.Tmotion, t0 + cfg.switchOutage_s);
    solape = max(0, min(der, t1) - max(izq, t0));
    fraccionInterrupcion = fraccionInterrupcion + solape ./ (der - izq);
end
fraccionInterrupcion = min(1, max(0, fraccionInterrupcion));

real1 = G.los(1) * double(~bPkt(1, :)) + G.nlos(1);
real2 = G.los(2) * double(~bPkt(2, :)) + G.nlos(2);
elegida = real1;
elegida(eleccion == 2) = real2(eleccion == 2);
% Eleccion no optima: pierde mas de 0.1 % de la ganancia de la mejor luminaria.
% Tolerancia relativa porque las ganancias reflejadas de ambas luminarias
% difieren en el muestreo de la ponderacion de sombra.
mala = (elegida < max(real1, real2) * (1 - 1e-3));
end
