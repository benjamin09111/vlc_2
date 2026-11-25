function b = bloquea_cilindro(A, B, x, y, w, h)
%BLOQUEA_CILINDRO  Segmentos que atraviesan obstaculos cilindricos verticales.
%
%   b = BLOQUEA_CILINDRO(A, B, x, y, w, h)
%     A       Extremo comun de los segmentos [x y z] (m), 1x3.
%     B       Otros extremos, nB x 3 (m).
%     x, y    Centro de cada obstaculo en el piso (m), vectores fila 1 x M.
%     w, h    Diametro y altura de cada obstaculo (m), vectores fila 1 x M.
%   Devuelve una matriz logica nB x M: b(i,j) es true si el segmento A-B(i,:)
%   atraviesa el cilindro j (eje vertical en (x,y), radio w/2, de z = 0 a h).
%
%   Modelo de obstruccion de [PJ2020] (basado en Zhang et al.): el enlace se
%   bloquea si pasa a menos de w/2 del eje y por debajo de la altura h. Se
%   resuelve de forma exacta: se halla el tramo del segmento dentro del radio
%   y se exige que su punto mas bajo no supere h.
nB = size(B, 1);
M = numel(x);
D = B - A;                                    % nB x 3
a = D(:,1).^2 + D(:,2).^2;                    % nB x 1
cx = A(1) - x;                                % 1 x M
cy = A(2) - y;
r = w / 2;
bq = 2 * (D(:,1)*cx + D(:,2)*cy);             % nB x M
cc = (cx.^2 + cy.^2 - r.^2) .* ones(nB, 1);   % nB x M
vertical = a < 1e-12;
disc = bq.^2 - 4*a.*cc;
sq = sqrt(max(disc, 0));
den = 2*a; den(vertical) = 1;
t1 = (-bq - sq) ./ den;
t2 = (-bq + sq) ./ den;
lo = max(0, t1);
hi = min(1, t2);
hay = disc >= 0 & lo <= hi;
% Enlaces verticales: dentro del radio en todo el segmento.
hay(vertical, :) = cc(vertical, :) <= 0;
lo(vertical, :) = 0;
hi(vertical, :) = 1;
zlo = A(3) + lo .* D(:,3);
zhi = A(3) + hi .* D(:,3);
zmin = min(zlo, zhi);
b = hay & (zmin <= h) & (w > 0);
end
