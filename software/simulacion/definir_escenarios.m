function esc = definir_escenarios(cfg)
%DEFINIR_ESCENARIOS  Lista de escenarios de simulacion de la galeria.
%
%   esc = DEFINIR_ESCENARIOS(cfg) devuelve un arreglo de estructuras con
%     nombre, grupo   Identificadores del escenario.
%     conc            Concentracion de polvo (mg/m^3).
%     lente           Transmitancia neta de los lentes (0 a 1).
%     Ta              Temperatura ambiente (C).
%     Rth, disip      Resistencia termica (K/W) y su etiqueta.
%     eps             Llegadas de obstrucciones por minuto.
%     interf          true si hay interferencia luminica (focos de vehiculos).
%     emi             Elevacion del piso de ruido Wi-Fi por interferencia
%                     electromagnetica (dB); no afecta al enlace optico.
%
%   Los grupos varian una condicion a la vez respecto de la referencia limpia
%   (E0: sin polvo, lentes limpios, 25 C, sin obstrucciones ni interferencia),
%   salvo E6, que combina condiciones hostiles moderadas.
%     E1 polvo, E2 suciedad de lentes, E3 temperatura (con dos disipadores),
%     E4 intensidad de obstrucciones, E5 interferencia, E6 combinado y
%     E7 temperatura con polvo denso (1200 mg/m^3), donde el margen de enlace
%     es pequeno y el disipador marca diferencia.
base = struct('nombre', '', 'grupo', '', 'conc', 0, 'lente', 1, 'Ta', 25, ...
              'Rth', cfg.termico.Rth_std, 'disip', 'estandar', 'eps', 0, ...
              'interf', false, 'emi', 0);
esc = base;
esc(1).nombre = 'E0_referencia';
esc(1).grupo = 'E0';
for c = [25 100 300 600 1000 1200 1500 2000]
    e = base; e.grupo = 'E1'; e.nombre = sprintf('E1_polvo_%03d', c); e.conc = c;
    esc(end+1) = e;
end
for t = [0.8 0.6 0.4]
    e = base; e.grupo = 'E2'; e.nombre = sprintf('E2_lente_%.1f', t); e.lente = t;
    esc(end+1) = e;
end
for Ta = [20 30 40 50 60]
    e = base; e.grupo = 'E3'; e.nombre = sprintf('E3_temp_%02d_estandar', Ta); e.Ta = Ta;
    esc(end+1) = e;
    e.nombre = sprintf('E3_temp_%02d_mejorado', Ta);
    e.Rth = cfg.termico.Rth_mej; e.disip = 'mejorado';
    esc(end+1) = e;
end
for ep = [5 10 20 40]
    e = base; e.grupo = 'E4'; e.nombre = sprintf('E4_obstruc_%02d', ep); e.eps = ep;
    esc(end+1) = e;
end
for Ta = [25 40 50 60]
    e = base; e.grupo = 'E7'; e.conc = 1200; e.Ta = Ta;
    e.nombre = sprintf('E7_polvo1200_temp_%02d_estandar', Ta);
    esc(end+1) = e;
    e.nombre = sprintf('E7_polvo1200_temp_%02d_mejorado', Ta);
    e.Rth = cfg.termico.Rth_mej; e.disip = 'mejorado';
    esc(end+1) = e;
end
e = base; e.grupo = 'E5'; e.nombre = 'E5_interferencia'; e.interf = true;
esc(end+1) = e;
e = base; e.grupo = 'E6'; e.nombre = 'E6_combinado';
e.conc = 1000; e.lente = 0.6; e.Ta = 50; e.eps = 10; e.interf = true;
esc(end+1) = e;
for emi = [10 20 30 40 50]
    e = base; e.grupo = 'E8'; e.nombre = sprintf('E8_emi_%02d', emi); e.emi = emi;
    esc(end+1) = e;
end
e = base; e.grupo = 'E9'; e.nombre = 'E9_polvo1500_emi40_obstruc10';
e.conc = 1500; e.emi = 40; e.eps = 10;
esc(end+1) = e;
e = base; e.grupo = 'E9'; e.nombre = 'E9_combinado_emi40';
e.conc = 1000; e.lente = 0.6; e.Ta = 50; e.eps = 10; e.interf = true; e.emi = 40;
esc(end+1) = e;
end
