function gan = ganancias_escenario(can, esc, cfg)
%GANANCIAS_ESCENARIO  Ganancias de canal de cada luminaria en un escenario.
%
%   gan = GANANCIAS_ESCENARIO(can, esc, cfg)
%     can  Canal estatico (ver canal_galeria.m).
%     esc  Escenario con campos conc (mg/m^3), lente (transmitancia, 0 a 1)
%          y eps (llegadas de obstrucciones por minuto).
%     cfg  Parametros.
%   Devuelve gan.los(i) y gan.nlos(i), la ganancia LOS y la reflejada de la
%   luminaria i, ya afectadas por el polvo, la lente y la sombra esperada de
%   las reflexiones.
%
%   Polvo: cada trayecto de longitud L se atenua exp(-alpha L) con
%   alpha = k C (ver extincion_polvo.m). Lente: la transmitancia neta de los
%   lentes del LED y del fotodiodo multiplica la potencia recibida. Sombra de
%   las reflexiones: ponderacion esperada exp(-epsilon Td (E[p_iw]+E[p_wj])).
k = extincion_polvo(cfg);
alpha = k * esc.conc;
lambda = esc.eps / 60;
for i = 1:2
    gan.los(i) = can.los(i) * exp(-alpha * can.d(i)) * esc.lente;
    peso = exp(-lambda * cfg.sombra.permanencia_s * can.nlos(i).Ep);
    gan.nlos(i) = sum(can.nlos(i).g .* peso .* exp(-alpha * can.nlos(i).path)) ...
                  * esc.lente;
end
end
