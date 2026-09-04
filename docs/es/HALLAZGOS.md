# Hallazgos

Lo que apareció al desmontar el cartucho. Cada cifra de aquí está medida:
ejecutando las rutinas del propio cartucho, o volcando la memoria del emulador
y comparándola byte a byte.

## El mapa de colisiones es la propia pantalla

Este cartucho no guarda en ninguna parte por dónde va la carretera. Para saber
si el coche ha tocado el borde **lee la pantalla**. La rutina de 0x6D8B calcula
la casilla en la que está el coche, se la pide al VDP con `SETRD` y se trae con
un `in a,(c)` el tile que hay dibujado ahí.

Después lo clasifica por tandas:

| tile | qué es |
|---|---|
| por debajo de 0xCF | golpe seguro |
| 0xCF a 0xD8 | libre |
| 0xD9 a 0xE8 | el borde, y hay que afinar hasta el píxel |

Es la manera más barata de que el coche choque con **lo que se ve**, sea lo que
sea lo que la carretera haya pintado ahí. Y explica por qué la cola del arcén
existe: para lo que no está en pantalla —dónde reaparecer, dónde soltar un
objeto— sí hace falta memoria aparte.

## Una rutina escondida dentro de su propia tabla de punteros

0x5540 hace `call 05716h`, y 0x5716 cae **dentro** de la tabla de punteros de
paisaje de 0x570C: son sus dos últimos bytes.

Konami los usa para dos cosas a la vez. Leídos como palabra son la sexta
entrada de la tabla. Ejecutados son el `ld hl,(0e046h)` con el que arranca la
rutina que corre el anillo:

    ld hl,(0e046h)      por donde va el anillo
    ld bc,0ffeah        veintidos atras: una fila
    add hl,bc
    ld (0e046h),hl
    ld bc,0e170h        0xE186 - 22, o sea antes del principio
    and a / sbc hl,bc
    jr nz,+6
    ld hl,0e380h        y entonces a 0xE380, que mas 22 da 0xE396
    ld (0e046h),hl
    ld de,(0e046h) / ld hl,0e058h / ld bc,00016h / ldir

Lo que delata el truco es que la sexta entrada apuntaría a 0x462A, y 0x462A es
un `jr` de dentro del descompresor RLE: no es ningún dibujo de paisaje. La
tabla tiene **cinco** entradas, y lo que sigue ya es código.

Estos treinta y seis bytes estuvieron todo el desensamblado clasificados como
datos que no lee nadie. La prueba de que son código no es que se puedan
desensamblar: es que, declarados como tales, **el listado sigue devolviendo la
ROM byte a byte**.

## Las dos compilaciones se diferencian en UN byte

Del cartucho circulan dos volcados. Difieren en **un solo byte, el 0x53CB**:
uno tiene 0x05 y el otro 0xFF.

Ese byte es el decimoquinto tramo de la fila de la **etapa 5** en el plan de
0x537D, que son seis filas de dieciséis bytes cerradas con 0xFF y rellenas con
0xFF hasta el final.

Medido en openMSX, forzando (0xE043) a 5 y colocando el puntero de tramos al
final de esa fila:

    con 0x05   ... plan+13 tramo=0x0A -> plan+14 tramo=0x05 -> plan+0 (vuelve)
    con 0xFF   ... plan+13 tramo=0x0A ->                       plan+0 (vuelve)

O sea: la del 0x05 juega **quince** tramos por ciclo y la del 0xFF,
**catorce**. El que desaparece es el tramo 5, cuyo registro (0x5329) es
`00 04 18 08 08 28`.

**Cuál de las dos se juega más difícil no se dice aquí, porque no se ha
medido.** Los nombres "Easy" y "Hard" con los que circulan son del volcado, no
de la ROM.

## El coche tiene una franja muerta de velocidad

Acelerando, el coche avanza por la pantalla 0x48 de 256 de píxel por fotograma.
Pero no siempre: la rutina de 0x6C93 sólo lo deja moverse en dos franjas de
velocidad, y entre ellas hay una tercera en la que se queda clavado.

