function app = demo_vlc(varargin)
%DEMO_VLC  Demostracion interactiva del enlace VLC en la galeria minera.
%
%   DEMO_VLC() abre la ventana de demostracion. Cada ciclo de 24 s es una
%   replica de la simulacion del paper (mismas funciones: ejecutar_escenarios_mina,
%   canal_galeria, enlace_wifi), reproducida en tiempo real. Al mover un control
%   se simula de nuevo un ciclo con las condiciones elegidas.
%
%   Pestanas: Simulacion (vista superior, BER y Goodput), Vista 3D, Cobertura
%   (mapa que reacciona a los controles) y Densidad de luminarias. El boton
%   Ayuda explica como leer la pantalla.
%
%   Opciones: 'Visible' (true), 'Automatico' (true: inicia la reproduccion).
%   Devuelve app con las funciones paso(), estado() y cerrar() para pruebas.
p = inputParser;
addParameter(p, 'Visible', true, @islogical);
addParameter(p, 'Automatico', true, @islogical);
parse(p, varargin{:});
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));

cfg = parametros('mina');
can = canal_galeria(cfg);
txt = textos_demo();
est = estilo_figura();
K = cfg.nSnapshots;
azul = est.col.azul;
FN = 'Arial';
a_ = char(225); e_ = char(233); i_ = char(237); o_ = char(243); u_ = char(250); n_ = char(241);
E_ = char(201); C_ = char(67);

cond = struct('conc', 0, 'lente', 1, 'Ta', 25, 'disip', 'estandar', 'eps', 0, ...
              'interf', false, 'emi', 0);
presets = [ ...
    struct('conc', 0,    'lente', 1,   'Ta', 25, 'eps', 0,  'interf', false, 'emi', 0), ...
    struct('conc', 0,    'lente', 1,   'Ta', 25, 'eps', 40, 'interf', false, 'emi', 0), ...
    struct('conc', 1200, 'lente', 1,   'Ta', 25, 'eps', 0,  'interf', false, 'emi', 0), ...
    struct('conc', 1000, 'lente', 0.6, 'Ta', 50, 'eps', 10, 'interf', true,  'emi', 0), ...
    struct('conc', 1500, 'lente', 1,   'Ta', 25, 'eps', 10, 'interf', false, 'emi', 40)];
arq = 4; vel = 1; semilla = 20261124; k = 1; corriendo = false;
tr = []; d = [];

% --- ventana ------------------------------------------------------------------------
fig = uifigure('Name', txt.titulo, 'Position', [30 30 1340 780], 'Color', 'w', ...
    'Visible', matlab.lang.OnOffSwitchState(p.Results.Visible));
fig.Theme = 'light';
raizGl = uigridlayout(fig, [2 2]);
raizGl.RowHeight = {62, '1x'}; raizGl.ColumnWidth = {310, '1x'};
raizGl.BackgroundColor = 'w'; raizGl.Padding = [10 8 10 8]; raizGl.RowSpacing = 6;

