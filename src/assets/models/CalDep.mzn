include "alldifferent.mzn";

% Cargar datos:
int: n;
int: Min;
int: Max;
array[int, int] of int: D;

% Variables:  Cal de dimensión 2(n - 1) x n
int: size = 2*(n-1);
set of int: rowSize = 1..size;
set of int: cRowSizeMax = 1..(size)-Max;
set of int: tourRowSize = 1..(size)+2;
set of int: colSize = 1..n;
array[rowSize, colSize] of var int: Cal;

% Restricciones:
% A tener en cuenta: i = Fecha, j = Equipo, k = local, -k = visitante

%1. n debe ser par.
constraint n mod 2 = 0;

%2. Cal[i,j] = k si y solo si Cal[i,k] = -j: Bicondicional es la conjunción de dos condicionales p → q  y  q → p.
constraint forall (i in rowSize, j in colSize, k in colSize) (
   (Cal[i,j] = k) = (Cal[i,k] = -j)
);

%3.{|Cal[i,j]| : 1 <= j <= n} = {1,2,...,n}, para todo 1 <= i <= 2(n - 1)
% Con esta restricción cubrimos {|Cal[i,j]| : 1 <= j <= n} = {1,2,...,n}.
constraint forall(i in rowSize, j in colSize) (
  abs(Cal[i,j]) in colSize
);

%4.n/2 = |{Cal[i,j] > 0 : 1 <= j <= n}| = |{ Cal[i,j] < 0 : 1 <= j <= n}|, para todo 1 <= i <= 2(n - 1)
% Fuente de inspiración: https://drive.google.com/file/d/1g0NzEyd3fOloMImDZNXugj9k_bdBCGsp/view

constraint forall(i in rowSize) (% Itero sobre cada equipo [Fixed, 1...n].
  % Con esto valido que la suma de todos los positivos - n/2 sea igual a la suma de todos los negativos - n/2
  % Si aplico valor absoluto la cago pero casi siempre lo que va a pasar es lo siguiente:
  % Ejemplo: Si n = 4, entonces n/2 = 2. Si la cantidad de positivos fuera 3 y la cantidad de negativos fuera 1.
  % Entonces 3 - 2 = 1 - 2 Por lo tanto: 1 = -1. No se cumple. En cualquier otro caso imaginario, pasará casi lo mismo porque habrá alguna de las dos sumas
  % que será menor que n/2. Por lo que el único caso que se cumplirá será que positivos = negativos y por lo tanto 0 = 0, o sea: n/2 = sumPositivos = sumNegativos
   sum(j in colSize)(bool2int(Cal[i,j] > 0)) - (n div 2) = sum(j in colSize)(bool2int(Cal[i,j] < 0)) - (n div 2)
);

%5. Para todo j que pertenece a [1..n], Para todo k diferente de j, existe un i_1,i_2 que pertenece a [1.,2(n-1)] : Cal[i_1,j] = k /\ Cal[i_2,j] = -k:
% ESTO SERÍA LA RESTRICCIÓN QUE PERMITE QUE SE JUEGUE DE LOCAL Y DE VISITANTE
constraint forall(j in colSize, k in colSize where k != j)( %Para todo j que pertenece a [1..n], Para todo k diferente de j
    exists(i1, i2 in rowSize)( % existe un i_1,i_2 que pertenece a [1.,2(n-1)]
      Cal[i1,j] = k /\ Cal[i2,j] = -k % Cal[i_1,j] = k /\ Cal[i_2,j] = -k
    )
);

%6. Adicionalmente no se permite que en dos fechas consecutivas se repita un mismo partido
% NOTA: Creo que esto se puede lograr con una restricción global aplicado sobre las filas de la matriz https://www.youtube.com/watch?v=TuoA9RqJmxM Min 3:31 pero no supe cómo hacerlo así que escribí esto
constraint forall (j in colSize) ( % Me posiciono en cada columna [1..2(n-1), Fixed]
  forall(i in rowSize, k in rowSize where k = i+1) ( % Me enfoco en iterar las filas de esa columna
     abs(Cal[i,j]) != abs(Cal[k,j]) % miro que el valor absoluto de su sucesor sea diferente del valor absoluto del actual valor
  )
);

