#!/usr/bin/env python3
"""Mide donde acaba cada guion de rotulos EJECUTANDO el interprete que lo lee.

El presupuesto exige que todo byte del cartucho este explicado, y adivinar
donde acaba un bloque produce rangos convincentes que no son nada. Aqui no se
adivina: el cartucho trae su propio interprete y se ejecuta.

El interprete es L_45F0 (0x45f0), y el guion le llega en DE. Traducido:

    L_45F0  ld c,0ffh          la mascara: 0xFF deja el byte como esta
    L_45F2  ex de,hl / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / inc de
                               HL = destino en VRAM, DE = el guion + 2
    L_45F8  ld a,(de) / inc de
            ld b,a / inc b / ret z      byte 0xFF -> FIN del guion
            inc b / jr z,L_45F2         byte 0xFE -> otro destino de VRAM
            and c                       la mascara
            call 0x004D                 BIOS WRTVRM: escribe en VRAM
            inc hl
            jr L_45F8

Y L_4607 (0x4607) es la MISMA rutina con c=0: escribe ceros en vez de los
bytes, o sea que borra el rotulo dejando su geometria. Por eso los dos
comparten los guiones.

O sea que el formato es: [destino VRAM, word] [bytes de tile...] y dos codigos
de control, 0xFE para saltar a otro destino y 0xFF para terminar. Ejecutando
eso desde cada arranque salen los bytes consumidos EXACTOS.

Los arranques no se eligen a ojo: se sacan del listado, buscando las
constantes que el codigo carga en DE justo antes de llamar al interprete.

Uso: guiones.py <rom> <org> <listado.asm> [--textos]
"""
import re
import sys

ORG_POR_DEFECTO = 0x4000
INTERPRETES = (0x45F0, 0x4607)

# Los bytes que el guion escribe en la VRAM son indices de patron, y la fuente
# del cartucho esta ordenada como el ASCII a partir del espacio: el indice 0
# es el espacio (0x20). Comprobado con el propio contenido -"+/.!-)" en 0x7f1d
# sale "KONAMI" y "34!24" en 0x7896 sale "START"-, no supuesto.
DESPLAZAMIENTO_FUENTE = 0x20


def lee_listado(path):
    """Los arranques ciertos: la constante cargada en DE antes de llamar."""
    carga = re.compile(r"\bld\s+de,\s*0([0-9a-f]{4})h\b", re.I)
    llama = re.compile(r"\b(?:call|jp)\s+(?:[a-z]{1,2},\s*)?(?:L_)?0?([0-9A-Fa-f]{4})h?\b")
    arranques = []
    ultimo_de = None
    ultima_dir = None
    for ln in open(path, encoding="utf-8"):
        m = carga.search(ln)
        if m:
            ultimo_de = int(m.group(1), 16)
            ultima_dir = ln
            continue
        m = llama.search(ln)
        if m and ultimo_de is not None:
            if int(m.group(1), 16) in INTERPRETES:
                arranques.append((ultimo_de, ln.split(";")[-1].strip()))
                ultimo_de = None
        # cualquier otra instruccion que toque DE invalida la constante
        if re.search(r"\bld\s+de\b|\bpop\s+de\b|\bex\s+de,hl\b|\bldir\b", ln, re.I):
            if not carga.search(ln):
                ultimo_de = None
    return arranques


def ejecuta(rom, org, inicio):
    """Corre el interprete desde `inicio`. Devuelve (fin, texto, destinos)."""
    p = inicio - org
    if p < 0 or p + 2 > len(rom):
        return None
    texto = []
    destinos = []
    while True:
        if p + 2 > len(rom):
            return None                      # se sale: no era un guion
        destino = rom[p] | (rom[p + 1] << 8)
        destinos.append(destino)
        p += 2
        texto.append("\n[VRAM 0x%04X] " % destino)
        while True:
            if p >= len(rom):
                return None
            b = rom[p]
            p += 1
            if b == 0xFF:                    # fin del guion
                return org + p, "".join(texto), destinos
            if b == 0xFE:                    # otro destino
                break
            c = b + DESPLAZAMIENTO_FUENTE
            texto.append(chr(c) if 0x20 <= c < 0x7F else "<%02X>" % b)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ver_textos = "--textos" in sys.argv
    if len(args) < 3:
        print(__doc__)
        return 2
    rom = open(args[0], "rb").read()
    org = int(args[1], 0)
    arranques = lee_listado(args[2])

    vistos = {}
    for ini, ctx in arranques:
        if ini in vistos:
            continue
        r = ejecuta(rom, org, ini)
        vistos[ini] = r

    total = 0
    print("  arranque   ..fin      bytes  destinos  texto")
    print("  " + "-" * 70)
    for ini in sorted(vistos):
        r = vistos[ini]
        if r is None:
            print("  0x%04X     NO CIERRA: se sale de la ROM" % ini)
            continue
        fin, texto, destinos = r
        total += fin - ini
        limpio = " ".join(texto.split())
        print("  0x%04X..0x%04X  %5d  %8d  %s"
              % (ini, fin, fin - ini, len(destinos),
                 limpio[:44] + ("..." if len(limpio) > 44 else "")))
        if ver_textos:
            print(texto)
            print()

    print("  " + "-" * 70)
    print("  %d guiones, %d bytes consumidos" % (len(vistos), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