| velocidad | ¿se mueve? |
|---|---|
| por debajo de 0x18 | no |
| 0x18 a 0x50 | sí |
| 0x50 a 0x7E | **no** |
| por encima de 0x7E | sí |

Medido, no deducido. En 900 fotogramas de la demostración la Y del coche se
queda quieta en 0x8FC0 mientras la velocidad sube de 0x51 a 0x7D, y vuelve a
moverse en cuanto pasa de 0x7E. Cumplen la predicción 57 de los 58 fotogramas
comparables, y el que no cae justo en la frontera entre dos muestras.

De la misma medida salen otras dos cosas: los topes del código se alcanzan de
verdad —la Y se clava en 0x9A y la velocidad en 0xD7—, y **la demostración
corre con el acelerador pisado**, que sólo suelta un fotograma de cada 104.

## Tres hitos separados por nueve

El final de etapa no es un solo momento. Son tres, y están separados por nueve
de recorrido, que son nueve filas de anillo:

| recorrido | qué pasa |
|---|---|
| 0x0F00 | se suelta el coche rival |
| 0x0F09 | se pinta el rótulo de meta en el anillo |
| 0x0F12 | el coche la cruza: estado 3 y suena el efecto 0x92 |

Y el rótulo no es el mismo siempre. En las cinco primeras etapas son los once
tiles de `CHECK POINT`; en la sexta, los cinco de `GOAL`, tres columnas más a
la derecha. Se leen con la misma regla que el resto de textos del cartucho —el
índice de patrón es el código ASCII menos 0x20— y se comprobaron **dibujando
sus tiles** desde la VRAM del emulador, no suponiéndolo.

El mismo truco vale para el aviso de `EMPTY` de 0x6B59, que se escribe sobre la
propia calzada cuando se acaba la gasolina, y que se corre a la izquierda si no
cupiera dentro de las veintidós columnas del anillo.

## La calzada simétrica sale gratis

La etapa 3 dibuja la fila entera desde una sola palabra de dieciséis bits: cada
bit elige uno de dos tiles. Se piden doce columnas y después diez más, pero la
segunda llamada vuelve a cargar la misma palabra desde el principio, porque el
puntero no se ha movido.

Las columnas 12 a 21 repiten el dibujo de las diez primeras. La calzada sale
simétrica sin gastar un byte de más ni una instrucción de más.

## El nivel cambia cuatro cosas, no una

LEVEL A y LEVEL B no son un multiplicador de dificultad. El nivel, en (0xE03B),
se consulta en cuatro sitios que no tienen nada que ver entre sí: el empuje
lateral de los objetos (0x706D), el gasto de gasolina (0x7374), la espera del
reparto de objetos (0x6F72) y la lista de tramos, donde el primer nivel
**suprime un tramo entero**, cambiando el 0x0A por el 9 (0x7044).

## Lo que el cartucho se ahorra

Un puñado de trucos que aparecen una y otra vez:

- **El paso de escena no se compara**: se gasta con `djnz` encadenados.
- **Las tablas van pegadas detrás del `call`**, y el despachador recupera su
  propia dirección de retorno con un `pop hl` para leerlas. Son seis.
- **`L_440C` se come la dirección de retorno de quien la llamó** si su cuenta
  no llega a cero, que es un `return` de dos niveles en tres instrucciones.
- **Las líneas de la calzada son bitmaps**: doce bits por palabra, y cada bit
  elige uno de dos tiles.
- **Los retales se encadenan**: cada llamada al pegador hereda el destino que
  dejó la anterior, y a veces sólo se le cambia el registro E.

## La marca oculta de Konami

Los últimos quince bytes del cartucho no los lee nadie: son `RC-730` y el
título en katakana, ロードファイター, escritos del revés y rematados con la
longitud —diez bytes—, las dos cifras del RC en BCD y un 0xAA.

El formato de esa firma lo descubrió **Manuel Pazos**, y sin su hallazgo estos
quince bytes se habrían quedado en "datos que no lee nadie". Las gracias, desde
aquí.
