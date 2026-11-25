function cfg = parametros(perfil)
%PARAMETROS  Parametros del sistema, con unidad y origen de cada valor.
%
%   cfg = PARAMETROS() devuelve una estructura con todos los parametros del
%   simulador. Es la unica fuente de valores numericos: ningun otro archivo
%   debe contener constantes del modelo.
%
%   cfg = PARAMETROS(perfil) selecciona el conjunto de valores:
%     'v3'   (por defecto en la Fase 3) valores identicos a la version v3
%            (legacy/v3_companero), necesarios para la prueba P-01.
%     'mina' parametros del sistema optico de [PJ2020] (Tabla 3), con
%            reflexiones en paredes y sombra por obstaculos de Poisson.
%
%   Los parametros marcados como HIPOTESIS se reemplazan por valores
%   referenciados en la Fase 4 (ver plan.md).
%
%   Origen:  [PJ2020] Palacios Jativa et al., IEEE Access 8, 2020.
%            [Li2024] Li et al., Applied Optics 63(14), 2024.
%            HIPOTESIS = valor supuesto, sin respaldo de medicion.
if nargin < 1, perfil = 'v3'; end
assert(any(strcmp(perfil, {'v3', 'mina'})), 'Perfil desconocido: %s', perfil);

% --- Reproducibilidad ---------------------------------------------------
cfg.semilla = 20261109;

% --- Geometria de la galeria [m] (HIPOTESIS) ------------------------------
cfg.sala = [12 5 4];            % largo X, ancho Y, alto Z
cfg.tx1  = [5.0 1.55 3.8];      % luminaria 1
cfg.tx2  = [5.0 3.45 3.8];      % luminaria 2
cfg.rx   = [6.5 2.5 1.0];       % fotodetector

% --- Transmisor y receptor optico ----------------------------------------
cfg.Ptotal = 1.0;               % W, potencia optica total (HIPOTESIS)
cfg.Apd    = 1.0e-4;            % m^2, area del fotodiodo [PJ2020: 1 cm^2]
cfg.R      = 0.53;              % A/W, responsividad [PJ2020]
cfg.phiHalf = 60;               % grados, semiangulo a media potencia [PJ2020]
cfg.FOV    = 80;                % grados, campo de vision [Li2024]
cfg.filterGain       = 1;       % [PJ2020]
cfg.concentratorGain = 1;       % sin concentrador (HIPOTESIS)

% --- Ruido y enlace (v3) -------------------------------------------------
cfg.sigmaN = 0.17e-6;           % A RMS, ruido fijo (HIPOTESIS; Fase 4 lo reemplaza)
cfg.Rb     = 1e6;               % bit/s, tasa nominal (HIPOTESIS)
cfg.packetBits = 128;           % bits por paquete
cfg.basePilotBits = 8;          % sobrecarga de cabecera en todas las arquitecturas
cfg.adaptExtraPilotBits = 16;   % sobrecarga adicional del selector practico

% --- Simulacion Monte Carlo ----------------------------------------------
cfg.Tmotion = 24;               % s, ciclo de operacion simulado
cfg.nRuns = 40;                 % replicas independientes
cfg.nSnapshots = 480;           % paquetes (instantes) por replica

% --- Polvo ----------------------------------------------------------------
cfg.polvo.Qext = 2.2;           % eficiencia de extincion [Li2024]
cfg.polvo.radio_m = 2e-6;       % radio de particula [Li2024]
cfg.polvo.densidad_kgm3 = 1500; % HIPOTESIS
cfg.polvo.concentraciones_mgm3 = [0 25 100 300];  % escenarios, no mediciones
cfg.obstaculos = 0:3;           % maquinas activas por escenario

% --- Selector practico (HIPOTESIS de ingenieria) ----------------------------
cfg.csiUpdate_s = 0.12;         % s, periodo de refresco de la informacion de canal
cfg.feedbackDelay_s = 0.06;     % s, retardo de la informacion de canal
cfg.csiRelativeNoise = 0.08;    % error relativo de estimacion
cfg.hysteresis = 0.05;          % umbral relativo de conmutacion
cfg.switchOutage_s = 0.025;     % s sin datos al conmutar de luminaria
cfg.umbralPiloto = false;       % true: umbral con la amplitud real (pilotos del paquete)

% --- Interferencia luminica (HIPOTESIS) -----------------------------------
cfg.ambient.enabled = true;
cfg.ambient.period_s = 4.0;
cfg.ambient.duty = 0.08;
cfg.ambient.noiseMultiplier = 2.0;

