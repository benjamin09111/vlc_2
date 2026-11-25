function out = ejecutar_escenarios(cfg, rep, tActualiza)
%EJECUTAR_ESCENARIOS  Evalua BER y Goodput de todas las arquitecturas.
%
%   out = EJECUTAR_ESCENARIOS(cfg, rep, tActualiza)
%
%   Recorre cada nivel de polvo y cada numero de maquinas activas, y para
%   cada replica evalua las arquitecturas de cfg.etiquetas:
%     1  1 LED
%     2  2 LEDs fijos (potencia dividida 50/50)
%     3  2 LEDs con selector ideal (conoce la mejor luminaria)
%     4  2 LEDs con selector practico (ver selector_practico.m)
%     5  RF ilustrativo heredado de v3 (ver enlace_rf_v3.m)
%
%   Metricas
%     BER      Errores / bits, ponderada por el tiempo con enlace disponible.
%     Goodput  Tasa util promedio del ciclo completo (Mb/s): incluye la
%              sobrecarga de cabecera y el tiempo perdido al conmutar.
%
%   Salida (estructura)
%     resultados   Tabla con BER, Goodput, sus intervalos del 95 % entre
%                  replicas y los valores teoricos (probabilidad de error).
%     diagBloqueo  Porcentaje de tiempo bloqueado por luminaria.
%     diagSelector Conmutaciones, interrupcion y elecciones no optimas.
%     berRun, goodRun  Valores por escenario, arquitectura y replica.
[~, alpha] = extincion_polvo(cfg);
conc = cfg.polvo.concentraciones_mgm3;
obs = cfg.obstaculos;
nA = numel(alpha);
nO = numel(obs);
nS = 4 + double(cfg.rf.enabled);
R = cfg.nRuns;
K = cfg.nSnapshots;
L = cfg.packetBits;
etiquetas = cfg.etiquetas(1:nS);

[H1, d1] = canal_los(cfg.tx1, cfg.rx, cfg);
[H2, d2] = canal_los(cfg.tx2, cfg.rx, cfg);
assert(H1 > 0 && H2 > 0, 'Alguna luminaria queda fuera del campo de vision');

idx = @(i, j, s) ((i-1)*nO + j - 1)*nS + s;
scidx = @(i, j) (i-1)*nO + j;
numSc = nA * nO;
numFilas = numSc * nS;

berRun = zeros(numSc, nS, R);
goodRun = zeros(numSc, nS, R);
berTeoRun = zeros(numSc, nS, R);
goodTeoRun = zeros(numSc, nS, R);
geomB1 = zeros(nO, R);
geomB2 = zeros(nO, R);
geomAmbos = zeros(nO, R);
geomUno = zeros(nO, R);
selCambios = zeros(numSc, R);
selInterrup = zeros(numSc, R);
selMala = zeros(numSc, R);

for r = 1:R
    a = rep{r};
    for j = 1:nO
        [b1, b2] = bloqueos_activos(a.bloqueoPaquete, obs(j), K);
        geomB1(j, r) = mean(b1);
        geomB2(j, r) = mean(b2);
        geomAmbos(j, r) = mean(b1 & b2);
        geomUno(j, r) = mean(xor(b1, b2));
    end
    for i = 1:nA
        g1 = H1 * exp(-alpha(i) * d1);
        g2 = H2 * exp(-alpha(i) * d2);
        for j = 1:nO
            c = scidx(i, j);
            activas = obs(j);
            [b1, b2] = bloqueos_activos(a.bloqueoPaquete, activas, K);
            gan1 = g1 * double(~b1);
            gan2 = g2 * double(~b2);

            prx = zeros(nS, K);
            prx(1, :) = cfg.Ptotal * gan1;
            prx(2, :) = (cfg.Ptotal/2) * (gan1 + gan2);
            prx(3, :) = cfg.Ptotal * max(gan1, gan2);
            [eleccion, ganEst, fracInt, nCamb, mala] = ...
                selector_practico(a, activas, g1, g2, cfg, tActualiza);
            elegida = gan1;
            elegida(eleccion == 2) = gan2(eleccion == 2);
            prx(4, :) = cfg.Ptotal * elegida;
            selCambios(c, r) = nCamb;
            selInterrup(c, r) = mean(fracInt);
            selMala(c, r) = mean(mala);
            % El umbral del selector practico usa la amplitud estimada.
            umbralPractico = cfg.R * cfg.Ptotal * ganEst / 2;
            sigma = cfg.sigmaN * ones(1, K);
            if cfg.ambient.enabled
                sigma(a.pulsoAmbiente) = cfg.sigmaN * cfg.ambient.noiseMultiplier;
            end

            for s = 1:nS
                if s <= 4
                    corriente = cfg.R * prx(s, :);
                    rx = bsxfun(@times, a.bits, corriente) + ...
                         bsxfun(@times, a.z, sigma);
                    if s == 4
                        umbral = umbralPractico;
                        disponible = 1 - fracInt;
                    else
                        umbral = corriente / 2;
                        disponible = ones(1, K);
                    end
                    bitsRx = bsxfun(@ge, rx, umbral);
                    errores = sum(bitsRx ~= a.bits, 1);
                    ok = double(errores == 0);
                    % Umbral desajustado: promedio de error en bit 0 y bit 1.
                    pe = 0.25 * erfc(umbral ./ (sqrt(2)*sigma)) + ...
                         0.25 * erfc((corriente - umbral) ./ (sqrt(2)*sigma));
                    pGood = (1 - pe).^L;
                    pilotos = cfg.basePilotBits;
                    if s == 4, pilotos = pilotos + cfg.adaptExtraPilotBits; end
                else
                    [errores, ok, pe, pGood] = enlace_rf_v3(cfg, b1, ...
                        a.sombraRF, a.bits, a.z);
                    pilotos = cfg.basePilotBits;
                    disponible = ones(1, K);
                end
                escala = (cfg.Rb/1e6) * L / (L + pilotos);
                assert(sum(disponible) > 0, 'No hay tiempo de enlace activo');
                berRun(c, s, r) = sum(disponible .* (double(errores)/L)) / ...
                                  sum(disponible);
                goodRun(c, s, r) = escala * mean(disponible .* ok);
                berTeoRun(c, s, r) = sum(disponible .* pe) / sum(disponible);
                goodTeoRun(c, s, r) = escala * mean(disponible .* pGood);
            end
        end
    end
