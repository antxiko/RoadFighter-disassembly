# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`latido_del_sonido`, 0x4BFF, y `suena`, 0x4B6E, que le reparte las voces; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0x98 entera, 218 cuadros, tal como el juego la pide;
- la pieza 0x95 entera, 198 cuadros, pedida a la fuerza;
- los primeros 270 cuadros de cruzar la meta (0x92, que dura 346), hasta que el juego pide otro sonido encima.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`suena` recibe el número en A y `pide_efecto` elige la voz: el número más bajo manda. Los números por debajo de 0x0F son efectos de una o dos voces y del 0x0F en adelante hay música de tres. Cada voz ocupa once bytes desde 0xE010 y 0xE031 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de melodías (0x4DE0) pero ninguna rutina las pide con un `ld a`. Hay tres piezas cotejadas con openMSX, la 0x98, la 0x95 y la 0x92 (esta en sus 270 primeros cuadros); las demás salen del mismo motor, pero no se ha comparado cada una.

## Las músicas

**La pieza del 0x4266** (0x98)

Lo pide `L_4266`; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_98.mp3?v=a81b0ed1"></audio>

**Cruzar la meta** (0x92)

Lo pide `cruza_la_meta`; dura 5,8 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=59e1ec2e"></audio>

**La pieza del 0x4341** (0x95)

Lo pide `L_4341`; dura 3,3 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=9099f44b"></audio>

**Pista 0x90 de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 20,6 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=d1f8a0fc"></audio>

**Pista 0x91 de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,8 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=a06e832c"></audio>

**Pista 0x93 de la tabla** (0x93)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,8 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=e7f59c92"></audio>

**Pista 0x94 de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,8 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=2d631e92"></audio>

**Pista 0x96 de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=cbd83e08"></audio>

**Pista 0x97 de la tabla** (0x97)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=adb4c494"></audio>

**Pista 0x99 de la tabla** (0x99)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=b3164478"></audio>

**Pista 0x9A de la tabla** (0x9A)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,3 s.

<audio controls preload="none" src="../audio/musica_9A.mp3?v=9cfbf840"></audio>
