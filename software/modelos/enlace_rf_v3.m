function [errores, ok, pe, pGood] = enlace_rf_v3(cfg, bloqueado, sombraRF, bits, z)
%ENLACE_RF_V3  Enlace RF BPSK ilustrativo heredado de la version v3.
%
%   Se conserva solo para demostrar la no regresion (prueba P-01). La
%   Fase 5 lo reemplaza por un modelo Wi-Fi 2.4 GHz con parametros
%   industriales; la SNR de este modelo (~56 dB) hace trivial la comparacion.
%
%   Entradas: cfg, bloqueado (1xK logico, bloqueo de la luminaria 1),
%   sombraRF (1xK, dB), bits (LxK), z (LxK, ruido normal estandar).
%   Salidas: errores por paquete (1xK), paquete correcto (1xK), probabilidad
%   de error de bit teorica (1xK) y probabilidad de paquete correcto (1xK).
L = size(bits, 1);
dRF = norm(cfg.tx1 - cfg.rx);
perdida = cfg.rf.PL0_dB + ...
    10 * cfg.rf.pathExponent * log10(dRF / cfg.rf.d0_m) + ...
    cfg.rf.obstacleLoss_dB * double(bloqueado) + sombraRF;
prxdBm = cfg.rf.tx_dBm - perdida;
termicoDbm = -174 + 10*log10(cfg.rf.bandwidth_Hz) + cfg.rf.noiseFigure_dB;
ruidoDbm = 10*log10(10.^(termicoDbm/10) + 10.^(cfg.rf.interference_dBm/10));
ebn0 = 10.^((prxdBm - ruidoDbm + ...
            10*log10(cfg.rf.bandwidth_Hz / cfg.Rb)) / 10);
rx = bsxfun(@times, 2*bits - 1, sqrt(2*ebn0)) + z;
bitsRx = (rx >= 0);
errores = sum(bitsRx ~= bits, 1);
ok = (errores == 0);
pe = 0.5 * erfc(sqrt(ebn0));
pGood = (1 - pe).^L;
end
