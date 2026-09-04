#!/usr/bin/env python3
"""Rehace la VRAM del cartucho y la DIBUJA, sin capturar nada del emulador.

No hay ni una captura de pantalla en este repositorio: cada imagen sale de
correr en Python lo que hace el Z80, paso por paso y citando la direccion de
cada paso.

LA GEOMETRIA, QUE VA AL REVES DE LO NORMAL
------------------------------------------
Los ocho registros del VDP los escribe 0x4698 leyendolos de la tabla de
0x46A9, que son `02 E2 0E 7F 07 76 03 E4`:

    R0 = 0x02   SCREEN 2
    R1 = 0xE2   16K, pantalla encendida, interrupcion, SPRITES DE 16x16
    R2 = 0x0E   tabla de NOMBRES en 0x0E * 0x400 = 0x3800
    R3 = 0x7F   tabla de COLORES: el bit 7 esta a CERO, o sea base 0x0000
    R4 = 0x07   tabla de PATRONES: el bit 2 puesto, o sea base 0x2000
    R5 = 0x76   ATRIBUTOS de sprite en 0x76 * 0x80 = 0x3B00
    R6 = 0x03   PATRONES de sprite en 0x03 * 0x800 = 0x1800
    R7 = 0xE4   borde y fondo

Lo importante es R3 y R4: NO son una direccion, son base y mascara. Aqui
dejan los COLORES en 0x0000 y los PATRONES en 0x2000, justo al reves del
reparto habitual. El propio cartucho lo confirma: en 0x477f llena de 0xF0 la
zona de 0x0080 -letras blancas sobre transparente-, y 0xF0 solo tiene sentido
como color; como patron dejaria medio bloque pintado en cada tile.

LAS ESCENAS
-----------
Cada escena se monta con la lista de pasos que ejecuta el cartucho:

  titulo   0x4773 y 0x49A6: la fuente, el marcador y el rotulo grande
  juego    0x68AA y 0x744C: los tiles de carretera, sus espejos y los sprites

Uso: graficos.py <rom> <org> <carpeta destino>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rle import descomprime

ORG = 0x4000
COLORES = 0x0000        # R3 = 0x7F
PATRONES = 0x2000       # R4 = 0x07
NOMBRES = 0x3800        # R2 = 0x0E
SPRITES = 0x1800        # R6 = 0x03

# La paleta del TMS9918. El color 0 es TRANSPARENTE: se ve el fondo, que aqui
# lo dice R7 = 0xE4, o sea el color 4 (azul oscuro).
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]
# R7 vale 0xE4 en la presentacion -fondo azul- y el juego lo cambia a 0xE0, o
# sea fondo NEGRO. Comprobado en los registros que vuelca openMSX: `02 E2 0E
# 7F 07 76 03 E4` en el titulo y `... 03 E0` en marcha.
FONDO = PALETA[4]


def png(pix, ancho, alto, ruta, zoom=1):
    import struct
    import zlib
    if zoom > 1:
        grande = [None] * (ancho * zoom * alto * zoom)
        for y in range(alto):
            for x in range(ancho):
                c = pix[y * ancho + x]
                for dy in range(zoom):
                    for dx in range(zoom):
                        grande[(y * zoom + dy) * ancho * zoom + x * zoom + dx] = c
        pix, ancho, alto = grande, ancho * zoom, alto * zoom
    filas = bytearray()
    for y in range(alto):
        filas.append(0)
        for x in range(ancho):
            filas += bytes(pix[y * ancho + x])

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))
    open(ruta, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0))
        + trozo(b"IDAT", zlib.compress(bytes(filas), 9))
        + trozo(b"IEND", b""))


# ----------------------------------------------------------------------
# Los pasos del cartucho
# ----------------------------------------------------------------------

def carga(vram, rom, destino, origen):
    """L_45E0: el bloque, TRES veces, sumandole 0x800 al destino cada vez."""
    for t in range(3):
        r = descomprime(rom, ORG, origen, (destino + t * 0x800) & 0x3FFF)
        if r is None:
            raise SystemExit("0x%04X no descomprime" % origen)
        _, img, tocado, _ = r
        for i in range(0x4000):
            if tocado[i]:
                vram[i] = img[i]


def carga_directa(vram, rom, origen):
    """L_460B: igual, pero el destino va en los dos primeros bytes."""
    r = descomprime(rom, ORG, origen, None)
    if r is None:
        raise SystemExit("0x%04X no descomprime" % origen)
    _, img, tocado, _ = r
    for i in range(0x4000):
        if tocado[i]:
            vram[i] = img[i]


def llena(vram, destino, n, valor):
    """L_45CF: FILVRM en los tres tercios."""
    for t in range(3):
        d = (destino + t * 0x800) & 0x3FFF
        for i in range(n):
            vram[(d + i) & 0x3FFF] = valor


def espeja(vram, hl, de, c):
    """L_4652: lee C*8 bytes en HL, les da la vuelta y los deja en DE.

    El volteo es L_466E, `rr c / rla` ocho veces: el bit 0 pasa al 7. O sea
    el tile del reves, que es como el cartucho consigue la mitad derecha de
    la carretera sin guardarla.
    """
    for t in range(3):
        o = (hl + t * 0x800) & 0x3FFF
        d = (de + t * 0x800) & 0x3FFF
        for i in range(c * 8):
            b = vram[(o + i) & 0x3FFF]
            r = 0
            for _ in range(8):
                r = (r << 1) | (b & 1)
                b >>= 1
            vram[(d + i) & 0x3FFF] = r


def espeja_sprite(vram, hl, de, c):
    """L_4636: espeja C patrones de sprite, CAMBIANDO ADEMAS LAS MITADES.

    Un patron de 16x16 son 32 bytes: los 16 de la mitad izquierda y detras
    los 16 de la derecha. Para verlo del reves no basta con dar la vuelta a
    los bits: hay que cruzar las dos mitades, y eso es lo que hace el juego
    del registro E -sube 16, resta 0x20 y mira su bit 4-, que escribe los
    primeros 16 bytes 0x10 mas abajo y los siguientes 0x10 mas arriba.
    """
    for _ in range(c):
        for mitad in range(2):
            d = (de - (0x00 if mitad == 0 else 0x10)) & 0x3FFF
            for i in range(0x10):
                b = vram[hl & 0x3FFF]
                r = 0
                for _k in range(8):
                    r = (r << 1) | (b & 1)
                    b >>= 1
                vram[(d + i) & 0x3FFF] = r
                hl += 1
        de += 0x20


def rectangulo(vram, rom, hl, origen, filas, cols):
    """L_4575: `filas` renglones de `cols` tiles, saltando 0x20 por renglon."""
    p = origen - ORG
    for f in range(filas):
        for c in range(cols):
            vram[(hl + f * 0x20 + c) & 0x3FFF] = rom[p]
            p += 1


def guion(vram, rom, origen):
    """L_45F0: [destino][tiles...], 0xFE cambia de destino y 0xFF cierra."""
    p = origen - ORG
    while True:
        d = rom[p] | (rom[p + 1] << 8)
        p += 2
        d &= 0x3FFF
        while True:
            b = rom[p]
            p += 1
            if b == 0xFF:
                return
            if b == 0xFE:
                break
            vram[d & 0x3FFF] = b
            d += 1


def rotulo(vram, rom, hl, de, paso_hl, paso_de, filas, atras):
    """L_49EC: las tres filas del rotulo grande, que entran deslizandose.

    0x49f9 lee el byte y despues `ld a,c / cp 015h` decide el sentido: con
    C=0x15 el puntero avanza, y con C=0x11 RETROCEDE (`dec de / dec de /
    dec hl / dec hl` deshacen los `inc` y dejan un -1). Por eso la mitad de
    "ROAD" se recorre de derecha a izquierda desde 0x4b0c, y su 0xFF esta
    DELANTE de la fila, no detras.

    Las posiciones son las del final de la animacion, cuando (0xE004) vale 7:
    0x49d4 hace L = (0x20-(0xE004)) + 0x40 -> 0x59, y 0x49e4 hace
    L = (0xE004) + 0xC0 -> 0xC7.
    """
    for f in range(filas):
        h, d = hl + f * paso_hl, de + f * paso_de
        ini = d
        while True:
            b = rom[d - ORG]
            if b == 0xFF:
                break
            vram[h & 0x3FFF] = b
            h += -1 if atras else 1
            d += -1 if atras else 1
            if not atras and d - ini >= paso_de:
                break


def vram_limpia():
    return bytearray(0x4000)


def escena_titulo(rom, tono=1):
    """La pantalla de presentacion: 0x4773 y luego 0x49A6.

    `tono` es el par de colores del rotulo grande: 0x40ee lo saca del contador
    de 0xE004 con `and 003h`, asi que el rotulo va latiendo entre los cuatro
    pares de la tabla de 0x4112.
    """
    v = vram_limpia()
    # 0x489A: borra los 128 primeros de patron y pone un color por tile
    llena(v, PATRONES + 0x000, 0x80, 0x00)
    for i in range(16):                       # 0x48A4-0x48BA
        llena(v, COLORES + i * 8, 8, i)
    carga(v, rom, PATRONES + 0x080, 0x478A)   # 0x477C
    llena(v, COLORES + 0x080, 0x160, 0xF0)    # 0x477F: letras blancas
    carga(v, rom, PATRONES + 0x200, 0x490F)   # 0x48CF
    llena(v, COLORES + 0x200, 0xD8, 0xF0)     # 0x48D2
    carga(v, rom, PATRONES + 0x600, 0x4A25)   # 0x49B7
    llena(v, COLORES + 0x600, 0xB0, rom[0x4112 - ORG + tono * 2])      # 0x40FA
    llena(v, COLORES + 0x6B0, 0x58, rom[0x4112 - ORG + tono * 2 + 1])  # 0x4106
    rotulo(v, rom, 0x3859, 0x4B0C, 0x20, 0x11, 3, True)    # "ROAD",    0x49d7
    rotulo(v, rom, 0x38C7, 0x4B2F, 0x20, 0x15, 3, False)   # "FIGHTER", 0x49e7
    guion(v, rom, 0x472A)                     # 0x49C5: el texto del titulo
    guion(v, rom, 0x4751)                     # LEVEL B
    # La manita que senala la opcion elegida: 0x5045 hace `ld de,0475bh /
    # jp L_45F8`, o sea entra al interprete SALTANDOSE la lectura del destino,
    # que ya viene puesto en HL desde 0x5030 (la palabra 0x3A0A de 0x5033).
    guion_sin_destino(v, rom, 0x3A0A, 0x475B)
    return v


def guion_sin_destino(vram, rom, destino, origen):
    """L_45F8: como el interprete, pero el destino ya viene en HL."""
    p = origen - ORG
    d = destino & 0x3FFF
    while rom[p] != 0xFF:
        vram[d & 0x3FFF] = rom[p]
        p += 1
        d += 1


def escena_juego(rom, etapa=1):
    """El decorado de la carretera, en el orden en que lo monta el cartucho.

    Primero L_744C (0x4381) deja la calzada y el rotulo de salida, y despues
    L_68AA (0x419B) monta los tiles comunes y llama a L_6A30, que carga el
    decorado de ESTA etapa encima. Por eso lo de 0x74BC no se ve: se lo come
    el decorado, que va detras y al mismo sitio.
    """
    # Se parte de la VRAM que dejo el titulo, porque es lo que pasa de verdad:
    # el cartucho no la limpia entre pantalla y pantalla, y por eso durante la
    # partida siguen ahi los tiles del logotipo de Konami, invisibles porque
    # ninguna casilla de la tabla de nombres los nombra.
    v = escena_titulo(rom)
    for i in range(NOMBRES, 0x3B00):          # 0x4587: la tabla de nombres si
        v[i] = 0                              # se borra

    # L_744C (0x4381): la calzada
    carga(v, rom, PATRONES + 0x400, 0x74BC)   # 0x7452
    carga(v, rom, COLORES + 0x400, 0x7638)    # 0x745B
    rectangulo(v, rom, 0x382B, 0x76EC, 0x15, 0x05)     # 0x7467

    # L_68AA (0x419B): los tiles comunes a todas las etapas
    carga(v, rom, PATRONES + 0x200, 0x5DEC)   # 0x68B0
    carga(v, rom, COLORES + 0x200, 0x5F25)    # 0x68B9
    carga(v, rom, PATRONES + 0x680, 0x5FEC)   # 0x68C2
    carga(v, rom, COLORES + 0x680, 0x601D)    # 0x68CB
    espeja(v, PATRONES + 0x688, PATRONES + 0x6A8, 4)   # 0x68D6
    carga(v, rom, COLORES + 0x6A8, 0x601F)    # 0x68DF
    carga(v, rom, PATRONES + 0x6C8, 0x5FF7)   # 0x68E8
    carga(v, rom, COLORES + 0x6C8, 0x6022)    # 0x68F1
    espeja(v, PATRONES + 0x6C8, PATRONES + 0x708, 8)   # 0x68FC
    carga(v, rom, COLORES + 0x708, 0x6022)    # 0x6905
    carga(v, rom, PATRONES + 0x748, 0x6008)   # 0x690E
    carga(v, rom, COLORES + 0x748, 0x602D)    # 0x6917
    espeja(v, PATRONES + 0x760, PATRONES + 0x798, 6)   # 0x6922
    carga(v, rom, COLORES + 0x798, 0x6031)    # 0x692B
    carga_directa(v, rom, 0x5A71)             # 0x6931: sprites en 0x1800
    espeja_sprite(v, 0x1880, 0x1950, 6)       # 0x693C
    carga_directa(v, rom, 0x5B95)             # 0x6942: sprites en 0x1A00
    color_de_etapa(v, rom, etapa)             # 0x6945 -> L_6A06

    # el reparto por etapa de 0x6948
    if etapa in (1, 3, 6):
        decorado(v, rom, etapa)               # L_6A30 y nada mas
    elif etapa == 2:
        decorado(v, rom, etapa)               # 0x6989
        carga(v, rom, PATRONES + 0x588, 0x63AC)            # 0x6992
    elif etapa in (4, 5):                      # 0x6995
        carga(v, rom, PATRONES + 0x400, 0x63AC)            # 0x699B
        espeja(v, PATRONES + 0x400, PATRONES + 0x588, 0x18)  # 0x69A6
        carga(v, rom, COLORES + 0x588, 0x67C2)             # 0x69AF
        carga(v, rom, PATRONES + 0x400, 0x6645)            # 0x69B8
        espeja(v, PATRONES + 0x468, PATRONES + 0x400, 0x0D)  # 0x69C3
        carga(v, rom, COLORES + 0x400, 0x6737)             # 0x69CC
        carga(v, rom, COLORES + 0x468, 0x6737)             # 0x69D5
        carga(v, rom, PATRONES + 0x4D0, 0x6697)            # 0x69DE
        carga(v, rom, COLORES + 0x4D0, 0x675E)             # 0x69E7
        if etapa == 4:                                      # 0x69EA
            llena(v, COLORES + 0x430, 0x38, 0x66)
            llena(v, COLORES + 0x498, 0x38, 0x66)

    guion(v, rom, 0x470D)                     # el marcador
    guion(v, rom, 0x471F)                     # STAGE
    guion(v, rom, 0x476A)                     # los patrones 0x5a..0x5f
    return v


def color_de_etapa(vram, rom, etapa):
    """L_6A06: recolorea 128 bytes de color con el tono de la etapa.

    La tabla de 0x6A69 se indexa con la etapa SIN restarle uno, asi que su
    primer byte no lo usa nadie. De cada byte de color de 0x0748 se queda el
    nibble bajo y le mete el tono en el alto.
    """
    tono = rom[0x6A69 - ORG + etapa]
    for t in range(3):
        for i in range(0x80):
            d = (COLORES + t * 0x800 + 0x748 + i) & 0x3FFF
            vram[d] = tono | (vram[d] & 0x0F)


def decorado(vram, rom, etapa):
    """L_6A30: los dos bloques de ESTA etapa, de la tabla de 0x6A51."""
    p = 0x6A51 - ORG + (etapa - 1) * 4
    patron = rom[p] | (rom[p + 1] << 8)
    color = rom[p + 2] | (rom[p + 3] << 8)
    carga(vram, rom, PATRONES + 0x400, patron)   # 0x6A40
    carga(vram, rom, COLORES + 0x400, color)     # 0x6A4B



# ----------------------------------------------------------------------
# LA CARRETERA
# ----------------------------------------------------------------------
# El paisaje no vive en la VRAM: vive en un ANILLO de RAM de 24 filas por 22
# columnas, 0xE186..0xE395. L_572E lo vuelca entero a la tabla de nombres
# empezando en 0x3801 -o sea la columna 1-, fila a fila y saltando 0x20, y
# cuando el puntero llega a 0xE396 lo devuelve a 0xE186 (0x5753-0x575D). Las
# nueve columnas de la derecha no son carretera: son el cuadro de mandos.

ANILLO = 0xE186
ANILLO_FIN = 0xE396
ANCHO = 0x16                 # el `ld a,016h` de 0x7846 y el `ld b,016h` de 0x574B


def pega_retal(ram, rom, hl, de, veces):
    """L_783F. Devuelve DE despues de pegar, que es lo que usa el que sigue."""
    p = hl - ORG
    alto, ancho = rom[p], rom[p + 1]
    for _ in range(veces):
        q = p + 2
        for _f in range(alto):
            for c in range(ancho):
                ram[de - ANILLO + c] = rom[q]
                q += 1
            de += ANCHO
    return de


def carretera_de_salida(rom):
    """El paisaje de la salida, montado como lo monta 0x77C8.

    Se sigue el codigo instruccion a instruccion, porque los retales no traen
    su sitio: cada llamada hereda el DE que dejo la anterior y solo le cambia
    lo que hace falta -a veces nada mas que E-.
    """
    ram = bytearray(ANILLO_FIN + 0x20 - ANILLO)
    for i in range(0xE3AC - ANILLO):          # 0x77CE: todo hierba
        ram[i] = 0xA0
    de = pega_retal(ram, rom, 0x7875, 0xE18E, 6)    # 0x77D5  la calzada
    de = pega_retal(ram, rom, 0x78B2, 0xE198, 1)    # 0x77DF  el arcen
    de = pega_retal(ram, rom, 0x78B2, (de - 0x100) & 0xFF00 | 0xB3, 1)  # 0x77E8
    de = pega_retal(ram, rom, 0x78A5, (de & 0xFF00) | 0x36, 15)         # 0x77EE
    hl = de                                          # 0x77F8
    for i in range(5):
        ram[hl - ANILLO + i] = 0x4E
    ram[hl - ANILLO + 5] = 0x56
    de = pega_retal(ram, rom, 0x78BE, 0xE251, 14)   # 0x7804
    de = pega_retal(ram, rom, 0x785B, 0xE18A, 1)    # 0x780F  el arco de meta
    de = pega_retal(ram, rom, 0x789F, (de & 0xFF00) | 0x06, 13)         # 0x7818
    hl = de + 1                                      # 0x7822
    for i in range(3):
        ram[hl - ANILLO + i] = 0x4E
    de = pega_retal(ram, rom, 0x7893, (de & 0xFF00) | 0x31, 1)          # 0x782C  START
    de = pega_retal(ram, rom, 0x78AC, (de & 0xFF00) | 0x67, 1)          # 0x7834
    de = pega_retal(ram, rom, 0x78AC, 0xE338, 1)    # 0x783C
    return ram


def vuelca_carretera(vram, ram):
    """L_572E: las 24 filas de 22 a la tabla de nombres, desde 0x3801."""
    de = ANILLO
    for f in range(24):
        for c in range(ANCHO):
            vram[NOMBRES + f * 0x20 + 1 + c] = ram[de - ANILLO]
            de += 1
            if de == ANILLO_FIN:
                de = ANILLO


# ----------------------------------------------------------------------
# El dibujo
# ----------------------------------------------------------------------

def usa_fondo(c):
    """El color de fondo, que lo dice el nibble bajo de R7."""
    global FONDO
    FONDO = PALETA[c]


def pinta_celda(vram, fila, col, tile, pix, ancho):
    """Una celda de 8x8, con las tablas del tercio que le toca.

    En SCREEN 2 la pantalla son tres tercios independientes: la fila decide
    que copia de las tablas se usa, y por eso el mismo indice de patron puede
    dar dibujos distintos arriba y abajo.
    """
    tercio = (fila // 8) * 0x800
    for y in range(8):
        forma = vram[PATRONES + tercio + tile * 8 + y]
        color = vram[COLORES + tercio + tile * 8 + y]
        tinta = PALETA[color >> 4] if (color >> 4) else FONDO
        papel = PALETA[color & 15] if (color & 15) else FONDO
        for x in range(8):
            pix[(fila * 8 + y) * ancho + col * 8 + x] = \
                tinta if forma & (0x80 >> x) else papel


def pantalla(vram, ruta):
    pix = [FONDO] * (256 * 192)
    for f in range(24):
        for c in range(32):
            pinta_celda(vram, f, c, vram[NOMBRES + f * 32 + c], pix, 256)
    png(pix, 256, 192, ruta)


def hoja_de_tiles(vram, tercio, ruta):
    """Los 256 tiles de un tercio, en 16 filas de 16, con su color."""
    pix = [FONDO] * (16 * 8 * 16 * 8)
    base = tercio * 0x800
    for t in range(256):
        fx, fy = (t % 16) * 8, (t // 16) * 8
        for y in range(8):
            forma = vram[PATRONES + base + t * 8 + y]
            color = vram[COLORES + base + t * 8 + y]
            tinta = PALETA[color >> 4] if (color >> 4) else FONDO
            papel = PALETA[color & 15] if (color & 15) else FONDO
            for x in range(8):
                pix[(fy + y) * 128 + fx + x] = \
                    tinta if forma & (0x80 >> x) else papel
    png(pix, 128, 128, ruta, zoom=3)


def hoja_de_sprites(vram, ruta, n=64):
    """Los patrones de sprite de 16x16, en filas de ocho.

    El VDP los guarda en cuatro cuartos de 8x8: izquierda-arriba,
    izquierda-abajo, derecha-arriba y derecha-abajo. El color no esta aqui
    -lo pone la tabla de atributos, byte a byte y en marcha-, asi que se
    pintan en blanco.
    """
    filas = (n + 7) // 8
    ancho, alto = 8 * 16, filas * 16
    pix = [FONDO] * (ancho * alto)
    for s in range(n):
        ox, oy = (s % 8) * 16, (s // 8) * 16
        for cuarto in range(4):
            dx = 8 if cuarto >= 2 else 0
            dy = 8 if cuarto % 2 else 0
            for y in range(8):
                b = vram[SPRITES + s * 32 + cuarto * 8 + y]
                for x in range(8):
                    if b & (0x80 >> x):
                        pix[(oy + dy + y) * ancho + ox + dx + x] = PALETA[15]
    png(pix, ancho, alto, ruta, zoom=3)


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    if org != ORG:
        raise SystemExit("este cartucho va en 0x4000")
    salida = sys.argv[3]
    os.makedirs(salida, exist_ok=True)

    # R7 vale 0xE4 mientras esta el logotipo de la casa y 0xE0 ya en el menu,
    # que es la pantalla que se dibuja aqui. Medido en los volcados del
    # emulador: info_00 da E4 y info_04 da E0.
    usa_fondo(0)
    v = escena_titulo(rom)
    pantalla(v, os.path.join(salida, "titulo.png"))
    for t in range(3):
        hoja_de_tiles(v, t, os.path.join(salida, "tiles_titulo_%d.png" % t))

    usa_fondo(0)                              # R7 = 0xE0 durante la partida
    for e in range(1, 7):
        v = escena_juego(rom, e)
        vuelca_carretera(v, carretera_de_salida(rom))
        pantalla(v, os.path.join(salida, "carretera_%d.png" % e))
        hoja_de_tiles(v, 0, os.path.join(salida, "tiles_etapa_%d.png" % e))
        if e == 1:
            hoja_de_sprites(v, os.path.join(salida, "sprites.png"))
    print("escrito en %s" % salida)


if __name__ == "__main__":
    main()
