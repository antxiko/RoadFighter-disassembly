# En el emulador

Mirar un dibujo no basta para darlo por bueno. Lo que cierra la duda es volcar
la memoria de la máquina y compararla, byte a byte, con lo que dicen las notas.
Todo lo que se afirma en esta web sobre lo que el cartucho hace en marcha está
medido así.

## Los guiones

En `tools/` hay cuatro guiones de openMSX. Ninguno pone un punto de ruptura
salvo el que lo necesita: los demás van por reloj emulado, que es lo único que
no ahoga al emulador.

    tools/omsx_vram.tcl       vuelca los 16 KB de VRAM y los registros del VDP
    tools/omsx_coche.tcl      apunta el movimiento del coche, fotograma a fotograma
    tools/omsx_carretera.tcl  vuelca el estado del generador de carretera
    tools/omsx_etapa.tcl      lo mismo, forzando qué etapa se juega

Se corren así:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart roadfighter.rom -script tools/omsx_vram.tcl

## Los gráficos, contra la VRAM

`tools/graficos.py` rehace las pantallas ejecutando en Python los pasos del
propio cartucho: el descompresor, el intérprete de rótulos, los espejos y el
pegador de retales. Después se compara con lo que el VDP tiene de verdad.

    PANTALLA DE TITULO   color, sprites, patrón y nombres: 0 diferencias en las cuatro
    ESCENA DE JUEGO      color 0/6144   sprites 0/2048   patrón 0/6144
                         nombres 2/528

Las dos casillas que no cuadran son el **arco de meta**, fila 4, columnas 6 y
7, que está animado: alterna 0x46/0x47 con 0x48/0x49. O sea que las dos que
fallan fallan porque tienen que fallar.

## La carretera, paso a paso

Ésta es la comprobación que más cuesta y la que más vale. La carretera es
procedural, así que comparar un volcado suelto no dice nada: no hay forma de
saber en qué punto del guion estaba.

Lo que sí vale es esto. `tools/omsx_carretera.tcl` apunta el estado **entero**
del generador —las variables de 0xE040 a 0xE0C0 y el anillo de 528 bytes— en
fotogramas seguidos. Después, en Python, se carga el estado del fotograma N, se
ejecuta **un paso** del motor rehecho y se compara con el estado del N+1.

Resultado, con las seis etapas forzadas una a una:

| etapa | pasos comparados | idénticos |
|---|---|---|
| 1 | 44 | **44** |
| 2 | 44 | **44** |
| 3 | 44 | **44** |
| 4 | 44 | **44** |
| 5 | 44 | **44** |
| 6 | 43 | **43** |

Idénticos quiere decir el anillo entero, los 528 bytes, y todas las variables
del generador. En los 263 pasos, ni una diferencia.

Esa comprobación destapó tres errores de lectura que sólo se ven así: que la
rutina de 0x5784 empieza con un `ldi` propio, que el `ldir` del puente se
solapa consigo mismo y arrastra siete casillas en vez de seis, y que el vaivén
de los dos guiones estaba leído al revés.

## Forzar una etapa

La demostración sortea la etapa con el registro R, y en un arranque limpio de
openMSX el sorteo sale siempre igual: la 2. Para ver las otras cinco hay que
forzarla, y **el sitio importa**.

`tools/omsx_etapa.tcl` pone un punto de ruptura en 0x504C, la primera
instrucción de `prepara_la_etapa`, y escribe (0xE043) **antes** de que la
rutina monte nada. Así el decorado, los guiones y las listas se eligen todos
para la etapa forzada y el estado queda coherente.

Forzarla a mitad de partida no vale: el decorado se queda en el de la etapa
anterior y la pantalla sale con basura. La lectura del plan de tramos sí sirve
—sólo depende de (0xE043) y del puntero—, pero las capturas no.

## El coche

`tools/omsx_coche.tcl` apunta, novecientas veces, la Y del coche junto al
acelerador y la velocidad. De ahí salen tres cosas:

- **(0xE04C) es la Y del sprite del coche**: coincidió con la que el VDP tenía
  en la tabla de atributos en las 900 muestras, sin una excepción.
- Los topes del código se alcanzan de verdad: la Y se clava en 0x9A y la
  velocidad en 0xD7.
- La franja muerta de velocidad de 0x6C93 se cumple en 57 de los 58 fotogramas
  comparables.

## Cómo jugarlo

Cualquier emulador de MSX1 sirve. Con openMSX:

    openmsx -machine Philips_VG_8020 -cart roadfighter.rom

Y si se quiere ver la otra compilación, la misma orden con
`roadfighter_dificil.rom`. La diferencia está en la etapa 5, y es un tramo.
