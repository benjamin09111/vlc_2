function hay = interseccion_aabb(p0, p1, bmin, bmax)
%INTERSECCION_AABB  Intersecta un segmento con una caja alineada con los ejes.
%
%   hay = INTERSECCION_AABB(p0, p1, bmin, bmax)
%     p0, p1      Extremos del segmento [x y z] (m).
%     bmin, bmax  Esquinas de la caja [x y z] (m).
%   Devuelve true si el segmento atraviesa la caja (metodo de las losas).
v = p1 - p0;
t0 = 0;
t1 = 1;
hay = false;
for a = 1:3
    if abs(v(a)) < 1e-12
        if p0(a) < bmin(a) || p0(a) > bmax(a), return; end
    else
        ta = (bmin(a) - p0(a)) / v(a);
        tb = (bmax(a) - p0(a)) / v(a);
        t0 = max(t0, min(ta, tb));
        t1 = min(t1, max(ta, tb));
        if t0 > t1, return; end
    end
end
hay = true;
end
