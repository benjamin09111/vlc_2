function paredes = paredes_caja(dim, rho, lista)
%PAREDES_CAJA  Superficies reflectantes de un recinto rectangular.
%
%   paredes = PAREDES_CAJA(dim, rho, lista)
%     dim    Dimensiones [Lx Ly Lz] (m); el recinto ocupa [0,Lx]x[0,Ly]x[0,Lz].
%     rho    Reflectividad de las superficies (0 a 1).
%     lista  Celda con los nombres de las superficies a incluir:
%              'x0','x1'  extremos en x = 0 y x = Lx
%              'y0','y1'  paredes laterales en y = 0 e y = Ly
%              'z0','z1'  piso y techo
%            Por defecto se incluyen las seis.
%   Cada superficie es una estructura con origen, aristas u y v, normal
%   unitaria hacia el interior y reflectividad (ver canal_nlos.m).
if nargin < 3, lista = {'x0','x1','y0','y1','z0','z1'}; end
Lx = dim(1); Ly = dim(2); Lz = dim(3);
def.x0 = {[0 0 0],  [0 Ly 0], [0 0 Lz], [ 1 0 0]};
def.x1 = {[Lx 0 0], [0 Ly 0], [0 0 Lz], [-1 0 0]};
def.y0 = {[0 0 0],  [Lx 0 0], [0 0 Lz], [0  1 0]};
def.y1 = {[0 Ly 0], [Lx 0 0], [0 0 Lz], [0 -1 0]};
def.z0 = {[0 0 0],  [Lx 0 0], [0 Ly 0], [0 0  1]};
def.z1 = {[0 0 Lz], [Lx 0 0], [0 Ly 0], [0 0 -1]};
paredes = repmat(struct('origen',[0 0 0],'u',[0 0 0],'v',[0 0 0], ...
                        'normal',[0 0 0],'rho',rho), 1, numel(lista));
for q = 1:numel(lista)
    d = def.(lista{q});
    paredes(q).origen = d{1};
    paredes(q).u = d{2};
    paredes(q).v = d{3};
    paredes(q).normal = d{4};
    paredes(q).rho = rho;
end
end
