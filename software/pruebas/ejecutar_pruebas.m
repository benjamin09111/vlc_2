function tabla = ejecutar_pruebas(varargin)
%EJECUTAR_PRUEBAS  Pruebas unitarias, de validacion y de no regresion.
%
%   tabla = EJECUTAR_PRUEBAS() ejecuta las pruebas, imprime el resultado de
%   cada una y escribe docs/registro_pruebas.csv. Falla (error) si alguna
%   prueba no se cumple. Los casos estan descritos en docs/PRUEBAS.md.
%
%   EJECUTAR_PRUEBAS('Rapido', true) omite P-01, que ejecuta la simulacion
%   completa (unos segundos).
p = inputParser;
addParameter(p, 'Rapido', false, @islogical);
parse(p, varargin{:});

raiz = fileparts(fileparts(mfilename('fullpath')));      % .../software
addpath(genpath(raiz));
proyecto = fileparts(raiz);
cfg = parametros();
cfgM = parametros('mina');

ids = {}; objetivo = {}; valor = {}; aprobada = [];
    function registrar(id, texto, medida, ok)
        ids{end+1, 1} = id;                  %#ok<AGROW>
        objetivo{end+1, 1} = texto;          %#ok<AGROW>
        valor{end+1, 1} = medida;            %#ok<AGROW>
        aprobada(end+1, 1) = logical(ok);    %#ok<AGROW>
        fprintf('[%s] %s | %s\n', ternario(ok, 'APROBADA', 'FALLIDA '), id, medida);
    end

% --- P-01 No regresion frente a la linea base v3 -----------------------------
out = [];
if ~p.Results.Rapido
    out = ejecutar_simulacion('Guardar', false, 'Perfil', 'v3');
    refPath = fullfile(proyecto, 'legacy', 'v3_companero', 'Resultados_VLC_v3', ...
        'Resultados_Completos_VLC_RF.csv');
    ref = readtable(refPath, 'TextType', 'char');
    nuevo = out.resultados;
    mismasFilas = height(ref) == height(nuevo);
    mismoSistema = mismasFilas && isequal(ref.Sistema, nuevo.Sistema);
    difMax = NaN;
    if mismoSistema
        difMax = 0;
        for c = 2:width(ref)
            difMax = max(difMax, max(abs(ref{:, c} - nuevo{:, c})));
        end
    end
    registrar('P-01', 'No regresion frente a v3 (80 filas)', ...
        sprintf('filas=%d, diferencia maxima=%.3g', height(nuevo), difMax), ...
        mismoSistema && difMax < 1e-9);
end

% --- P-02 La potencia recibida en LOS decae como 1/d^2 -------------------------
tx = [0 0 4];
alturas = 0.5:0.5:3;
H = zeros(size(alturas)); d = H;
for q = 1:numel(alturas)
    [H(q), d(q)] = canal_los(tx, [0 0 alturas(q)], cfg);
end
pend = polyfit(log(d), log(H), 1);
registrar('P-02', 'Decaimiento 1/d^2 en LOS', ...
    sprintf('pendiente log-log=%.6f (esperada -2)', pend(1)), ...
    abs(pend(1) + 2) < 0.01);

% --- P-03 Sin polvo no hay extincion -------------------------------------------
[~, alfa] = extincion_polvo(cfg);
registrar('P-03', 'Concentracion nula implica extincion nula', ...
    sprintf('alpha(C=0)=%g, transmision=%g', alfa(1), exp(-alfa(1)*3)), ...
    alfa(1) == 0 && exp(-alfa(1)*3) == 1);

% --- P-04 Sin maquinaria no hay bloqueo ---------------------------------------
mat = true(3, 10, 2);
[b1, b2] = bloqueos_activos(mat, 0, 10);
ok4 = ~any(b1) && ~any(b2);
if ~isempty(out)
    ok4 = ok4 && all(out.diagBloqueo.Bloqueo_LED1_pct(out.diagBloqueo.Obs == 0) == 0) ...
              && all(out.diagBloqueo.Bloqueo_LED2_pct(out.diagBloqueo.Obs == 0) == 0);
