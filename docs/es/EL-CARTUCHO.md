# El cartucho

**RC-730**, 16.384 bytes, en la **página 1** del MSX. Es un cartucho de ROM sin
mapeador: se ve entero de 0x4000 a 0x7FFF y no hay nada que conmutar.

## La cabecera

Los dieciséis primeros bytes son la cabecera que el MSX busca al arrancar:
`"AB"`, la dirección de INIT (**0x404F**), y STATEMENT, DEVICE y TEXT a cero,
más seis bytes reservados que también valen cero.

## Todo cuelga de la interrupción

INIT no arranca ningún bucle de juego. Lo que hace es enganchar **H.KEYI** con
0x4013 y quedarse en un `jr $`. A partir de ahí, todo el juego se ejecuta
dentro del gancho de interrupción, una vez por cuadro.

El gancho lleva su propio cerrojo de reentrada en (0xE005), porque un cuadro
lento puede pillar al anterior sin terminar.

## El reparto de memoria

    0xE000   la escena, y 0xE001 el paso dentro de ella
    0xE002   las banderas de la partida (el bit 6 es "partida en curso")
    0xE003   el reloj del juego, uno por cuadro
    0xE043   la etapa, de 1 a 6      0xE042  la vuelta
    0xE046   por dónde va el anillo de la carretera
    0xE049   el estado del coche     0xE04B..0xE04C  su Y en punto fijo
    0xE04D..0xE04E  su x             0xE04F  la velocidad
    0xE058..0xE06D  LA FILA NUEVA: 22 columnas
    0xE078   lo recorrido en la etapa, 16 bits
    0xE083   la gasolina
    0xE098..0xE0AF  la cola del arcén: una casilla por fila del anillo
    0xE0E5   los objetos de la carretera, 16 bytes cada uno
    0xE10E..0xE185  la copia en RAM de los treinta atributos de sprite
    0xE186..0xE395  EL ANILLO: 24 filas de 22 columnas

Que 0xE10E más 0x78 dé exactamente 0xE186 no es casualidad: la copia de
atributos de sprite acaba justo donde empieza el anillo, y por eso los dos
volcados que el cartucho hace a la VRAM —0x34 bytes y 0x78— cuadran sin dejar
hueco.

## La pantalla

SCREEN 2, y con las tablas en un sitio poco habitual. Los ocho bytes que el
cartucho carga en los registros del VDP, de la tabla de 0x46A9, valen
`02 E2 0E 7F 07 76 03 E4`:

| registro | valor | qué queda dónde |
|---|---|---|
| R2 | 0x0E | tabla de NOMBRES en 0x3800 |
| R3 | 0x7F | tabla de COLORES en **0x0000** |
| R4 | 0x07 | tabla de PATRONES en **0x2000** |
| R5 | 0x76 | ATRIBUTOS de sprite en 0x3B00 |
| R6 | 0x03 | PATRONES de sprite en 0x1800 |
| R7 | 0xE4 | en el título; 0xE0 en marcha, con el fondo negro |

Los colores debajo de los patrones, al revés de lo habitual. R3 y R4 no son
direcciones sino una base y una máscara, y leerlos como si lo fueran da un
resultado que engaña: las formas salen bien y los colores a franjas.

## El despachador

El cartucho reparte trabajo con un despachador de nueve instrucciones en
0x4045 que se come su propia dirección de retorno:

    add a,a / pop hl / call 0x403B / ld e,(hl) / inc hl / ld d,(hl)
    ex de,hl / jp (hl)

El `pop hl` recupera la dirección a la que iba a volver, que es justo donde
empieza la tabla, porque **la tabla va pegada detrás del `call`**. Hay seis
tablas así: 0x4099 (las escenas), 0x50C9 (el paisaje por etapa), 0x5526 (la
calzada por etapa), 0x570C (el paisaje de los lados), 0x6A80 (los estados del
coche) y 0x70C9 (los estados de un objeto).

Ninguna se puede deducir siguiendo saltos, así que van declaradas a mano en
`src/roadfighter.entries`, cada una con su justificación escrita al lado.

## Las nueve escenas

El índice es (0xE000) y el paso, (0xE001). Cada escena empieza con una fila de
`djnz` encadenados: el paso no se compara con nada, se **gasta**.

| escena | qué es |
|---|---|
| 0 | el arranque y la portada |
| 1 | la espera |
| 2 | el remate de una partida |
| 3 | la más larga: el menú, el montaje de la carretera y el arranque |
| 4 | la cuenta atrás, con la carretera ya rodando |
| 5 | la partida |
| 6 | el choque |
| 7 | GAME OVER |
| 8 | la vuelta a la portada |

La décima palabra de la tabla sería 0x1310, que no cae en la ROM: esos dos
bytes son ya el `djnz` de 0x40AB, que además es el primer destino de la propia
tabla. Ese encaje es lo que fija el final de la tabla sin tener que suponerlo.

## La marca oculta

Los últimos quince bytes no los lee nadie. Son `RC-730` y el título en
katakana, ロードファイター, escritos del revés y rematados con la longitud, las
dos cifras del RC en BCD y un 0xAA. El formato de esa firma lo descubrió
**Manuel Pazos**.
