#!/usr/bin/env python3
"""El descompresor del cartucho, rehecho en Python para MEDIR y DIBUJAR.

La rutina es L_4611, y escribe DIRECTAMENTE en la VRAM: no deja el resultado
en memoria, lo saca por el puerto de datos del VDP. Traducida instruccion a
instruccion, con DE apuntando al flujo y HL a la direccion de VRAM:

    L_4611  call 0x4591        fija la direccion de escritura (SETWRT con HL)
    L_4614  ld a,(de)
            and a / ret z      un 0x00 TERMINA el bloque
            inc de
            ld b,a             B se queda con el byte ENTERO
            and 07fh / cp b    si coinciden, el bit 7 estaba a cero
            jr z,L_462C        bit 7 = 0 -> repeticion
            and a / jr z,L_460B    el byte 0x80 -> direccion nueva
            ld b,a
    L_4622  ld a,(de) / inc de / out (c),a / djnz    literal de B bytes
            jr L_4614
    L_462C  ld a,(de) / inc de
    L_462E  out (c),a / djnz                          el byte, B veces
            jr L_4614

    L_460B  ex de,hl / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / inc de
            call 0x4591        HL = la palabra leida, y se fija ahi la escritura

O sea, un mandato por byte:

    0x00           cierra el bloque
    0x01..0x7F     el byte que sigue, repetido esa cuenta
    0x80           los dos bytes que siguen son una direccion de VRAM NUEVA,
                   y a partir de ahi se escribe alli
    0x81..0xFF     copia tal cual los (mandato & 0x7F) bytes que siguen

El 0x80 es lo que distingue a este de los demas descompresores de la serie:
un mismo bloque puede repartirse por sitios distintos de la VRAM, y por eso
para dibujarlo hay que llevar la cuenta de DONDE cae cada tramo, no solo de
que sale.

Las direcciones van con el BIT DE ESCRITURA ya puesto: el cartucho pide 0x6200
donde la VRAM tiene 0x2200. No es un error suyo -SETWRT (0x0053) hace
`and 03fh` sobre H antes de nada, asi que los dos bits de arriba se tiran-, de
modo que aqui hay que enmascarar igual con 0x3FFF o los bloques caen fuera.

Ejecutarlo es la unica forma honesta de saber donde acaba cada bloque: el
tamano no esta escrito en ninguna parte, lo marca el propio 0x00 final.

Hay DOS puertas. Por L_4611 la direccion de VRAM llega en HL, puesta por quien
llama. Por L_460B la direccion va DENTRO del bloque, en sus dos primeros bytes:
por eso los bloques que se cargan desde 0x40B9, 0x6931 y 0x6942 empiezan por
una palabra que no es dato comprimido sino destino. Aqui, `auto` para esa.

Uso: rle.py <rom> <org> <dir vram|auto> <dir dato> [<dir dato> ...]
     rle.py <rom> <org> --tramos <dir vram|auto> <dir dato>   detalla los tramos
"""
import sys

VRAM = 0x4000       # tamano de la VRAM de un MSX1


def descomprime(rom, org, inicio, vram_ini):
    """Ejecuta el bloque. Devuelve (fin, vram, tramos) o None si no cierra.

    `vram` es una imagen de 16 KB con lo escrito, y `tramos` la lista de
    (direccion de vram, cuantos bytes) en el orden en que se escribieron.

    Con vram_ini a None se entra por L_460B: los dos primeros bytes del bloque
    son la direccion de destino.
    """
    p = inicio - org
    if p < 0 or p >= len(rom):
        return None
    if vram_ini is None:                      # puerta L_460B
        if p + 1 >= len(rom):
            return None
        vram_ini = rom[p] | (rom[p + 1] << 8)
        p += 2
    vram = bytearray(VRAM)
    tocado = bytearray(VRAM)
    tramos = []
    dst = vram_ini & 0x3FFF
    ini_tramo = dst
    escritos = 0

    def cierra_tramo():
        if escritos:
            tramos.append((ini_tramo, escritos))

    while True:
        if p >= len(rom):
            return None                       # se sale: no era un bloque
        ctrl = rom[p]
        p += 1
        if ctrl == 0x00:
            cierra_tramo()
            return inicio + (p - (inicio - org)), vram, tocado, tramos
        if ctrl == 0x80:
            if p + 1 >= len(rom):
                return None
            cierra_tramo()
            dst = (rom[p] | (rom[p + 1] << 8)) & 0x3FFF
            p += 2
            ini_tramo, escritos = dst, 0
            continue
        if ctrl & 0x80:                       # literal
            n = ctrl & 0x7F
            if p + n > len(rom):
                return None
            for i in range(n):
                vram[dst & 0x3FFF] = rom[p + i]
                tocado[dst & 0x3FFF] = 1
                dst += 1
            p += n
        else:                                 # repeticion
            if p >= len(rom):
                return None
            v = rom[p]
            p += 1
            for _ in range(ctrl):
                vram[dst & 0x3FFF] = v
                tocado[dst & 0x3FFF] = 1
                dst += 1
        escritos += ctrl & 0x7F if (ctrl & 0x80) else ctrl


def main():
    rom = open(sys.argv[1], 'rb').read()
    org = int(sys.argv[2], 0)
    args = sys.argv[3:]
    detalle = False
    if args and args[0] == '--tramos':
        detalle = True
        args = args[1:]
    vram_ini = None if args[0] == 'auto' else int(args[0], 0)
    for a in args[1:]:
        d = int(a, 0)
        r = descomprime(rom, org, d, vram_ini)
        if r is None:
            print('0x%04X  NO cierra dentro de la ROM' % d)
            continue
        fin, vram, tocado, tramos = r
        n = sum(tocado)
        print('0x%04X..0x%04X  %5d bytes comprimidos -> %5d de VRAM, %d tramos'
              % (d, fin - 1, fin - d, n, len(tramos)))
        if detalle:
            for v, c in tramos:
                print('      vram 0x%04X  %5d bytes' % (v, c))


if __name__ == '__main__':
    main()
