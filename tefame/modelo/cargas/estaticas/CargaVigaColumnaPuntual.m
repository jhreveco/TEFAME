% ______________________________________________________________________
%|                                                                      |
%|          TEFAME - Toolbox para Elementos Finitos y Analisis          |
%|                  Matricial de Estructuras en MATLAB                  |
%|                                                                      |
%|                   Area  de Estructuras y Geotecnia                   |
%|                   Departamento de Ingenieria Civil                   |
%|              Facultad de Ciencias Fisicas y Matematicas              |
%|                         Universidad de Chile                         |
%|                                                                      |
%| TEFAME es una  plataforma en base a objetos para modelar, analizar y |
%| visualizar  la respuesta de sistemas  estructurales usando el metodo |
%| de elementos finitos y analisis matricial de estructuras en MATLAB.  |
%| La plataforma es desarrollada en  propagacion orientada a objetos en |
%| MATLAB.                                                              |
%|______________________________________________________________________|
% ______________________________________________________________________
%|                                                                      |
%| Clase CargaVigaColumnaPuntual                                        |
%|                                                                      |
%| Este archivo contiene la definicion de la Clase CargaVigaColumnaPuntual|
%| CargaVigaColumnaPuntual es una subclase de la clase Carga y          |
%| corresponde a la representacion de una carga puntual en un elemento  |
%| tipo Viga-Columna.                                                   |
%| La clase CargaVigaColumnaPuntual es una clase que contiene el        |
%| elemento al al que se le va a aplicar la carga, el valor de esta     |
%| carga, la distancia a uno de los nodos como porcentaje del largo y   |
%| el angulo de aplicacion.                                             |
%|                                                                      |
%| Programado: Pablo Pizarro @ppizarror.com                             |
%| Fecha: 11/06/2018                                                    |
%|______________________________________________________________________|
%
%  Properties (Access=private):
%       elemObj
%       carga
%       dist
%       theta
%  Methods:
%       obj = CargaVigaColumnaPuntual(etiquetaCarga,elemObjeto,carga,distancia,theta)
%       aplicarCarga(obj,factorDeCarga)
%       disp(obj)
%  Methods SuperClass (CargaEstatica):
%       masa = obtenerMasa(obj)
%       definirFactorUnidadMasa(obj,factor)
%       definirFactorCargaMasa(obj,factor)
%       nodos = obtenerNodos(obj)
%  Methods SuperClass (ComponenteModelo):
%       etiqueta = obtenerEtiqueta(obj)
%       e = equals(obj,obj)
%       objID = obtenerIDObjeto(obj)

