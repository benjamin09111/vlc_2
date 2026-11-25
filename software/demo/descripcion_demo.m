function [titulo, detalle] = descripcion_demo(tr, k, arq)
%DESCRIPCION_DEMO  Texto que explica, en palabras, que esta pasando en el paquete k.
%   titulo   Que enlace esta usando el sistema elegido.
%   detalle  Estado de ese enlace (libre, bloqueado por una maquina, caido).
a = char(225); i_ = char(237); o = char(243); e = char(233);
[act, bloq, wifiCaido] = enlaces_demo(tr, k, arq);
nombres = {['Luminaria 1'], ['Luminaria 2'], 'Wi-Fi'};
usados = find(act);
if arq == 2
    titulo = ['Transmiten las dos luminarias a la vez'];
elseif arq == 6
    if tr.usaWifi(k)
        titulo = ['Usa Wi-Fi: la se' char(241) 'al de luz est' a ' d' e 'bil'];
    else
        titulo = ['Usa luz (' nombres{usados} ')'];
    end
else
    titulo = ['Usa ' nombres{usados(1)}];
end
partes = {};
for j = usados
    if j == 3
        if wifiCaido
            partes{end+1} = ['Wi-Fi ca' i_ 'do: la interferencia es mayor que su se' char(241) 'al']; %#ok<AGROW>
        elseif bloq(3)
            partes{end+1} = ['Wi-Fi atenuado por una m' a 'quina en el camino']; %#ok<AGROW>
        else
            partes{end+1} = 'Wi-Fi libre'; %#ok<AGROW>
        end
    else
        if bloq(j)
            partes{end+1} = [nombres{j} ' bloqueada por una m' a 'quina: solo llegan reflejos de las paredes']; %#ok<AGROW>
        else
            partes{end+1} = [nombres{j} ' con l' i_ 'nea de vista libre']; %#ok<AGROW>
        end
    end
end
detalle = strjoin(partes, newline);
end
