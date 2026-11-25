function t = textos_demo()
%TEXTOS_DEMO  Textos en espanol de la demostracion (con tildes, sin archivos no ASCII).
n = char(241); a = char(225); e = char(233); i = char(237); o = char(243); u = char(250);
t.sis = {'1 LED', '2 LEDs fijos', '2 LEDs selector ideal', ['2 LEDs selector pr' a 'ctico'], ...
         'Wi-Fi 2.4 GHz', ['H' i 'brido VLC/Wi-Fi']};
t.titulo = ['Comunicaci' o 'n por luz visible en una galer' i 'a minera'];
t.polvo = ['Polvo (mg/m^3)'];
t.temp = ['Temperatura (' char(176) 'C)'];
t.lente = 'Transmitancia de lentes';
t.obstr = ['Obstrucciones por minuto'];
t.emi = ['Interferencia electromagn' e 'tica (dB)'];
t.interf = ['Interferencia luminosa (focos)'];
t.disip = 'Disipador';
t.disipOpc = {['Est' a 'ndar'], 'Mejorado'};
t.arq = ['Arquitectura'];
t.escen = ['Escenario predefinido'];
t.vel = 'Velocidad';
t.iniciar = 'Iniciar'; t.pausar = 'Pausar'; t.reiniciar = 'Nuevo ciclo';
t.preset = {'Referencia limpia', ['Obstrucciones intensas (40/min)'], ['Polvo denso (1200 mg/m^3)'], ...
            ['Combinado (E6)'], ['Fallas simult' a 'neas (polvo, EMI, obstrucciones)']};
t.tiempo = 'Tiempo';
t.ber = 'BER acumulada (0 = sin errores)';
t.gp = 'Goodput (Mb/s)';
t.gpMov = ['Goodput (ventana de 5 s)'];
t.gpAcum = ['Goodput acumulado (Mb/s)'];
t.x_m = 'Posici'; t.x_m = ['Largo de la galer' i 'a (m)'];
t.y_m = 'Ancho (m)';
t.lum = 'Luminaria'; t.rx = ['Casco (receptor)']; t.ap = 'Punto de acceso';
t.enlaceCaido = ['Wi-Fi ca' i 'do'];
t.estado = @(ber, gp) sprintf('BER %s    Goodput %.2f Mb/s', fmtber(ber), gp);
t.lum1 = [char(76) 'uminaria 1']; t.lum2 = [char(76) 'uminaria 2'];
t.ap = ['Punto de acceso Wi-Fi'];
t.rxCasco = ['Casco del minero (receptor)'];
t.leyenda = {['Enlace de luz libre, en uso'], ['Enlace de luz bloqueado, en uso (solo llegan reflejos)'], ...
             ['Enlace que no se usa'], ['Enlace Wi-Fi en uso'], ['M' a 'quina (obstrucci' o 'n)'], ...
             ['Zona con l' i 'nea de vista (hasta 5.5 m)']};
t.maximo = ['M' a 'ximo posible'];
t.sinErrores = ['Sin errores hasta ahora (BER = 0)'];
t.berActual = 'BER actual:';
t.tituloBarras = ['Goodput promedio de cada sistema'];
t.n = n; t.u = u;
end

function s = fmtber(b)
if b <= 0, s = '0'; else, s = sprintf('%.1e', b); end
end
