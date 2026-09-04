#!/usr/bin/env python3
"""Mide las listas ciclicas de la carretera EJECUTANDO sus recorredores.

El juego lleva cuatro clases de lista, todas cerradas por 0xFF y todas
ciclicas: al llegar al 0xFF el puntero vuelve atras y la lista se repite. Los
limites no se estiman, se sacan corriendo el mismo recorrido que el Z80.

  bits    L_56CC. `ld b,00ch` y luego doce veces `sla l / rl h`: de cada
          palabra -guardada al reves, byte ALTO primero- se sacan los doce
          bits de arriba, y cada bit elige uno de dos tiles (0x80 o 0x0F, y en
          la etapa 3 el 0x9B o el 0x04). O sea que cada palabra es UNA FILA de
          doce casillas de calzada, y la lista entera es la animacion de la
          linea discontinua. Las usan 0x50D5 y 0x56C3 (0x7FE4) y 0x557A
          (0x7C85), con el puntero en 0xE090.

  cuatro  L_5545. Registros de CUATRO bytes que se copian a 0xE058, que es la
          fila nueva que 0x5732 mete en el anillo. Puntero en 0xE08A.

  bytes   0x5587. Lista de bytes con el puntero en 0xE06F; al topar con el
          0xFF retrocede 0x30 (`ld bc,0ffd0h / add hl,bc`), o sea que el ciclo
          son los ultimos 48 bytes, no la lista entera.

Uso: listas.py <rom> <org> <clase> <dir> [<dir> ...]
     clase = bits | cuatro | bytes
"""
import sys

ORG = 0x4000


def bits(rom, d):
    """Palabras de 12 bits utiles, byte alto primero, hasta el 0xFF."""
    p = d - ORG
    filas = []
    while p + 1 < len(rom):
        if rom[p] == 0xFF:
            return ORG + p + 1, filas
        w = (rom[p] << 8) | rom[p + 1]
        filas.append(''.join('#' if w & (0x8000 >> i) else '.' for i in range(12)))
        p += 2
    return None, filas


def cuatro(rom, d):
    p = d - ORG
    regs = []
    while p < len(rom):
        if rom[p] == 0xFF:
            return ORG + p + 1, regs
        regs.append(rom[p:p + 4])
        p += 4
    return None, regs


def bytes_(rom, d):
    p = d - ORG
    n = 0
    while p < len(rom):
        if rom[p] == 0xFF:
            return ORG + p + 1, n
        n += 1
        p += 1
    return None, n


def main():
    rom = open(sys.argv[1], 'rb').read()
    org = int(sys.argv[2], 0)
    assert org == ORG
    clase = sys.argv[3]
    for a in sys.argv[4:]:
        d = int(a, 0)
        if clase == 'bits':
            fin, filas = bits(rom, d)
            print('0x%04X..0x%04X  %3d bytes, %d filas de calzada'
                  % (d, fin - 1, fin - d, len(filas)))
            for f in filas:
                print('      ' + f)
        elif clase == 'cuatro':
            fin, regs = cuatro(rom, d)
            print('0x%04X..0x%04X  %3d bytes, %d registros de cuatro'
                  % (d, fin - 1, fin - d, len(regs)))
            for r in regs:
                print('      ' + ' '.join('%02X' % b for b in r))
        else:
            fin, n = bytes_(rom, d)
            print('0x%04X..0x%04X  %3d bytes, %d antes del 0xFF (el ciclo son '
                  'los ultimos 48)' % (d, fin - 1, fin - d, n))


if __name__ == '__main__':
    main()
