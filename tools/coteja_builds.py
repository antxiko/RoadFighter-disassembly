#!/usr/bin/env python3
"""Compara las dos compilaciones de Yie Ar Kung-Fu POR INSTRUCCION.

Byte a byte, la version facil y la dificil difieren en 15.618 de 16.384 bytes,
o sea el 95 %. Esa cifra no dice nada: las dos estan RELOCALIZADAS, y un byte
de mas en un sitio desplaza todo lo que va detras. Con el codigo desplazado se
desplazan tambien todas las direcciones absolutas, asi que la comparacion byte
a byte da casi el 100 % de diferencias aunque el programa sea el mismo.

Lo que si dice algo es comparar las INSTRUCCIONES, y comparar su FORMA sin las
direcciones. Este fichero:

  1. Recorre cada ROM instruccion a instruccion, con la tabla de longitudes del
     Z80 -no hace falta desensamblar de verdad, solo saber donde acaba cada
     una-, partiendo de los tramos que el trazado de la version facil dio por
     codigo.
  2. Normaliza cada instruccion: se queda con los bytes de OPCODE y sustituye
     por un comodin todo operando de 16 bits que caiga dentro del cartucho
     (0x4000-0x7FFF), que es justamente lo que la relocalizacion cambia.
  3. Alinea las dos listas con difflib y cuenta lo que comparten.

Uso: coteja_builds.py <rom facil> <rom dificil> <traza de la facil>
"""
import difflib
import json
import sys

ORG = 0x4000

# Longitud de cada instruccion por su primer byte. Los prefijos se tratan
# aparte. Lo unico que hace falta es avanzar bien, no dar nombres.
LARGO = [
    1, 3, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,   # 00-0F
    2, 3, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1,   # 10-1F
    2, 3, 3, 1, 1, 1, 2, 1, 2, 1, 3, 1, 1, 1, 2, 1,   # 20-2F
    2, 3, 3, 1, 1, 1, 2, 1, 2, 1, 3, 1, 1, 1, 2, 1,   # 30-3F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 40-4F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 50-5F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 60-6F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 70-7F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 80-8F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 90-9F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # A0-AF
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # B0-BF
    1, 1, 3, 3, 3, 1, 2, 1, 1, 1, 3, 2, 3, 3, 2, 1,   # C0-CF  (CB = 2)
    1, 1, 3, 2, 3, 1, 2, 1, 1, 1, 3, 2, 3, 3, 2, 1,   # D0-DF  (DD aparte)
    1, 1, 3, 1, 3, 1, 2, 1, 1, 1, 3, 1, 3, 3, 2, 1,   # E0-EF  (ED aparte)
    1, 1, 3, 1, 3, 1, 2, 1, 1, 1, 3, 1, 3, 3, 2, 1,   # F0-FF  (FD aparte)
]

# Instrucciones de dos bytes bajo el prefijo ED que llevan direccion.
ED_LARGO_4 = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}


def largo(b, p):
    """Cuantos bytes ocupa la instruccion que empieza en p."""
    o = b[p]
    if o == 0xCB:
        return 2
    if o == 0xED:
        return 4 if p + 1 < len(b) and b[p + 1] in ED_LARGO_4 else 2
    if o in (0xDD, 0xFD):
        if p + 1 >= len(b):
            return 2
        s = b[p + 1]
        if s == 0xCB:
            return 4
        n = LARGO[s]
        # con prefijo, las que llevan (ix+d) meten un byte mas
        if 0x34 <= s <= 0x36 or (0x46 <= s <= 0x7E and s & 0x07 == 6) or \
           (0x70 <= s <= 0x77) or (0x86 <= s <= 0xBE and s & 0x07 == 6):
            n += 1
        return 1 + n
    return LARGO[o]


def normaliza(b, p, n):
    """La instruccion, con las direcciones del cartucho sustituidas.

    Solo se toca el operando de 16 bits cuando cae dentro de 0x4000-0x7FFF,
    que es lo que la relocalizacion mueve. Una constante como 0x0080 o una
    direccion de RAM como 0xE000 se dejan tal cual, porque esas NO cambian y
    son justamente las que confirman que se trata de la misma instruccion.
    """
    t = b[p:p + n]
    if n >= 3:
        w = t[n - 2] | (t[n - 1] << 8)
        if 0x4000 <= w < 0x8000:
            return bytes(t[:n - 2]) + b'\xAA\xAA'
    return bytes(t)


def instrucciones(b, tramos):
    """Recorre los tramos de codigo y devuelve la lista normalizada."""
    fuera = []
    for a, z in tramos:
        p = a - ORG
        fin = min(z - ORG, len(b))
        while p < fin:
            n = largo(b, p)
            if p + n > fin:
                break
            fuera.append(normaliza(b, p, n))
            p += n
    return fuera


def main():
    facil = open(sys.argv[1], 'rb').read()
    dificil = open(sys.argv[2], 'rb').read()
    traza = json.load(open(sys.argv[3]))
    tramos = [(a, z) for tipo, a, z in traza['blocks'] if tipo == 'c']

    print('Byte a byte:')
    d = sum(1 for i in range(min(len(facil), len(dificil))) if facil[i] != dificil[i])
    print('  %d de %d bytes distintos (%.1f %%)\n'
          % (d, len(facil), 100.0 * d / len(facil)))

    a = instrucciones(facil, tramos)
    # de la dificil se recorre TODO el cartucho, porque no se sabe donde
    # empieza cada tramo suyo
    b = instrucciones(dificil, [(ORG, ORG + len(dificil))])
    print('Por instruccion:')
    print('  la facil, en sus tramos de codigo: %d instrucciones' % len(a))
    print('  la dificil, de corrido:            %d instrucciones' % len(b))

    m = difflib.SequenceMatcher(None, a, b, autojunk=False)
    iguales = sum(n for _, _, n in m.get_matching_blocks())
    print('  COMPARTEN %d instrucciones (%.1f %% de la facil)\n'
          % (iguales, 100.0 * iguales / len(a)))

    print('Los tramos comunes mas largos:')
    bloques = sorted(m.get_matching_blocks(), key=lambda x: -x[2])[:12]
    for i, j, n in bloques:
        if n < 8:
            continue
        print('  %5d instrucciones' % n)


if __name__ == '__main__':
    main()
