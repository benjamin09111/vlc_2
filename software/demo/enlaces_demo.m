function [act, bloq, wifiCaido] = enlaces_demo(tr, k, arq)
%ENLACES_DEMO  Enlaces usados por la arquitectura en el paquete k de la traza.
%   act(1:3)   Luminaria 1, luminaria 2 y Wi-Fi en uso.
%   bloq(1:3)  Bloqueo de cada enlace (el Wi-Fi comparte la obstruccion de la luminaria 1).
%   wifiCaido  true si el Wi-Fi no tiene ningun MCS disponible.
act = false(1, 3);
switch arq
    case 1, act(1) = true;
    case 2, act(1:2) = true;
    case 3, act(tr.mejor(k)) = true;
    case 4, act(tr.eleccion(k)) = true;
    case 5, act(3) = true;
    case 6
        if tr.usaWifi(k), act(3) = true; else, act(tr.eleccion(k)) = true; end
end
bloq = [tr.bloqueo(1, k), tr.bloqueo(2, k), tr.bloqueo(1, k)];
wifiCaido = ~tr.wifiDisponible(k);
end