%7. no programar partidos de vuelta hasta tanto no se hayan programado todos los partidos de ida
constraint forall(j in colSize) ( % Me posiciono en cada columna [1..2(n-1) / 2, Fixed]
  alldifferent([abs(Cal[i,j]) | i in 1..(size div 2)]) % Me enfoco en iterar la mitad de las filas que equivaldría a la primera ronda de esa columna
                                                       % Miro que todos los valores contenidos en la fila sean diferentes. 
                                                       % Por lo tanto, no se programan partidos de vuelta hasta tanto no se hayan programado todos los partidos de ida
);

%8. Una calendario tal que el tamaño de toda gira y toda permanencia es mayor o igual a Min y menor o igual a Max
% EQUIPO DE GIRA = Cantidad de elementos negativos consecutivos
% EQUIPO DE PERMANENCIA = Cantidad de elementos positivos consecutivos

constraint forall (j in colSize) ( %Se itera para cada equipo
  forall(i in cRowSizeMax) ( %Se itera para cada fecha segun el equipo menos la holgura que se genera en sumatoria
    Max >= sum(k in 0..Max)(bool2int(Cal[i+k,j] > 0)) 
    /\
    Max >= sum(k in 0..Max)(bool2int(Cal[i+k,j] < 0)) %Se suman los partidos locales(mayor a 0) en partidos seguidos dados desde i hasta Max para cada i.      
  )
);

%9. Una calendario tal que el tamaño de toda gira y toda permanencia es mayor o igual a Min y menor o igual a Max
constraint forall (j in colSize) ( %Se itera para cada equipo
  forall(i in cRowSizeMax) ( %Se itera para cada fecha segun el equipo menos la holgura que se genera en sumatoria
    Min <= sum(k in 0..Max) (bool2int ( Cal[i+k,j] > 0)) 
    /\
    Min <= sum(k in 0..Max) (bool2int ( Cal[i+k,j] < 0))
  )
);% <= Max Se suman los partidos locales(mayor a 0) en partidos seguidos dados desde i hasta Max para cada i. 


% --------- Funciones aux ---------------

% Nombre: get tour
% Entradas: Matriz de enteros de tamaño 2*(n-1) x n
% Salida: Matriz de enteros de tamaño 2*(n-1)+2 x n
% Objetivo: Lograr modelar una matriz que represente la gira de cada equipo.
% Para lograrlo se establece la siguiente lógica: Las dos filas que se agregaron, funcionan como un punto de partida y un punto final.
% La idea es que esta matriz resultante tenga en cada columna solamente las localidades en las que está y a las cuales se mueve.
% Por ejemplo digamos que la primera columna de Cal fuera: [3, 2, 4, -3, -2, -4].
% Esta función daría como salida: [0, 0, 0, 1, 3, 2, 4, 1].
% Lo cual estaría representando que el equipo 1 haría la gira: d1,3 + d3,2 + d2,4 + d4,1.

% Para lograr la salida, la lógica principal es recorrer cada fila de cada columna y preguntar: si el valor actual es cero y el sucesor
% es un valor mayor a cero entonces quiere decir que voy desde la localidad ```j``` hasta la localidad del sucesor. Esta pregunta se hace desde 1 hasta la
% penultima fila (2*(n-1)+2)-1. Y lo que se hará en la ultima fila de la matriz resultante siempre sera [j1, j2...jn-1, jn].
% Porque de una u otra manera, siempre el equipo j debe retornar a su localidad.

% Segundo ejemplo para un equipo 3 con el siguiente arreglo: [-1, 4, 2, 1, -4, -2].
% Salida: initial_tour = [0,1,0,0,0,4,2,3] -> Aplicando la lógica principal -> [3, 1, 0, 0, 3, 4, 2, 3]

% NOTA IMPORTANTE: La explicación dada se hizo a nivel de una columna de una matriz equis. La idea detrás de esta función es aplicar esa misma lógica a
% nivel matricial.