end

% --- Tabla de resultados con intervalos entre replicas ---------------------
Sistema = cell(numFilas, 1);
Concentracion_mg_m3 = zeros(numFilas, 1);
Alpha_m1 = zeros(numFilas, 1);
Obstaculos = zeros(numFilas, 1);
BER = zeros(numFilas, 1);
BER_IC95_inf = zeros(numFilas, 1);
BER_IC95_sup = zeros(numFilas, 1);
BER_Teorica = zeros(numFilas, 1);
Goodput_Mbps = zeros(numFilas, 1);
Goodput_IC95_inf = zeros(numFilas, 1);
Goodput_IC95_sup = zeros(numFilas, 1);
Goodput_Teorico_Mbps = zeros(numFilas, 1);
for i = 1:nA
    for j = 1:nO
        c = scidx(i, j);
        for s = 1:nS
            k = idx(i, j, s);
            Sistema{k} = etiquetas{s};
            Concentracion_mg_m3(k) = conc(i);
            Alpha_m1(k) = alpha(i);
            Obstaculos(k) = obs(j);
            x = reshape(berRun(c, s, :), [], 1);
            [BER(k), BER_IC95_inf(k), BER_IC95_sup(k)] = media_intervalo(x, 0, 1);
            BER_Teorica(k) = mean(reshape(berTeoRun(c, s, :), [], 1));
            x = reshape(goodRun(c, s, :), [], 1);
            [Goodput_Mbps(k), Goodput_IC95_inf(k), Goodput_IC95_sup(k)] = ...
                media_intervalo(x, 0, cfg.Rb/1e6);
            Goodput_Teorico_Mbps(k) = mean(reshape(goodTeoRun(c, s, :), [], 1));
        end
    end
end
out.resultados = table(Sistema, Concentracion_mg_m3, Alpha_m1, Obstaculos, ...
    BER, BER_IC95_inf, BER_IC95_sup, BER_Teorica, ...
    Goodput_Mbps, Goodput_IC95_inf, Goodput_IC95_sup, Goodput_Teorico_Mbps);

% --- Diagnosticos (no son metricas de rendimiento) -------------------------
Obs = obs(:);
Bloqueo_LED1_pct = 100 * mean(geomB1, 2);
Bloqueo_LED2_pct = 100 * mean(geomB2, 2);
Bloqueo_ambos_pct = 100 * mean(geomAmbos, 2);
Bloqueo_unico_pct = 100 * mean(geomUno, 2);
out.diagBloqueo = table(Obs, Bloqueo_LED1_pct, Bloqueo_LED2_pct, ...
    Bloqueo_ambos_pct, Bloqueo_unico_pct);

C_mg_m3 = zeros(numSc, 1);
Obstaculos_activos = zeros(numSc, 1);
Cambios_medio = zeros(numSc, 1);
Tiempo_interrupcion_pct = zeros(numSc, 1);
Seleccion_suboptima_pct = zeros(numSc, 1);
for i = 1:nA
    for j = 1:nO
        c = scidx(i, j);
        C_mg_m3(c) = conc(i);
        Obstaculos_activos(c) = obs(j);
        Cambios_medio(c) = mean(selCambios(c, :));
        Tiempo_interrupcion_pct(c) = 100 * mean(selInterrup(c, :));
        Seleccion_suboptima_pct(c) = 100 * mean(selMala(c, :));
    end
end
out.diagSelector = table(C_mg_m3, Obstaculos_activos, Cambios_medio, ...
    Tiempo_interrupcion_pct, Seleccion_suboptima_pct);

out.berRun = berRun;
out.goodRun = goodRun;

% --- Comprobaciones internas de coherencia ---------------------------------
assert(all(isfinite(BER)) && all(BER >= 0 & BER <= 1));
assert(all(isfinite(Goodput_Mbps)) && ...
       all(Goodput_Mbps >= 0 & Goodput_Mbps <= cfg.Rb/1e6 + 1e-12));
% El selector ideal nunca elige peor que el LED unico en la misma realizacion.
assert(all(reshape(berRun(:, 3, :) - berRun(:, 1, :), [], 1) <= 1e-12));
assert(all(reshape(goodRun(:, 3, :) - goodRun(:, 1, :), [], 1) >= -1e-12));
end
