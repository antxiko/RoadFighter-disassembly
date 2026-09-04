# Empezar

El repositorio trae el listado ya generado, pero lo que de verdad importa es
que se puede **rehacer entero desde el cartucho** y que el resultado vuelve a
ser la ROM byte a byte. Eso es lo que hace que las notas se puedan creer.

## Lo que hace falta

- **Python 3** (nada más: ni una dependencia)
- **pasmo**, el ensamblador de Z80, para la prueba del reensamblado
- **make**
- Para las comprobaciones contra la máquina, **openMSX**

## El cartucho

No viaja con el repositorio. Hay que ponerlo en la raíz como
`roadfighter.rom`, 16.384 bytes exactos:

    6d36c9e9b6a6b93f642722dcd314834d01e519ab3a98d7e4ca257468bcaf29e1

La otra compilación, que hace falta sólo para `make coteja`, va como
`roadfighter_dificil.rom`:

    070fc231f979a04bb4652f7c5e585f6445758af32ffcbf60757deb1f7b5856e7

`make comprueba` verifica los dos.

## Lo que hace `make`

    make            traza, genera el listado, verifica y pasa los tests
    make trace      sigue el flujo desde los puntos de entrada
    make listado    escribe src/roadfighter.asm
    make verify     LA PRUEBA: reensambla y compara con la ROM
    make sanity     lo que el reensamblado no puede cazar
    make densidad   cuánto está comentado, rutina por rutina
    make test       los tests
    make web        genera esta web

`make verify` es el que decide si el desensamblado es fiable. Mientras no esté
en verde, cualquier cosa que se diga del cartucho se dice a ciegas.

## Los tests corren sin el cartucho

Los tests no necesitan la ROM. `tests/test_listado.py` reconstruye los bytes de
datos leyendo las filas `defb` y `defw` del propio listado, que llevan su
dirección en el comentario. Así el descompresor, el intérprete de rótulos, el
pegador de retales y el generador de carretera se pueden **ejecutar** en un
clon pelado, sin cartucho y sin `make`.

## Cómo está organizado

    src/roadfighter.asm       el listado, generado
    src/roadfighter.notes     LO ENTENDIDO: de aquí salen los comentarios
    src/roadfighter.entries   los puntos de entrada que no se deducen solos
    src/roadfighter.nocode    lo que no es código aunque lo parezca
    tools/                    las herramientas
    tests/                    lo que vigila que esto no se degrade

El `.asm` **se regenera**: no se edita. Lo que se edita es el `.notes`, y por
eso los comentarios sobreviven a un retrazado.
