function [tr, out] = simular_ciclo(cfg, can, p, semilla)
%SIMULAR_CICLO  Un ciclo de 24 s de la simulacion, paquete a paquete.
%
%   tr = SIMULAR_CICLO(cfg, can, p, semilla)
%     cfg      Parametros del perfil 'mina'.
%     can      Canal estatico (canal_galeria).
%     p        Condiciones: conc, lente, Ta, disip ('estandar' o 'mejorado'),
%              eps, interf, emi (ver definir_escenarios.m).
%     semilla  Semilla de la replica (bits, obstrucciones, ruido y sombreado).
%   Usa ejecutar_escenarios_mina con una sola replica, es decir, exactamente
%   las funciones de la simulacion del paper; devuelve la traza de esa replica
%   (ver el campo traza de ejecutar_escenarios_mina) y sus obstrucciones; la
%   segunda salida es la salida completa de ejecutar_escenarios_mina.
cfg.trazas = true;
cfg.nRuns = 1;
cfg.semilla = semilla;
rng(semilla, 'twister');
[rep, tAct] = generar_replicas_mina(cfg);
Rth = cfg.termico.Rth_std;
if strcmp(p.disip, 'mejorado'), Rth = cfg.termico.Rth_mej; end
esc = struct('nombre', 'demo', 'grupo', 'demo', 'conc', p.conc, 'lente', p.lente, ...
             'Ta', p.Ta, 'Rth', Rth, 'disip', p.disip, 'eps', p.eps, ...
             'interf', logical(p.interf), 'emi', p.emi);
out = ejecutar_escenarios_mina(cfg, can, rep, tAct, esc);
tr = out.traza{1};
tr.obs = rep{1}.obs;
tr.marca = rep{1}.marca;
tr.presente = rep{1}.presPkt & (rep{1}.marca <= p.eps / cfg.sombra.epsilon_max_min);
tr.margen_dB = 20 * log10(out.escenarios.Margen_SNR_1LED);
end
