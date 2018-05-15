% ______________________________________________________________________
%|                                                                      |
%|           TEFAME - Toolbox para Elemento Finitos y Analisis          |
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
%|                                                                      |
%| Desarrollado por:                                                    |
%|       Fabian Rojas, PhD (frojas@ing.uchile.cl)                       |
%|       Prof. Asistente, Departamento de Ingenieria Civil              |
%|       Universidad de Chile                                           |
%|______________________________________________________________________|
% ______________________________________________________________________
%|                                                                      |
%| Clase CargaVigaPuntual                                               |
%|                                                                      |
%| Este archivo contiene la definicion de la Clase CargaVigaPuntual     |
%| CargaVigaPuntual es una subclase de la clase Carga y corresponde a la|
%| representacion de una carga puntual en un elemento tipo Viga.        |
%| La clase CargaVigaPuntual es una clase que contiene el elemento al   |
%| al que se le va a aplicar la carga, el valor de esta carga y la      |
%| distancia a uno de los nodos como porcentaje del largo.              |
%|                                                                      |
%| Programado: PABLO PIZARRO @ppizarror.com                             |
%| Fecha: 14/05/2018                                                    |
%|______________________________________________________________________|
%
%  Properties (Access=private):
%       elemObj
%       carga
%       dist
%
%  Methods:
%       cargaNodoObj = Carga(etiquetaCarga,nodoObjeto,cargaNodo)
%       aplicarCarga(cargaNodoObj,factorDeCarga)
%       disp(cargaNodoObj)
%  Methods Suplerclass (Carga):
%  Methods Suplerclass (ComponenteModelo):
%       etiqueta = obtenerEtiqueta(componenteModeloObj)

classdef CargaVigaPuntual < Carga
    
    properties(Access = private)
        elemObj % Variable que guarda el elemento que se le va a aplicar la carga
        carga % Valor de la carga
        dist % Distancia de la carga al primer nodo del elemento
    end % properties CargaNodo
    
    methods
        
        function cargaVigaPuntualObj = CargaVigaPuntual(etiquetaCarga, elemObjeto, carga, distancia)
            % Elemento: es el constructor de la clase CargaVigaPuntual
            %
            % cargaVigaPuntualObj=CargaVigaPuntual(etiquetaCarga,elemObjeto,carga,distancia)
            % Crea un objeto de la clase CargaVigaPuntual, en donde toma como atributo
            % el objeto a aplicar la carga, la distancia como porcentaje
            % del largo del elemento con respecto al primer nodo y el
            % elemento tipo viga.
            
            if nargin == 0
                etiquetaCarga = '';
                elemObjeto = [];
                carga = 0;
                distancia = 0;
            end % if
            
            % Llamamos al constructor de la SuperClass que es la clase Carga
            cargaVigaPuntualObj = cargaVigaPuntualObj@Carga(etiquetaCarga);
            
            % Guarda los valores
            cargaVigaPuntualObj.elemObj = elemObjeto;
            cargaVigaPuntualObj.carga = carga;
            cargaVigaPuntualObj.dist = distancia * elemObjeto.obtenerLargo();
            
        end % CargaVigaPuntual constructor
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para aplicar la Carga Puntual durante el an�lisis
        
        function aplicarCarga(cargaVigaPuntualObj, factorDeCarga)
            % aplicarCarga: es un metodo de la clase CargaVigaPuntual que se usa para aplicar
            % la carga sobre los dos nodos del elemento.
            %
            % aplicarCarga(cargaVigaPuntualObj, factorDeCarga)
            
            % Largo de la viga
            L = cargaVigaPuntualObj.elemObj.obtenerLargo();
            
            % Posici�n de la carga
            d = cargaVigaPuntualObj.dist;
            
            % Carga
            P = cargaVigaPuntualObj.carga;
            
            % Se calculan apoyos y reacciones en un caso de viga empotrada
            % sometida a una carga P aplicada a (L-d) de un apoyo y d del
            % otro. Esto se hizo al no tener la funci�n dirac(x) y
            % distintos errores fruto de la evaluaci�n de la integral. El
            % caso con las funciones de interpolaci�n N1..N4 se realiz�
            % correctamente para el caso de la carga distribu�da.
            v1 = P * ((L - d)^2 / L^2)*(3-2*(L - d)/L);
            v2 = P * (d^2 / L^2)*(3-2*d/L);
            theta1 = P * d * (L - d)^2 / (L^2);
            theta2 = -P * (d^2) * (L - d) / (L^2);
            
            vectorCarga1 = [0, -v1, -theta1]';
            vectorCarga2 = [0, -v2, -theta2]';
            cargaVigaPuntualObj.elemObj.sumarFuerzaEquivalente([-v1, -theta1, -v2, -theta2]');
            
            % Aplica vectores de carga
            nodos = cargaVigaPuntualObj.elemObj.obtenerNodos();
            nodos{1}.agregarCarga(factorDeCarga*vectorCarga1);
            nodos{2}.agregarCarga(factorDeCarga*vectorCarga2);
            
        end % aplicarCarga function
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para mostar la informacion de la Carga Nodal en pantalla
        
        function disp(cargaVigaPuntualObj)
            % disp: es un metodo de la clase CargaVigaPuntual que se usa para imprimir en
            % command Window la informacion de la carga aplicada sobre el
            % elemento
            %
            % disp(cargaVigaPuntualObj)
            % Imprime la informacion guardada en la Carga Puntual de la
            % Viga (cargaVigaPuntualObj) en pantalla
            
            fprintf('Propiedades Carga Viga Puntual:\n');
            
            disp@Carga(cargaVigaPuntualObj);
            
            % Obtiene la etiqueta del elemento
            etiqueta = cargaVigaPuntualObj.elemObj.obtenerEtiqueta();
            
            % Obtiene la etiqueta del primer nodo
            nodo1etiqueta = cargaVigaPuntualObj.elemObj.obtenerNodos();
            nodo1etiqueta = nodo1etiqueta{1}.obtenerEtiqueta();
            
            fprintf('\tCarga: %.3f aplicada en Elemento:%s a %.3f del Nodo:%s\n', ...
                cargaVigaPuntualObj.carga, etiqueta, cargaVigaPuntualObj.dist, nodo1etiqueta);
            
        end % disp function
        
    end % methods CargaVigaPuntual
    
end % class CargaVigaPuntual