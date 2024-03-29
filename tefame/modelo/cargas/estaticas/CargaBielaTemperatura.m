%|______________________________________________________________________|
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
%| Repositorio: https://github.com/ppizarror/TEFAME                     |
%|______________________________________________________________________|
%|                                                                      |
%| Clase CargaBielaTemperatura                                          |
%|                                                                      |
%| Este archivo contiene la definicion de la Clase CargaBielaTemperatura|
%| CargaBielaTemperatura es una subclase de la clase Carga y corresponde|
%| a la representacion de una carga producto de un incremento de la     |
%| temperatura en una biela, que genera esfuerzos axiales dependiendo de|
%| dT.                                                                  |
%| La clase CargaBielaTemperatura es una clase que contiene el elemento |
%| al que se le va a aplicar la diferencia de temperatura y el coefici- |
%| ente de dilatacion del material alpha.                               |
%|______________________________________________________________________|
%|                                                                      |
%| MIT License                                                          |
%| Copyright (c) 2018-2019 Pablo Pizarro R @ppizarror.com.              |
%|                                                                      |
%| Permission is hereby granted, free of charge, to any person obtai-   |
%| ning a copy of this software and associated documentation files (the |
%| "Software"), to deal in the Software without restriction, including  |
%| without limitation the rights to use, copy, modify, merge, publish,  |
%| distribute, sublicense, and/or sell copies of the Software, and to   |
%| permit persons to whom the Software is furnished to do so, subject   |
%| to the following conditions:                                         |
%|                                                                      |
%| The above copyright notice and this permission notice shall be       |
%| included in all copies or substantial portions of the Software.      |
%|                                                                      |
%| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,      |
%| EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF   |
%| MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.|
%| IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY |
%| CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, |
%| TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE    |
%| SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.               |
%|______________________________________________________________________|
%
%  Methods(Access=public):
%       obj = CargaBielaTemperatura(etiquetaCarga,elemObjeto,deltaTemperatura,alpha)
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

classdef CargaBielaTemperatura < CargaEstatica
    
    properties(Access = private)
        alpha % Coeficiente de dilatacion termica de la biela
        carga % Carga generada por la temperatura
        deltaTemperatura % Diferencia de temperatura aplicada al material
        elemObj % Variable que guarda el elemento que se le va a aplicar la carga
    end % private properties CargaBielaTemperatura
    
    methods(Access = public)
        
        function obj = CargaBielaTemperatura(etiquetaCarga, elemObjeto, deltaTemperatura, alpha)
            % CargaBielaTemperatura: es el constructor de la clase CargaBielaTemperatura
            %
            % Crea un objeto de la clase CargaBielaTemperatura, en donde toma como atributo
            % el objeto a aplicar la carga, la diferencia de temperatura y
            % el coeficiente de dilatacion termica del material (alpha)
            
            if nargin == 0
                etiquetaCarga = '';
                deltaTemperatura = 0;
                alpha = 0;
            end
            
            % Llamamos al constructor de la SuperClass que es la clase
            % CargaEstatica
            obj = obj@CargaEstatica(etiquetaCarga);
            
            % Guarda los valores
            obj.deltaTemperatura = deltaTemperatura;
            obj.alpha = alpha;
            obj.elemObj = elemObjeto;
            obj.nodosCarga = elemObjeto.obtenerNodos();
            
            % Crea la carga
            obj.carga = elemObjeto.obtenerAE() * deltaTemperatura * alpha;
            
        end % CargaBielaTemperatura constructor
        
        function c = calcularCarga(obj)
            % calcularCarga: Calcula la carga
            
            c = obj.carga;
            
        end % calcularCarga function
        
        function masa = obtenerMasa(obj)
            % obtenerMasa: Obtiene la masa asociada a la carga
            
            c = obj.calcularCarga();
            masa = abs(c) .* (obj.factorCargaMasa * obj.factorUnidadMasa);
            
        end % obtenerMasa function
        
        function aplicarCarga(obj, factorDeCarga)
            % aplicarCarga: es un metodo de la clase CargaBielaTemperatura
            % que se usa para aplicar la carga en los nodos
            
            % Obtiene el angulo de la Biela
            theta = obj.elemObj.obtenerAngulo();
            
            % Carga sin cambiar el angulo
            c = obj.calcularCarga();
            
            % Genera las cargas nodales
            vectorCarga1 = factorDeCarga * [-c * cos(theta), -c * sin(theta)]';
            vectorCarga2 = factorDeCarga * [c * cos(theta), c * sin(theta)]';
            obj.elemObj.sumarCargaTemperaturaReaccion( ...
                factorDeCarga*[vectorCarga1(1), vectorCarga1(2), vectorCarga2(1), vectorCarga2(2)]');
            
            % Aplica vectores de carga
            nodos = obj.elemObj.obtenerNodos();
            nodos{1}.agregarCarga(vectorCarga1);
            nodos{2}.agregarCarga(vectorCarga2);
            
        end % aplicarCarga function
        
        function disp(obj)
            % disp: es un metodo de la clase CargaBielaTemperatura que se usa para imprimir en
            % command Window la informacion de la carga generada en los
            % nodos fruto de la diferencia de temperatura y el coeficiente
            % del material
            %
            % Imprime la informacion guardada en la carga fruto de la
            % diferencia de temperatura de la Biela (obj)
            % en pantalla
            
            fprintf('Propiedades carga biela temperatura:\n');
            disp@CargaEstatica(obj);
            
            % Obtiene la etiqueta del elemento
            etiqueta = obj.elemObj.obtenerEtiqueta();
            
            fprintf('\tCarga: %.3f aplicada en Elemento: %s producto de una diferencia de temperatura: %.3f\n', ...
                obj.carga, etiqueta, obj.deltaTemperatura);
            dispMetodoTEFAME();
            
        end % disp function
        
    end % public methods CargaBielaTemperatura
    
end % class CargaBielaTemperatura