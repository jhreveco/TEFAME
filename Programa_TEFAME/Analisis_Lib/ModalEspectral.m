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
%|       Pablo Pizarro                                                  |
%|       Estudiante de Magister en Ingenieria Civil Estructural         |
%|       Universidad de Chile                                           |
%|______________________________________________________________________|
% ______________________________________________________________________
%|                                                                      |
%| Clase ModalEspectral                                                 |
%|                                                                      |
%| Este archivo contiene la definicion de la Clase ModalEspectral       |
%| ModalEspectral es una clase que se usa para resolver la estructura   |
%| aplicando el metodo modal espectral. Para ello se calcula la matriz  |
%| de masa y de rigidez.                                                |
%|                                                                      |
%| Programado: Pablo Pizarro @ppizarror                                 |
%| Fecha: 18/03/2019                                                    |
%|______________________________________________________________________|
%
%  Properties (Access=private):
%       modeloObj
%       numeroGDL
%       Kt
%       F
%       u
%       wn
%       Tn
%       phin
%       Mm
%       Km
%       r
%       Lm
%       Mmeff
%       Mmeffacum
%       Mmeffacump
%
%  Methods:
%       analisisObj = ModalEspectral(modeloObjeto)
%       definirNumeracionGDL(analisisObj)
%       analizar(analisisObj)
%       ensamblarMatrizRigidez(analisisObj)
%       ensamblarMatrizMasa(analisisObj)
%       ensamblarVectorFuerzas(analisisObj)
%       numeroEquaciones = obtenerNumeroEquaciones(analisisObj)
%       K_Modelo = obtenerMatrizRigidez(analisisObj)
%       M_Modelo = obtenerMatrizMasa(analisisObj)
%       F_Modelo = obtenerVectorFuerzas(analisisObj)
%       u_Modelo = obtenerDesplazamientos(analisisObj)
%       plot(analisisObj)
%       disp(analisisObj)