end
registrar('P-04', 'Sin maquinas no hay bloqueo', ...
    sprintf('bloqueo con 0 maquinas = %d paquetes', sum(b1) + sum(b2)), ok4);

% --- P-06 Interseccion segmento-caja en casos conocidos ------------------------
bmin = [0.9 -0.5 -0.5]; bmax = [1.1 0.5 0.5];
casos = {
    [0 0 0], [2 0 0], true;      % atraviesa la caja
    [0 2 0], [2 2 0], false;     % pasa al lado
    [0 0 0], [0.5 0 0], false;   % termina antes de la caja
    [1 0 0], [1.5 0 0], true;    % empieza dentro
    [0 0.8 0], [2 0.8 0], false; % paralelo fuera de la caja
    [1 -2 0], [1 2 0], true};    % atraviesa en Y
fallos = 0;
for q = 1:size(casos, 1)
    if interseccion_aabb(casos{q,1}, casos{q,2}, bmin, bmax) ~= casos{q,3}
        fallos = fallos + 1;
    end
end
registrar('P-06', 'Interseccion segmento-caja', ...
    sprintf('%d de %d casos correctos', size(casos,1) - fallos, size(casos,1)), ...
    fallos == 0);

% --- P-07 Sin reflectividad no hay componente NLOS -------------------------------
pw0 = paredes_caja([6 3 5], 0, {'y0', 'y1'});
g0 = canal_nlos([3 0.5 4.5], [0 0 -1], [3 1 1.8], [0 0 1], pw0, cfgM, 0.2);
registrar('P-07', 'Con rho = 0 la ganancia NLOS es nula', ...
    sprintf('suma de ganancias = %g', sum(g0)), sum(g0) == 0);

% --- P-09 Reciprocidad del canal reflejado ----------------------------------------
cfgR = cfgM; cfgR.FOV = 90; cfgR.phiHalf = 60; cfgR.concentratorGain = 1;
pwR = paredes_caja([6 3 5], 0.6);
posT = [1.5 1 4.0]; posR = [3.2 2 1.5];
gA = sum(canal_nlos(posT, [0 0 -1], posR, [0 0 1], pwR, cfgR, 0.1));
gB = sum(canal_nlos(posR, [0 0 1], posT, [0 0 -1], pwR, cfgR, 0.1));
registrar('P-09', 'Reciprocidad: intercambiar emisor y receptor', ...
    sprintf('ganancia=%.6g y %.6g, dif. relativa=%.2g', gA, gB, abs(gA-gB)/gA), ...
    abs(gA - gB) / gA < 1e-9);

% --- P-10 Convergencia de la discretizacion de las paredes -------------------------
rGruesa = escenario_referencia(0.10);
rFina = escenario_referencia(0.02);
conv = abs(sum(rGruesa.gNlos) - sum(rFina.gNlos)) / sum(rFina.gNlos);
registrar('P-10', 'Convergencia NLOS: elementos de 0.10 m frente a 0.02 m', ...
    sprintf('diferencia relativa de la ganancia total=%.2g', conv), conv < 0.01);

% --- P-11 Bloqueo por obstaculos cilindricos en casos conocidos --------------------
A = [0 0 3];
c11 = {
    [4 0 1],   2,   0,   1.0, 2.0, true;     % pasa por el cilindro, mas bajo que h
    [4 0 1],   2,   0,   1.0, 1.5, false;    % pasa por encima del cilindro
    [4 0 1],   2,   0.6, 1.0, 2.0, false;    % pasa a mas de w/2 del eje
    [4 0 1],   5,   0,   1.0, 3.0, false;    % cilindro mas alla del extremo
    [4 0 1],   2,   0,   0.0, 3.0, false};   % ancho nulo
fallos = 0;
for q = 1:size(c11, 1)
    r = bloquea_cilindro(A, c11{q,1}, c11{q,2}, c11{q,3}, c11{q,4}, c11{q,5});
    if r ~= c11{q,6}, fallos = fallos + 1; end
