#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado y sobre la web.

Ninguna necesita el cartucho: se hacen sobre src/roadfighter.asm,
src/roadfighter.notes y el trazado. Vigilan que el listado no se degrade sin que
nadie se entere -que no desaparezcan comentarios, que no vuelvan a aparecer
bloques sin identificar- y que las cifras publicadas en la web sean las del
arbol y no las que habia cuando se escribio el texto.

Las de TestRLE, TestRotulos, TestRetales y TestTablas no miran el aspecto de
los bytes: EJECUTAN el descompresor, el interprete de rotulos y el pegador de
retales que se rehicieron en tools/. Si el formato estuviera mal leido, los
bloques no cerrarian donde cierran ni los rotulos dirian lo que dicen.
"""
import json
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "roadfighter.asm")
NOTES = os.path.join(RAIZ, "src", "roadfighter.notes")
ENTRIES = os.path.join(RAIZ, "src", "roadfighter.entries")
TRACE = os.path.join(RAIZ, "work", "roadfighter.trace.json")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0x8000

sys.path.insert(0, os.path.join(RAIZ, "tools"))

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE y
# con el pie de catorce paginas de otro proyecto.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Hyper Sports", "Nemesis", "Demonia", "Cabbage",
    "Hole in One", "Casio World Open", "3D Golf", "Baseball",
    "Yie Ar Kung-Fu", "King's Valley", "Sky Jaguar", "Mopi Ranger",
    "Ping Pong", "Descubrimiento", "War in Middle Earth",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bloques_del_listado(lineas):
    """Los mismos bloques que cuenta tools/densidad.py, con su misma logica.

    Dos detalles suyos hay que respetar o las cifras no cuadran: una etiqueta
    solo cuenta si su linea no lleva nada mas (salvo un comentario), y una
    linea es de INSTRUCCION cuando su direccion viene pegada al punto y coma
    (";4323"), mientras que las de datos llevan un espacio ("; 4323"). Por eso
    los bloques DATA_ salen con cero instrucciones y no cuentan como rutina.
    """
    bloques, nombre, ini, n, c = [], "(cabecera)", 0, 0, 0
    for ln in lineas:
        m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):\s*(;.*)?$", ln)
        if m:
            if n:
                bloques.append((nombre, ini, n, c))
            nombre, ini, n, c = m.group(1), 0, 0, 0
            continue
        m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
        if not m:
            continue
        if not ini:
            ini = int(m.group(1), 16)
        n += 1
        if ";" in m.group(2):
            c += 1
    if n:
        bloques.append((nombre, ini, n, c))
    return bloques


def rom_del_listado():
    """Reconstruye los BYTES DE DATOS del cartucho leyendo el listado.

    El cartucho no viaja con el repositorio, pero src/roadfighter.asm si, y cada
    fila de datos lleva su direccion en el comentario -eso lo pone mkasm.py-.
    Con las filas `defb` y `defw` se rehace un buffer de 16 KB con todas las
    zonas de datos en su sitio, que es lo unico que el descompresor necesita
    leer. Asi estos tests corren en un clon pelado, sin cartucho y sin `make`.
    """
    rom = bytearray(FIN - ORG)
    for linea in lee(ASM).splitlines():
        m = re.match(r"\s*(defb|defw)\s+([^;]+);\s*([0-9a-f]{4})", linea)
        if not m:
            continue
        que, cuerpo, addr = m.group(1), m.group(2), int(m.group(3), 16)
        p = addr - ORG
        for tok in cuerpo.split(","):
            tok = tok.strip()
            if not re.fullmatch(r"[0-9][0-9a-fA-F]*h", tok):
                continue
            v = int(tok[:-1], 16)
            if que == "defb":
                rom[p] = v & 0xFF
                p += 1
            else:
                rom[p] = v & 0xFF
                rom[p + 1] = (v >> 8) & 0xFF
                p += 2
    return bytes(rom)


def bloques_declarados():
    """Las directivas D del .notes: {nombre: (ini, fin, explicacion)}."""
    d = {}
    for m in re.finditer(
            r"^D\s+(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)\s+(\S+)(.*)$",
            lee(NOTES), re.MULTILINE):
        d[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16),
                         m.group(4).strip())
    return d


def como_texto(bs):
    """Los tiles leidos como letras: el indice de patron es el ASCII menos 0x20."""
    return "".join(chr(b + 0x20) if 0x20 <= b + 0x20 < 0x7F else "."
                   for b in bs)


class TestListado(unittest.TestCase):
    """El listado en si."""

    @classmethod
    def setUpClass(cls):
        cls.asm = lee(ASM)
        cls.lineas = cls.asm.splitlines()

    def test_no_quedan_bloques_sin_identificar(self):
        """Cada bloque de datos tiene que tener nombre y explicacion.

        mkasm.py escribe "DATOS sin identificar" en los bloques que no tienen
        una directiva D en el .notes. Que vuelva a aparecer uno significa que
        el trazado ha cambiado y hay bytes que ya nadie explica.
        """
        sueltos = [l for l in self.lineas if "DATOS sin identificar" in l]
        self.assertEqual(
            sueltos, [],
            "han vuelto a aparecer bloques sin identificar:\n"
            + "\n".join(sueltos))

    def test_todas_las_rutinas_llegan_al_liston(self):
        """Ninguna rutina por debajo del 10 % de densidad de comentario.

        Es el liston de la serie, y se mide igual que densidad.py: solo cuentan
        las rutinas de SEIS instrucciones o mas, porque por debajo de eso un
        solo comentario ya distorsiona el porcentaje.
        """
        flojas = ["%s 0x%04X (%d/%d)" % (nom, ini, c, n)
                  for nom, ini, n, c in bloques_del_listado(self.lineas)
                  if n >= 6 and c * 100 // n < 10]
        self.assertEqual(flojas, [],
                         "rutinas por debajo del 10 %%: %s" % ", ".join(flojas))

    def test_hay_al_menos_dos_mil_comentarios(self):
        """Un suelo para que un cambio no se lleve por delante el trabajo.

        El listado va por 2.224 comentarios de linea; el suelo se pone en dos
        mil para que quepa alguna reorganizacion sin que salte, pero no una
        perdida de verdad.
        """
        comentados = sum(1 for l in self.lineas
                         if re.search(r";[0-9a-f]{4}\s+;", l))
        self.assertGreaterEqual(comentados, 2000,
                                "solo quedan %d comentarios de linea"
                                % comentados)

    def test_las_etiquetas_son_snake_case(self):
        """mkasm.py no acepta parentesis ni espacios en un nombre de rutina.

        Cuando pasa, no da error: funde el bloque con el anterior y esa rutina
        desaparece de la cuenta sin avisar.
        """
        malas = []
        for linea in self.lineas:
            m = re.match(r"^([^\s:]+):", linea)
            if m and not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", m.group(1)):
                malas.append(m.group(1))
        self.assertEqual(malas, [], "etiquetas con caracteres raros: %s" % malas)

    def test_ninguna_cabecera_de_bloque_sale_repetida(self):
        """Cada cabecera de bloque, una sola vez.

        aplica_comentarios.py se puede correr varias veces, y hasta que se le
        enseno a filtrar las B repetidas metia otra vez las mismas: este
        listado llego a tener la misma cabecera DIEZ veces y noventa kilobytes
        de mas. Un `B` duplicado no rompe el ensamblado, asi que sin este test
        no lo caza nadie.
        """
        cabeceras = [m.group(1) for m in re.finditer(
            r"^B\s+(0x[0-9a-f]{4})\s", lee(NOTES), re.MULTILINE)]
        repes = sorted({d for d in cabeceras if cabeceras.count(d) > 1})
        self.assertEqual(repes, [], "cabeceras repetidas: %s" % repes)


class TestCobertura(unittest.TestCase):
    """El presupuesto de los 16 KB."""

    def test_el_trazado_cubre_el_cartucho_entero(self):
        """Codigo trazado mas datos declarados tienen que dar los 16.384."""
        if not os.path.exists(TRACE):
            self.skipTest("falta el trazado; corre `make trace` primero")
        with open(TRACE, encoding="utf-8") as f:
            trace = json.load(f)
        explicado = set()
        for tipo, ini, fin in trace["blocks"]:
            explicado.update(range(max(ini, ORG), min(fin, FIN)))
        for linea in lee(NOTES).splitlines():
            m = re.match(r"^D\s+(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)", linea)
            if m:
                explicado.update(range(int(m.group(1), 16),
                                       int(m.group(2), 16)))
        sin_explicar = sorted(set(range(ORG, FIN)) - explicado)
        self.assertEqual(
            sin_explicar, [],
            "%d bytes sin explicar, el primero en 0x%04X"
            % (len(sin_explicar), sin_explicar[0] if sin_explicar else 0))

    def test_las_entradas_estan_justificadas(self):
        """Cada punto de entrada lleva su razon escrita al lado.

        Una entrada sin justificar es una direccion que alguien metio a mano
        para que el trazado cuadrase, y eso es exactamente lo que no se puede
        hacer sin dejar constancia.
        """
        sin_razon = []
        for linea in lee(ENTRIES).splitlines():
            limpia = linea.strip()
            if not limpia or limpia.startswith("#"):
                continue
            if "#" not in limpia:
                sin_razon.append(limpia)
        self.assertEqual(sin_razon, [],
                         "entradas sin justificacion: %s" % sin_razon)


class TestNotas(unittest.TestCase):
    """El fichero de notas, que es donde vive lo entendido."""

    @classmethod
    def setUpClass(cls):
        cls.notes = lee(NOTES)

    def test_cada_bloque_de_datos_tiene_nombre_y_explicacion(self):
        """Ninguna directiva D puede quedarse en un nombre a secas.

        La norma de la serie es que cada bloque diga QUE es y COMO se sabe. Un
        bloque con nombre y sin explicacion esta bautizado, no entendido, que
        es justo lo que el nombre disimula.
        """
        pelados = []
        for m in re.finditer(
                r"^D\s+0x[0-9a-fA-F]+\s+0x[0-9a-fA-F]+\s+(\S+)(.*)$",
                self.notes, re.MULTILINE):
            if len(m.group(2).strip()) < 20:
                pelados.append(m.group(1))
        self.assertEqual(pelados, [],
                         "bloques D sin explicacion: %s" % pelados[:10])

    def test_las_anchuras_declaradas_apuntan_a_un_bloque(self):
        """Toda F tiene que caer en la direccion de arranque de una D.

        La F que se escribe con la direccion equivocada no da error: se aplica
        al bloque de al lado y le pone una anchura que no es la suya. Es un
        fallo silencioso, y este test es la unica forma de cazarlo.
        """
        inicios = {d.lower() for d in
                   re.findall(r"^D\s+(0x[0-9a-fA-F]+)", self.notes,
                              re.MULTILINE)}
        huerfanas = [f for f in re.findall(r"^F\s+(0x[0-9a-fA-F]+)",
                                           self.notes, re.MULTILINE)
                     if f.lower() not in inicios]
        self.assertEqual(huerfanas, [],
                         "anchuras que no caen en ningun bloque: %s"
                         % huerfanas)

    def test_las_zonas_de_datos_no_se_solapan(self):
        """Ninguna D puede pisar a otra.

        El cartucho SI reaprovecha la cola de tres de sus bloques comprimidos
        como cabeza del siguiente, pero eso no se declara con rangos que se
        pisen: cada D solo se queda con los bytes que son suyos, y el solape
        se explica en su texto. Asi el presupuesto de los 16 KB no cuenta un
        byte dos veces. Los solapes de verdad los mide TestRLE ejecutando el
        descompresor.
        """
        rangos = sorted((ini, fin, nom)
                        for nom, (ini, fin, _e) in bloques_declarados().items())
        solapes = ["%s 0x%04X..0x%04X con %s 0x%04X..0x%04X"
                   % (n1, i1, f1, n2, i2, f2)
                   for (i1, f1, n1), (i2, f2, n2) in zip(rangos, rangos[1:])
                   if i2 < f1]
        self.assertEqual(solapes, [], "zonas de datos que se pisan: %s" % solapes)


class TestRLE(unittest.TestCase):
    """El descompresor del cartucho, rehecho en tools/rle.py.

    No compara bytes: EJECUTA el descompresor sobre los datos del listado y
    comprueba que cada bloque cierra EXACTAMENTE donde su directiva D dice.
    Un formato mal leido no cerraria en el sitio ni una sola vez, y aqui son
    todos los del cartucho de golpe.
    """

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.decl = bloques_declarados()

    # Los dos bloques que el cartucho encabalga sobre el siguiente: cada uno
    # cierra MAS ALLA de su rango declarado, en el final del que viene detras.
    # No es un error de lectura -los dos cierran solos en su 0x00-, es que el
    # cartucho reaprovecha la cola. Su D solo declara los bytes exclusivos.
    ENCABALGADOS = {"rle_color_0680": 0x6022, "rle_color_0748": 0x603E}

    def test_cada_bloque_rle_cierra_donde_dice_su_directiva(self):
        from rle import descomprime
        comprobados = []
        for nom, (ini, fin, expl) in sorted(self.decl.items()):
            if not nom.startswith("rle_"):
                continue
            # el destino va dentro del bloque en los que lo dicen; los demas
            # lo reciben en HL, y para medir el final da igual cual se use
            dentro = "destino va dentro" in expl
            r = descomprime(self.rom, ORG, ini, None if dentro else 0x0000)
            self.assertIsNotNone(r, "%s (0x%04X) no cierra como RLE" % (nom, ini))
            esperado = self.ENCABALGADOS.get(nom, fin)
            self.assertEqual(
                r[0], esperado,
                "%s cierra en 0x%04X y deberia en 0x%04X"
                % (nom, r[0], esperado))
            if nom in self.ENCABALGADOS:
                self.assertIn("SOLAPE", expl,
                              "%s se encabalga y su directiva no lo dice" % nom)
            comprobados.append(nom)
        self.assertGreaterEqual(len(comprobados), 20,
                                "solo se han comprobado %d bloques RLE"
                                % len(comprobados))

    def test_los_tres_encabalgados_comparten_la_cola_entera(self):
        """El cartucho reaprovecha la cola de tres bloques comprimidos.

        En los dos de 0x601D y 0x602D la cola compartida es el bloque
        SIGUIENTE entero; en el de 0x5DEC son los treinta y dos ultimos bytes,
        que a su vez son la cabeza de otro bloque -el de 0x5F25- que el
        cartucho carga por su cuenta. Los tres se comprueban EJECUTANDO el
        descompresor, no mirando los bytes.
        """
        from rle import descomprime
        for nom, esperado in sorted(self.ENCABALGADOS.items()):
            ini, fin, _e = self.decl[nom]
            # el bloque de dentro cierra en el mismo sitio: es su cola
            self.assertEqual(descomprime(self.rom, ORG, fin, 0)[0], esperado,
                             "el bloque de 0x%04X no cierra donde %s"
                             % (fin, nom))
        # y el tercero, el de los sprites
        ini, fin, _e = self.decl["rle_patron_2200"]
        self.assertEqual(descomprime(self.rom, ORG, ini, 0x2200)[0], fin)
        self.assertEqual(fin - 0x5F25, 32,
                         "la cola compartida es de %d bytes, no de 32"
                         % (fin - 0x5F25))
        self.assertEqual(descomprime(self.rom, ORG, 0x5F25, 0)[0],
                         self.decl["rle_color_0200"][1],
                         "el bloque de 0x5F25 ya no cierra donde rle_color_0200")


class TestRotulos(unittest.TestCase):
    """Los textos del cartucho, leidos como texto de verdad.

    La fuente esta ordenada como el ASCII a partir del espacio, o sea que el
    indice de patron es el codigo menos 0x20. Que cinco bloques sueltos den
    palabras en ingles con esa misma regla es lo que demuestra que la regla es
    la buena; y los rotulos de meta se comprobaron ademas DIBUJANDO sus tiles
    desde la VRAM del emulador.
    """

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.decl = bloques_declarados()

    def trozo(self, nombre):
        ini, fin, _ = self.decl[nombre]
        return self.rom[ini - ORG:fin - ORG]

    def test_el_rotulo_de_meta_dice_check_point(self):
        self.assertEqual(como_texto(self.trozo("rotulo_check_point")),
                         "CHECK POINT")

    def test_la_sexta_etapa_remata_en_goal(self):
        self.assertTrue(como_texto(self.trozo("rotulo_goal")).startswith("GOAL"))

    def test_el_aviso_de_gasolina_dice_empty(self):
        self.assertEqual(como_texto(self.trozo("rotulo_empty")), "EMPTY")

    def test_los_guiones_de_rotulo_cierran_donde_dicen(self):
        """Cada guion se mide EJECUTANDO el interprete L_45F0 del cartucho."""
        from guiones import ejecuta
        n = 0
        for nom, (ini, fin, _e) in sorted(self.decl.items()):
            if not nom.startswith("guion_"):
                continue
            r = ejecuta(self.rom, ORG, ini)
            self.assertIsNotNone(r, "%s (0x%04X) no cierra" % (nom, ini))
            self.assertEqual(r[0], fin,
                             "%s cierra en 0x%04X y su directiva dice 0x%04X"
                             % (nom, r[0], fin))
            n += 1
        self.assertGreaterEqual(n, 5, "solo hay %d guiones de rotulo" % n)

    def test_el_guion_del_titulo_nombra_a_konami(self):
        from guiones import ejecuta
        ini, _f, _e = self.decl["guion_titulo"]
        texto = ejecuta(self.rom, ORG, ini)[1]
        self.assertIn("KONAMI", texto)
        self.assertIn("1985", texto)


class TestRetales(unittest.TestCase):
    """Los retales del paisaje de la salida, medidos con su propio pegador."""

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.decl = bloques_declarados()

    def test_cada_retal_mide_lo_que_dice_su_directiva(self):
        """La D de cada retal lleva escrito su tamano: "4 x 6", "7 x 4"...

        Lo que se compara es eso contra lo que sale de leer sus dos primeras
        medidas y recorrerlo entero. Un retal mal medido se saldria de su
        bloque o dejaria bytes sueltos detras.

        CUIDADO con el orden: las directivas dicen ANCHO x ALTO, que es como
        se lee un rectangulo, y la ROM guarda los dos bytes al reves. Este
        test se escribio la primera vez sin darles la vuelta y "corrigio" una
        directiva que estaba bien.
        """
        from retales import lee as lee_retal
        n = 0
        for nom, (ini, fin, expl) in sorted(self.decl.items()):
            if not nom.startswith("retal_"):
                continue
            m = re.search(r"(\d+)\s*x\s*(\d+)", expl)
            self.assertIsNotNone(m, "%s no dice su tamano" % nom)
            r = lee_retal(self.rom, ORG, ini)
            self.assertIsNotNone(r, "%s (0x%04X) no se puede leer" % (nom, ini))
            alto, ancho, _filas, final = r
            self.assertEqual((ancho, alto), (int(m.group(1)), int(m.group(2))),
                             "%s mide %d de ancho por %d de alto y su "
                             "directiva dice %s x %s"
                             % (nom, ancho, alto, m.group(1), m.group(2)))
            self.assertEqual(final, fin,
                             "%s acaba en 0x%04X y su directiva dice 0x%04X"
                             % (nom, final, fin))
            n += 1
        self.assertGreaterEqual(n, 8, "solo hay %d retales" % n)

    def test_el_retal_del_rotulo_dice_start(self):
        """El retal de 5 x 2 lleva la palabra escrita en tiles."""
        from retales import lee as lee_retal
        ini, _f, _e = self.decl["retal_start"]
        _alto, _ancho, filas, _fin = lee_retal(self.rom, ORG, ini)
        self.assertIn("START", "".join(como_texto(f) for f in filas))


class TestTablas(unittest.TestCase):
    """Las tablas del cartucho, y la prueba de donde acaba cada una."""

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.decl = bloques_declarados()

    def palabra(self, a):
        return self.rom[a - ORG] | (self.rom[a - ORG + 1] << 8)

    def test_el_plan_de_etapas_son_seis_filas_de_dieciseis(self):
        """SEIS etapas, una fila de dieciseis bytes cada una."""
        ini, fin, _ = self.decl["plan_de_las_etapas"]
        self.assertEqual(fin - ini, 6 * 16,
                         "el plan mide %d bytes" % (fin - ini))

    def test_cada_fila_del_plan_cierra_con_ff_y_se_rellena_con_ff(self):
        """La lista de tramos de cada etapa acaba en 0xFF, y detras solo 0xFF.

        Es lo que hace que la lista sea CICLICA sin llevar su longitud escrita:
        0x7020 recorre la fila y al topar con el 0xFF vuelve a su principio.
        """
        ini, _fin, _ = self.decl["plan_de_las_etapas"]
        for etapa in range(6):
            fila = self.rom[ini - ORG + etapa * 16:ini - ORG + etapa * 16 + 16]
            self.assertIn(0xFF, fila, "la etapa %d no cierra" % (etapa + 1))
            cola = fila[fila.index(0xFF):]
            self.assertEqual(set(cola), {0xFF},
                             "la etapa %d tiene algo detras de su 0xFF: %s"
                             % (etapa + 1, list(cola)))

    def test_la_diferencia_entre_las_dos_compilaciones_cae_en_el_plan(self):
        """0x53CB es el unico byte que separa la facil de la dificil.

        No hacen falta las dos ROM para comprobar lo que importa: que esa
        direccion cae dentro del plan de etapas, en la fila de la QUINTA, y
        que es su decimoquinto tramo. Con 0x05 la etapa juega quince tramos
        por ciclo y con 0xFF, catorce; esta MEDIDO en el emulador.
        """
        ini, fin, _ = self.decl["plan_de_las_etapas"]
        self.assertTrue(ini <= 0x53CB < fin, "0x53CB no cae en el plan")
        self.assertEqual((0x53CB - ini) // 16, 4, "no es la fila de la etapa 5")
        self.assertEqual((0x53CB - ini) % 16, 14, "no es el decimoquinto tramo")

    def test_la_tabla_de_tramos_son_quince_registros_de_seis(self):
        """Quince tramos, y cada uno arma DOS objetos de tres campos."""
        ini, fin, _ = self.decl["tabla_de_tramos"]
        self.assertEqual((fin - ini) % 6, 0, "no es multiplo de seis")
        self.assertEqual((fin - ini) // 6, 15,
                         "hay %d registros de tramo" % ((fin - ini) // 6))

    def test_todos_los_tramos_del_plan_existen_en_la_tabla(self):
        """Ningun valor de la lista puede caerse fuera de los quince tramos.

        0x7049 hace `dec a` antes de indexar, o sea que el 1 es el primer
        registro y el 15 el ultimo. Un valor por encima leeria basura.
        """
        pini, pfin, _ = self.decl["plan_de_las_etapas"]
        tini, tfin, _ = self.decl["tabla_de_tramos"]
        cuantos = (tfin - tini) // 6
        malos = sorted({b for b in self.rom[pini - ORG:pfin - ORG]
                        if b != 0xFF and not 1 <= b <= cuantos})
        self.assertEqual(malos, [],
                         "tramos que no existen en la tabla: %s" % malos)

    def test_la_altura_del_coche_baja_de_etapa_en_etapa(self):
        """0x8B, 0x71, 0x54, 0x3A, 0x1B, 0x00: estrictamente decreciente.

        Es la Y en la que el coche se planta al rematar cada etapa. Que la
        serie sea monotona no es casualidad: cada etapa lo hace subir un
        trecho mas largo que la anterior.
        """
        ini, fin, _ = self.decl["altura_del_coche_por_etapa"]
        alturas = list(self.rom[ini - ORG:fin - ORG])
        self.assertEqual(len(alturas), 6, "no son seis etapas")
        self.assertEqual(alturas, sorted(alturas, reverse=True),
                         "las alturas no bajan: %s" % alturas)
        self.assertEqual(alturas[-1], 0x00, "la sexta no acaba en cero")

    def test_la_tabla_de_escenas_tiene_nueve_entradas(self):
        """Nueve escenas, y la decima palabra ya no cae en la ROM.

        Es el encaje que fija el final de la tabla sin suponerlo: los dos
        bytes que seguirian son ya el `djnz` de 0x40AB, que es ademas el
        primer destino de la propia tabla.
        """
        ini, fin, _ = self.decl["tabla_de_escenas"]
        self.assertEqual((fin - ini) // 2, 9,
                         "hay %d escenas" % ((fin - ini) // 2))
        destinos = [self.palabra(ini + 2 * i) for i in range(9)]
        self.assertEqual(min(destinos), fin,
                         "la tabla cierra en 0x%04X y su primer destino es "
                         "0x%04X" % (fin, min(destinos)))

    def test_las_tablas_pegadas_detras_del_call_estan_declaradas(self):
        """Las SEIS tablas que van pegadas detras de su `call`.

        El despachador hace `pop hl` para recuperar su propia direccion de
        retorno, que es la tabla. El trazado no puede deducirlas solo: van
        declaradas en el .entries, y si alguna se cayera el listado seguiria
        ensamblando pero esos bytes pasarian a ser codigo inventado.
        """
        entries = lee(ENTRIES)
        for tabla in ("0x4099", "0x50C9", "0x5526", "0x570C", "0x6A80",
                      "0x70C9"):
            self.assertTrue(
                re.search(tabla, entries, re.IGNORECASE)
                or re.search(r"^D\s+%s" % tabla.lower(), lee(NOTES),
                             re.MULTILINE | re.IGNORECASE),
                "la tabla %s ya no esta declarada" % tabla)

    def test_la_marca_de_konami_dice_rc730(self):
        """La marca oculta que encontro Manuel Pazos, al final de la ROM.

        Formato: el titulo del reves, su longitud, las dos cifras del RC en BCD
        y un 0xAA. Aqui son diez bytes de titulo y el 0x30 de RC-730.
        """
        self.assertEqual(self.rom[0x7FFF - ORG], 0xAA, "no cierra con 0xAA")
        self.assertEqual(self.rom[0x7FFE - ORG], 0x30, "el RC no es 730")
        self.assertEqual(self.rom[0x7FFD - ORG], 0x0A,
                         "el titulo no mide diez bytes")


class TestPista(unittest.TestCase):
    """El generador de carretera rehecho en tools/pista.py.

    Este cartucho no lleva mapas: la carretera se GENERA fila a fila. Las seis
    ramas se comprobaron contra openMSX -tools/omsx_etapa.tcl fuerza la etapa
    en 0x504C y vuelca el estado en fotogramas seguidos-, y en los 264 pasos
    comparados el anillo entero de 528 bytes y todas las variables del
    generador salieron IDENTICAS a las de la maquina. tests/pistas.sha congela
    ese resultado; si pista.py se toca y deja de dar lo mismo, salta aqui.
    """

    def test_las_seis_pistas_dan_la_huella_comprobada(self):
        import hashlib
        ref = os.path.join(RAIZ, "tests", "pistas.sha")
        if not os.path.exists(ref):
            self.skipTest("falta tests/pistas.sha")
        try:
            from pista import corre
        except ImportError as e:
            self.skipTest("no se puede importar pista.py: %s" % e)
        rom = rom_del_listado()
        # las filas salen de listas y guiones, que son datos: el listado los
        # lleva enteros y por eso esto corre sin el cartucho
        for linea in lee(ref).splitlines():
            if linea.startswith("#") or not linea.strip():
                continue
            etapa, filas, sha = linea.split()
            m = corre(rom, int(etapa), int(filas))
            h = hashlib.sha256(b"".join(m.filas)).hexdigest()
            self.assertEqual(h, sha, "la etapa %s ya no genera la misma "
                             "carretera" % etapa)

    def test_la_carretera_cabe_en_las_veintidos_columnas(self):
        """Ninguna fila puede salir mas ancha que el anillo."""
        try:
            from pista import corre, ANCHO
        except ImportError as e:
            self.skipTest("no se puede importar pista.py: %s" % e)
        rom = rom_del_listado()
        for etapa in range(1, 7):
            for f in corre(rom, etapa, 240).filas:
                self.assertEqual(len(f), ANCHO,
                                 "la etapa %d da una fila de %d columnas"
                                 % (etapa, len(f)))


class TestWeb(unittest.TestCase):
    """La web: que las cifras sean las del arbol y no las del texto viejo."""

    def paginas(self):
        for carpeta, _dirs, ficheros in os.walk(DOCS):
            for fich in ficheros:
                if fich.endswith((".md", ".html")):
                    yield fich, lee(os.path.join(carpeta, fich))

    def test_no_se_nombra_otro_juego_de_la_serie(self):
        """El nombre de otro juego en estas paginas es un copia y pega.

        Ya paso con cinco ficheros LICENSE y con el pie de catorce paginas.
        """
        if not os.path.isdir(DOCS):
            self.skipTest("todavia no hay web")
        fallos = []
        for fich, texto in self.paginas():
            for juego in OTROS_JUEGOS:
                if juego in texto:
                    fallos.append("%s en %s" % (juego, fich))
        self.assertEqual(fallos, [], "nombres de otros juegos: %s" % fallos)

    def test_las_cifras_publicadas_son_las_del_listado(self):
        """La densidad y las rutinas flojas que dice la web, medidas ahora.

        Es el fallo que mas veces se ha colado en esta serie: se comenta mas,
        las cifras suben y el texto se queda con las de ayer.
        """
        if not os.path.isdir(DOCS):
            self.skipTest("todavia no hay web")
        bloques = bloques_del_listado(lee(ASM).splitlines())
        instr = sum(n for _no, _i, n, _c in bloques)
        coment = sum(c for _no, _i, _n, c in bloques)
        densidad = "%.1f" % (100.0 * coment / instr)
        vistas = 0
        for fich, texto in self.paginas():
            for m in re.finditer(r"(\d+),(\d)\s*%", texto):
                cifra = "%s.%s" % (m.group(1), m.group(2))
                if 15.0 <= float(cifra) <= 99.9:
                    self.assertEqual(
                        cifra, densidad,
                        "%s dice %s %% de densidad y el listado da %s %%"
                        % (fich, cifra.replace(".", ","),
                           densidad.replace(".", ",")))
                    vistas += 1
        if not vistas:
            self.skipTest("la web todavia no publica la densidad")


if __name__ == "__main__":
    unittest.main()
