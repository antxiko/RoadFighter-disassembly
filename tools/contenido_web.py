#!/usr/bin/env python3
"""El CONTENIDO de la portada: los hallazgos y los pies de la galeria.

Va aparte de make_web.py a proposito. make_web.py es el generador -la
plantilla, la maquetacion, el HTML- y no cambia de un juego al siguiente; esto
es lo unico que hay que reescribir entero en cada cartucho. Teniendolo separado
no hay que ir buscando los textos del juego anterior dentro del generador, que
es justo como se han colado los nombres equivocados otras veces.

Cada hallazgo es (titulo, html) y cada entrada de galeria
(fichero, pie en castellano, pie en ingles).
"""

HALLAZGOS = {
    "es": [
        ('El mapa de colisiones es la propia pantalla',
         '<p>Este cartucho no guarda en ninguna parte por donde va la '
         'carretera. Para saber si el coche ha tocado el borde <b>lee la '
         'pantalla</b>: la rutina de 0x6D8B calcula la casilla en la que esta '
         'el coche, se la pide al VDP con <code>SETRD</code> y se trae con un '
         '<code>in a,(c)</code> el tile que hay dibujado ahi.</p>'
         '<p>Despues lo clasifica por tandas: por debajo de 0xCF hay golpe '
         'seguro, de 0xCF a 0xD8 esta libre, y de 0xD9 a 0xE8 es el borde y '
         'hay que afinar hasta el pixel. Es la manera mas barata de que el '
         'coche choque con <b>lo que se ve</b>, sea lo que sea lo que la '
         'carretera haya pintado ahi.</p>'),
        ('La carretera no existe: se fabrica, fila a fila',
         '<p>No hay mapas de circuito. Hay un <b>anillo de RAM de veinticuatro '
         'filas por veintidos columnas</b> en 0xE186, y cada vez que la '
         'carretera avanza se retrocede el puntero una fila y se mete una fila '
         'nueva en el hueco que queda. No se mueve un solo byte de paisaje: lo '
         'que se mueve es por donde se empieza a leer.</p>'
         '<p>Y la fila nueva la arma un motor con <b>una rama por etapa</b>: '
         'la 2 pega cuatro columnas de una lista ciclica, la 3 saca la fila '
         'entera de una palabra de dieciseis bits, la 4 guarda siete columnas '
         'y calcula el espejo sumando 0x0D a cada tile, la 5 hace lo mismo con '
         'cuatro, y la 6 es como la 3 pero ademas rehace las lineas encima.</p>'
         '<p>Las seis carreteras de esta pagina estan dibujadas ejecutando ese '
         'motor en Python, rutina por rutina. La comprobacion no es que se '
         'vean bien: es que en <b>264 pasos cotejados contra openMSX</b> -44 '
         'por etapa- el anillo entero de 528 bytes y todas las variables del '
         'generador salieron identicos a los de la maquina.</p>'),
        ('Una rutina escondida dentro de su propia tabla de punteros',
         '<p>0x5540 hace <code>call 05716h</code>, y 0x5716 cae <b>dentro</b> '
         'de la tabla de punteros de paisaje de 0x570C: son sus dos ultimos '
         'bytes. Konami los usa para dos cosas a la vez. Leidos como palabra '
         'son la sexta entrada de la tabla; ejecutados son el '
         '<code>ld hl,(0e046h)</code> con el que arranca la rutina que corre '
         'el anillo.</p>'
         '<p>Que la sexta entrada apunte a 0x462A -un <code>jr</code> de '
         'dentro del descompresor RLE, que no es ningun dibujo de paisaje- es '
         'lo que delata el truco: la tabla tiene <b>cinco</b> entradas, y lo '
         'que sigue ya es codigo. Estos treinta y seis bytes estuvieron todo '
         'el desensamblado clasificados como datos que no lee nadie.</p>'),
        ('Las dos compilaciones se diferencian en UN byte',
         '<p>Del cartucho circulan dos volcados. Difieren en '
         '<b>un solo byte, el 0x53CB</b>: uno tiene 0x05 y el otro 0xFF.</p>'
         '<p>Ese byte es el decimoquinto tramo de la fila de la <b>etapa '
         '5</b> en el plan de 0x537D, que son seis filas de dieciseis bytes '
         'cerradas con 0xFF. Medido en el emulador colocando el puntero al '
         'final de esa fila: la version con 0x05 juega <b>quince</b> tramos '
         'por ciclo y la del 0xFF, <b>catorce</b>. El que desaparece es el '
         'tramo 5.</p>'
         '<p>Cual de las dos se juega mas dificil no se dice aqui, porque no '
         'se ha medido. Los nombres "Easy" y "Hard" con los que circulan son '
         'del volcado, no de la ROM.</p>'),
        ('El coche tiene una franja muerta de velocidad',
         '<p>Acelerando, el coche avanza por la pantalla 0x48 de 256 de pixel '
         'por fotograma. Pero no siempre: la rutina de 0x6C93 solo lo deja '
         'moverse con la velocidad <b>entre 0x18 y 0x50, o por encima de '
         '0x7E</b>. Entre 0x50 y 0x7E se queda clavado donde este.</p>'
         '<p>Esta medido, no deducido: en 900 fotogramas de la demostracion la '
         'Y del coche se queda quieta en 0x8FC0 mientras la velocidad sube de '
         '0x51 a 0x7D, y vuelve a moverse en cuanto pasa de 0x7E. Cumplen la '
         'prediccion 57 de los 58 fotogramas comparables, y el que no cae '
         'justo en la frontera entre dos muestras.</p>'),
        ('CHECK POINT, y GOAL solo en la ultima',
         '<p>El final de etapa tiene <b>tres hitos separados por nueve</b>, '
         'que son nueve filas de anillo: a 0x0F00 de recorrido se suelta el '
         'coche rival, a 0x0F09 se pinta el rotulo de meta y a 0x0F12 se '
         'cruza.</p>'
         '<p>Y el rotulo no es el mismo siempre: en las cinco primeras etapas '
         'son los once tiles de <code>CHECK POINT</code>, y en la sexta los '
         'cinco de <code>GOAL</code>, tres columnas mas a la derecha. Se leen '
         'con la misma regla que el resto de textos del cartucho -el indice de '
         'patron es el codigo ASCII menos 0x20- y se comprobaron '
         '<b>dibujandolos</b> desde la VRAM del emulador.</p>'),
        ('La calzada simetrica sale gratis',
         '<p>La etapa 3 dibuja la fila entera desde <b>una sola palabra de '
         'dieciseis bits</b>: cada bit elige uno de dos tiles. Se piden doce '
         'columnas y despues diez mas, pero la segunda llamada <b>vuelve a '
         'cargar la misma palabra desde el principio</b>, porque el puntero no '
         'se ha movido.</p>'
         '<p>El resultado es que las columnas 12 a 21 repiten el dibujo de las '
         'diez primeras: la calzada sale simetrica sin gastar un byte de mas '
         'ni una instruccion de mas. No es un descuido, es el ahorro.</p>'),
        ('Los colores van debajo de los patrones, al reves de lo normal',
         '<p>En SCREEN 2 lo habitual es poner los patrones en 0x0000 y los '
         'colores en 0x2000. Aqui es al reves, y lo dicen los ocho bytes que '
         'el cartucho carga en los registros del VDP -la tabla de 0x46A9, que '
         'vale <code>02 E2 0E 7F 07 76 03 E4</code>-: <b>R3=0x7F</b> pone los '
         'colores en 0x0000 y <b>R4=0x07</b> los patrones en 0x2000.</p>'
         '<p>R3 y R4 no son direcciones, son base y mascara, y leerlos como si '
         'lo fueran da un resultado que <b>parece</b> bueno: las formas salen '
         'bien y los colores a franjas. Lo confirma el propio cartucho, que en '
         '0x477F llena de 0xF0 la zona de 0x0080, y 0xF0 solo tiene sentido '
         'como color.</p>'),
        ('El nivel no cambia solo la dificultad: cambia el cartucho',
         '<p>LEVEL A y LEVEL B no son un multiplicador. El nivel, que vive en '
         '(0xE03B), se mete por medio en <b>cuatro sitios distintos</b>: '
         'dobla o no el empuje lateral con el que salen los objetos (0x706D), '
         'cambia el paso del gasto de gasolina -0x0180 contra 0x01FF, en '
         '0x7374-, cambia la cuenta de espera del reparto de objetos entre '
         'siete y doce (0x6F72), y <b>suprime un tramo entero</b>: en el '
         'primer nivel el tramo 0x0A se cambia por el 9 (0x7044).</p>'),
        ('La marca oculta de Konami',
         '<p>Los ultimos quince bytes del cartucho no los lee nadie: son '
         '<code>RC-730</code> y el titulo en katakana, '
         '<b>&#12525;&#12540;&#12489;&#12501;&#12449;&#12452;&#12479;&#12540;'
         '</b>, escritos del reves y rematados con la longitud, las dos cifras '
         'del RC en BCD y un 0xAA.</p>'
         '<p>El formato de esa firma lo descubrio <b>Manuel Pazos</b>, y sin '
         'su hallazgo estos quince bytes se habrian quedado en "datos que no '
         'lee nadie". Las gracias, desde aqui.</p>'),
    ],
    "en": [
        ('The collision map is the screen itself',
         '<p>This cartridge stores nowhere where the road actually is. To find '
         'out whether the car has touched the verge it <b>reads the '
         'screen</b>: the routine at 0x6D8B works out the cell the car is in, '
         'asks the VDP for it with <code>SETRD</code> and pulls back, with a '
         'single <code>in a,(c)</code>, whatever tile is drawn there.</p>'
         '<p>Then it sorts it into bands: below 0xCF it is a certain crash, '
         '0xCF to 0xD8 is clear, and 0xD9 to 0xE8 is the verge and needs '
         'pixel-level checking. It is the cheapest way to make the car hit '
         '<b>what you can see</b>, whatever the road happened to paint '
         'there.</p>'),
        ('The road does not exist: it is manufactured, row by row',
         '<p>There are no track maps. There is a <b>ring of RAM, twenty-four '
         'rows by twenty-two columns</b> at 0xE186, and every time the road '
         'moves the pointer steps back one row and a new row goes into the gap '
         'it leaves. Not one byte of scenery moves: what moves is where you '
         'start reading.</p>'
         '<p>And the new row is built by an engine with <b>one branch per '
         'stage</b>: stage 2 pastes four columns from a cyclic list, stage 3 '
         'pulls the whole row out of a single sixteen-bit word, stage 4 stores '
         'seven columns and computes the mirror by adding 0x0D to each tile, '
         'stage 5 does the same with four, and stage 6 is like 3 but also '
         'redraws the lane markings on top.</p>'
         '<p>The six roads on this page are drawn by running that engine in '
         'Python, routine by routine. The check is not that they look right: '
         'it is that across <b>264 steps compared against openMSX</b> -44 per '
         'stage- the entire 528-byte ring and every generator variable came '
         'out identical to the machine\'s.</p>'),
        ('A routine hidden inside its own pointer table',
         '<p>0x5540 does <code>call 05716h</code>, and 0x5716 lands '
         '<b>inside</b> the scenery pointer table at 0x570C: it is its last '
         'two bytes. Konami uses them for two things at once. Read as a word '
         'they are the table\'s sixth entry; executed they are the '
         '<code>ld hl,(0e046h)</code> that starts the routine which advances '
         'the ring.</p>'
         '<p>The giveaway is that the sixth entry points at 0x462A - a '
         '<code>jr</code> inside the RLE decompressor, which is no scenery '
         'artwork at all. The table has <b>five</b> entries, and what follows '
         'is already code. These thirty-six bytes spent the whole disassembly '
         'classified as data nobody reads.</p>'),
        ('The two builds differ by ONE byte',
         '<p>Two dumps of this cartridge are in circulation. They differ by '
         '<b>a single byte, 0x53CB</b>: one has 0x05, the other 0xFF.</p>'
         '<p>That byte is the fifteenth segment in the <b>stage 5</b> row of '
         'the plan at 0x537D, six rows of sixteen bytes each closed with 0xFF. '
         'Measured in the emulator by placing the pointer at the end of that '
         'row: the 0x05 version plays <b>fifteen</b> segments per cycle and '
         'the 0xFF one, <b>fourteen</b>. The one that vanishes is segment '
         '5.</p>'
         '<p>Which of the two plays harder is not claimed here, because it has '
         'not been measured. The "Easy" and "Hard" labels they circulate under '
         'come from the dump, not from the ROM.</p>'),
        ('The car has a dead band of speed',
         '<p>Under acceleration the car moves up the screen by 0x48 of 256 of '
         'a pixel per frame. But not always: the routine at 0x6C93 only lets '
         'it move while the speed is <b>between 0x18 and 0x50, or above '
         '0x7E</b>. Between 0x50 and 0x7E it stays put.</p>'
         '<p>This is measured, not inferred: across 900 frames of the attract '
         'mode the car\'s Y sits still at 0x8FC0 while the speed climbs from '
         '0x51 to 0x7D, and starts moving again the moment it passes 0x7E. '
         '57 of the 58 comparable frames match the prediction, and the one '
         'that does not falls exactly on the boundary between two samples.</p>'),
        ('CHECK POINT, and GOAL only on the last one',
         '<p>The end of a stage has <b>three marks nine apart</b>, which is '
         'nine ring rows: at 0x0F00 of distance the rival car is released, at '
         '0x0F09 the finish sign is painted and at 0x0F12 it is crossed.</p>'
         '<p>And the sign is not always the same: the first five stages get '
         'the eleven tiles of <code>CHECK POINT</code>, and the sixth the five '
         'of <code>GOAL</code>, three columns further right. They read with '
         'the same rule as every other text in the cartridge -the pattern '
         'index is the ASCII code minus 0x20- and were confirmed by '
         '<b>drawing them</b> out of the emulator\'s VRAM.</p>'),
        ('The symmetrical road comes free',
         '<p>Stage 3 draws the whole row from <b>a single sixteen-bit word</b>: '
         'each bit picks one of two tiles. Twelve columns are asked for and '
         'then ten more, but the second call <b>reloads the same word from the '
         'start</b>, because the pointer has not moved.</p>'
         '<p>The upshot is that columns 12 to 21 repeat the pattern of the '
         'first ten: the road comes out symmetrical without spending one extra '
         'byte or one extra instruction. It is not an oversight, it is the '
         'saving.</p>'),
        ('Colours sit below patterns, the wrong way round',
         '<p>In SCREEN 2 the usual layout is patterns at 0x0000 and colours at '
         '0x2000. Here it is the other way round, and the eight bytes the '
         'cartridge loads into the VDP registers say so - the table at 0x46A9, '
         'which reads <code>02 E2 0E 7F 07 76 03 E4</code>: <b>R3=0x7F</b> '
         'puts colours at 0x0000 and <b>R4=0x07</b> patterns at 0x2000.</p>'
         '<p>R3 and R4 are not addresses, they are a base and a mask, and '
         'reading them as if they were gives a result that <b>looks</b> right: '
         'the shapes come out fine and the colours come out in stripes. The '
         'cartridge itself confirms it, filling the area at 0x0080 with 0xF0 '
         'at 0x477F, and 0xF0 only makes sense as a colour.</p>'),
        ('The level does not just change the difficulty: it changes the '
         'cartridge',
         '<p>LEVEL A and LEVEL B are not a multiplier. The level, which lives '
         'at (0xE03B), gets involved in <b>four separate places</b>: it '
         'doubles or does not double the sideways push objects come out with '
         '(0x706D), it changes the fuel-burn step - 0x0180 against 0x01FF, at '
         '0x7374 -, it changes the object spawn delay between seven and twelve '
         '(0x6F72), and it <b>removes an entire segment</b>: on the first '
         'level segment 0x0A is swapped for 9 (0x7044).</p>'),
        ('Konami\'s hidden mark',
         '<p>The last fifteen bytes of the cartridge are read by nobody: they '
         'are <code>RC-730</code> and the title in katakana, '
         '<b>&#12525;&#12540;&#12489;&#12501;&#12449;&#12452;&#12479;&#12540;'
         '</b>, written backwards and closed with the length, the two RC '
         'digits in BCD and an 0xAA.</p>'
         '<p>The format of that signature was discovered by <b>Manuel '
         'Pazos</b>, and without his find these fifteen bytes would have '
         'stayed filed under "data nobody reads". Our thanks.</p>'),
    ],
}