end
rv1 = bloquea_cilindro([0 0 4], [0 0 1], 0.2, 0, 1.0, 2.0);   % enlace vertical
rv2 = bloquea_cilindro([0 0 4], [0 0 1], 0.2, 0, 1.0, 0.5);
fallos = fallos + double(~rv1) + double(rv2);
registrar('P-11', 'Bloqueo por obstaculo cilindrico', ...
    sprintf('%d de %d casos correctos', 7 - fallos, 7), fallos == 0);

% --- V-01 Reproduccion del escenario de referencia de [PJ2020] ----------------------
rPaper = escenario_referencia(0.10, 'SinFactorPi', true);
rFisico = escenario_referencia(0.10);
razonPaper = 100 * rPaper.razonLosNlos;
objetivoRazon = 11.47;                       % % reportado por [PJ2020], Sec. VII-B
difRazon = abs(razonPaper - objetivoRazon) / objetivoRazon;
llegaDespues = min(rPaper.tauNlos(rPaper.gNlos > 0)) > rPaper.tauLos;
drmsOk = rPaper.drms >= 9.01e-12 && rPaper.drms <= 8.28e-9;
registrar('V-01', 'Escenario de referencia de [PJ2020]: NLOS/LOS, retardo, D_RMS', ...
    sprintf(['NLOS/LOS=%.2f %% (articulo 11.47 %%, dif. %.1f %%); con 1/pi=%.2f %%; ' ...
             'D_RMS=%.3g ns; reflexiones posteriores a LOS=%d'], ...
             razonPaper, 100*difRazon, 100*rFisico.razonLosNlos, ...
             rPaper.drms*1e9, llegaDespues), ...
    difRazon < 0.15 && llegaDespues && drmsOk);

% --- V-02 BER por simulacion de bits frente a la expresion analitica -----------------
flujo = RandStream('mt19937ar', 'Seed', 20261124);
amplitudes = [2 3 4 5 6];                   % corriente de senal / ruido RMS
N = 2e6;
peor = 0; ok = true;
for a = amplitudes
    bits = rand(flujo, N, 1) < 0.5;
    rx = a * double(bits) + randn(flujo, N, 1);
    err = mean((rx >= a/2) ~= bits);
    pAna = 0.5 * erfc(a / (2*sqrt(2)));
    z = abs(err - pAna) / sqrt(pAna * (1 - pAna) / N);
    peor = max(peor, z);
    ok = ok && z < 4;
end
registrar('V-02', 'BER Monte Carlo frente a Q(a/2), OOK con umbral a/2', ...
    sprintf('%d puntos, 2e6 bits cada uno; peor desviacion=%.2f desv. estandar', ...
            numel(amplitudes), peor), ok);

% --- V-03 Bloqueo por obstaculos de Poisson frente a la ponderacion analitica ---------
% Se usa un enlace largo e inclinado y mayor intensidad de llegadas para que
% la probabilidad de bloqueo sea apreciable y la comparacion tenga poder.
flujo = RandStream('mt19937ar', 'Seed', 20261125);
cfgS = cfgM;
cfgS.sombra.epsilon_min = 20;
cfgS.sala = [12 5 4];
cfgS.sombra.ancho_m = [0 2];            % distribuciones U[0,2] de [PJ2020]
cfgS.sombra.alto_m = [0 2];
enlaceA = [1 0.5 4.2];
enlaceB = [10 4.5 1.8];
R = 4000;
fr = zeros(R, 1);
for r = 1:R
    obs = obstaculos_poisson(cfgS, cfgS.Tmotion, flujo);
    tt = cfgS.Tmotion * rand(flujo, 1, 4);
    fr(r) = mean(bloqueo_serie(obs, enlaceA, enlaceB, tt));
