function figuras_resultados()
%FIGURAS_RESULTADOS  Figuras de resultados del paper (Fase 6).
%
%   Lee resultados/datos/resultados.csv, escenarios.csv y mitigaciones.csv
%   (generados por ejecutar_simulacion y mitigaciones) y calcula el mapa de
%   cobertura estatico. Genera en resultados/figuras (y copia el PDF a
%   paper/figuras):
%     fig_cobertura     Margen de enlace en la galeria, limpio y hostil.
%     fig_polvo         BER y Goodput frente a la concentracion de polvo.
%     fig_temperatura   BER y Goodput frente a la temperatura, dos disipadores.
%     fig_obstrucciones BER y Goodput frente a las obstrucciones.
%     fig_comparacion   VLC, Wi-Fi e hibrido: interferencia y fallas simultaneas.
%     fig_mitigaciones  Efecto de las mitigaciones.
%     fig_densidad      Cobertura y Goodput segun el numero de luminarias.
%   Una BER nula se dibuja en el borde inferior del eje (piso de 1e-5).
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));
datos = fullfile(raiz, '..', 'resultados', 'datos');
R = readtable(fullfile(datos, 'resultados.csv'));
M = readtable(fullfile(datos, 'mitigaciones.csv'));
est = estilo_figura();
cfg = parametros('mina');

sis = {'1 LED', '2 LEDs fijo', '2 LEDs ideal', '2 LEDs practico', ...
       'Wi-Fi 2.4 GHz', 'Hibrido VLC/Wi-Fi'};
col = {est.col.gris, est.col.azul, est.col.azulClaro, est.col.naranjo, ...
       est.col.verde, est.col.negro};
lin = {'-', '-', '-', '-', '-', '--'};
mrk = {'o', 's', '^', 'd', 'x', 'none'};
piso = 1e-5;
txt = textos();

% ------------------------------------------------------------------------------
% Cobertura
% ------------------------------------------------------------------------------
fprintf('Calculando mapa de cobertura...\n');
xs = 0:1:26; ysMitad = 0.25:0.5:2.25; ys = [ysMitad, 5 - fliplr(ysMitad)];
cond(1) = struct('conc', 0, 'lente', 1, 'eps', 0, 'Ta', 25);
cond(2) = struct('conc', 600, 'lente', 1, 'eps', 0, 'Ta', 25);
cond(3) = struct('conc', 1000, 'lente', 0.6, 'eps', 0, 'Ta', 50);
[Z, Zx] = deal(zeros(numel(ys), numel(xs), 3), zeros(1, 53, 3));
xp = 0:0.5:26;
Zx = zeros(numel(xp), 3);
for ix = 1:numel(xs)
    for iy = 1:numel(ysMitad)
        can = canal_galeria(cfg, [xs(ix) ysMitad(iy) 1.8]);
        for c = 1:3
            m = margen(can, cond(c), cfg);
            Z(iy, ix, c) = m;
            Z(numel(ys) + 1 - iy, ix, c) = m;
        end
    end
end
for ix = 1:numel(xp)
    can = canal_galeria(cfg, [xp(ix) 2.5 1.8]);
    for c = 1:3, Zx(ix, c) = margen(can, cond(c), cfg); end
end
[~, ord] = sort(ys); ys = ys(ord); Z = Z(ord, :, :);
Posicion_m = xp(:); Margen_limpio_dB = Zx(:, 1); Margen_polvo600_dB = Zx(:, 2); Margen_hostil_dB = Zx(:, 3);
writetable(table(Posicion_m, Margen_limpio_dB, Margen_polvo600_dB, Margen_hostil_dB), ...
    fullfile(datos, 'cobertura_perfil.csv'));

