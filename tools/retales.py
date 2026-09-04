#!/usr/bin/env python3
"""Mide y dibuja los RETALES de tiles, ejecutando el pegador del cartucho.

El paisaje de la carretera no se guarda como una pantalla entera: se guarda
como retales rectangulares que L_783F pega en un buffer de RAM. Cada retal
empieza por sus dos medidas y detras van los tiles seguidos, fila a fila:

    [alto] [ancho] [tile ...]        alto * ancho bytes

Y el pegador, traducido:

    L_783F  push hl
            ld b,(hl) / inc hl      B = alto
            ld c,(hl) / inc hl      C = ancho
    L_7844  push bc
            ex af,af'
            ld a,016h / sub c       22 menos el ancho: lo que sobra de fila
            ld b,000h
            ldir                    la fila, C bytes
            ld c,a / ex af,af'
            ex de,hl / add hl,bc / ex de,hl   el destino salta al renglon
            pop bc
            djnz L_7844             alto filas
            pop hl
            dec a / jr nz,L_783F    A dice cuantas VECES se repite el retal
            inc a / ret

El 0x16 es lo que fija la anchura del buffer: VEINTIDOS columnas, no las 32
de la pantalla. Y el `dec a / jr nz` al final repite el mismo retal hacia
abajo tantas veces como diga A, que es como se alarga un tramo de carretera
sin gastar mas bytes.

El tamano de cada retal NO se estima: sale de sus dos primeros bytes, y la
suma de todos tiene que cerrar el hueco del presupuesto.

Uso: retales.py <rom> <org> <dir> [<dir> ...]     mide y dibuja cada retal
     retales.py <rom> <org> --seguidos <dir> <n>  n retales pegados
"""
import sys

ANCHO_BUFFER = 0x16     # las 22 columnas del `ld a,016h` de 0x7846

# La fuente del cartucho va como el ASCII a partir del espacio: el tile 0x21
# es la 'A'. Comprobado con "+/.!-)" -> KONAMI en 0x7f1d y "34!24" -> START
# en 0x7895.
DESPLAZAMIENTO_FUENTE = 0x20


def lee(rom, org, d):
    """Devuelve (alto, ancho, filas, fin) del retal que empieza en `d`."""
    p = d - org
    if p + 2 > len(rom):
        return None
    alto, ancho = rom[p], rom[p + 1]
    p += 2
    if alto == 0 or ancho == 0 or ancho > ANCHO_BUFFER:
        return None
    if p + alto * ancho > len(rom):
        return None
    filas = [rom[p + i * ancho:p + (i + 1) * ancho] for i in range(alto)]
    return alto, ancho, filas, org + p + alto * ancho


def texto(fila):
    """La fila leida como letras, para los retales que llevan rotulos."""
    out = []
    for b in fila:
        c = b + DESPLAZAMIENTO_FUENTE
        out.append(chr(c) if 0x20 <= c < 0x7F else '.')
    return ''.join(out)


def main():
    rom = open(sys.argv[1], 'rb').read()
    org = int(sys.argv[2], 0)
    args = sys.argv[3:]
    if args and args[0] == '--seguidos':
        d = int(args[1], 0)
        n = int(args[2], 0)
        dirs = []
        for _ in range(n):
            r = lee(rom, org, d)
            if r is None:
                break
            dirs.append(d)
            d = r[3]
    else:
        dirs = [int(a, 0) for a in args]

    total = 0
    for d in dirs:
        r = lee(rom, org, d)
        if r is None:
            print('0x%04X  NO es un retal' % d)
            continue
        alto, ancho, filas, fin = r
        total += fin - d
        print('0x%04X..0x%04X  %2d x %2d  %4d bytes'
              % (d, fin - 1, ancho, alto, fin - d))
        for f in filas:
            print('      ' + ' '.join('%02X' % b for b in f) + '   |' + texto(f) + '|')
        print()
    print('%d retales, %d bytes' % (len(dirs), total))


if __name__ == '__main__':
    main()
