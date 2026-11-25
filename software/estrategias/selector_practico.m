function [eleccion, gananciaEstimada, fraccionInterrupcion, nCambios, mala] = ...
    selector_practico(a, activas, g1, g2, cfg, tActualiza)
%SELECTOR_PRACTICO  Seleccion de luminaria con informacion de canal imperfecta.
%
%   Aporte de la version v3, conservado sin cambios de logica. El selector
%   decide con una estimacion retrasada y ruidosa de la ganancia de cada
%   luminaria, aplica histeresis y pierde datos durante la conmutacion.
%   Nunca usa la ganancia verdadera para fijar el umbral de decision.
%
%   Entradas
%     a           Replica (ver generar_replicas.m).
%     activas     Numero de maquinas presentes.
%     g1, g2      Ganancias de canal de las luminarias tras la extincion.
%     cfg         Parametros.
%     tActualiza  Instantes de actualizacion de la informacion de canal (s).
%
%   Salidas
%     eleccion              Luminaria elegida (1 o 2) en cada paquete.
%     gananciaEstimada      Ganancia estimada de la luminaria elegida.
%     fraccionInterrupcion  Fraccion del intervalo de cada paquete sin datos.
%     nCambios              Numero de conmutaciones en la replica.
%     mala                  true si la eleccion no fue la mejor disponible.
nU = numel(tActualiza);
eleccionU = ones(1, nU);
estU = zeros(2, nU);
for u = 1:nU
    [b1, b2] = bloqueos_activos(a.bloqueoCSI(:, u, :), activas, 1);
    est1 = max(0, g1*double(~b1) + cfg.csiRelativeNoise*g1*a.ruidoCSI(1, u));
    est2 = max(0, g2*double(~b2) + cfg.csiRelativeNoise*g2*a.ruidoCSI(2, u));
    estU(:, u) = [est1; est2];
    if u == 1
        previa = 1;
    else
        previa = eleccionU(u-1);
    end
    if previa == 1
        if est2 > (1 + cfg.hysteresis) * est1
            eleccionU(u) = 2;
        else
            eleccionU(u) = 1;
        end
    else
        if est1 > (1 + cfg.hysteresis) * est2
            eleccionU(u) = 1;
        else
            eleccionU(u) = 2;
        end
    end
end
indices = min(nU, floor(a.t / cfg.csiUpdate_s) + 1);
eleccion = eleccionU(indices);
gananciaEstimada = estU(sub2ind([2 nU], eleccion, indices));

cambio = [false diff(eleccionU) ~= 0];
nCambios = sum(cambio);
tCambio = tActualiza(cambio);
fraccionInterrupcion = zeros(1, numel(a.t));
% Integracion exacta de la indisponibilidad en el intervalo de cada paquete.
izq = a.bordes(1:end-1);
der = a.bordes(2:end);
for u = 1:numel(tCambio)
    t0 = tCambio(u);
    t1 = min(cfg.Tmotion, t0 + cfg.switchOutage_s);
    solape = max(0, min(der, t1) - max(izq, t0));
    fraccionInterrupcion = fraccionInterrupcion + solape ./ (der - izq);
end
fraccionInterrupcion = min(1, max(0, fraccionInterrupcion));

[b1, b2] = bloqueos_activos(a.bloqueoPaquete, activas, numel(a.t));
real1 = g1 * double(~b1);
real2 = g2 * double(~b2);
elegida = real1;
elegida(eleccion == 2) = real2(eleccion == 2);
mala = (elegida < max(real1, real2) - 1e-15);
end
