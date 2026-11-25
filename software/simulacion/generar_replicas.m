function [rep, tActualiza] = generar_replicas(cfg, maq)
%GENERAR_REPLICAS  Genera las replicas independientes del experimento Monte Carlo.
%
%   [rep, tActualiza] = GENERAR_REPLICAS(cfg, maq)
%
%   Cada replica (unidad experimental, 24 s) tiene fases de movimiento
%   independientes, bits y ruido nuevos. Los paquetes dentro de una replica
%   estan correlacionados en el tiempo, por lo que los intervalos de
%   confianza se calculan entre replicas. El generador de numeros aleatorios
%   debe fijarse antes de llamar (rng) y el orden de las llamadas no debe
%   alterarse: determina la reproducibilidad frente a la version v3.
%
%   Campos de cada replica
%     fases          Fase de oscilacion de cada maquina (rad).
%     bordes         Bordes temporales de los K intervalos (s).
%     t              Instante de cada paquete (s), uno por intervalo.
%     pulsoAmbiente  Paquetes afectados por la interferencia luminica.
%     bits, z        Bits transmitidos y ruido normal estandar (LxK).
%     sombraRF       Sombreado RF correlacionado (dB), media nula.
%     bloqueoPaquete Bloqueo [maquina x paquete x luminaria].
%     bloqueoCSI     Bloqueo observado por el selector, con retardo.
%     ruidoCSI       Ruido de estimacion de canal (2 x actualizaciones).
R = cfg.nRuns;
K = cfg.nSnapshots;
L = cfg.packetBits;
nM = numel(maq);
nU = ceil(cfg.Tmotion / cfg.csiUpdate_s) + 1;
tActualiza = (0:nU-1) * cfg.csiUpdate_s;
rep = cell(R, 1);
for r = 1:R
    a = struct();
    a.fases = 2*pi*rand(1, nM);
    a.bordes = (0:K) * cfg.Tmotion / K;
    a.t = a.bordes(1:K) + rand(1, K) * (cfg.Tmotion / K);
    faseAmb = cfg.ambient.period_s * rand;
    a.pulsoAmbiente = cfg.ambient.enabled & ...
        (mod(a.t + faseAmb, cfg.ambient.period_s) < ...
         cfg.ambient.duty * cfg.ambient.period_s);
    a.bits = double(randi([0 1], L, K));
    a.z = randn(L, K);
    innov = randn(1, K);
    rho = cfg.rf.shadowCorr;
    a.sombraRF = cfg.rf.shadowSigma_dB * sqrt(1 - rho^2) * ...
        filter(1, [1 -rho], innov);
    a.sombraRF = a.sombraRF - mean(a.sombraRF);
    a.bloqueoPaquete = false(nM, K, 2);
    a.bloqueoCSI = false(nM, nU, 2);
    for o = 1:nM
        for p = 1:K
            [mn, mx] = caja_maquina(maq(o), a.t(p), a.fases(o));
            a.bloqueoPaquete(o, p, 1) = interseccion_aabb(cfg.tx1, cfg.rx, mn, mx);
            a.bloqueoPaquete(o, p, 2) = interseccion_aabb(cfg.tx2, cfg.rx, mn, mx);
        end
        for p = 1:nU
            tObs = max(0, tActualiza(p) - cfg.feedbackDelay_s);
            [mn, mx] = caja_maquina(maq(o), tObs, a.fases(o));
            a.bloqueoCSI(o, p, 1) = interseccion_aabb(cfg.tx1, cfg.rx, mn, mx);
            a.bloqueoCSI(o, p, 2) = interseccion_aabb(cfg.tx2, cfg.rx, mn, mx);
        end
    end
    a.ruidoCSI = randn(2, nU);
    rep{r} = a;
end
end