classdef CargaVigaColumnaPuntual < CargaEstatica
    
    properties(Access = private)
        elemObj % Variable que guarda el elemento que se le va a aplicar la carga
        carga % Valor de la carga
        dist % Distancia de la carga al primer nodo del elemento
        theta % Angulo de aplicacion de la carga
    end % properties CargaVigaColumnaPuntual
    
    methods
        
        function obj = CargaVigaColumnaPuntual(etiquetaCarga, ...
                elemObjeto, carga, distancia, theta)
            % CargaVigaColumnaPuntual: es el constructor de la clase CargaVigaColumnaPuntual
            %
            % Crea un objeto de la clase CargaVigaColumnaPuntual, en donde toma como atributo
            % el objeto a aplicar la carga, la distancia como porcentaje
            % del largo del elemento con respecto al primer nodo, el
            % elemento tipo viga y el angulo de aplicacion de la carga con respecto a la normal
            
            if nargin == 0
                etiquetaCarga = '';
                elemObjeto = [];
                carga = 0;
                distancia = 0;
                theta = 0;
            end % if
            
            % Llamamos al constructor de la SuperClass que es la clase Carga
            obj = obj@CargaEstatica(etiquetaCarga);
            
            % Guarda los valores
            obj.elemObj = elemObjeto;
            obj.carga = carga;
            obj.dist = distancia * elemObjeto.obtenerLargo();
            obj.theta = theta;
            obj.nodosCarga = elemObjeto.obtenerNodos();
            
        end % CargaVigaColumnaPuntual constructor
        
        function [u1, u2, v1, v2, theta1, theta2] = calcularCarga(obj)
            % calcularCarga: Calcula la carga
            
            % Largo de la viga
            L = obj.elemObj.obtenerLargo();
            
            % Posicion de la carga
            d = obj.dist;
            
            % Carga normal
            P = obj.carga * cos(obj.theta);
            
            % Carga axial
            H = -obj.carga * sin(obj.theta);
            
            % Se calculan apoyos y reacciones en un caso de viga empotrada
            % sometida a una carga P aplicada a (L-d) de un apoyo y d del
            % otro. Esto se hizo al no tener la funcion dirac(x) y
            % distintos errores fruto de la evaluacion de la integral
            v1 = P * ((L - d)^2 / L^2) * (3 - 2 * (L - d) / L);
            v2 = P * (d^2 / L^2) * (3 - 2 * d / L);
            theta1 = P * d * (L - d)^2 / (L^2);
            theta2 = -P * (d^2) * (L - d) / (L^2);
            
            % Para el caso de las cargas normales se usan las funciones de
            % interpolacion
            Nu1 = @(x) (1 - x / L);
            Nu2 = @(x) x / L;
            u1 = H * Nu1(d);
            u2 = H * Nu2(d);
            
        end % calcularCarga function
        
        function masa = obtenerMasa(obj)
            % obtenerMasa: Obtiene la masa asociada a la carga
            
            [u1, u2, v1, v2, ~, ~] = obj.calcularCarga();
            masa = abs(u1 + u2 + v1 + v2) .* (obj.factorCargaMasa * obj.factorUnidadMasa);
            
        end % obtenerMasa function
        
        function aplicarCarga(obj, factorDeCarga)
            % aplicarCarga: es un metodo de la clase CargaVigaColumnaPuntual
            % que se usa para aplicar la carga sobre los dos nodos del elemento
            
            % Calcula la carga
            [u1, u2, v1, v2, theta1, theta2] = obj.calcularCarga();
            vectorCarga = factorDeCarga * [u1, v1, theta1, u2, v2, theta2]';
            obj.elemObj.sumarFuerzaEquivalente(vectorCarga);
            
            % Aplica vectores de carga en coordenadas globales
            vectorCarga = obj.elemObj.obtenerMatrizTransformacion()' * vectorCarga;
            nodos = obj.elemObj.obtenerNodos();
            nodos{1}.agregarCarga([vectorCarga(1), vectorCarga(2), vectorCarga(3)]');
            nodos{2}.agregarCarga([vectorCarga(4), vectorCarga(5), vectorCarga(6)]');
            
        end % aplicarCarga function
        
        function disp(obj)
            % disp: es un metodo de la clase CargaVigaPuntual que se usa para imprimir en
            % command Window la informacion de la carga aplicada sobre el
            % elemento
            %
            % Imprime la informacion guardada en la carga puntual de la
            % Viga-Columna (obj) en pantalla
            
            fprintf('Propiedades carga viga-columna puntual:\n');
            disp@CargaEstatica(obj);
            
            % Obtiene la etiqueta del elemento
            etiqueta = obj.elemObj.obtenerEtiqueta();
            
            % Obtiene la etiqueta del primer nodo
            nodo1etiqueta = obj.elemObj.obtenerNodos();
            nodo1etiqueta = nodo1etiqueta{1}.obtenerEtiqueta();
            
            % Obtiene cargas axiales y normales
            P = obj.carga * cos(obj.theta);
            H = obj.carga * sin(obj.theta);
            
            fprintf('\tCarga aplicada en Elemento: %s a %.3f del Nodo: %s\n', ...
                etiqueta, obj.dist, nodo1etiqueta);
            fprintf('\t\tComponente NORMAL:\t%.3f\n', P);
            fprintf('\t\tComponente AXIAL:\t%.3f\n', H);
            dispMetodoTEFAME();
            
        end % disp function
        
    end % methods CargaVigaColumnaPuntual
    
end % class CargaVigaColumnaPuntual