end
[Pana, ep] = peso_sombra(enlaceA, enlaceB, cfgS, 200000);
emp = mean(fr);
ana = 1 - Pana;
ee = std(fr) / sqrt(R);
registrar('V-03', 'Bloqueo de Poisson simulado frente a 1 - exp(-eps Td E[p])', ...
    sprintf('simulado=%.4f +/- %.4f, analitico=%.4f (E[p]=%.4f)', emp, ee, ana, ep), ...
    abs(emp - ana) < 4 * ee + 1e-3);

% --- Simulacion completa del perfil 'mina' (Fase 4) --------------------------------
outM = ejecutar_simulacion('Guardar', false);
cfgS4 = outM.cfg;

% --- P-05 Monotonia con la temperatura -----------------------------------------------
Tas = 20:10:60;
[fStd, ~] = modelo_termico(Tas, cfgS4.termico.Rth_std, cfgS4);
[fMej, ~] = modelo_termico(Tas, cfgS4.termico.Rth_mej, cfgS4);
f25 = modelo_termico(25, cfgS4.termico.Rth_std, cfgS4);
s0v = zeros(size(Tas));
for q = 1:numel(Tas)
    s0v(q) = ruido_receptor(0, cfgS4.ruido.Ibg, Tas(q), cfgS4);
end
ok5 = all(diff(fStd) < 0) && all(diff(fMej) < 0) && all(diff(s0v) > 0) && ...
      all(fMej > fStd) && abs(f25 - 1) < 1e-12;
registrar('P-05', 'Mayor temperatura: menos potencia optica y mas ruido', ...
    sprintf('factor 20-60 C: %.3f a %.3f; factor(25 C)=%.3f; ruido creciente=%d', ...
            fStd(1), fStd(end), f25, all(diff(s0v) > 0)), ok5);

% --- P-08 El Goodput no supera la tasa nominal en ningun escenario --------------------
tope = (cfgS4.Rb/1e6) * cfgS4.packetBits / (cfgS4.packetBits + cfgS4.basePilotBits);
gmax = max(outM.resultados.Goodput_Mbps);
registrar('P-08', 'Goodput no supera la tasa nominal util', ...
    sprintf('Goodput maximo=%.4f Mb/s; tope=%.4f Mb/s', gmax, tope), gmax <= tope + 1e-9);

% --- P-12 Ruido termico frente al calculo manual ---------------------------------------
cfgN = cfgS4; cfgN.ruido.Id0 = 0;
sig = ruido_receptor(0, 0, 25, cfgN);
kT = 1.38e-23 * 298.15;
CA = 112e-8 * 1e-4;
B = 10e6;
manual = sqrt(8*pi*kT/10 * CA * 0.562 * B^2 + ...
              16*pi^2 * kT * 1.5 / 0.03 * CA^2 * 0.0868 * B^3);
registrar('P-12', 'Ruido termico a 10 Mb/s y 25 C frente al calculo manual', ...
    sprintf('modelo=%.4g A, manual=%.4g A', sig, manual), ...
    abs(sig - manual) / manual < 1e-9);

% --- P-13 Convergencia de la discretizacion en la galeria ----------------------------------
pwG = paredes_caja(cfgS4.sala, cfgS4.nlos.rho);
gG1 = sum(canal_nlos(cfgS4.tx1, [0 0 -1], cfgS4.rx, [0 0 1], pwG, cfgS4, 0.5));
gG2 = sum(canal_nlos(cfgS4.tx1, [0 0 -1], cfgS4.rx, [0 0 1], pwG, cfgS4, 0.1));
convG = abs(gG1 - gG2) / gG2;
registrar('P-13', 'Convergencia NLOS en la galeria: elementos de 0.5 m frente a 0.1 m', ...
    sprintf('diferencia relativa=%.2g', convG), convG < 0.03);

% --- P-15 Retardo RMS compatible con la tasa de transmision ------------------------------------
drmsMax = max(outM.canal.drms);
registrar('P-15', 'Tasa nominal inferior a 1/(10 D_RMS)', ...
    sprintf('D_RMS=%.3g ns; 1/(10 D_RMS)=%.3g Mb/s; Rb=%.0f Mb/s', ...
            drmsMax*1e9, 1e-6/(10*drmsMax), cfgS4.Rb/1e6), cfgS4.Rb < 1/(10*drmsMax));

