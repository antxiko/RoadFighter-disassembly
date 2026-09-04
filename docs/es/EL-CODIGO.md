# El código

7.797 bytes de código y 8.587 de datos. Los dos números suman los 16.384 del
cartucho, y esa suma es la comprobación: **ni un byte sin asignar**.

## El anillo, que es toda la idea

La carretera no se desplaza. Lo que se desplaza es **por dónde se empieza a
leer**.

En 0xE186 hay un anillo de veinticuatro filas por veintidós columnas. La
rutina de 0x5716 retrocede el puntero de (0xE046) veintidós posiciones —una
fila— y mete en el hueco la fila nueva que se acaba de armar. Cuando el puntero
baja de 0xE170 vuelve a 0xE380, que más veintidós da 0xE396, el final del
anillo.

Los límites cuadran solos, y por eso se pueden dar por buenos: 0xE186 menos 22
es exactamente 0xE170, y 0xE380 más 22 es exactamente 0xE396.

Después, 0x573A vuelca las veinticuatro filas a la tabla de nombres empezando
en 0x3801 y saltando 0x20 por fila, porque la pantalla tiene treinta y dos
columnas y la carretera sólo ocupa veintidós. Las que sobran a la derecha son
el cuadro de mandos.

## Una fila nueva, paso a paso

    0x551D  motor_de_la_carretera
      0x592A  llena la fila de veintidós columnas con el tile de fondo
      ...     la rama de ESTA etapa pinta la calzada encima
      0x58AF  cada ocho filas pega un tramo de calzada
      0x56F7  el paisaje de los lados, por una de tres puertas
      0x590E  apunta el arcén de esta fila en la cola
      0x5944  el rótulo de meta, si toca
      0x54AF  los tramos sueltos del guion de paisaje
      0x5716  y la fila entra en el anillo

## Las seis calzadas

La tabla de 0x5526 se indexa con (0xE043) **sin restar uno**, y las etapas van
de 1 a 6: la entrada 0 no la usa nadie y por eso repite la de la etapa 1.

| etapa | qué hace su rama |
|---|---|
| 1 | sólo las líneas de la calzada |
| 2 | pega cuatro columnas de una lista cíclica |
| 3 | saca la fila entera de una palabra de dieciséis bits, y el puente |
| 4 | guarda siete columnas y calcula el espejo sumando 0x0D |
| 5 | lo mismo con cuatro columnas y otra tabla |
| 6 | como la 3, y además rehace las líneas encima |

Las seis desembocan en el mismo remate, que acaba con un `pop hl` en 0x5543:
se come la dirección de retorno para salir directamente a quien llamó al
reparto, saltándose un nivel.

## La calzada simétrica de la etapa 3

La rutina de 0x56CC saca tiles de una palabra de dieciséis bits, uno por bit,
empezando por el de más peso. Se le piden **doce** columnas y después **diez**
más.

Pero la segunda llamada entra por 0x56CE, que vuelve a cargar la palabra desde
el puntero, y el puntero no se ha movido. O sea que las columnas 12 a 21
repiten el dibujo de las diez primeras. La calzada sale simétrica sin gastar un
byte de más.

## El espejo de las etapas 4 y 5

Aquí se guarda media calzada y se calcula la otra media. Los siete bytes del
lado izquierdo se vuelven a leer, se les suma **0x0D** —que es el salto de un
tile a su versión espejada en la tabla de patrones— y se escriben hacia atrás
desde el final de la fila.

## El puente de la etapa 3

Cuatro columnas del guion, **siete** de tile 0xD0 en medio y otras cuatro del
guion, de la columna 4 a la 18. Las siete del centro no se escriben una a una:
se pone el 0xD0 en la primera y un `ldir` que se solapa consigo mismo lo
arrastra hasta el final. Por eso son siete y no las seis que dice el
`ld c,006h`.

Y dos filas de cada cuatro llevan un 0xD1 en la columna 11, que es la raya
discontinua del centro.

## La cola del arcén

En 0xE098 hay veinticuatro casillas, una por fila del anillo, y en cada una el
margen del arcén en los seis bits de arriba y el modo de paisaje en los dos de
abajo. Cada fila nueva las corre todas una posición y mete la suya por arriba.

Es la memoria de por dónde iba la calzada en cada altura de la pantalla. Sin
ella, un objeto que lleva veinte filas cayendo no sabría a qué altura está el
borde, y el propio coche no sabría dónde reaparecer después de un choque.

## El coche

    0xE049          el estado, y una tabla de ocho ramas en 0x6A80
    0xE04B..0xE04C  la Y, en punto fijo 8.8
    0xE04D..0xE04E  la x, en el mismo formato
    0xE04F          la velocidad, con tope 0xD7

Los ocho estados: rodando, reventado y ardiendo, gastando gasolina,
retirándose de la pantalla, derrapando, en trompo, esperando, y rebotando
contra el borde.

El byte alto de la Y es, tal cual, la Y del sprite en la VRAM. No es una
suposición: en novecientos fotogramas de la demostración las dos coincidieron
sin una sola excepción.

## Los objetos

Un objeto son dieciséis bytes, y en juego hay dos. El reparto va por **tramos**:
un puntero recorre la fila de dieciséis bytes que le toca a la etapa en el plan
de 0x537D, y cada valor indexa una tabla de quince registros. Cada registro
trae seis bytes, o sea dos objetos de tres campos, que se arman en dos ranuras
y desde ahí se copian enteros al primer hueco libre.

Todo el acceso a un objeto pasa por dos rutinas: 0x72F6, que trae el campo C, y
0x72E7, que le suma DE a la palabra que acaba en el campo C. De ahí el
`ld c,006h` —la Y— y el `ld c,009h` —la velocidad— que salen por todas partes.

## El descompresor

Los gráficos van comprimidos con un RLE que escribe **directamente en la
VRAM**, con `out (c),a` sobre el puerto de datos del VDP:

    0x00           cierra el bloque
    0x01..0x7F     el byte que sigue, repetido esa cuenta
    0x80           los dos bytes que siguen son una dirección de VRAM nueva
    0x81..0xFF     copia tal cual los (mandato & 0x7F) bytes que siguen

Hay dos puertas: por 0x4611 el destino llega en HL y por 0x460B va dentro del
propio bloque, en sus dos primeros bytes. Y 0x45E0 llama al descompresor tres
veces sumándole 0x800 a HL, que es la geometría de SCREEN 2: un solo bloque
llena los tres tercios.

Los límites de los veintidós bloques no están estimados: los mide
`tools/rle.py` ejecutando ese mismo descompresor, y cada uno cierra en su
propio 0x00.

## Tres bloques encabalgados

Tres de esos bloques no acaban donde empieza el siguiente: **acaban después**.
El cartucho reaprovecha la cola de uno como cuerpo del que viene detrás.

| bloque | cierra en | lo que comparte |
|---|---|---|
| 0x5DEC | 0x5F45 | sus 32 últimos bytes son la cabeza del bloque de 0x5F25 |
| 0x601D | 0x6022 | se come entero el bloque de 0x601F |
| 0x602D | 0x603E | se come entero el bloque de 0x6031 |

No es un error de lectura: los tres cierran solos en su 0x00 y los tres cuadran
con la VRAM del emulador.