fig = est.nueva(8.9, 12.5);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
mapa = [linspace(1, est.col.azul(1), 64)', linspace(1, est.col.azul(2), 64)', ...
        linspace(1, est.col.azul(3), 64)'];
tit = {txt.limpio, txt.hostil};
cc = [1 3];
for k = 1:2
    ax = nexttile(tl);
    imagesc(ax, xs, ys, Z(:, :, cc(k)), [0 50]);
    set(ax, 'YDir', 'normal'); colormap(ax, mapa);
    hold(ax, 'on');
    contour(ax, xs, ys, Z(:, :, cc(k)), [21.6 21.6], 'Color', est.col.naranjo, ...
        'LineWidth', 1.2);
    plot(ax, [cfg.tx1(1) cfg.tx2(1)], [cfg.tx1(2) cfg.tx2(2)], 'k^', ...
        'MarkerFaceColor', 'w', 'MarkerSize', 5);
    plot(ax, cfg.rx(1), cfg.rx(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    axis(ax, 'tight'); est.aplicar(ax); set(ax, 'XGrid', 'off', 'YGrid', 'off');
    ylabel(ax, txt.y_m); text(ax, 0.3, 4.4, tit{k}, 'FontSize', 8, 'Color', 'k', ...
        'BackgroundColor', 'w', 'Margin', 1);
    if k == 1, set(ax, 'XTickLabel', []); end
    cb = colorbar(ax, 'eastoutside'); cb.Label.String = txt.margen; cb.Color = 'k';
    cb.FontSize = 8; cb.Label.FontSize = 8;
end
ax = nexttile(tl);
hold(ax, 'on');
estilos = {'-', '--', ':'}; colores = {est.col.azul, est.col.gris, est.col.naranjo};
for c = 1:3
    plot(ax, xp, Zx(:, c), estilos{c}, 'Color', colores{c}, 'LineWidth', 1.1);
end
yline(ax, 21.6, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.6);
xlabel(ax, txt.x_m); ylabel(ax, txt.margen_corto); ylim(ax, [-20 50]);
lg = legend(ax, {txt.limpio, 'Polvo 600 mg/m^3', txt.hostil_corto}, ...
    'Box', 'off', 'FontSize', 7, 'TextColor', 'k', 'NumColumns', 1);
lg.Layout.Tile = 'south';
est.aplicar(ax);
est.exportar(fig, 'fig_cobertura'); close(fig);

% ------------------------------------------------------------------------------
% Polvo
% ------------------------------------------------------------------------------
cs = [0 25 100 300 600 1000 1200 1500 2000];
nombres = [{'E0_referencia'}, arrayfun(@(c) sprintf('E1_polvo_%03d', c), cs(2:end), 'UniformOutput', false)];
[ber, gp, bi, bs, gi, gs] = serie(R, nombres, sis);
fig = doble(est, cs, ber, gp, bi, bs, gi, gs, sis, col, lin, mrk, piso, ...
    txt.polvo, txt, [1 2 3 4 5 6]);
est.exportar(fig, 'fig_polvo'); close(fig);

% ------------------------------------------------------------------------------
% Temperatura (polvo de 1200 mg/m3, E7) con dos disipadores; LED unico y practico
% ------------------------------------------------------------------------------
Ts = [25 40 50 60];
nE = arrayfun(@(t) sprintf('E7_polvo1200_temp_%02d_estandar', t), Ts, 'UniformOutput', false);
nM = arrayfun(@(t) sprintf('E7_polvo1200_temp_%02d_mejorado', t), Ts, 'UniformOutput', false);
sTemp = {'1 LED'};
[bE, gE, bEi, bEs, gEi, gEs] = serie(R, nE, sTemp);
[bM, gM, bMi, bMs, gMi, gMs] = serie(R, nM, sTemp);
fig = est.nueva(8.9, 7.2);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
paneles = {max(bE, piso), max(bM, piso); gE, gM};
lims = {[piso 1], [0 10]};
for k = 1:2
    ax = nexttile(tl); hold(ax, 'on');
    errorbar(ax, Ts, paneles{k, 1}, [], [], 'o-', 'Color', est.col.gris, ...
        'MarkerFaceColor', 'w', 'MarkerSize', 4, 'LineWidth', 1.0);
    errorbar(ax, Ts, paneles{k, 2}, [], [], 's--', 'Color', est.col.azul, ...
        'MarkerFaceColor', est.col.azulClaro, 'MarkerSize', 4, 'LineWidth', 1.0);
    if k == 1, set(ax, 'YScale', 'log'); ylabel(ax, txt.ber); else, ylabel(ax, txt.gp); end
    ylim(ax, lims{k}); xlim(ax, [22 63]); xlabel(ax, txt.temp);
    est.aplicar(ax);
    if k == 1
        legend(ax, {txt.estandar, txt.mejorado}, 'Location', 'southeast', ...
            'Box', 'off', 'FontSize', 7, 'TextColor', 'k');
    end
end
est.exportar(fig, 'fig_temperatura'); close(fig);

% ------------------------------------------------------------------------------
% Obstrucciones
% ------------------------------------------------------------------------------
eps_ = [0 5 10 20 40];
nombres = {'E0_referencia', 'E4_obstruc_05', 'E4_obstruc_10', 'E4_obstruc_20', 'E4_obstruc_40'};
[ber, gp, bi, bs, gi, gs] = serie(R, nombres, sis);
fig = doble(est, eps_, ber, gp, bi, bs, gi, gs, sis, col, lin, mrk, piso, ...
    txt.obstr, txt, [1 2 3 4 5 6]);
est.exportar(fig, 'fig_obstrucciones'); close(fig);

% ------------------------------------------------------------------------------
% Comparacion VLC / Wi-Fi / hibrido
% ------------------------------------------------------------------------------
emis = [0 10 20 30 40 50];
nombres = [{'E0_referencia'}, arrayfun(@(e) sprintf('E8_emi_%02d', e), emis(2:end), 'UniformOutput', false)];
sel = [4 5 6];
[~, gp, ~, ~, gi, gs] = serie(R, nombres, sis(sel));
fig = est.nueva(8.9, 9.5);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl); hold(ax, 'on');
hh = gobjects(1, 3);
for q = 1:3
    if sel(q) == 6
        hh(q) = plot(ax, emis, gp(:, q), lin{6}, 'Color', col{6}, 'LineWidth', 1.2);
    else
        lo = gp(:, q) - gi(:, q); hi = gs(:, q) - gp(:, q);
        omitir = abs(gp(:, q) - 9.4118) < 1e-3; lo(omitir) = 0; hi(omitir) = 0;
        hh(q) = errorbar(ax, emis, gp(:, q), lo, hi, ...
            [lin{sel(q)} mrk{sel(q)}], 'Color', col{sel(q)}, 'MarkerSize', 4, ...
            'LineWidth', 1.0, 'CapSize', 3);
    end
end
xlabel(ax, txt.emi); ylabel(ax, txt.gp); ylim(ax, [0 10]); est.aplicar(ax);
lg = legend(ax, hh, {txt.sis{sel}}, 'Box', 'off', 'FontSize', 7, 'TextColor', 'k');
lg.Layout.Tile = 'north';
% barras por escenario
escn = {'E1_polvo_1500', 'E4_obstruc_40', 'E6_combinado', 'E9_polvo1500_emi40_obstruc10', 'E9_combinado_emi40'};
etiq = {txt.b1, txt.b2, txt.b3, txt.b4, txt.b5};
[~, gp2, ~, ~, gi2, gs2] = serie(R, escn, sis(sel));
ax = nexttile(tl); hold(ax, 'on');
b = bar(ax, gp2, 'grouped', 'EdgeColor', 'none');
for q = 1:3, b(q).FaceColor = col{sel(q)}; end
for q = 1:3
    lo = gp2(:, q) - gi2(:, q); hi = gs2(:, q) - gp2(:, q);
    omitir = abs(gp2(:, q) - 9.4118) < 1e-3 | gp2(:, q) < 0.01; lo(omitir) = 0; hi(omitir) = 0;
    errorbar(ax, b(q).XEndPoints, gp2(:, q), lo, hi, ...
        'k', 'LineStyle', 'none', 'CapSize', 2, 'LineWidth', 0.6);
end
set(ax, 'XTick', 1:5, 'XTickLabel', etiq); ylabel(ax, txt.gp); ylim(ax, [0 10.5]);
est.aplicar(ax); set(ax, 'XGrid', 'off');
est.exportar(fig, 'fig_comparacion'); close(fig);

% ------------------------------------------------------------------------------
% Mitigaciones
% ------------------------------------------------------------------------------
fig = est.nueva(8.9, 9.5);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
% (a) selector practico, 40 obstrucciones por minuto
vars = {'base', 'umbral con pilotos', 'sin error de estimacion', 'sin retardo de informacion', ...
        'histeresis 15 %', 'pilotos y sin error ni retardo'};
etA = {txt.v1, txt.v2, txt.v3, txt.v4, txt.v5, txt.v6};
bA = zeros(numel(vars), 1);
for v = 1:numel(vars)
    k = strcmp(M.Experimento, 'A_selector') & strcmp(M.Variante, vars{v}) & ...
        strcmp(M.Escenario, 'E4_obstruc_40') & strcmp(M.Sistema, '2 LEDs practico');
    bA(v) = M.BER(k);
end
kI = strcmp(M.Experimento, 'A_selector') & strcmp(M.Variante, 'base') & ...
     strcmp(M.Escenario, 'E4_obstruc_40') & strcmp(M.Sistema, '2 LEDs ideal');
ax = nexttile(tl); hold(ax, 'on');
barh(ax, bA, 'FaceColor', est.col.naranjo, 'EdgeColor', 'none');
xline(ax, M.BER(kI), '-', 'Color', est.col.azulClaro, 'LineWidth', 1.2);
set(ax, 'YTick', 1:numel(vars), 'YTickLabel', etA, 'YDir', 'reverse', 'XScale', 'log');
xlim(ax, [1e-3 0.1]); xlabel(ax, txt.ber); est.aplicar(ax); set(ax, 'YGrid', 'off');
ylim(ax, [0.2 6.6]);
text(ax, M.BER(kI) * 1.08, 0.45, txt.ideal, 'FontSize', 7, 'Color', est.col.azulClaro, ...
    'VerticalAlignment', 'middle');
% (b) lentes y tasa con polvo denso
ax = nexttile(tl); hold(ax, 'on');
lens = [1 0.8 0.6 0.4]; gl = zeros(1, 4);
for q = 1:4
    k = strcmp(M.Experimento, 'B_lentes') & strcmp(M.Escenario, sprintf('polvo1200_lente_%.1f', lens(q))) & ...
        strcmp(M.Sistema, '1 LED');
    gl(q) = M.Goodput_Mbps(k);
end
plot(ax, lens, gl, 'o-', 'Color', est.col.gris, 'MarkerFaceColor', 'w', 'MarkerSize', 4, ...
    'LineWidth', 1.0);
xlabel(ax, txt.lente); ylabel(ax, txt.gp); ylim(ax, [0 10]); xlim(ax, [0.35 1.05]);
set(ax, 'XDir', 'reverse'); est.aplicar(ax);
text(ax, 0.98, 9.3, txt.polvo1200, 'FontSize', 7, 'Color', 'k');
est.exportar(fig, 'fig_mitigaciones'); close(fig);
% ------------------------------------------------------------------------------
% Densidad de luminarias (requiere densidad.csv de densidad_luminarias)
% ------------------------------------------------------------------------------
rutaDens = fullfile(datos, 'densidad.csv');
if exist(rutaDens, 'file')
    fig = est.nueva(8.9, 10.5);
    tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax1 = nexttile(tl); ax2 = nexttile(tl);
    dibujar_densidad(ax1, ax2, readtable(rutaDens), true);
    est.exportar(fig, 'fig_densidad'); close(fig);
end
fprintf('Figuras de resultados generadas.\n');
end

% ==================================================================================
function m = margen(can, c, cfg)
% Margen de enlace (dB) de 2 LEDs fijos: 20 log10(corriente de senal / ruido).
esc = struct('conc', c.conc, 'lente', c.lente, 'eps', c.eps);
G = ganancias_escenario(can, esc, cfg);
[fT, ~] = modelo_termico(c.Ta, cfg.termico.Rth_std, cfg);
P = (cfg.Ptotal * fT / 2) * (G.los(1) + G.nlos(1) + G.los(2) + G.nlos(2));
[~, s1] = ruido_receptor(P, cfg.ruido.Ibg, c.Ta, cfg);
m = 20 * log10(cfg.R * P / s1);
end

function [ber, gp, bi, bs, gi, gs] = serie(R, nombres, sis)
n = numel(nombres); q = numel(sis);
[ber, gp, bi, bs, gi, gs] = deal(zeros(n, q));
for i = 1:n
    for j = 1:q
        k = strcmp(R.Escenario, nombres{i}) & strcmp(R.Sistema, sis{j});
        assert(nnz(k) == 1, 'Falta %s / %s', nombres{i}, sis{j});
        ber(i, j) = R.BER(k); gp(i, j) = R.Goodput_Mbps(k);
        bi(i, j) = R.BER_IC95_inf(k); bs(i, j) = R.BER_IC95_sup(k);
        gi(i, j) = R.Goodput_IC95_inf(k); gs(i, j) = R.Goodput_IC95_sup(k);
    end
end
end

function fig = doble(est, x, ber, gp, bi, bs, gi, gs, sis, col, lin, mrk, piso, xl, txt, sel)
fig = est.nueva(8.9, 11.5);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:2
    ax = nexttile(tl); hold(ax, 'on'); h = gobjects(1, numel(sel));
    for j = 1:numel(sel)
        q = sel(j);
        if k == 1
            y = max(ber(:, q), piso); lo = y - max(bi(:, q), piso); hi = max(bs(:, q), piso) - y;
            omitir = ber(:, q) <= 0;
        else
            y = gp(:, q); lo = y - gi(:, q); hi = gs(:, q) - y;
            omitir = gp(:, q) < 0.01 | abs(gp(:, q) - 9.4118) < 1e-3;
        end
        lo(omitir) = 0; hi(omitir) = 0;
        if q == 6
            h(j) = plot(ax, x, y, lin{q}, 'Color', col{q}, 'LineWidth', 1.2);
        else
            h(j) = errorbar(ax, x, y, lo, hi, [lin{q} mrk{q}], 'Color', col{q}, ...
                'MarkerSize', 4, 'LineWidth', 0.9, 'CapSize', 2);
        end
    end
    if k == 1
        set(ax, 'YScale', 'log'); ylim(ax, [piso 1]); ylabel(ax, txt.ber);
        set(ax, 'XTickLabel', []);
        lg = legend(ax, h, txt.sis(sel), 'Box', 'off', 'FontSize', 7, ...
            'TextColor', 'k', 'NumColumns', 2);
        lg.Layout.Tile = 'north';
    else
        ylim(ax, [0 10]); ylabel(ax, txt.gp); xlabel(ax, xl);
    end
    xlim(ax, [min(x) max(x)]);
    est.aplicar(ax);
end
end

function t = textos()
n = char(241); a = char(225); e = char(233); i = char(237); o = char(243); u = char(250);
t.limpio = ['Condiciones limpias'];
t.hostil = ['Hostil: 1000 mg/m^3, lentes 0.6, 50 ' char(176) 'C'];
t.hostil_corto = ['Hostil (1000 mg/m^3, 0.6, 50 ' char(176) 'C)'];
t.margen = ['Margen de enlace (dB)'];
t.margen_corto = ['Margen (dB)'];
t.x_m = ['Posici' o 'n a lo largo de la galer' i 'a (m)'];
t.y_m = ['Ancho (m)'];
t.ber = 'BER';
t.gp = 'Goodput (Mb/s)';
t.polvo = ['Concentraci' o 'n de polvo (mg/m^3)'];
t.obstr = ['Llegadas de obstrucciones por minuto'];
t.temp = ['Temperatura ambiente (' char(176) 'C)'];
t.mejorado = 'Disipador mejorado';
t.emi = ['Interferencia electromagn' e 'tica (dB sobre el ruido t' e 'rmico)'];
t.sis = {'1 LED', '2 LEDs fijos', '2 LEDs selector ideal', ['2 LEDs selector pr' a 'ctico'], ...
         'Wi-Fi 2.4 GHz', ['H' i 'brido VLC/Wi-Fi']};
t.b1 = 'Polvo 1500'; t.b2 = '40 obstr./min'; t.b3 = 'Combinado'; t.b4 = 'Polvo+EMI+obstr.';
t.b5 = 'Combinado+EMI';
t.v1 = ['Base']; t.v2 = ['Umbral con pilotos']; t.v3 = ['Sin error de estimaci' o 'n'];
t.v4 = ['Sin retardo']; t.v5 = [char(72) 'ist' e 'resis 15 %']; t.v6 = ['Pilotos, sin error ni retardo'];
t.ideal = 'Selector ideal';
t.lente = ['Transmitancia de los lentes'];
t.polvo1200 = ['Polvo de 1200 mg/m^3, LED '  u 'nico'];
t.estandar = ['Disipador est' a 'ndar'];
end