% --- V-04 BER simulada frente a la BER teorica del escenario ------------------------------------
res = outM.resultados;
ee = (res.BER_IC95_sup - res.BER_IC95_inf) / (2*1.96);
util = res.BER_Teorica > 1e-5 & ee > 0;
z = abs(res.BER(util) - res.BER_Teorica(util)) ./ ee(util);
registrar('V-04', 'BER simulada frente a la teorica condicionada al canal', ...
    sprintf('%d filas con BER teorica > 1e-5; peor desviacion=%.2f errores estandar', ...
            sum(util), max([z; 0])), all(z < 4));

% --- V-05 Bloqueo del enlace en la simulacion frente a la ponderacion analitica -------------------
cfgB = parametros('mina');
cfgB.nRuns = 2000;
rng(20261126, 'twister');
repB = generar_replicas_mina(cfgB);
epsB = 10;
fracB = zeros(cfgB.nRuns, 1);
for r = 1:cfgB.nRuns
    a = repB{r};
    m = a.marca <= epsB / cfgB.sombra.epsilon_max_min;
    fracB(r) = mean((a.presPkt(:, m) * double(a.bloquea(m, 1))) > 0);
end
cfgE = cfgB; cfgE.sombra.epsilon_min = epsB;
[PB, epB] = peso_sombra(cfgB.tx1, cfgB.rx, cfgE, 200000);
eeB = std(fracB) / sqrt(cfgB.nRuns);
registrar('V-05', 'Bloqueo simulado con adelgazamiento frente a 1 - exp(-eps Td E[p])', ...
    sprintf('simulado=%.4f +/- %.4f, analitico=%.4f (E[p]=%.4f)', mean(fracB), eeB, 1-PB, epB), ...
    abs(mean(fracB) - (1 - PB)) < 4 * eeB + 1e-3);

% --- W-01 Balance de potencia Wi-Fi frente al calculo manual ----------------------------------------
cfgW = parametros('mina');
dW = norm(cfgW.rx - cfgW.rf.ap);
PrManual = 20 - (20*log10(4*pi*2.4e9/299792458) + 22*log10(dW));
w0 = enlace_wifi(false, 0, 0, cfgW);
registrar('W-01', 'Balance de potencia Wi-Fi: Pr, MCS y tasa frente al calculo manual', ...
    sprintf('d=%.2f m; Pr modelo=%.2f dBm, manual=%.2f dBm; MCS=%d; tasa=%.2f Mb/s', ...
            dW, w0.Pr_dBm, PrManual, w0.mcs, w0.tasa), ...
    abs(w0.Pr_dBm - PrManual) < 1e-9 && w0.mcs == 8 && abs(w0.tasa - cfgW.Rb/1e6) < 1e-12);

% --- W-02 Monotonia del Wi-Fi con la interferencia y el bloqueo -----------------------------------
emiV = 0:5:70;
mcsLibre = zeros(size(emiV)); mcsBloq = mcsLibre;
for i = 1:numel(emiV)
    mcsLibre(i) = enlace_wifi(false, 0, emiV(i), cfgW).mcs;
    mcsBloq(i) = enlace_wifi(true, 0, emiV(i), cfgW).mcs;
end
registrar('W-02', 'MCS no crece con la interferencia y es menor con bloqueo', ...
    sprintf('MCS libre %d a %d; bloqueado %d a %d', mcsLibre(1), mcsLibre(end), mcsBloq(1), mcsBloq(end)), ...
    all(diff(mcsLibre) <= 0) && all(diff(mcsBloq) <= 0) && all(mcsBloq <= mcsLibre) && mcsLibre(end) == 0);

