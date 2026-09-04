# Preguntas abiertas

El cartucho está explicado al 100 % —ni un byte sin asignar— y reensambla byte
a byte. Eso no quiere decir que no queden cosas por saber. Éstas son, y están
aquí en vez de disimuladas en otra página.

## Cuál de las dos compilaciones se juega más difícil

Es la pregunta obvia y no está contestada.

Lo que **sí** está medido: las dos difieren en un solo byte, el 0x53CB, que es
el decimoquinto tramo de la fila de la etapa 5 en el plan de 0x537D. Con 0x05
esa etapa juega quince tramos por ciclo y con 0xFF, catorce. El que desaparece
es el tramo 5, cuyo registro es `00 04 18 08 08 28`.

Lo que **no** está medido: si quitar ese tramo hace la etapa más fácil o más
difícil. Un tramo menos por ciclo puede significar menos coches con los que
tropezar, o puede significar que el ciclo se repite antes y salen más deprisa
los que quedan. Sin jugarlo o sin contar los objetos que salen de verdad en un
ciclo completo, no se puede decir.

Los nombres "Easy" y "Hard" con los que circulan los dos volcados vienen del
catálogo de GoodMSX, no de la ROM, y aquí no valen como prueba de nada.

## Si el modo 5 de paisaje se usa alguna vez

La tabla de punteros de paisaje de 0x570C tiene cinco entradas, y la sexta
palabra ya es código. El índice sale del nibble bajo de (0xE07A), así que un
modo con nibble bajo 5 se saldría de la tabla y saltaría a 0x462A, dentro del
descompresor.

Que el cartucho use esos dos bytes como código es seguro: hay un `call 05716h`
explícito, y declararlos así sigue devolviendo la ROM byte a byte. Lo que no
está comprobado es si algún guion de paisaje llega a pedir el modo 5. Habría
que recorrer los guiones desde sus arranques de verdad, y esos arranques no
están todos identificados.

## Los arranques de los guiones de paisaje

Los pares [modo, cuenta] de 0x78C4 a 0x7C23 y de 0x7E60 a 0x7FE4 son los
guiones de paisaje, y a ellos apunta la tabla de 0x5161. Los arranques que se
usan de verdad están localizados —0x78C4 y 0x78E5, 0x7AAA, 0x7BAA, 0x7ACD,
0x7960, 0x7E60, 0x7E83, 0x7EA8, 0x7F6B y 0x7ED1—, pero **el final de cada uno
no está marcado**: 0x585F lee los dos bytes sin comprobar nada, y lo que corta
es que se acabe la etapa.

Eso significa que no se puede decir cuántos pares tiene cada guion sin
ejecutarlo con la etapa entera por delante.

## Por qué el coche baja al acelerar

Está medido que la Y del sprite crece con el acelerador pisado —o sea, el coche
baja por la pantalla— hasta clavarse en 0x9A, y que sin acelerar decrece. Eso
es un hecho.

Lo que no se sabe es si eso responde a una idea concreta del diseño o es sólo
la forma más barata de dar sensación de velocidad. Aquí no se especula.

## Los tres bloques encabalgados

Está medido que tres bloques comprimidos cierran más allá de su rango, comiendo
el bloque siguiente entero o parte de él. Lo que no se sabe es si eso es
deliberado —una compresión aprovechando la cola— o el resultado de que la
herramienta con la que Konami los generó los dejara así por casualidad.

Los tres cierran solos en su 0x00 y los tres cuadran con la VRAM del emulador,
así que la lectura no está en duda. La intención, sí.

## El punto ciego del trazado

Queda uno, y está declarado: el `JP (HL)` de 0x404E, que es el despachador
genérico. No se puede resolver siguiendo saltos porque su destino sale de una
tabla distinta cada vez. Las seis tablas están todas declaradas a mano en el
`.entries`, cada una con su justificación, y el presupuesto cierra en 16.384
bytes sin ninguna zona sin explicar.
