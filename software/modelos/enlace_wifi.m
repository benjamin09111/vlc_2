function w = enlace_wifi(bloqueado, sombra_dB, emi_dB, cfg)
%ENLACE_WIFI  Enlace Wi-Fi 2.4 GHz (IEEE 802.11n) con adaptacion de tasa ideal.
%
%   w = ENLACE_WIFI(bloqueado, sombra_dB, emi_dB, cfg)
%     bloqueado   Logico 1 x K: maquina metalica cruzando el enlace.
%     sombra_dB   Sombreado lognormal de la replica (dB, escalar).
%     emi_dB      Elevacion del piso de ruido por interferencia
%                 electromagnetica (dB sobre el ruido termico; escalar).
%     cfg         Parametros (campo rf, ver parametros.m).
%
%   Modelo
%     Perdida   PL = PL0 + 10 n log10(d/d0) + sombreado + perdida de obstaculo
%     Potencia  Pr = Pt - PL                                  (dBm)
%     Seleccion MCS mas alto con Pr >= sensibilidad + emi_dB; si ninguno, el
%               enlace esta caido (disponible = false).
%     Tasa util min(cfg.Rb, eficiencia_MAC * tasa_PHY)        (Mb/s)
%     BER       Modulacion del MCS sin codificacion (conservadora), con
%               SNR = Pr - piso_termico - emi_dB, tomada como Es/N0 por simbolo.
%   Devuelve w.ber (1 x K), w.tasa (Mb/s, 1 x K), w.mcs (0 = caido),
%   w.disponible, w.Pr_dBm.
r = cfg.rf;
d = norm(cfg.rx - r.ap);
PL = r.PL0_dB + 10 * r.pathExponent * log10(d / r.d0_m) + sombra_dB + ...
     r.obstacleLoss_dB * double(bloqueado);
Pr = r.tx_dBm - PL;
piso = -174 + 10*log10(r.bandwidth_Hz) + r.noiseFigure_dB;   % dBm
snr_dB = Pr - piso - emi_dB;

K = numel(bloqueado);
mcs = zeros(1, K);
for m = 1:numel(r.mcsSens_dBm)
    mcs(Pr >= r.mcsSens_dBm(m) + emi_dB) = m;      % el ultimo que cumple es el mas alto
end
disponible = mcs > 0;

ber = 0.5 * ones(1, K);
tasa = zeros(1, K);
for m = 1:numel(r.mcsSens_dBm)
    sel = mcs == m;
    if ~any(sel), continue; end
    k = r.mcsBitsSym(m);
    snr = 10.^(snr_dB(sel) / 10);
    if k == 1
        ber(sel) = qf(sqrt(2 * snr));
    else
        M = 2^k;
        ps = 4 * (1 - 1/sqrt(M)) * qf(sqrt(3 * snr / (M - 1)));
        ber(sel) = min(0.5, ps / k);
    end
    tasa(sel) = min(cfg.Rb / 1e6, r.macEfficiency * r.mcsRate_Mbps(m));
end
w.ber = ber; w.tasa = tasa; w.mcs = mcs; w.disponible = disponible;
w.Pr_dBm = Pr; w.snr_dB = snr_dB;
end

function p = qf(x)
p = 0.5 * erfc(x / sqrt(2));
end