GALERIA = [
    ("titulo.png",
     "<b>La pantalla de titulo</b>, montada ejecutando los pasos del propio "
     "cartucho. El rotulo grande entra deslizandose desde los dos lados, y por "
     "eso la palabra ROAD esta guardada <b>al reves</b> en la ROM, con su 0xFF "
     "por delante",
     "<b>The title screen</b>, built by running the cartridge's own steps. The "
     "big wordmark slides in from both sides, which is why the word ROAD is "
     "stored <b>backwards</b> in the ROM, with its 0xFF in front"),
    ("salida.png",
     "La <b>salida</b>, con el arco de meta y el rotulo START. Esta pantalla "
     "no sale de ninguna lista: la monta a mano la rutina de 0x77C8, pegando "
     "ocho retales uno detras de otro y heredando cada llamada el destino que "
     "dejo la anterior",
     "The <b>start line</b>, with the finish arch and the START sign. This "
     "screen comes from no list: the routine at 0x77C8 builds it by hand, "
     "pasting eight patches one after another, each call inheriting the "
     "destination the previous one left behind"),
    ("pista_1.png",
     "<b>Etapa 1</b>, ciento veinte filas seguidas. No es una captura ni un "
     "mapa: es el motor de carretera del cartucho ejecutado en Python. Se ven "
     "las casas con su seto, la piscina, los coches aparcados, las pistas de "
     "tenis y un cartel de <b>Konami</b> al principio",
     "<b>Stage 1</b>, a hundred and twenty rows in a row. Not a capture and "
     "not a map: it is the cartridge's road engine run in Python. You can pick "
     "out the houses with their hedges, the swimming pool, the parked cars, "
     "the tennis courts and a <b>Konami</b> billboard near the top"),
    ("pista_2.png",
     "<b>Etapa 2</b>: la playa. La calzada se estrecha hacia el final del "
     "tramo, y las cuatro columnas de la izquierda salen de una lista ciclica "
     "propia de esta etapa, la de 0x7DC5",
     "<b>Stage 2</b>: the beach. The road narrows towards the end of the "
     "stretch, and the four columns on the left come from this stage's own "
     "cyclic list, the one at 0x7DC5"),
    ("pista_3.png",
     "<b>Etapa 3</b>: la unica que dibuja la fila entera desde una palabra de "
     "bits, y la unica que tiene tiles de calzada propios -0x9B y 0x04 en vez "
     "de 0x80 y 0x0F-, que es lo que le da ese borde distinto",
     "<b>Stage 3</b>: the only one that draws the whole row from a word of "
     "bits, and the only one with its own road tiles - 0x9B and 0x04 instead "
     "of 0x80 and 0x0F - which is what gives it that different edge"),
    ("pista_4.png",
     "<b>Etapa 4</b>: la curva en S. Aqui solo estan guardadas las siete "
     "columnas de un lado; las del otro se calculan sumando 0x0D a cada tile, "
     "que es el salto de un dibujo a su version espejada",
     "<b>Stage 4</b>: the S-bend. Only the seven columns on one side are "
     "stored; the ones on the other are computed by adding 0x0D to each tile, "
     "which is the jump from a drawing to its mirrored version"),
    ("pista_5.png",
     "<b>Etapa 5</b>, la que separa las dos compilaciones. El byte 0x53CB, el "
     "unico que las diferencia, es el decimoquinto tramo de esta fila del plan",
     "<b>Stage 5</b>, the one that tells the two builds apart. Byte 0x53CB, "
     "the only difference between them, is the fifteenth segment of this row "
     "of the plan"),
    ("pista_6.png",
     "<b>Etapa 6</b>: la ultima, la que remata con GOAL en vez de CHECK POINT. "
     "Trae su propio juego de guiones -no lo comparte con ninguna- y otro "
     "cartel de <b>KONAMI</b>, este en mayusculas",
     "<b>Stage 6</b>: the last one, the one that ends with GOAL instead of "
     "CHECK POINT. It brings its own set of scripts - shared with none of the "
     "others - and another <b>KONAMI</b> billboard, this one in capitals"),
    ("tiles.png",
     "Los <b>tiles de la etapa 1</b> con su color, tal como quedan en la VRAM. "
     "Arriba la fuente completa, ordenada como el ASCII a partir del espacio; "
     "por eso los textos del cartucho se leen restando 0x20 al indice de "
     "patron. Se ven tambien SPEED y FUEL, y el cartel de Konami",
     "The <b>stage 1 tiles</b> with their colour, exactly as they end up in "
     "VRAM. At the top the complete font, ordered like ASCII from the space "
     "onwards; that is why the cartridge's text reads by subtracting 0x20 from "
     "the pattern index. SPEED and FUEL are in there too, and the Konami "
     "billboard"),
    ("sprites.png",
     "Los <b>patrones de sprite</b>, en blanco porque en el MSX1 el color de "
     "un sprite va en su atributo y no en el patron. Estan los coches en sus "
     "posturas, las explosiones, las banderas y los rotulos de puntos: "
     "<b>300, 500, 800 y 1000</b>",
     "The <b>sprite patterns</b>, in white because on the MSX1 a sprite's "
     "colour lives in its attribute and not in the pattern. The cars in their "
     "poses are all there, the explosions, the flags and the score pop-ups: "
     "<b>300, 500, 800 and 1000</b>"),
]
