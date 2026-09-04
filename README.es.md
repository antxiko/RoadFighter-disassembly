# Road Fighter (Konami, 1985) — desensamblado comentado

Desensamblado completo y comentado del cartucho de MSX1 **Road Fighter**
(Konami, número de catálogo **RC-730**, 16 KB), reproducible byte a byte.

**Web: <https://antxiko.github.io/RoadFighter-disassembly/es/>** · [In English](README.md)

|  |  |
|---|---|
| Del binario explicado | **100 %** — 0 bytes sin asignar, de 16.384 |
| Reensambla | **byte a byte**, al mismo sha256 |
| Listado comentado | **55,1 %** — 2.234 comentarios sobre 4.053 instrucciones |
| Rutinas por debajo del 10 % | **0** de 482 |

## Qué hay aquí

    src/roadfighter.asm       el listado, generado
    src/roadfighter.notes     lo entendido: bloques de datos y comentarios
    src/roadfighter.entries   los puntos de entrada, cada uno con su razón
    src/roadfighter.nocode    los rangos que no son código
    tools/                    el trazador, el generador y las herramientas de dibujo
    docs/                     la web, en castellano e inglés

## Cómo se corre

El cartucho **no** se distribuye aquí. Hay que ponerlo en la raíz como
`roadfighter.rom` (16.384 bytes, sha256 `6d36c9e9b6a6b93f642722dcd314834d01e519ab3a98d7e4ca257468bcaf29e1`)
y ejecutar:

    make comprueba      # comprueba que el volcado es el bueno
    make                # traza, genera, reensambla, verifica y pasa los tests

Acaba con `OK: reproducible byte a byte`, que quiere decir que el listado
devuelve el cartucho exactamente.

## Algo de lo que apareció

- **El mapa de colisiones es la propia pantalla.** El juego no guarda en
  ninguna parte por dónde va la carretera: le pide al VDP el tile que hay bajo
  el coche y lo clasifica por tandas.
- **Una rutina escondida dentro de su propia tabla de punteros.** El
  `call 05716h` cae en los dos últimos bytes de una tabla de paisaje, que valen
  a la vez como puntero y como primera instrucción de la rutina que corre la
  carretera.
- **Las dos compilaciones se diferencian en un byte.** El 0x53CB, decimoquinto
  tramo de la etapa 5: una juega quince tramos por ciclo y la otra, catorce.
- **La carretera no existe: se fabrica**, fila a fila, en un anillo de 24×22 en
  RAM. Las seis carreteras de la web están dibujadas ejecutando ese motor, y
  cotejadas contra openMSX en 263 pasos sin una sola diferencia.
- **El coche tiene una franja muerta de velocidad**: entre 0x50 y 0x7E no se
  desplaza por la pantalla. Medido sobre 900 fotogramas.
- **Los colores van debajo de los patrones** en la memoria de vídeo, al revés
  de lo habitual.

La lista entera está en [Hallazgos](https://antxiko.github.io/RoadFighter-disassembly/es/HALLAZGOS.html),
y lo que **no** se sabe, en
[Preguntas abiertas](https://antxiko.github.io/RoadFighter-disassembly/es/PREGUNTAS-ABIERTAS.html).

## Crédito

El formato de la marca oculta de Konami al final de la ROM —el `RC-730` y el
título en katakana— lo descubrió **Manuel Pazos**.

## Legal

Esto es trabajo de preservación, estudio y documentación. El juego y sus
gráficos siguen siendo de sus titulares, y la imagen del cartucho no se
distribuye aquí. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