% --- Enlace RF heredado de v3 (se reemplaza en la Fase 5) ------------------
cfg.rf.enabled = true;
cfg.rf.freq_Hz = 2.4e9;
cfg.rf.tx_dBm = 0;
cfg.rf.d0_m = 1.0;
cfg.rf.PL0_dB = 20*log10(4*pi*cfg.rf.freq_Hz*cfg.rf.d0_m/299792458);
cfg.rf.interference_dBm = -Inf;
cfg.rf.pathExponent = 2.0;
cfg.rf.shadowSigma_dB = 4;
cfg.rf.obstacleLoss_dB = 12;
cfg.rf.noiseFigure_dB = 8;
cfg.rf.bandwidth_Hz = 1e6;
cfg.rf.shadowCorr = 0.85;       % coeficiente de correlacion del sombreado

% --- Maquinaria movil (HIPOTESIS) -------------------------------------------
% Cada fila: centro X [m], largo X [m], ancho Y [m], altura [m],
%            amplitud de oscilacion en Y [m], periodo [s]. Centro Y = 2.5 m.
cfg.maquinas.yc = 2.5;
cfg.maquinas.tabla = [ ...
    5.40 0.40 0.70 3.20 1.10 4; ...
    5.91 0.32 0.75 2.45 1.05 6; ...
    6.34 0.24 0.65 1.55 0.95 8];

% --- Etiquetas de arquitecturas ---------------------------------------------
cfg.etiquetas = {'1 LED','2 LEDs fijo','2 LEDs ideal','2 LEDs practico', ...
                 'RF BPSK ilustrativo'};

% --- Reflexiones en paredes (Fase 3) ------------------------------------------
cfg.nlos.rho = 0.6;             % reflectividad de pared [PJ2020, Tabla 2]
cfg.nlos.resolucion_m = 0.10;   % lado maximo del elemento reflectante
                                % (convergencia verificada en la prueba P-10)

% --- Sombra por obstaculos de Poisson (Fase 3) ---------------------------------
% Llegadas de Poisson con intensidad epsilon [PJ2020]; ancho y alto uniformes
% [PJ2020: U[0,2]]; posicion uniforme en el piso de la galeria.
cfg.sombra.epsilon_min = 5;     % llegadas por minuto [PJ2020]
cfg.sombra.permanencia_s = 30;  % s, permanencia media (HIPOTESIS)
cfg.sombra.ancho_m = [0 2];     % [PJ2020]
cfg.sombra.alto_m = [0 2];      % [PJ2020]

