function out = ejecutar_escenarios_mina(cfg, can, rep, tActualiza, esc)
%EJECUTAR_ESCENARIOS_MINA  BER y Goodput de las arquitecturas VLC en la galeria.
%
%   out = EJECUTAR_ESCENARIOS_MINA(cfg, can, rep, tActualiza, esc)
%
%   Para cada escenario y cada replica evalua las cuatro arquitecturas VLC,
%   el enlace Wi-Fi y el esquema hibrido (ver enlace_wifi.m):
%     1  1 LED (luminaria 1)
%     2  2 LEDs fijos (potencia dividida 50/50)
%     3  2 LEDs con selector ideal
%     4  2 LEDs con selector practico (ver selector_practico_mina.m)
%     5  Wi-Fi 2.4 GHz (IEEE 802.11n)
%     6  Hibrido: VLC practico, con Wi-Fi si la senal optica estimada es baja
%   La potencia optica total es cfg.Ptotal en todas las arquitecturas, afectada
%   por el factor termico del escenario. El ruido es el del receptor segun
%   ruido_receptor.m, con interferencia luminica como corriente de fondo.
%
%   Metricas (iguales a las de ejecutar_escenarios.m)
%     BER      Errores / bits, ponderada por el tiempo con enlace disponible.
%     Goodput  Tasa util promedio del ciclo (Mb/s), con cabecera y conmutacion.
%
%   Salida
%     resultados  Tabla larga (escenario x arquitectura) con BER, Goodput, sus
%                 intervalos del 95 % entre replicas y los valores teoricos.
%     escenarios  Tabla con una fila por escenario: condiciones, temperatura de
%                 juntura, factor termico, ganancias, bloqueo y diagnostico del
%                 selector.
R = cfg.nRuns;
K = cfg.nSnapshots;
L = cfg.packetBits;
nE = numel(esc);
nS = 6;
nV = 4;                          % arquitecturas opticas
etiquetas = cfg.etiquetas(1:nS);
berRun = zeros(nE, nS, R);
goodRun = zeros(nE, nS, R);
berTeoRun = zeros(nE, nS, R);
goodTeoRun = zeros(nE, nS, R);
bloq = zeros(nE, 3, R);               % LED1, LED2, ambos
selCamb = zeros(nE, R);
selInt = zeros(nE, R);
selMala = zeros(nE, R);
trazar = isfield(cfg, 'trazas') && cfg.trazas;   % guarda la replica 1 paquete a paquete
traza = cell(nE, 1);
wifiDisp = zeros(nE, R);
hibWifi = zeros(nE, R);
hibCamb = zeros(nE, R);
Tj = zeros(nE, 1);
fT = zeros(nE, 1);
snr = zeros(nE, 1);
G = cell(nE, 1);

