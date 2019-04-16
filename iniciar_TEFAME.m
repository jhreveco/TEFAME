% ______________________________________________________________________
%|                                                                      |
%|               Iniciar_TEFAME - Inicia la libreria TEFAME             |
%|                                                                      |
%|                   Area  de Estructuras y Geotecnia                   |
%|                   Departamento de Ingenieria Civil                   |
%|              Facultad de Ciencias Fisicas y Matematicas              |
%|                         Universidad de Chile                         |
%|______________________________________________________________________|

TEFAME_ver = 'v0.61';

% Agrega las carpetas de la plataforma TEFAME al PATH
addpath('tefame');
addpath('tefame/analisis');
addpath('tefame/modelo');
addpath('tefame/modelo/base');
addpath('tefame/modelo/cargas');
addpath('tefame/modelo/cargas/dinamicas');
addpath('tefame/modelo/cargas/estaticas');
addpath('tefame/modelo/cargas/patrones');
addpath('tefame/modelo/elementos');
addpath('tefame/modelo/nodo');
addpath('tefame/modelo/restricciones');

% Agrega los test al path
addpath('test');
addpath('test/estatico');
addpath('test/modal');