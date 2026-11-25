function figuras_validacion()
%FIGURAS_VALIDACION  Figuras de la validacion del canal y del calculo de BER.
%
%   Genera en resultados/figuras (y copia el PDF a paper/figuras):
%     fig_validacion_cir.pdf  Respuesta al impulso del escenario de referencia
%                             de [PJ2020]: linea de vista y reflexiones.
%     fig_validacion_ber.pdf  BER por simulacion de bits frente a la expresion
%                             analitica (prueba V-02).
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(raiz));
est = estilo_figura();
ntilde = char(241); iacute = char(237); oacute = char(243);

% --- Respuesta al impulso del escenario de referencia -------------------------
r = escenario_referencia(0.10, 'SinFactorPi', true);
tns = r.t * 1e9;
piso = 1e-9;
fig = est.nueva(8.9, 6.2);
ax = axes(fig);
hold(ax, 'on');
iL = find(r.hLos > 0);
iN = find(r.hNlos > 0);
tallo = @(tt, hh, col) plot(ax, [tt tt]', [piso*ones(size(hh)) hh]', ...
    'Color', col, 'LineWidth', 1.2);
tallo(tns(iN), r.hNlos(iN), est.col.naranjo);
hN = plot(ax, NaN, NaN, 'Color', est.col.naranjo, 'LineWidth', 1.2);
tallo(tns(iL), r.hLos(iL), est.col.azul);
hL = plot(ax, NaN, NaN, 'Color', est.col.azul, 'LineWidth', 1.2);
set(ax, 'YScale', 'log');
xlim(ax, [5 35]); ylim(ax, [1e-9 3e-5]);
xlabel(ax, 'Retardo (ns)');
ylabel(ax, ['Respuesta al impulso (adimensional)']);
legend(ax, [hL hN], {['L' iacute 'nea de vista'], ['Primera reflexi' oacute 'n']}, ...
    'Location', 'northeast', 'Box', 'off', 'FontSize', 8, 'TextColor', 'k');
est.aplicar(ax);
est.exportar(fig, 'fig_validacion_cir');
close(fig);

% --- BER por simulacion frente a expresion analitica ---------------------------
flujo = RandStream('mt19937ar', 'Seed', 20261124);
a = 1:0.5:6;
N = 2e6;
pAna = 0.5 * erfc(a / (2*sqrt(2)));
pMC = zeros(size(a));
for q = 1:numel(a)
    bits = rand(flujo, N, 1) < 0.5;
    rx = a(q) * double(bits) + randn(flujo, N, 1);
    pMC(q) = mean((rx >= a(q)/2) ~= bits);
end
sd = 1.96 * sqrt(pMC .* (1 - pMC) / N);
fig = est.nueva(8.9, 6.2);
ax = axes(fig);
hold(ax, 'on');
aa = linspace(1, 6, 200);
hA = plot(ax, aa, 0.5 * erfc(aa / (2*sqrt(2))), '-', 'Color', est.col.negro, ...
    'LineWidth', 1.0);
hM = errorbar(ax, a, pMC, sd, 'o', 'Color', est.col.azul, 'MarkerSize', 4, ...
    'MarkerFaceColor', est.col.azulClaro, 'LineWidth', 0.8, 'CapSize', 3);
set(ax, 'YScale', 'log');
ylim(ax, [1e-4 0.4]);
xlabel(ax, ['Amplitud de se' ntilde 'al / ruido RMS']);
ylabel(ax, 'Tasa de error de bit (BER)');
legend(ax, [hA hM], {['Expresi' oacute 'n anal' iacute 'tica'], ...
    ['Simulaci' oacute 'n (IC 95 %)']}, 'Location', 'southwest', ...
    'Box', 'off', 'FontSize', 8, 'TextColor', 'k');
est.aplicar(ax);
est.exportar(fig, 'fig_validacion_ber');
close(fig);
end