for e = 1:nE
    s = esc(e);
    G{e} = ganancias_escenario(can, s, cfg);
    [fT(e), Tj(e)] = modelo_termico(s.Ta, s.Rth, cfg);
    Ptx = cfg.Ptotal * fT(e);
    [trErr, trOk, trDisp, trRate] = deal(zeros(nS, K));
    umbralMarca = s.eps / cfg.sombra.epsilon_max_min;
    for r = 1:R
        a = rep{r};
        mask = a.marca <= umbralMarca;
        bPkt = false(2, K);
        bCSI = false(2, size(a.presCSI, 1));
        if any(mask)
            for i = 1:2
                bPkt(i, :) = ((a.presPkt(:, mask) * double(a.bloquea(mask, i))) > 0)';
                bCSI(i, :) = ((a.presCSI(:, mask) * double(a.bloquea(mask, i))) > 0)';
            end
        end
        bloq(e, :, r) = [mean(bPkt(1,:)) mean(bPkt(2,:)) mean(bPkt(1,:) & bPkt(2,:))];
        gan1 = G{e}.los(1) * double(~bPkt(1, :)) + G{e}.nlos(1);
        gan2 = G{e}.los(2) * double(~bPkt(2, :)) + G{e}.nlos(2);

        prx = zeros(nS, K);
        prx(1, :) = Ptx * gan1;
        prx(2, :) = (Ptx / 2) * (gan1 + gan2);
        prx(3, :) = Ptx * max(gan1, gan2);
        [eleccion, ganEst, fracInt, nCamb, mala] = ...
            selector_practico_mina(a, bCSI, bPkt, G{e}, cfg, tActualiza);
        elegida = gan1;
        elegida(eleccion == 2) = gan2(eleccion == 2);
        prx(4, :) = Ptx * elegida;
        selCamb(e, r) = nCamb;
        selInt(e, r) = mean(fracInt);
        selMala(e, r) = mean(mala);
        umbralPractico = cfg.R * Ptx * ganEst / 2;

        Ibg = cfg.ruido.Ibg * ones(1, K);
        if s.interf
            Ibg(a.pulsoAmbiente) = Ibg(a.pulsoAmbiente) + cfg.ambient.Ibg_pulso_A;
        end

        for q = 1:nV
            corriente = cfg.R * prx(q, :);
            [s0, s1] = ruido_receptor(prx(q, :), Ibg, s.Ta, cfg);
            sigma = bsxfun(@plus, s0, bsxfun(@times, a.bits, s1 - s0));
            rx = bsxfun(@times, a.bits, corriente) + a.z .* sigma;
            if q == 4
                umbral = umbralPractico;
                if cfg.umbralPiloto, umbral = corriente / 2; end   % mitigacion: pilotos del paquete
                disponible = 1 - fracInt;
            else
                umbral = corriente / 2;
                disponible = ones(1, K);
            end
            bitsRx = bsxfun(@ge, rx, umbral);
            errores = sum(bitsRx ~= a.bits, 1);
            ok = double(errores == 0);
            pe = 0.25 * erfc(umbral ./ (sqrt(2) * s0)) + ...
                 0.25 * erfc((corriente - umbral) ./ (sqrt(2) * s1));
            pGood = (1 - pe).^L;
            pilotos = cfg.basePilotBits;
            if q == 4, pilotos = pilotos + cfg.adaptExtraPilotBits; end
            escala = (cfg.Rb / 1e6) * L / (L + pilotos);
            assert(sum(disponible) > 0, 'No hay tiempo de enlace activo');
            berRun(e, q, r) = sum(disponible .* (double(errores) / L)) / sum(disponible);
            goodRun(e, q, r) = escala * mean(disponible .* ok);
            berTeoRun(e, q, r) = sum(disponible .* pe) / sum(disponible);
            goodTeoRun(e, q, r) = escala * mean(disponible .* pGood);
            if trazar && r == 1
                trErr(q, :) = errores; trOk(q, :) = ok;
                trDisp(q, :) = disponible; trRate(q, :) = escala * ones(1, K);
            end
            if q == 2
                err2 = errores; ok2 = ok; disp2 = disponible;
                pe2 = pe; pGood2 = pGood; escala2 = escala;
                gan2fijo = 0.5 * (gan1 + gan2);
            end
        end

        % --- Wi-Fi 2.4 GHz (misma obstruccion que la luminaria 1) ----------------
        % Flujo aleatorio propio por replica: no altera el de las arquitecturas
        % opticas y es comun a todos los escenarios (comparacion pareada).
        st = RandStream('mt19937ar', 'Seed', cfg.semilla + r);
        sombraWifi = cfg.rf.shadowSigma_dB * randn(st);
        uWifi = rand(st, L, K);
        w = enlace_wifi(bPkt(1, :), sombraWifi, s.emi, cfg);
        errW = sum(bsxfun(@lt, uWifi, w.ber), 1);
        errW(~w.disponible) = 0;
        okW = double(errW == 0 & w.disponible);
        pGoodW = (1 - w.ber).^L .* double(w.disponible);
        escalaW = L / (L + cfg.basePilotBits);
        tasaW = w.tasa * escalaW;                       % Mb/s por paquete
        if any(w.disponible)
            berRun(e, 5, r) = sum(double(w.disponible) .* (errW / L)) / sum(w.disponible);
            berTeoRun(e, 5, r) = sum(double(w.disponible) .* w.ber) / sum(w.disponible);
        else
            berRun(e, 5, r) = NaN;
            berTeoRun(e, 5, r) = NaN;
        end
        goodRun(e, 5, r) = mean(okW .* tasaW);
        goodTeoRun(e, 5, r) = mean(pGoodW .* tasaW);
        wifiDisp(e, r) = mean(w.disponible);

        % --- Esquema hibrido: VLC con 2 LEDs fijos; Wi-Fi cuando la corriente
        % de senal del enlace optico cae bajo umbralQ veces el ruido y el Wi-Fi
        % esta disponible ---------------
        [~, s1fijo] = ruido_receptor(Ptx * gan2fijo, cfg.ruido.Ibg, s.Ta, cfg);
        opticoDebil = (cfg.R * Ptx * gan2fijo ./ s1fijo) < cfg.hibrido.umbralQ;
        usaW = opticoDebil & w.disponible;               % el RSSI del Wi-Fi es medible
        trans = [false, diff(double(usaW)) ~= 0];        % el paquete del cambio se pierde
        dispH = double(~trans) .* (usaW + (~usaW) .* disp2);
        errH = usaW .* errW + (~usaW) .* err2;
        okH = usaW .* okW + (~usaW) .* ok2;
        tasaH = usaW .* tasaW + (~usaW) .* (escala2 * ones(1, K));
        assert(sum(dispH) > 0, 'No hay tiempo de enlace activo (hibrido)');
        berRun(e, 6, r) = sum(dispH .* (errH / L)) / sum(dispH);
        goodRun(e, 6, r) = mean(dispH .* okH .* tasaH);
        peH = usaW .* w.ber + (~usaW) .* pe2;
        berTeoRun(e, 6, r) = sum(dispH .* peH) / sum(dispH);
        goodTeoRun(e, 6, r) = mean(dispH .* (usaW .* pGoodW .* tasaW + ...
                                   (~usaW) .* pGood2 * escala2));
        if trazar && r == 1
            trErr(5, :) = errW; trOk(5, :) = okW; trDisp(5, :) = 1; trRate(5, :) = tasaW;
            trErr(6, :) = errH; trOk(6, :) = okH; trDisp(6, :) = dispH; trRate(6, :) = tasaH;
            traza{e} = struct('t', a.t, 'bloqueo', bPkt, 'err', trErr, 'ok', trOk, ...
                'disp', trDisp, 'tasa', trRate, 'eleccion', eleccion, ...
                'mejor', 1 + double(gan2 > gan1), 'usaWifi', usaW, ...
                'wifiDisponible', w.disponible, 'marcaMax', umbralMarca);
        end
        hibWifi(e, r) = mean(usaW);
        hibCamb(e, r) = sum(trans);
    end
    % Margen de senal a ruido (corriente de senal / ruido) del enlace 1 LED sin
    % bloqueo; con interferencia se evalua durante un pulso de focos.
    P1 = Ptx * (G{e}.los(1) + G{e}.nlos(1));
    IbgPeor = cfg.ruido.Ibg + double(s.interf) * cfg.ambient.Ibg_pulso_A;   % durante un pulso
    [~, s1] = ruido_receptor(P1, IbgPeor, s.Ta, cfg);
    snr(e) = cfg.R * P1 / s1;