% encabezado
enc = uigridlayout(raizGl, [2 1]); enc.Layout.Row = 1; enc.Layout.Column = [1 2];
enc.RowHeight = {30, 24}; enc.Padding = [0 0 0 0]; enc.RowSpacing = 0; enc.BackgroundColor = 'w';
uilabel(enc, 'Text', ['Enlace de luz visible (VLC) en una galer' i_ 'a minera: demostraci' o_ 'n de la simulaci' o_ 'n'], ...
    'FontName', FN, 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', azul);
uilabel(enc, 'Text', ['Las luminarias LED transmiten datos con luz; las m' a_ 'quinas la bloquean, el polvo la absorbe y el calor la debilita. ' ...
    'Cada ciclo de 24 s es una r' e_ 'plica real de la simulaci' o_ 'n del paper.'], ...
    'FontName', FN, 'FontSize', 12, 'FontColor', [0.35 0.35 0.35]);

% columna izquierda: estado en vivo (siempre visible) y, debajo, los controles
izq = uigridlayout(raizGl, [2 1]);
izq.Layout.Row = 2; izq.Layout.Column = 1;
izq.RowHeight = {200, '1x'}; izq.RowSpacing = 6; izq.Padding = [0 0 0 0]; izq.BackgroundColor = 'w';
card = uipanel(izq, 'BackgroundColor', [0.95 0.95 0.95], 'BorderType', 'none');
card.Layout.Row = 1;
cg = uigridlayout(card, [5 1]); cg.RowHeight = {24, '1x', 32, 32, 20}; cg.Padding = [10 6 10 6];
cg.RowSpacing = 2; cg.BackgroundColor = [0.95 0.95 0.95];
lbSis = uilabel(cg, 'Text', '', 'FontName', FN, 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', azul);
lbEnl = uilabel(cg, 'Text', '', 'FontName', FN, 'FontSize', 12, 'WordWrap', 'on', 'VerticalAlignment', 'top');
lbBER = uilabel(cg, 'Text', '', 'FontName', FN, 'FontSize', 20, 'FontWeight', 'bold');
lbGP = uilabel(cg, 'Text', '', 'FontName', FN, 'FontSize', 20, 'FontWeight', 'bold');
lbMar = uilabel(cg, 'Text', '', 'FontName', FN, 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);

ctrl = uigridlayout(izq, [22 1]);
ctrl.Layout.Row = 2; ctrl.Scrollable = 'on';
ctrl.RowHeight = repmat({22}, 1, 22); ctrl.RowSpacing = 3;
ctrl.Padding = [0 0 6 0]; ctrl.BackgroundColor = 'w';
fila = 0;
    function r = sig(), fila = fila + 1; r = fila; end

seccion('1. Elige un escenario');
ddPre = uidropdown(ctrl, 'Items', txt.preset, 'ItemsData', 1:5, 'Value', 1, 'FontName', FN, ...
    'Tooltip', 'Escenarios listos: ajustan todos los controles de abajo', ...
    'ValueChangedFcn', @(~, ~) aplicarPreset()); ddPre.Layout.Row = sig();
seccion('2. O ajusta el entorno');
[slPolvo, ~] = deslizador(txt.polvo, [0 2000], 0, '%.0f', ['Polvo en suspensi' o_ 'n: absorbe la luz. Sobre 1200 mg/m^3 el enlace colapsa.']);
[slTemp, ~] = deslizador(txt.temp, [20 60], 25, '%.0f', 'El calor reduce la potencia del LED y aumenta el ruido.');
[slLente, ~] = deslizador(txt.lente, [0.4 1], 1, '%.2f', 'Suciedad en los lentes: 1 = limpios, 0.4 = muy sucios.');
[slObs, ~] = deslizador(txt.obstr, [0 40], 0, '%.0f', ['M' a_ 'quinas que cruzan y bloquean la luz (c' i_ 'rculos grises).']);
[slEmi, ~] = deslizador(txt.emi, [0 50], 0, '%.0f', ['Ruido electromagn' e_ 'tico: solo afecta al Wi-Fi, no a la luz.']);
cbInt = uicheckbox(ctrl, 'Text', txt.interf, 'Value', false, 'FontName', FN, ...
    'Tooltip', ['Focos de veh' i_ 'culos: ruido de luz sobre el receptor'], ...
    'ValueChangedFcn', @(~, ~) cambioCond()); cbInt.Layout.Row = sig();
dis = uigridlayout(ctrl, [1 2]); dis.Layout.Row = sig(); dis.Padding = [0 0 0 0]; dis.ColumnWidth = {80, '1x'};
dis.BackgroundColor = 'w';
uilabel(dis, 'Text', txt.disip, 'FontName', FN);
ddDis = uidropdown(dis, 'Items', txt.disipOpc, 'ItemsData', {'estandar', 'mejorado'}, 'Value', 'estandar', ...
    'FontName', FN, 'Tooltip', ['El disipador mejorado enfr' i_ 'a mejor el LED.'], ...
    'ValueChangedFcn', @(~, ~) cambioCond());
seccion(['3. Qu' e_ ' sistema mirar']);
ddArq = uidropdown(ctrl, 'Items', txt.sis, 'ItemsData', 1:6, 'Value', 4, 'FontName', FN, ...
    'Tooltip', ['Sistema de comunicaci' o_ 'n cuyo enlace y m' e_ 'tricas se muestran'], ...
    'ValueChangedFcn', @(~, ~) cambioArq()); ddArq.Layout.Row = sig();
vg = uigridlayout(ctrl, [1 2]); vg.Layout.Row = sig(); vg.Padding = [0 0 0 0]; vg.ColumnWidth = {80, '1x'};
vg.BackgroundColor = 'w';
uilabel(vg, 'Text', txt.vel, 'FontName', FN);
ddVel = uidropdown(vg, 'Items', {'1x', '2x', '4x'}, 'ItemsData', [1 2 4], 'Value', 1, 'FontName', FN, ...
    'ValueChangedFcn', @(~, ~) setVel());
bGl = uigridlayout(ctrl, [1 3]); bGl.Layout.Row = sig(); bGl.Padding = [0 0 0 0]; bGl.BackgroundColor = 'w';
btnIni = uibutton(bGl, 'Text', txt.pausar, 'FontName', FN, 'ButtonPushedFcn', @(~, ~) alternar());
btnNue = uibutton(bGl, 'Text', txt.reiniciar, 'FontName', FN, 'ButtonPushedFcn', @(~, ~) nuevoCiclo());
btnAyu = uibutton(bGl, 'Text', 'Ayuda', 'FontName', FN, 'FontWeight', 'bold', 'FontColor', azul, ...
    'ButtonPushedFcn', @(~, ~) ayuda()); %#ok<NASGU>

% pestanas (derecha)
tg = uitabgroup(raizGl); tg.Layout.Row = 2; tg.Layout.Column = 2;
tab1 = uitab(tg, 'Title', [char(83) 'imulaci' o_ 'n']);
tab2 = uitab(tg, 'Title', 'Vista 3D');
tab3 = uitab(tg, 'Title', 'Cobertura');
tab4 = uitab(tg, 'Title', 'Densidad de luminarias');
tg.SelectionChangedFcn = @(~, ~) dibujar();

der = uigridlayout(tab1, [4 2]);
der.RowHeight = {44, '1.35x', '1x', '1x'}; der.ColumnWidth = {'1.7x', '1x'};
der.BackgroundColor = 'w'; der.Padding = [4 4 4 4];
leyendaTab(der, ['Vista superior de la galer' i_ 'a (26 m x 5 m). El enlace en uso se dibuja sobre el casco del minero: ' ...
    'continuo = la luz llega; discontinuo = una m' a_ 'quina lo bloquea. Abajo: errores y velocidad de datos de este sistema, y comparaci' o_ 'n con los dem' a_ 's.']);
axG = uiaxes(der); axG.Layout.Row = 2; axG.Layout.Column = [1 2];
axB = uiaxes(der); axB.Layout.Row = 3; axB.Layout.Column = 1;
axP = uiaxes(der); axP.Layout.Row = 4; axP.Layout.Column = 1;
axC = uiaxes(der); axC.Layout.Row = [3 4]; axC.Layout.Column = 2;
vista = vista_demo('crear', axG, axB, axP, axC, cfg, true);

g3 = uigridlayout(tab2, [2 1]); g3.RowHeight = {44, '1x'}; g3.Padding = [4 4 4 4]; g3.BackgroundColor = 'w';
leyendaTab(g3, ['Misma escena en 3D: los conos azules son la luz de cada luminaria y los cilindros grises, las m' a_ 'quinas con su altura real. ' ...
    'Arrastra con el mouse para girar la vista.']);
ax3 = uiaxes(g3); ax3.Layout.Row = 2;
vista3 = vista3d_demo('crear', ax3, cfg);

gc = uigridlayout(tab3, [3 1]); gc.RowHeight = {44, '1.3x', '1x'}; gc.Padding = [4 4 4 4]; gc.BackgroundColor = 'w';
leyendaTab(gc, ['Margen de enlace: qu' e_ ' tan por encima del ruido llega la se' n_ 'al (m' a_ 's oscuro = mejor). ' ...
    'La l' i_ 'nea naranja marca el m' i_ 'nimo para tener casi cero errores (21.6 dB). Mueve polvo, temperatura o lentes y el mapa cambia.']);
axMap = uiaxes(gc); axMap.Layout.Row = 2; axPer = uiaxes(gc); axPer.Layout.Row = 3;
cob = mapa_cobertura_demo('crear', axMap, axPer, cfg);
malla = canal_malla(cfg);
cob = mapa_cobertura_demo('actualizar', cob, malla, cond, cfg);

gd = uigridlayout(tab4, [3 1]); gd.RowHeight = {44, '1x', '1x'}; gd.Padding = [4 4 4 4]; gd.BackgroundColor = 'w';
leyendaTab(gd, ['Cu' a_ 'ntas luminarias conviene instalar con la misma potencia total: de 2 a 3 la cobertura sube mucho; ' ...
    'de 3 en adelante la mejora es peque' n_ 'a. An' a_ 'lisis est' a_ 'tico (ver paper, secci' o_ 'n IV-F).']);
axD1 = uiaxes(gd); axD1.Layout.Row = 2; axD2 = uiaxes(gd); axD2.Layout.Row = 3;
rutaDens = fullfile(raiz, '..', 'resultados', 'datos', 'densidad.csv');
if exist(rutaDens, 'file')
    dibujar_densidad(axD1, axD2, readtable(rutaDens));
else
    text(axD1, 0.1, 0.5, 'Ejecute densidad_luminarias() para generar resultados/datos/densidad.csv');
end

resimular();
tmr = [];
if p.Results.Automatico
    tmr = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.05, 'BusyMode', 'drop', ...
        'TimerFcn', @(~, ~) paso());
    corriendo = true; start(tmr);
end
fig.CloseRequestFcn = @(~, ~) cerrar();
app.paso = @paso; app.cerrar = @cerrar; app.fig = fig;
app.estado = @estado;

% --- funciones auxiliares ---------------------------------------------------------------
    function seccion(texto)
        l = uilabel(ctrl, 'Text', texto, 'FontName', FN, 'FontWeight', 'bold', 'FontSize', 13, 'FontColor', azul);
        l.Layout.Row = sig();
    end

    function leyendaTab(padre, texto)
        l = uilabel(padre, 'Text', texto, 'FontName', FN, 'FontSize', 12, 'WordWrap', 'on', ...
            'FontColor', [0.25 0.25 0.25], 'VerticalAlignment', 'center');
        l.Layout.Row = 1;
        if numel(padre.ColumnWidth) > 1, l.Layout.Column = [1 2]; end
    end

    function [sl, lb] = deslizador(texto, lim, val, fmt, ayudaTxt)
        lb = uilabel(ctrl, 'Text', sprintf(['%s: ' fmt], texto, val), 'FontName', FN, 'FontWeight', 'bold');
        lb.Layout.Row = sig();
        sl = uislider(ctrl, 'Limits', lim, 'Value', val, 'MajorTicks', [], 'MinorTicks', [], 'Tooltip', ayudaTxt);
        sl.Layout.Row = sig();
        sl.ValueChangingFcn = @(~, ev) set(lb, 'Text', sprintf(['%s: ' fmt], texto, ev.Value));
        sl.ValueChangedFcn = @(~, ~) cambioCond();
        sl.UserData = struct('texto', texto, 'fmt', fmt, 'lb', lb);
        lb.Tooltip = ayudaTxt;
    end

    function cambioCond()
        cond.conc = slPolvo.Value; cond.Ta = slTemp.Value; cond.lente = slLente.Value;
        cond.eps = slObs.Value; cond.emi = slEmi.Value; cond.interf = cbInt.Value;
        cond.disip = ddDis.Value;
        refrescarEtiquetas();
        cob = mapa_cobertura_demo('actualizar', cob, malla, cond, cfg);
        nuevoCiclo();
    end

    function refrescarEtiquetas()
        hs = [slPolvo slTemp slLente slObs slEmi];
        for ii = 1:numel(hs)
            u = hs(ii).UserData;
            u.lb.Text = sprintf(['%s: ' u.fmt], u.texto, hs(ii).Value);
        end
    end

    function aplicarPreset()
        s = presets(ddPre.Value);
        slPolvo.Value = s.conc; slTemp.Value = s.Ta; slLente.Value = s.lente;
        slObs.Value = s.eps; slEmi.Value = s.emi; cbInt.Value = s.interf;
        ddDis.Value = 'estandar';
        cambioCond();
    end

    function cambioArq()
        arq = ddArq.Value; dibujar();
    end

    function setVel()
        vel = ddVel.Value;
    end

    function alternar()
        if isempty(tmr), return; end
        if corriendo
            stop(tmr); corriendo = false; btnIni.Text = txt.iniciar;
        else
            start(tmr); corriendo = true; btnIni.Text = txt.pausar;
        end
    end

    function nuevoCiclo()
        semilla = semilla + 1; resimular();
    end

    function ayuda()
        L = {['QU' E_ ' SE VE?'], ...
             '', ...
             ['Tri' a_ 'ngulos: luminarias LED que transmiten datos con luz. Cuadrado negro: casco del minero, que recibe.'], ...
             '', ...
             ['L' i_ 'nea azul continua: enlace de luz libre y en uso. L' i_ 'nea gris discontinua: enlace en uso pero bloqueado por una m' a_ 'quina (solo llegan reflejos de las paredes). L' i_ 'nea gris clara: enlace que ese sistema no usa. L' i_ 'nea verde: Wi-Fi.'], ...
             '', ...
             ['C' i_ 'rculos grises: m' a_ 'quinas que cruzan la galer' i_ 'a y bloquean la luz.'], ...
             '', ...
             sprintf(['BER: fracci' o_ 'n de bits recibidos con error (0 = perfecto). Goodput: velocidad de datos ' u_ 'tiles; el m' a_ 'ximo posible es %.2f Mb/s.'], vista.gmax), ...
             '', ...
             ['Barras: Goodput promedio de cada sistema en este ciclo, para compararlos.'], ...
             '', ...
             ['Prueba: elige "Obstrucciones intensas" y mira c' o_ 'mo el selector cambia de luminaria; luego "Polvo denso" y mira c' o_ 'mo la luz colapsa.']};
        uialert(fig, strjoin(L, newline), [C_ o_ 'mo leer esta pantalla'], 'Icon', 'info');
    end

    function resimular()
        tr = simular_ciclo(cfg, can, cond, semilla);
        d = metricas_traza(tr, cfg);
        k = 1; dibujar();
    end

    function paso()
        if ~isvalid(fig), return; end
        if k >= K
            semilla = semilla + 1; resimular(); return;
        end
        k = min(K, k + vel); dibujar();
    end

    function dibujar()
        vista_demo('actualizar', vista, tr, d, k, arq, cfg);
        if tg.SelectedTab == tab2, vista3d_demo('actualizar', vista3, tr, k, arq); end
        [titulo, detalle] = descripcion_demo(tr, k, arq);
        lbSis.Text = txt.sis{arq};
        lbEnl.Text = [{titulo}, strsplit(detalle, newline)];
        if d.ber(arq, k) <= 0
            lbBER.Text = 'BER: 0 (sin errores)';
        else
            lbBER.Text = sprintf('BER: %.1e', d.ber(arq, k));
        end
        lbGP.Text = sprintf('Goodput: %.2f Mb/s', d.gpMov(arq, k));
        lbMar.Text = sprintf(['Margen del enlace de luz (sin m' a_ 'quinas): %.1f dB'], tr.margen_dB);
        drawnow limitrate;
    end

    function s = estado()
        s = struct('k', k, 'arq', arq, 'cond', cond, 'semilla', semilla);
    end

    function cerrar()
        if ~isempty(tmr) && isvalid(tmr), stop(tmr); delete(tmr); end
        if isvalid(fig), delete(fig); end
    end
end