% --- W-03 Esquema hibrido: casos limite -------------------------------------------------------------
gp = @(esc, sis) res.Goodput_Mbps(strcmp(res.Escenario, esc) & strcmp(res.Sistema, sis));
bp = @(esc, sis) res.BER(strcmp(res.Escenario, esc) & strcmp(res.Sistema, sis));
dif0 = abs(gp('E0_referencia', 'Hibrido VLC/Wi-Fi') - gp('E0_referencia', '2 LEDs fijo')) + ...
       abs(bp('E0_referencia', 'Hibrido VLC/Wi-Fi') - bp('E0_referencia', '2 LEDs fijo'));
dif1 = abs(gp('E1_polvo_2000', 'Hibrido VLC/Wi-Fi') - gp('E1_polvo_2000', 'Wi-Fi 2.4 GHz')) + ...
       abs(bp('E1_polvo_2000', 'Hibrido VLC/Wi-Fi') - bp('E1_polvo_2000', 'Wi-Fi 2.4 GHz'));
registrar('W-03', 'Hibrido: con VLC sano equivale a 2 LEDs fijos; con VLC caido, al Wi-Fi', ...
    sprintf('dif. en referencia=%.2g; dif. con polvo 2000=%.2g', dif0, dif1), ...
    dif0 < 1e-9 && dif1 < 1e-9);

% --- D-01 La traza de la demostracion reproduce los resultados de la simulacion --------------------
pD = struct('conc', 1000, 'lente', 0.6, 'Ta', 50, 'disip', 'estandar', 'eps', 20, ...
            'interf', true, 'emi', 40);
canD = canal_galeria(cfgW);
[trD, outD] = simular_ciclo(cfgW, canD, pD, 777);
dD = metricas_traza(trD, cfgW);
difBER = max(abs(outD.resultados.BER - dD.ber(:, end)));
difGP = max(abs(outD.resultados.Goodput_Mbps - dD.gpAcum(:, end)));
registrar('D-01', 'Traza de la demostracion frente a la tabla de resultados (6 arquitecturas)', ...
    sprintf('diferencia maxima BER=%.2g; Goodput=%.2g Mb/s', difBER, difGP), ...
    difBER < 1e-12 && difGP < 1e-12);

% --- D-02 La ventana de la demostracion se construye y avanza sin errores ---------------------------
okD = true; msgD = 'ventana creada, 30 pasos y cuatro pestanas';
try
    appD = demo_vlc('Visible', false, 'Automatico', false);
    for kk = 1:30, appD.paso(); end
    okD = appD.estado().k == 31;
    tgD = findall(appD.fig, 'Type', 'uitabgroup');
    for tt = 2:4        % recorre las pestanas 3D, cobertura y densidad
        tgD.SelectedTab = tgD.Children(tt); tgD.SelectionChangedFcn(tgD, []);
        appD.paso();
    end
    appD.cerrar();
catch ME
    okD = false; msgD = ME.message;
end
registrar('D-02', 'Demostracion interactiva: construccion de la ventana, avance de 30 paquetes y las cuatro pestanas', ...
    msgD, okD);

% --- D-03 El mapa de cobertura de la demostracion coincide con la simulacion en el punto de operacion -----
rowE0 = strcmp(outM.escenarios.Escenario, 'E0_referencia');
mDemo = margen_enlace(canD, struct('conc', 0, 'lente', 1, 'eps', 0, 'Ta', 25), cfgW);
mSim = 20 * log10(outM.escenarios.Margen_SNR_1LED(rowE0));
registrar('D-03', 'Margen de la demostracion (2 LEDs fijos) frente al margen de la simulacion en la referencia', ...
    sprintf('demostracion=%.4f dB; simulacion=%.4f dB', mDemo, mSim), abs(mDemo - mSim) < 1e-6);

tabla = table(ids, objetivo, valor, aprobada, ...
    'VariableNames', {'ID','Objetivo','Resultado','Aprobada'});
writetable(tabla, fullfile(proyecto, 'docs', 'registro_pruebas.csv'));
assert(all(aprobada), 'Alguna prueba fallo. Revisar la salida.');
fprintf('Todas las pruebas ejecutadas fueron aprobadas (%d).\n', numel(aprobada));
end

function s = ternario(cond, a, b)
if cond, s = a; else, s = b; end
end