function array[tourRowSize, colSize] of var int: get_tour(array[rowSize, colSize] of var int: matrixToFind) = (
  let {
    array[tourRowSize, colSize] of var int: initial_tour = array2d(
      tourRowSize,
      colSize,
      [0 | i in colSize]++
      [if matrixToFind[i,j] < 0 then abs(matrixToFind[i,j]) else 0 endif | i in rowSize, j in colSize]++
      [0 | i in colSize]
    )
  } in (
      array2d(
        tourRowSize,
        colSize,
        [if initial_tour[i,j] == 0 /\ initial_tour[i+1,j] > 0 then j else initial_tour[i,j] endif | i in 1..(size)+1, j in colSize]++
        [i | i in colSize]
      )
  )
);

% Nombre función: get_tour_cost_by_team
% Entrada: un arreglo de tamaño 2*(n-1)+2 y un valor entero col
% Lógica: Realizar la sumatoria de D[k-1, k] para todo valor mayor a cero dentro del arreglo de entrada.
% Para lograr lo anterior. Supongamos que tenemos como entrada el arreglo [3, 1, 0, 0, 3, 4, 2, 3] y representa al equipo j = col = 3.
% Primero, la función tomará el arreglo de entrada e iterará sobre este preguntando: Si el valor actual es cero y el antecesor es mayor a cero entonces reemplazará
% el valor actual por j / col, que en este caso sería 3. De esta manera, la variable local tendría el siguiente valor: [3,1,3,0,3,4,2,3].
% Lo que se logra con lo anterior, es que si en medio de la gira, el equipo j viajó a otra localidad y luego volvió a su localidad j, entonces se vea reflejado aquí.
% Con este resultado, la función procederá a realizar la siguiente sumatoria sólo de los valores consecutivos mayores a cero. Para cualquier otro valor
% se sumará cero. Con esta lógica se logra a partir del arreglo local [3,1,3,0,3,4,2,3], obtener: d3,1 + d1,3 + d3,4 + d4,2 + d2,3.


% NOTA IMPORTANTE: Note que una solución más sencilla es crear una variable local que filtre los elementos que sean cero. De esta manera, si se tiene
% de entrada [3, 1, 0, 0, 3, 4, 2, 3] -> se lograría [3, 1, 3, 4, 2, 3] y por lo tanto se haría una sumatoria sencilla de D[k-1, k]. Que representa 
% perfectamente la gira del equipo 3: d3,1 + d1,3 + d3,4 + d4,2 + d2,3.
% Sin embargo debido a que crear ```list comprehensions``` con base en variables de búsqueda (var int, var float...) genera variables de tipo options (var opt int...).
% No sería posible generar un arreglo menor al tamaño del arreglo de entrada porque en vez de sacar el valor cero de la lista, MiniZinc retornaría:
%
% Entrada: [3, 1, 0, 0, 3, 4, 2, 3]
% Salida Esperada: [3, 1, 3, 4, 2, 3]
% Salida Real: [3, 1, <>, <>, 3, 4, 2, 3]

% Fuente: https://www.minizinc.org/doc-2.4.3/en/optiontypes.html#hidden-option-types
function var int: get_tour_cost_by_team(array[tourRowSize] of var int: arr, int: col) = (
    let {
      array[tourRowSize] of var int: teamTour = [if i-1 == 0 then arr[i] elseif arr[i] == 0 /\ arr[i-1] > 0 then col else arr[i] endif |i in tourRowSize];
    } in
    sum(i in 1..length(teamTour)) (
      if i-1 == 0 then 0
      elseif teamTour[i] > 0 /\ teamTour[i-1] > 0 then
        D[teamTour[i-1], teamTour[i]]
      else
        0
      endif
    )
);
%--------------------------------------------------------------------------

%10. Función objetivo:
%   Una matriz Cal de dimensión 2(n - 1) x n representando un calendario valido tal que la suma total de los costos de todas las giras es minimo.
var int: u;
constraint u = sum(j in colSize)(
  let {
    array[tourRowSize, colSize] of var int: Tour = get_tour(Cal); % Matriz con las giras de todos los equipos
  } in
  get_tour_cost_by_team([Tour[i,j] | i in tourRowSize], j) % Sumatoria del total de los costos de todas las giras
);

solve minimize u;