end

% --- Tabla larga con intervalos entre replicas ---------------------------------
n = nE * nS;
Escenario = cell(n, 1); Grupo = cell(n, 1); Sistema = cell(n, 1);
BER = zeros(n, 1); BER_IC95_inf = BER; BER_IC95_sup = BER; BER_Teorica = BER;
Goodput_Mbps = BER; Goodput_IC95_inf = BER; Goodput_IC95_sup = BER;
Goodput_Teorico_Mbps = BER;
k = 0;
for e = 1:nE
    for q = 1:nS
        k = k + 1;
        Escenario{k} = esc(e).nombre;
        Grupo{k} = esc(e).grupo;
        Sistema{k} = etiquetas{q};
        x = reshape(berRun(e, q, :), [], 1);
        x = x(~isnan(x));
        if isempty(x)
            BER(k) = NaN; BER_IC95_inf(k) = NaN; BER_IC95_sup(k) = NaN;
            BER_Teorica(k) = NaN;
        else
            [BER(k), BER_IC95_inf(k), BER_IC95_sup(k)] = media_intervalo(x, 0, 1);
            xt = reshape(berTeoRun(e, q, :), [], 1);
            BER_Teorica(k) = mean(xt(~isnan(xt)));
        end
        x = reshape(goodRun(e, q, :), [], 1);
        [Goodput_Mbps(k), Goodput_IC95_inf(k), Goodput_IC95_sup(k)] = ...
            media_intervalo(x, 0, cfg.Rb / 1e6);
        Goodput_Teorico_Mbps(k) = mean(reshape(goodTeoRun(e, q, :), [], 1));
    end