if strcmp(perfil, 'mina')
    % Sistema optico de [PJ2020], Tabla 3.
    cfg.Ptotal = 10;                                  % W
    cfg.Apd = 1.0e-4;                                 % m^2 (1 cm^2)
    cfg.R = 0.53;                                     % A/W
    cfg.phiHalf = 60;                                 % grados
    cfg.FOV = 70;                                     % grados
    cfg.eta = 1.5;                                    % indice de refraccion
    cfg.filterGain = 1;
    cfg.concentratorGain = cfg.eta^2 / sind(cfg.FOV)^2;   % ec. (4) de [PJ2020]
    cfg.rx = [13 2.5 1.8];                            % casco del minero, 1.8 m

    % Geometria de la galeria en el borde entre dos luminarias (HIPOTESIS de
    % diseno): luminarias separadas 10 m sobre el eje de la galeria y receptor
    % a medio camino, a 5 m de horizontal de cada una. Con el campo de vision de
    % 70 y las luminarias 2 m sobre el casco, el enlace directo existe hasta
    % 5.5 m de horizontal; este es el punto de menor margen con cobertura LOS.
    cfg.sala = [26 5 4];
    cfg.tx1 = [8 2.5 3.8];
    cfg.tx2 = [18 2.5 3.8];
    cfg.nlos.resolucion_m = 0.5;      % convergencia verificada en la prueba P-13

    % Enlace
    cfg.Rb = 10e6;                    % bit/s; D_RMS permite hasta ~1/(10 D_RMS) (P-15)

    % Receptor y ruido [PJ2020, Tabla 3; Komine y Nakagawa 2004]
    cfg.ruido.q = 1.6e-19;            % C
    cfg.ruido.kB = 1.38e-23;          % J/K
    cfg.ruido.G = 10;                 % ganancia en lazo abierto
    cfg.ruido.Gamma = 1.5;            % factor de ruido del canal del FET
    cfg.ruido.gm = 0.03;              % S, transconductancia del FET
    cfg.ruido.Cpd = 112e-8;           % F/m^2 (112 pF/cm^2), capacitancia por area
    cfg.ruido.I2 = 0.562;             % factor de ancho de banda de ruido
    cfg.ruido.I3 = 0.0868;
    cfg.ruido.Ibg = 10e-9;            % A, corriente de fondo [PJ2020]
    cfg.ruido.Id0 = 1e-9;             % A a 25 C, corriente oscura (HIPOTESIS)

    % Modelo termico del LED (HIPOTESIS de hoja de datos de LED de potencia)
    cfg.termico.Tref_C = 25;          % temperatura de referencia del flujo
    cfg.termico.etaOpt0 = 0.30;       % eficiencia optica a 25 C
    cfg.termico.kT = 0.004;           % 1/K, caida relativa del flujo por grado
    cfg.termico.Rth_std = 1.5;        % K/W, disipador estandar
    cfg.termico.Rth_mej = 0.8;        % K/W, disipador mejorado
    cfg.termico.Tj_max_C = 125;       % limite de juntura

    % Interferencia luminica: corriente de fondo durante los pulsos de focos
    cfg.ambient.Ibg_pulso_A = 50e-6;  % A (HIPOTESIS)

    % Sombra: intensidad maxima simulada; los escenarios la reducen por adelgazamiento.
    % Dimensiones de vehiculos y maquinaria de mina (HIPOTESIS): los U[0,2] m de
    % [PJ2020] son ilustrativos y dejarian pasar casi todos los enlaces que
    % llegan desde el techo a un casco a 1.8 m.
    cfg.sombra.epsilon_max_min = 40;
    cfg.sombra.ancho_m = [0.5 2.5];
    cfg.sombra.alto_m = [0.5 3.5];

    % --- Enlace Wi-Fi 2.4 GHz, IEEE 802.11n (Fase 5) ------------------------------
    % Reemplaza al RF ilustrativo de v3. Punto de acceso en la luminaria 1 (mismo
    % lugar y mismas obstrucciones que el enlace optico de la luminaria 1).
    % Valores de la norma: tabla MCS de 20 MHz, un flujo, GI de 800 ns, y
    % sensibilidades minimas del receptor [IEEE 802.11n]. Parametros del canal:
    % HIPOTESIS dentro del rango publicado para canales industriales a 868 MHz y
    % 2.4 GHz [Tanghe2008]: n de 2.0 a 2.3, sombreado de 5.0 a 5.7 dB (no se
    % pudo verificar el 2.4 GHz en el articulo original).
    cfg.rf = struct();
    cfg.rf.freq_Hz = 2.4e9;
    cfg.rf.tx_dBm = 20;                   % dBm, potencia de transmision tipica
    cfg.rf.bandwidth_Hz = 20e6;           % canal de 20 MHz
    cfg.rf.noiseFigure_dB = 7;            % HIPOTESIS
    cfg.rf.d0_m = 1;
    cfg.rf.PL0_dB = 20*log10(4*pi*cfg.rf.freq_Hz*cfg.rf.d0_m/299792458);  % espacio libre a 1 m
    cfg.rf.pathExponent = 2.2;            % HIPOTESIS [Tanghe2008]
    cfg.rf.shadowSigma_dB = 5;            % HIPOTESIS [Tanghe2008]
    cfg.rf.obstacleLoss_dB = 15;          % dB, maquina metalica en el enlace (HIPOTESIS, 10 a 20)
    cfg.rf.macEfficiency = 0.65;          % HIPOTESIS: cabeceras, ACK y contencion
    cfg.rf.ap = cfg.tx1;                  % punto de acceso junto a la luminaria 1
    cfg.rf.mcsRate_Mbps = [6.5 13 19.5 26 39 52 58.5 65];       % [IEEE 802.11n]
    cfg.rf.mcsSens_dBm  = [-82 -79 -77 -74 -70 -66 -65 -64];    % [IEEE 802.11n]
    cfg.rf.mcsBitsSym   = [1 2 2 4 4 6 6 6];     % bits por simbolo (BPSK, QPSK, 16-QAM, 64-QAM)

    % --- Esquema hibrido VLC / Wi-Fi ------------------------------------------------
    % Usa Wi-Fi cuando la corriente de senal estimada del enlace optico queda por
    % debajo de umbralQ veces el ruido (Q = 12 equivale a BER ~ 1e-33 gaussiana;
    % margen deliberado frente al error de estimacion). HIPOTESIS.
    cfg.hibrido.umbralQ = 12;

    cfg.etiquetas = {'1 LED','2 LEDs fijo','2 LEDs ideal','2 LEDs practico', ...
                     'Wi-Fi 2.4 GHz','Hibrido VLC/Wi-Fi'};
end
end