classdef ModalEspectral < handle
    
    properties(Access = private)
        modeloObj % Guarda el objeto que contiene el modelo
        numeroGDL % Guarda el numero de grados de libertad totales del modelo
        Kt % Matriz de Rigidez del modelo
        Mt % Matriz de Masa del modelo
        gdlCond % Grados de libertad condensados
        F % Vector de Fuerzas aplicadas sobre el modelo
        u % Vector con los desplazamientos de los grados de libertad del modelo
        wn % Frecuencias del sistema
        Tn % Periodos del sistema
        phin % Vectores propios del sistema
        phinExt % Vector propio del sistema extendido considerando grados condensados
        Mm % Matriz masa modal
        Km % Matriz rigidez modal
        rm % Vector influencia
        Lm % Factor de participacion modal
        Mmeff % Masa modal efectiva
        Mmeffacum % Masa modal efectiva acumulada
        Mtotal % Masa total del modelo
        analisisFinalizado % Indica que el analisis ha sido realizado
        numModos % Numero de modos del analisis
        numDG % Numero de grados de libertad por modo despues del analisis
        cRayleigh % Matriz de amortiguamiento de Rayleigh
        cPenzien % Matriz de amortiguamiento de Wilson-Penzien
        mostrarDeformada % Muestra la posicion no deformada en los graficos
    end % properties ModalEspectral
    
    methods
        
        function analisisObj = ModalEspectral(modeloObjeto)
            % ModalEspectral: es el constructor de la clase ModalEspectral
            %
            % analisisObj = ModalEspectral(modeloObjeto)
            % Crea un objeto de la clase ModalEspectral, y guarda el modelo,
            % que necesita ser analizado
            
            if nargin == 0
                modeloObjeto = [];
            end % if
            
            analisisObj.modeloObj = modeloObjeto;
            analisisObj.numeroGDL = 0;
            analisisObj.Kt = [];
            analisisObj.Mt = [];
            analisisObj.u = [];
            analisisObj.F = [];
            analisisObj.analisisFinalizado = false;
            analisisObj.mostrarDeformada = false;
            
        end % ModalEspectral constructor
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para definir y analizar el modelo
        
        function definirNumeracionGDL(analisisObj)
            % definirNumeracionGDL: es un metodo de la clase ModalEspectral que
            % se usa para definir como se enumeran los GDL en el modelo
            %
            % definirNumeracionGDL(analisisObj)
            % Define y asigna la enumeracion de los GDL en el modelo
            
            % Primero se aplican las restricciones al modelo
            analisisObj.modeloObj.aplicarRestricciones();
            
            % Extraemos los nodos para que sean enumerados
            nodoObjetos = analisisObj.modeloObj.obtenerNodos();
            numeroNodos = length(nodoObjetos);
            
            % Inicializamos en cero el contador de GDL
            contadorGDL = 0;
            
            for i = 1:numeroNodos
                
                gdlidNodo = nodoObjetos{i}.obtenerGDLID;
                
                % Si no es reaccion entonces se agrega como GDL
                for j = 1:length(gdlidNodo)
                    if (gdlidNodo(j) == -1)
                        contadorGDL = contadorGDL + 1;
                        gdlidNodo(j) = contadorGDL;
                    end % if
                end % for j
                nodoObjetos{i}.definirGDLID(gdlidNodo);
                
            end % for i
            
            % Guardamos el numero de GDL, es decir el numero de ecuaciones
            % del sistema
            analisisObj.numeroGDL = contadorGDL;
            
            % Extraemos los Elementos del modelo
            elementoObjetos = analisisObj.modeloObj.obtenerElementos();
            numeroElementos = length(elementoObjetos);
            
            % Definimos los GDLID en los elementos para poder formar la matriz de rigidez
            for i = 1:numeroElementos
                elementoObjetos{i}.definirGDLID();
            end % for i
            
        end % definirNumeracionGDL function
        
        function analizar(analisisObj, nModos, betacR, betacP, maxcond)
            % analizar: es un metodo de la clase ModalEspectral que se usa para
            % realizar el analisis estatico
            %
            % analizar(analisisObj,nModos,betacR,betacP,maxcond)
            % Analiza estaticamente el modelo lineal y elastico sometido a un
            % set de cargas, requiere el numero de modos para realizar el
            % analisis y de los modos conocidos con sus beta
            
            % Ajusta variables de entrada
            if ~exist('nModos', 'var')
                nModos = 20;
            end
            if ~exist('maxcond', 'var')
                maxcond = 0.001;
            end
            fprintf('Ejecuntando analisis modal espectral:\n\tNumero de modos: %d\n', nModos);
            
            % Se definen los grados de libertad por nodo -> elementos
            analisisObj.definirNumeracionGDL();
            
            % Se aplica patron de carga
            analisisObj.modeloObj.aplicarPatronesDeCargas();
            
            % Se calcula la matriz de rigidez
            analisisObj.ensamblarMatrizRigidez();
            
            % Se calcula la matriz de masa
            analisisObj.ensamblarMatrizMasa();
            diagMt = diag(analisisObj.Mt);
            analisisObj.Mtotal = sum(diagMt);
            
            % Se ensambla el vector de fuerzas
            analisisObj.ensamblarVectorFuerzas();
            
            % Obtiene los grados de libertad
            ngdl = length(analisisObj.Mt); % Numero de grados de libertad
            ngdlExt = ngdl;
            ndg = analisisObj.modeloObj.obtenerNumerosGDL(); % Grados de libertad por nodo
            
            % ---------------- CONDENSACION ESTATICA DE GUYAN ---------------
            % Primero se genera matriz para reordenar elementos (rot)
            vz = []; % Vector que identifica indices a condensar
            j = 1;
            if maxcond >= 0
                for i = 1:length(diagMt)
                    if diagMt(i) <= maxcond
                        vz(j) = i; %#ok<AGROW>
                        j = j + 1;
                    end
                end
            end
            
            % Si condensa grados
            analisisObj.gdlCond = length(vz);
            if analisisObj.gdlCond > 0
                
                % Chequea cuantos grados quedan
                nndg = ndg;
                if ndg > 2
                    for i = 2:ndg
                        % Si todos los grados se dividen por 3, entonces se borra
                        % el tercer grado de libertad (giro por ejemplo)
                        if allDivMod(vz, i)
                            nndg = nndg - 1;
                        end
                    end
                end
                ndg = nndg;
                
                lpasivos = length(vz);
                lactivos = length(diagMt) - lpasivos;
                rot = zeros(length(diagMt), length(diagMt));
                aux0 = 1;
                aux1 = 1;
                aux2 = length(diagMt) - lpasivos + 1;
                for i = 1:1:length(rot)
                    if aux0 <= length(vz) && i == vz(aux0)
                        rot(i, aux2) = 1;
                        aux2 = aux2 + 1;
                        aux0 = aux0 + 1;
                    else
                        rot(i, aux1) = 1;
                        aux1 = aux1 + 1;
                    end
                end
                
                % Se realiza rotacion de matriz de rigidez
                Krot = rot' * analisisObj.Kt * rot;
                
                % Se determina matriz de rigidez condensada (Keq)
                Kaa = Krot(1:lactivos, 1:lactivos);
                Kap = Krot(1:lactivos, lactivos+1:end);
                Kpa = Krot(lactivos+1:end, 1:lactivos);
                Kpp = Krot(lactivos+1:end, lactivos+1:end);
                Keq = Kaa - Kap * Kpp^(-1) * Kpa;
                
                % Se determina matriz de masa condensada (Meq)
                Meq = analisisObj.Mt;
                j = 0;
                for i = 1:1:length(vz)
                    Meq(vz(i)-j, :) = [];
                    Meq(:, vz(i)-j) = [];
                    j = j + 1;
                end
                
                % Actualiza los grados
                cngdl = length(Meq);
                if cngdl < ngdl
                    fprintf('\tSe han condensado %d grados de libertad\n', ngdl-cngdl);
                    ngdl = cngdl;
                end
                
            else % No condensa grados
                Meq = analisisObj.Mt;
                Keq = analisisObj.Kt;
                fprintf('\tNo se han condensado grados de libertad\n');
            end
            
            fprintf('\tGrados de libertad totales: %d\n', ngdl);
            fprintf('\tNumero de direcciones de analisis: %d\n', ndg);
            nModos = min(nModos, ngdl);
            analisisObj.numModos = nModos;
            
            %--------------------------------------------------------------
            
            % Resuelve la ecuacion del sistema, para ello crea la matriz
            % inversa de la masa y calcula los valores propios
            invMt = zeros(ngdl, ngdl);
            for i = 1:ngdl
                invMt(i, i) = 1 / Meq(i, i);
            end
            sysMat = invMt * Keq;
            
            [modalPhin, syseig] = eigs(sysMat, nModos, 'smallestabs');
            syseig = diag(syseig);
            
            % Calcula las frecuencias del sistema
            modalWn = sqrt(syseig);
            modalTn = (modalWn.^-1) .* 2 * pi; % Calcula los periodos
            
            % Calcula las matrices
            modalMmt = modalPhin' * Meq * modalPhin;
            modalPhin = modalPhin * diag(diag(modalMmt).^-0.5);
            modalMm = diag(diag(modalPhin'*Meq*modalPhin));
            modalKm = diag(diag(modalPhin'*Keq*modalPhin));
            
            % Reordena los periodos
            Torder = zeros(nModos, 1);
            Tpos = 1;
            for i = 1:nModos
                maxt = 0; % Periodo
                maxi = 0; % Indice
                for j = 1:nModos % Se busca el elemento para etiquetar
                    if Torder(j) == 0 % Si aun no se ha etiquetado
                        if modalTn(j) > maxt
                            maxt = modalTn(j);
                            maxi = j;
                        end
                    end
                end
                Torder(maxi) = Tpos;
                Tpos = Tpos + 1;
            end
            
            % Asigna valores
            analisisObj.Tn = zeros(nModos, 1);
            analisisObj.wn = zeros(nModos, 1);
            analisisObj.phin = zeros(ngdl, nModos);
            analisisObj.Mm = modalMm;
            analisisObj.Km = modalKm;
            for i = 1:nModos
                analisisObj.Tn(Torder(i)) = modalTn(i);
                analisisObj.wn(Torder(i)) = modalWn(i);
                analisisObj.phin(:, Torder(i)) = modalPhin(:, i);
            end
            
            % Crea vector influencia
            analisisObj.rm = zeros(ngdl, ndg);
            for j = 1:ndg
                for i = 1:ngdl
                    if mod(i, ndg) == j || (mod(i, ndg) == 0 && j == ndg)
                        analisisObj.rm(i, j) = 1;
                    end
                end
            end
            
            % Realiza el calculo de las participaciones modales
            analisisObj.Lm = zeros(nModos, ndg);
            analisisObj.Mmeff = zeros(ngdl, ndg);
            analisisObj.Mmeffacum = zeros(ngdl, ndg);
            Mtotr = zeros(ndg, 1);
            
            % Recorre cada grado de libertad (horizontal, vertical, giro)
            for j = 1:ndg
                Mtotr(j) = sum(Meq*analisisObj.rm(:, j));
                for k = 1:nModos
                    analisisObj.Lm(k, j) = analisisObj.phin(:, k)' * Meq * analisisObj.rm(:, j);
                    analisisObj.Mmeff(k, j) = analisisObj.Lm(k, j).^2 ./ modalMm(k, k);
                end
                
                analisisObj.Mmeff(:, j) = analisisObj.Mmeff(:, j) ./ Mtotr(j);
                analisisObj.Mmeffacum(1, j) = analisisObj.Mmeff(1, j);
                for i = 2:nModos
                    analisisObj.Mmeffacum(i, j) = analisisObj.Mmeffacum(i-1, j) + analisisObj.Mmeff(i, j);
                end
            end
            
            % Crea la matriz extendida de los modos, dejando en cero los
            % condensados
            if ngdlExt ~= ngdl
                analisisObj.phinExt = zeros(ngdlExt, nModos);
                k = 1; % Mantiene el indice entre (1, ngdl)
                for j = 1:ngdlExt
                    if isArrayMember(vz, j)
                        for i = 1:nModos
                            analisisObj.phinExt(j, i) = 0;
                        end
                    else
                        for i = 1:nModos
                            analisisObj.phinExt(j, i) = analisisObj.phin(k, i);
                        end
                        k = k + 1;
                    end
                end
            else
                analisisObj.phinExt = analisisObj.phin;
            end
            
            % -------- CALCULO DE AMORTIGUAMIENTO DE RAYLEIGH -------------
            
            % Se declaran dos amortiguamientos criticos asociados a dos modos
            % diferentes indicando si es horizontal o vertical (h o v)
            modocR = [1, 3];
            direcR = ['h', 'h'];
            countcR = [0, 0];
            m = 0;
            n = 0;
            for i = 1:nModos
                if analisisObj.Mmeff(i, 1) > max(analisisObj.Mmeff(i, 2:ndg))
                    countcR(1) = countcR(1) + 1;
                    if direcR(1) == 'h' && modocR(1) == countcR(1)
                        m = i;
                    elseif direcR(2) == 'h' && modocR(2) == countcR(1)
                        n = i;
                    end
                elseif analisisObj.Mmeff(i, 2) > max(analisisObj.Mmeff(i, 1), analisisObj.Mmeff(i, max(1, ndg)))
                    countcR(2) = countcR(2) + 1;
                    if direcR(1) == 'v' && modocR(1) == countcR(2)
                        m = i;
                    elseif direcR(2) == 'h' && modocR(2) == countcR(2)
                        n = i;
                    end
                end
            end
            if m == 0 || n == 0
                error('\tSe requiere aumentar el numero de modos para determinar matriz de amortiguamiento de Rayleigh')
            end
            w = analisisObj.wn;
            a = (2 * w(m) * w(n)) / (w(n)^2 - w(m)^2) .* [w(n), -w(m); ...
                -1 / w(n), 1 / w(m)] * betacR';
            analisisObj.cRayleigh = a(1) .* analisisObj.Mt + a(2) .* analisisObj.Kt;
            
            % ------ CALCULO DE AMORTIGUAMIENTO DE WILSON-PENZIEN ----------
            
            % Se declaran todos los amortiguamientos criticos del sistema,
            % (horizontal, vertical y traslacional)
            d = zeros(nModos, nModos);
            w = analisisObj.wn;
            Mn = modalMmt;
            for i = 1:nModos
                if analisisObj.Mmeff(i, 1) > max(analisisObj.Mmeff(i, 2:ndg))
                    d(i, i) = 2 * betacP(1) * w(i) / Mn(i, i);
                elseif analisisObj.Mmeff(i, 2) > max(analisisObj.Mmeff(i, 1), analisisObj.Mmeff(i, max(1, ndg)))
                    d(i, i) = 2 * betacP(2) * w(i) / Mn(i, i);
                else
                    d(i, i) = 2 * betacP(3) * w(i) / Mn(i, i);
                end
            end
            analisisObj.cPenzien = Meq * modalPhin * d * modalPhin' * Meq;
            
            %--------------------------------------------------------------
            
            % Termina el analisis
            analisisObj.analisisFinalizado = true;
            analisisObj.numDG = ndg;
            fprintf('\n');
            
        end % analizar function
        
        function ensamblarMatrizRigidez(analisisObj)
            % ensamblarMatrizRigidez: es un metodo de la clase ModalEspectral que se usa para
            % realizar el armado de la matriz de rigidez del modelo analizado
            %
            % ensamblarMatrizRigidez(analisisObj)
            % Ensambla la matriz de rigidez del modelo analizado usando el metodo
            % indicial
            
            analisisObj.Kt = zeros(analisisObj.numeroGDL, analisisObj.numeroGDL);
            
            % Extraemos los Elementos
            elementoObjetos = analisisObj.modeloObj.obtenerElementos();
            numeroElementos = length(elementoObjetos);
            
            % Definimos los GDLID en los elementos
            for i = 1:numeroElementos
                
                % Se obienen los gdl del elemento metodo indicial
                gdl = elementoObjetos{i}.obtenerGDLID();
                ngdl = elementoObjetos{i}.obtenerNumeroGDL;
                
                % Se obtiene la matriz de rigidez global del elemento-i
                k_globl_elem = elementoObjetos{i}.obtenerMatrizRigidezCoordGlobal();
                
                % Se calcula el metodo indicial
                for r = 1:ngdl
                    for s = 1:ngdl
                        i_ = gdl(r);
                        j_ = gdl(s);
                        
                        % Si corresponden a grados de libertad -> puntos en (i,j)
                        % se suma contribucion metodo indicial
                        if (i_ ~= 0 && j_ ~= 0)
                            analisisObj.Kt(i_, j_) = analisisObj.Kt(i_, j_) + k_globl_elem(r, s);
                        end
                        
                    end % for s
                end % for r
                
            end % for i
            
        end % ensamblarMatrizRigidez function
        
        function ensamblarMatrizMasa(analisisObj)
            % ensamblarMatrizMasa: es un metodo de la clase ModalEspectral que se usa para
            % realizar el armado de la matriz de masa del modelo
            %
            % ensamblarMatrizMasa(analisisObj)
            % Ensambla la matriz de masa del modelo analizado usando el metodo
            % indicial
            
            analisisObj.Mt = zeros(analisisObj.numeroGDL, analisisObj.numeroGDL);
            
            % Extraemos los Elementos
            elementoObjetos = analisisObj.modeloObj.obtenerElementos();
            numeroElementos = length(elementoObjetos);
            
            % Definimos los GDLID en los elementos
            for i = 1:numeroElementos
                
                % Se obienen los gdl del elemento metodo indicial
                gdl = elementoObjetos{i}.obtenerGDLID();
                ngdl = elementoObjetos{i}.obtenerNumeroGDL;
                
                % Se obtiene la matriz de masa
                m_elem = elementoObjetos{i}.obtenerMatrizMasa();
                
                % Se calcula el metodo indicial
                for r = 1:ngdl
                    for s = 1:ngdl
                        i_ = gdl(r);
                        j_ = gdl(s);
                        
                        % Si corresponden a grados de libertad -> puntos en (i,j)
                        % se suma contribucion metodo indicial
                        if (i_ ~= 0 && j_ ~= 0 && r == s)
                            analisisObj.Mt(i_, j_) = analisisObj.Mt(i_, j_) + m_elem(r);
                        end
                        
                    end % for s
                end % for r
                
            end % for i
            
            % Agrega las cargas de los nodos
            nodoObjetos = analisisObj.modeloObj.obtenerNodos();
            numeroNodos = length(nodoObjetos);
            
            for i = 1:numeroNodos
                gdlidNodo = nodoObjetos{i}.obtenerGDLID; % (x, y, giro)
                gly = gdlidNodo(2);
                carga = nodoObjetos{i}.obtenerReacciones(); % (x, y, giro)
                if gly == 0
                    continue;
                end
                analisisObj.Mt(gly, gly) = analisisObj.Mt(gly, gly) + carga(2);
            end
            
            % Chequea que la matriz de masa sea consistente
            for i = 1:analisisObj.numeroGDL
                if analisisObj.Mt(i, i) <= 0
                    error('La matriz de masa esta mal definida, Mt(%d,%d)<=0', i, i);
                end
                analisisObj.Mt(i, i) = analisisObj.Mt(i, i) / 9.80665; % [tonf->ton]
            end
            
        end % ensamblarMatrizMasa function
        
        function ensamblarVectorFuerzas(analisisObj)
            % ensamblarVectorFuerzas: es un metodo de la clase ModalEspectral que se usa para
            % realizar el armado del vector de fuerzas del modelo analizado
            %
            % ensamblarMatrizRigidez(analisisObj)
            % Ensambla el vector de fuerzas del modelo analizado usando el metodo
            % indicial
            
            analisisObj.F = zeros(analisisObj.numeroGDL, 1);
            
            % En esta funcion se tiene que ensamblar el vector de fuerzas
            % Extraemos los nodos
            nodoObjetos = analisisObj.modeloObj.obtenerNodos();
            numeroNodos = length(nodoObjetos);
            
            % Definimos los GDLID en los nodos
            for i = 1:numeroNodos
                
                ngdlid = nodoObjetos{i}.obtenerNumeroGDL(); % Numero grados de libertad del nodo
                gdl = nodoObjetos{i}.obtenerGDLID(); % Grados de libertad del nodo
                reacc = nodoObjetos{i}.obtenerReacciones(); % Reacciones del nodo
                
                % Recorre cada grado de libertad, si no es cero entonces
                % hay una carga aplicada en ese grado de libertad para
                % lograr el equilibrio
                for j = 1:ngdlid
                    if (gdl(j) ~= 0)
                        analisisObj.F(gdl(j)) = -reacc(j);
                    end
                end % for j
                
            end % for i
            
        end % ensamblarVectorFuerzas function
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para obtener la informacion del analisis
        
        function numeroEquaciones = obtenerNumeroEquaciones(analisisObj)
            % obtenerNumeroEquaciones: es un metodo de la clase ModalEspectral
            % que se usa para obtener el numero total de GDL, es decir, ecuaciones
            % del modelo
            %
            % numeroEquaciones = obtenerNumeroEquaciones(analisisObj)
            % Obtiene el numero total de GDL (numeroEquaciones) que esta guardado
            % en el Analisis (analisisObj)
            
            numeroEquaciones = analisisObj.numeroGDL;
            
        end % obtenerNumeroEquaciones function
        
        function K_Modelo = obtenerMatrizRigidez(analisisObj)
            % obtenerMatrizRigidez: es un metodo de la clase ModalEspectral
            % que se usa para obtener la matriz de rigidez del modelo
            %
            % K_Modelo = obtenerMatrizRigidez(analisisObj)
            % Obtiene la matriz de rigidez (K_Modelo) del modelo que se genero
            % en el Analisis (analisisObj)
            
            K_Modelo = analisisObj.Kt;
            
        end % obtenerMatrizRigidez function
        
        function M_Modelo = obtenerMatrizMasa(analisisObj)
            % obtenerMatrizMasa: es un metodo de la clase ModalEspectral
            % que se usa para obtener la matriz de masa del modelo
            %
            % M_Modelo = obtenerMatrizRigidez(analisisObj)
            % Obtiene la matriz de masa (M_Modelo) del modelo que se genero
            % en el Analisis (analisisObj)
            
            M_Modelo = analisisObj.Mt;
            
        end % obtenerMatrizMasa function
        
        function F_Modelo = obtenerVectorFuerzas(analisisObj)
            % obtenerMatrizRigidez: es un metodo de la clase ModalEspectral
            % que se usa para obtener el vector de fuerza del modelo
            %
            % F_Modelo = obtenerVectorFuerzas(analisisObj)
            % Obtiene el vector de fuerza (F_Modelo) del modelo que se genero
            % en el Analisis (analisisObj)
            
            F_Modelo = analisisObj.F;
            
        end % obtenerVectorFuerzas function
        
        function u_Modelo = obtenerDesplazamientos(analisisObj)
            % obtenerDesplazamientos: es un metodo de la clase ModalEspectral
            % que se usa para obtener el vector de desplazamiento del modelo
            % obtenido del analisis
            %
            % u_Modelo = obtenerDesplazamientos(analisisObj)
            % Obtiene el vector de desplazamiento (u_Modelo) del modelo que se
            % genero como resultado del Analisis (analisisObj)
            
            u_Modelo = analisisObj.u;
            
        end % obtenerDesplazamientos function
        
        function wn_Modelo = obtenerValoresPropios(analisisObj)
            % obtenerValoresPropios: es un metodo de la clase ModalEspectral
            % que se usa para obtener los valores propios del modelo
            % obtenido del analisis
            %
            % w_Modelo = obtenerValoresPropios(analisisObj)
            % Obtiene los valores propios (wn_Modelo) del modelo que se
            % genero como resultado del Analisis (analisisObj)
            
            wn_Modelo = analisisObj.wn;
            
        end % obtenerDesplazamientos function
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para graficar la estructura
        
        function activar_plot_deformada(analisisObj)
            % Activa el grafico de la deformada
            
            analisisObj.mostrarDeformada = true;
            
        end % activar_plot_deformada function
        
        function plt = plot(analisisObj, modo, factor, numCuadros, guardaGif)
            %PLOTMODELO Grafica un modelo
            %
            % plt = plot(analisisObj,modo,factor,numCuadros,guardaGif)
            
            deformada = false;
            if exist('modo', 'var')
                deformada = true;
            end
            
            if ~exist('factor', 'var')
                factor = 2;
            end
            
            if ~exist('numCuadros', 'var')
                numCuadros = 0;
            end
            
            guardarGif = false;
            if exist('guardaGif', 'var')
                guardarGif = true;
                guardaGif = sprintf(guardaGif, modo);
            else
                guardaGif = tempname;
            end
            
            modo = ceil(modo);
            if modo > analisisObj.numModos || modo <= 0
                error('El modo a graficar %d excede la cantidad de modos del sistema (%d)', ...
                    modo, analisisObj.numModos);
            end
            
            % Obtiene el periodo
            tn = analisisObj.Tn(modo);
            
            % Calcula los limites
            [limx, limy, limz] = analisisObj.obtenerLimitesDeformada(modo, factor);
            
            % Grafica la estructura
            plt = figure();
            fig_num = get(gcf, 'Number');
            movegui('center');
            hold on;
            grid on;
            % axis tight manual;
            % set(gca, 'nextplot', 'replacechildren');
            
            plotAnimado(analisisObj, deformada, modo, factor, 1, limx, limy, limz, tn, 1, 1);
            hold off;
            fprintf('Generando animacion analisis modal espectral:\n');
            if numCuadros ~= 0
                
                % Obtiene el numero de cuadros
                t = 0;
                dt = 2 * pi / numCuadros;
                reverse_porcent = '';
                
                % Crea la estructura de cuadros
                Fr(numCuadros) = struct('cdata', [], 'colormap', []);
                
                for i = 1:numCuadros
                    
                    % Si el usuario cierra el plot termina de graficar
                    if ~ishandle(plt) || ~ishghandle(plt)
                        delete(plt);
                        close(fig_num); % Cierra el grafico
                        fprintf('\n\tSe ha cancelado el proceso del grafico\n');
                        return;
                    end
                    
                    t = t + dt;
                    try
                        figure(fig_num); % Atrapa el foco
                        plotAnimado(analisisObj, deformada, modo, factor, sin(t), limx, limy, limz, tn, i, numCuadros);
                        drawnow;
                        Fr(i) = getframe(plt);
                        im = frame2im(Fr(i));
                        [imind, cm] = rgb2ind(im, 256);
                        if i == 1
                            imwrite(imind, cm, guardaGif, 'gif', 'Loopcount', inf, 'DelayTime', 0.1);
                        else
                            imwrite(imind, cm, guardaGif, 'gif', 'WriteMode', 'append', 'DelayTime', 0.1);
                        end
                    catch
                        fprintf('\n\tSe ha cancelado el proceso del grafico\n');
                        return;
                    end
                    hold off;
                    
                    msg = sprintf('\tCalculando... %.1f/100', i/numCuadros*100);
                    fprintf([reverse_porcent, msg]);
                    reverse_porcent = repmat(sprintf('\b'), 1, length(msg));
                    
                end % i = 1:numCuadros
                
                if guardarGif
                    fprintf('\n\tGuardando animacion gif en: %s', guardaGif);
                end
                
                % Reproduce la pelicula y cierra el grafico anterior
                close(fig_num);
                fprintf('\n\tAbriendo animacion\n');
                try
                    gifPlayerGUI(guardaGif, 1/min(numCuadros, 60));
                catch
                end
                
            end
            fprintf('\n');
            
        end % plot function
        
        function plotAnimado(analisisObj, deformada, modo, factor, phif, limx, limy, limz, per, cuadro, totCuadros)
            % Anima el grafico en funcion del numero del modo
            %
            % plotAnimado(analisisObj,deformada,modo,factor,phif,limx,limy,limz,per,cuadro,totCuadros)
            
            % Carga objetos
            nodoObjetos = analisisObj.modeloObj.obtenerNodos();
            numeroNodos = length(nodoObjetos);
            
            % Obtiene cuantos GDL tiene el modelo
            gdl = 2;
            j = 1;
            for i = 1:numeroNodos
                coords = nodoObjetos{i}.obtenerCoordenadas();
                ngdlid = length(coords);
                gdl = max(gdl, ngdlid);
                
                if ~nodoObjetos{i}.tipoApoyoRestringido() && ~deformada
                    if ngdlid == 2
                        plot(coords(1), coords(2), 'b.', 'MarkerSize', 10);
                    else
                        plot3(coords(1), coords(2), coords(3), 'b.', 'MarkerSize', 10);
                    end
                    if j == 1
                        hold on;
                    end
                    j = j + 1;
                end
                
            end
            
            % Grafica los elementos
            elementoObjetos = analisisObj.modeloObj.obtenerElementos();
            numeroElementos = length(elementoObjetos);
            
            for i = 1:numeroElementos
                
                % Se obienen los gdl del elemento metodo indicial
                nodoElemento = elementoObjetos{i}.obtenerNodos();
                coord1 = nodoElemento{1}.obtenerCoordenadas();
                coord2 = nodoElemento{2}.obtenerCoordenadas();
                
                if ~deformada || analisisObj.mostrarDeformada
                    if gdl == 2
                        plot([coord1(1), coord2(1)], [coord1(2), coord2(2)], 'b-', 'LineWidth', 0.5);
                    else
                        plot3([coord1(1), coord2(1)], [coord1(2), coord2(2)], [coord1(3), coord2(3)], ...
                            'b-', 'LineWidth', 0.5);
                    end
                end
                
                if deformada
                    
                    def1 = analisisObj.obtenerDeformadaNodo(nodoElemento{1}, modo, gdl);
                    def2 = analisisObj.obtenerDeformadaNodo(nodoElemento{2}, modo, gdl);
                    
                    % Suma las deformaciones
                    coord1 = coord1 + def1 .* factor * phif;
                    coord2 = coord2 + def2 .* factor * phif;
                    
                    % Grafica
                    if gdl == 2
                        plot([coord1(1), coord2(1)], [coord1(2), coord2(2)], 'k-', 'LineWidth', 1.25);
                    else
                        plot3([coord1(1), coord2(1)], [coord1(2), coord2(2)], [coord1(3), coord2(3)], ...
                            'k-', 'LineWidth', 1.25);
                    end
                    if i == 1
                        hold on;
                    end
                    
                end
                
            end
            
            % Grafica los nodos deformados
            if deformada
                for i = 1:numeroNodos
                    coords = nodoObjetos{i}.obtenerCoordenadas();
                    ngdlid = length(coords);
                    gdl = max(gdl, ngdlid);
                    def = analisisObj.obtenerDeformadaNodo(nodoObjetos{i}, modo, gdl);
                    coords = coords + def .* factor * phif;
                    
                    if ~nodoObjetos{i}.tipoApoyoRestringido()
                        if ngdlid == 2
                            plot(coords(1), coords(2), 'k.', 'MarkerSize', 20);
                        else
                            plot3(coords(1), coords(2), coords(3), 'k.', 'MarkerSize', 20);
                        end
                    end
                    
                end
                
            end
            
            % Setea el titulo
            if ~deformada
                title('Analisis modal espectral');
            else
                a = sprintf('Analisis modal espectral - Modo %d (T: %.3fs)', modo, per);
                if totCuadros > 1
                    b = sprintf('Escala deformacion x%d - Cuadro %s/%d', ...
                        factor, padFillNum(cuadro, totCuadros), totCuadros);
                else
                    b = sprintf('Escala deformacion x%d', factor);
                end
                title({a; b});
            end
            grid on;
            
            % Limita en los ejes
            if limx(1) < limx(2)
                xlim(limx);
            end
            if limy(1) < limy(2)
                ylim(limy);
            end
            if gdl == 3 && limz(1) < limz(2)
                zlim(limz);
            end
            
            if gdl == 2
                xlabel('X');
                ylabel('Y');
            else
                xlabel('X');
                ylabel('Y');
                zlabel('Z');
                view(45, 45);
            end
            
        end % plotAnimado function
        
        function [limx, limy, limz] = obtenerLimitesDeformada(analisisObj, modo, factor)
            % Obtiene los limites de deformacion
            
            factor = 1.25 * factor;
            limx = [inf, -inf];
            limy = [inf, -inf];
            limz = [inf, -inf];
            
            % Carga objetos
            nodoObjetos = analisisObj.modeloObj.obtenerNodos();
            numeroNodos = length(nodoObjetos);
            gdl = 2;
            for i = 1:numeroNodos
                coords = nodoObjetos{i}.obtenerCoordenadas();
                ngdlid = length(coords);
                gdl = max(gdl, ngdlid);
            end
            
            elementoObjetos = analisisObj.modeloObj.obtenerElementos();
            numeroElementos = length(elementoObjetos);
            for i = 1:numeroElementos
                nodoElemento = elementoObjetos{i}.obtenerNodos();
                coord1i = nodoElemento{1}.obtenerCoordenadas();
                coord2i = nodoElemento{2}.obtenerCoordenadas();
                def1 = analisisObj.obtenerDeformadaNodo(nodoElemento{1}, modo, gdl);
                def2 = analisisObj.obtenerDeformadaNodo(nodoElemento{2}, modo, gdl);
                coord1 = coord1i + def1 .* factor;
                coord2 = coord2i + def2 .* factor;
                limx(1) = min([limx(1), coord1(1), coord2(1)]);
                limy(1) = min([limy(1), coord1(2), coord2(2)]);
                limx(2) = max([limx(2), coord1(1), coord2(1)]);
                limy(2) = max([limy(2), coord1(2), coord2(2)]);
                if gdl == 3
                    limz(1) = min([limz(1), coord1(3), coord2(3)]);
                    limz(2) = max([limz(2), coord1(3), coord2(3)]);
                end
                coord1 = coord1i - def1 .* factor;
                coord2 = coord2i - def2 .* factor;
                limx(1) = min([limx(1), coord1(1), coord2(1)]);
                limy(1) = min([limy(1), coord1(2), coord2(2)]);
                limx(2) = max([limx(2), coord1(1), coord2(1)]);
                limy(2) = max([limy(2), coord1(2), coord2(2)]);
                if gdl == 3
                    limz(1) = min([limz(1), coord1(3), coord2(3)]);
                    limz(2) = max([limz(2), coord1(3), coord2(3)]);
                end
            end
            
        end % obtenerLimitesDeformada function
        
        function def = obtenerDeformadaNodo(analisisObj, nodo, modo, gdl)
            % Obtiene la deformada de un nodo
            
            ngdl = nodo.obtenerGDLID();
            def = zeros(gdl, 1);
            gdl = min(gdl, length(ngdl));
            for i = 1:gdl
                if ngdl(i) ~= 0
                    def(i) = analisisObj.phinExt(ngdl(i), modo);
                end
            end
            
        end % obtenerDeformadaNodo function
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Metodos para mostar la informacion del Analisis Modal Espectral en pantalla
        
        function disp(analisisObj)
            % disp: es un metodo de la clase ModalEspectral que se usa para imprimir en
            % command Window la informacion del analisis espectral realizado
            %
            % disp(modeloObj)
            % Imprime la informacion guardada en el ModalEspectral (analisisObj) en
            % pantalla
            
            if ~analisisObj.analisisFinalizado
                fprintf('El analisis modal aun no ha sido calculado');
            end
            
            fprintf('Propiedades analisis modal espectral:\n');
            
            % Muestra los grados de libertad
            fprintf('\tNumero de grados de libertad: %d\n', analisisObj.numeroGDL-analisisObj.gdlCond);
            fprintf('\tNumero de grados condensados: %d\n', analisisObj.gdlCond);
            fprintf('\tNumero de direcciones por grado: %d\n', analisisObj.numDG);
            fprintf('\tNumero de modos en el analisis: %d\n', analisisObj.numModos);
            
            % Propiedades de las matrices
            detKt = det(analisisObj.Kt);
            detMt = det(analisisObj.Mt);
            if detKt ~= Inf
                fprintf('\tMatriz de rigidez:\n');
                fprintf('\t\tDeterminante: %f\n', detKt);
            end
            if abs(detMt) >= 1e-20
                fprintf('\tMatriz de Masa:\n');
                fprintf('\t\tDeterminante: %f\n', detMt);
            end
            fprintf('\tMasa total de la estructura: %.3f\n', analisisObj.Mtotal);
            
            fprintf('\tPeriodos y participacion modal:\n');
            if analisisObj.numDG == 2
                fprintf('\t\tN\t|\tT (s)\t|\tw (Hz)\t|\tU1\t\t|\tU2\t\t|\tSum U1\t|\tSum U2\t|\n');
                fprintf('\t\t-----------------------------------------------------------------------------\n');
            elseif analisisObj.numDG == 3
                fprintf('\t\tN\t|\tT (s)\t|\tw (Hz)\t|\tU1\t\t|\tU2\t\t|\tUz\t\t|\tSum U1\t|\tSum U2\t|\tSum U3\t|\n');
                fprintf('\t\t----------------------------------------------------------------------------------------------------\n');
            end
            
            for i = 1:analisisObj.numModos
                if analisisObj.numDG == 2
                    fprintf('\t\t%d\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\n', i, analisisObj.Tn(i), ...
                        analisisObj.wn(i), analisisObj.Mmeff(i, 1), analisisObj.Mmeff(i, 2), ...
                        analisisObj.Mmeffacum(i, 1), analisisObj.Mmeffacum(i, 2));
                elseif analisisObj.numDG == 3
                    fprintf('\t\t%d\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\t|\t%.3f\n', i, analisisObj.Tn(i), ...
                        analisisObj.wn(i), analisisObj.Mmeff(i, 1), analisisObj.Mmeff(i, 2), analisisObj.Mmeff(i, 3), ...
                        analisisObj.Mmeffacum(i, 1), analisisObj.Mmeffacum(i, 2), analisisObj.Mmeffacum(i, 3));
                end
                fprintf('\n');
            end
            
            % Busca los periodos para los cuales se logra el 90%
            mt90p = zeros(analisisObj.numDG, 1);
            for i = 1:analisisObj.numDG
                fprintf('\t\tN periodo en U%d para el 90%% de la masa: ', i);
                for j = 1:analisisObj.numModos
                    if analisisObj.Mmeffacum(j, i) >= 0.90
                        mt90p(i) = j;
                        break;
                    end
                end
                if mt90p(i) > 0
                    fprintf('%d\n', mt90p(i));
                else
                    fprintf('INCREMENTAR NUMERO DE MODOS DE ANALISIS\n');
                end
            end
            
            fprintf('-------------------------------------------------\n');
            fprintf('\n');
            
        end % disp function
        
    end % methods ModalEspectral
    
end % class ModalEspectral