end
out.resultados = table(Escenario, Grupo, Sistema, BER, BER_IC95_inf, ...
    BER_IC95_sup, BER_Teorica, Goodput_Mbps, Goodput_IC95_inf, ...
    Goodput_IC95_sup, Goodput_Teorico_Mbps);

% --- Tabla por escenario ----------------------------------------------------------
Escenario = {esc.nombre}'; Grupo = {esc.grupo}';
Concentracion_mg_m3 = [esc.conc]'; Transmitancia_lente = [esc.lente]';
Temperatura_C = [esc.Ta]'; Disipador = {esc.disip}';
Obstrucciones_por_min = [esc.eps]'; Interferencia = [esc.interf]';
Tj_C = Tj; Factor_termico = fT;
Ganancia_LOS_1 = cellfun(@(g) g.los(1), G);
Ganancia_NLOS_1 = cellfun(@(g) g.nlos(1), G);
Ganancia_LOS_2 = cellfun(@(g) g.los(2), G);
Ganancia_NLOS_2 = cellfun(@(g) g.nlos(2), G);
Margen_SNR_1LED = snr;
Bloqueo_LED1_pct = 100 * mean(reshape(bloq(:, 1, :), nE, R), 2);
Bloqueo_LED2_pct = 100 * mean(reshape(bloq(:, 2, :), nE, R), 2);
Bloqueo_ambos_pct = 100 * mean(reshape(bloq(:, 3, :), nE, R), 2);
Cambios_selector = mean(selCamb, 2);
Interrupcion_selector_pct = 100 * mean(selInt, 2);
Seleccion_suboptima_pct = 100 * mean(selMala, 2);
EMI_dB = [esc.emi]';
WiFi_disponible_pct = 100 * mean(wifiDisp, 2);
Hibrido_en_WiFi_pct = 100 * mean(hibWifi, 2);
Hibrido_cambios = mean(hibCamb, 2);
out.escenarios = table(Escenario, Grupo, Concentracion_mg_m3, ...
    Transmitancia_lente, Temperatura_C, Disipador, Obstrucciones_por_min, ...
    Interferencia, Tj_C, Factor_termico, Ganancia_LOS_1, Ganancia_NLOS_1, ...
    Ganancia_LOS_2, Ganancia_NLOS_2, Margen_SNR_1LED, Bloqueo_LED1_pct, ...
    Bloqueo_LED2_pct, Bloqueo_ambos_pct, Cambios_selector, ...
    Interrupcion_selector_pct, Seleccion_suboptima_pct, EMI_dB, ...
    WiFi_disponible_pct, Hibrido_en_WiFi_pct, Hibrido_cambios);
out.berRun = berRun;
out.goodRun = goodRun;
out.bloqRun = bloq;
out.traza = traza;

% --- Comprobaciones internas ------------------------------------------------------
assert(all(isnan(BER) | (BER >= 0 & BER <= 1)));
assert(all(isfinite(Goodput_Mbps)) && ...
       all(Goodput_Mbps >= 0 & Goodput_Mbps <= cfg.Rb / 1e6 + 1e-12));
assert(all(reshape(berRun(:, 3, :) - berRun(:, 1, :), [], 1) <= 1e-12));
end
