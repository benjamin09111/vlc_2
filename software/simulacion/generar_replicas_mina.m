function [rep, tActualiza] = generar_replicas_mina(cfg)
%GENERAR_REPLICAS_MINA  Replicas independientes del experimento en la galeria.
%
%   [rep, tActualiza] = GENERAR_REPLICAS_MINA(cfg)
%
%   Cada replica es un ciclo de operacion de cfg.Tmotion segundos con
%   obstrucciones de Poisson, bits, ruido e interferencia luminica propios.
%   Se generan con la intensidad maxima cfg.sombra.epsilon_max_min y cada
%   obstruccion recibe una marca uniforme en [0,1]; un escenario con intensidad
%   epsilon conserva las obstrucciones con marca <= epsilon/epsilon_max. Por
%   adelgazamiento de un proceso de Poisson el resultado es un proceso de
%   Poisson de intensidad epsilon, y todos los escenarios comparten las mismas
%   realizaciones (comparacion pareada).
%
%   Campos de cada replica
%     t, bordes       Instante de cada paquete y bordes de los K intervalos (s).
%     bits, z         Bits transmitidos y ruido normal estandar (L x K).
%     pulsoAmbiente   Paquetes afectados por los focos de vehiculos (1 x K).
%     ruidoCSI        Ruido de estimacion de canal (2 x nU).
%     marca           Marca de adelgazamiento de cada obstruccion (1 x M).
%     bloquea         Bloqueo de cada enlace por cada obstruccion (M x 2).
%     presPkt         Presencia en los instantes de paquete (K x M).
%     presCSI         Presencia en los instantes observados por el selector,
%                     con el retardo de la informacion de canal (nU x M).
%     obs             Obstrucciones: ta, td, x, y, w, h (ver obstaculos_poisson.m).
%   El orden de las llamadas al generador aleatorio determina la
%   reproducibilidad; no debe alterarse.
R = cfg.nRuns;
K = cfg.nSnapshots;
L = cfg.packetBits;
nU = ceil(cfg.Tmotion / cfg.csiUpdate_s) + 1;
tActualiza = (0:nU-1) * cfg.csiUpdate_s;
tObs = max(0, tActualiza - cfg.feedbackDelay_s);
cfgMax = cfg;
cfgMax.sombra.epsilon_min = cfg.sombra.epsilon_max_min;
rep = cell(R, 1);
for r = 1:R
    a = struct();
    obs = obstaculos_poisson(cfgMax, cfg.Tmotion, []);
    M = numel(obs.x);
    a.marca = rand(1, M);
    a.bordes = (0:K) * cfg.Tmotion / K;
    a.t = a.bordes(1:K) + rand(1, K) * (cfg.Tmotion / K);
    faseAmb = cfg.ambient.period_s * rand;
    a.pulsoAmbiente = cfg.ambient.enabled & ...
        (mod(a.t + faseAmb, cfg.ambient.period_s) < ...
         cfg.ambient.duty * cfg.ambient.period_s);
    a.bits = double(randi([0 1], L, K));
    a.z = randn(L, K);
    a.ruidoCSI = randn(2, nU);
    a.bloquea = false(M, 2);
    if M > 0
        a.bloquea(:, 1) = bloquea_cilindro(cfg.tx1, cfg.rx, obs.x, obs.y, obs.w, obs.h)';
        a.bloquea(:, 2) = bloquea_cilindro(cfg.tx2, cfg.rx, obs.x, obs.y, obs.w, obs.h)';
    end
    a.presPkt = (a.t(:) >= obs.ta) & (a.t(:) < obs.td);
    a.presCSI = (tObs(:) >= obs.ta) & (tObs(:) < obs.td);
    a.obs = obs;                      % obstrucciones (solo para la demostracion)
    rep{r} = a;
end
end
