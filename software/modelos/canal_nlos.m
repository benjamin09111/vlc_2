function [g, tau, centros] = canal_nlos(tx, ejeTx, rx, ejeRx, paredes, cfg, resolucion, varargin)
%CANAL_NLOS  Componente de primera reflexion difusa en superficies planas.
%
%   [g, tau, centros] = CANAL_NLOS(tx, ejeTx, rx, ejeRx, paredes, cfg, resolucion)
%
%   Entradas
%     tx, rx       Posicion de la luminaria y del receptor [x y z] (m).
%     ejeTx, ejeRx Vector unitario de apuntamiento de cada elemento.
%     paredes      Arreglo de estructuras con campos
%                    origen  Esquina de la superficie [x y z] (m)
%                    u, v    Vectores de arista (m) que la generan
%                    normal  Normal unitaria hacia el interior de la galeria
%                    rho     Reflectividad (adimensional, 0 a 1)
%     cfg          Parametros (ver parametros.m).
%     resolucion   Lado maximo de cada elemento reflectante (m).
%
%   Salidas
%     g        Ganancia de cada elemento reflectante (adimensional).
%     tau      Retardo de cada trayecto luminaria-pared-receptor (s).
%     centros  Posicion de cada elemento (Nx3), para evaluar bloqueos.
%
%   Cada elemento es una fuente lambertiana (m = 1) y se suma una sola
%   reflexion, como en [PJ2020] y Kahn & Barry (1997):
%     dH = (m+1) Apd rho dA / (2 pi^2 d1^2 d2^2) *
%          cos^m(phi1) cos(alfa) cos(beta) cos(psi2) * Ganancia
%   La ganancia total es sum(g) y la respuesta temporal se obtiene
%   agrupando g segun tau (ver respuesta_impulso.m).
%
%   Opcion 'SinFactorPi', true elimina el factor 1/pi de la reemision
%   lambertiana de la pared, que es la expresion tal como esta impresa en
%   [PJ2020]; se usa solo para la comparacion de la validacion V-01.
p = inputParser;
addParameter(p, 'SinFactorPi', false, @islogical);
parse(p, varargin{:});
c = 299792458;
m = -log(2) / log(cosd(cfg.phiHalf));
G = cfg.filterGain * cfg.concentratorGain;
if p.Results.SinFactorPi
    factor = (m+1) / (2*pi);
else
    factor = (m+1) / (2*pi^2);
end
g = zeros(0, 1);
tau = zeros(0, 1);
centros = zeros(0, 3);
for w = 1:numel(paredes)
    W = paredes(w);
    nu = max(1, ceil(norm(W.u) / resolucion));
    nv = max(1, ceil(norm(W.v) / resolucion));
    dA = norm(cross(W.u, W.v)) / (nu*nv);
    [I, J] = ndgrid(((1:nu) - 0.5)/nu, ((1:nv) - 0.5)/nv);
    P = W.origen + I(:)*W.u + J(:)*W.v;                  % Nx3
    a = P - tx;                                          % luminaria -> pared
    d1 = sqrt(sum(a.^2, 2));
    cosPhi = (a * ejeTx(:)) ./ d1;
    cosAlfa = -(a * W.normal(:)) ./ d1;
    b = rx - P;                                          % pared -> receptor
    d2 = sqrt(sum(b.^2, 2));
    cosBeta = (b * W.normal(:)) ./ d2;
    cosPsi = -(b * ejeRx(:)) ./ d2;
    ok = cosPhi > 0 & cosAlfa > 0 & cosBeta > 0 & cosPsi > 0 & ...
         acosd(min(1, cosPsi)) <= cfg.FOV;
    gw = factor * cfg.Apd * W.rho * dA ./ (d1.^2 .* d2.^2) .* ...
         cosPhi.^m .* cosAlfa .* cosBeta .* cosPsi * G;
    gw(~ok) = 0;
    g = [g; gw];                                         %#ok<AGROW>
    tau = [tau; (d1 + d2) / c];                          %#ok<AGROW>
    centros = [centros; P];                              %#ok<AGROW>
end
end
