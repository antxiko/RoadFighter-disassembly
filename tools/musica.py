#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `suena` (0x4B6E, A = numero) y corre `latido_del_sonido`
(0x4BFF), que la interrupcion llama cada cuadro. Tres voces de 11 bytes desde
0xE010; la copia del registro 7 del PSG, en 0xE031.
Uso:  musica.py registros 0x98 [cuadros] | mp3 0x98 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x98, "La pieza del 0x4266", "The tune at 0x4266", "`L_4266`"),
    P(0x92, "Cruzar la meta", "Crossing the finish line", "`cruza_la_meta`"),
    P(0x95, "La pieza del 0x4341", "The tune at 0x4341", "`L_4341`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x90, 0x91, 0x93, 0x94, 0x96, 0x97, 0x99, 0x9A)]

PAGINA = motor_musica.pagina_basica(
    "`latido_del_sonido`, 0x4BFF, y `suena`, 0x4B6E, que le reparte las "
    "voces; lo llama la interrupción",
    "`latido_del_sonido`, 0x4BFF, and `suena`, 0x4B6E, which hands it the "
    "voices; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0x98 entera, 218 cuadros, tal como el juego la pide",
      "tune 0x98, whole, 218 frames, as the game asks for it"),
     ("la pieza 0x95 entera, 198 cuadros, pedida a la fuerza",
      "tune 0x95, whole, 198 frames, forced"),
     ("los primeros 270 cuadros de cruzar la meta (0x92, que dura 346), "
      "hasta que el juego pide otro sonido encima",
      "the first 270 frames of crossing the finish line (0x92, which lasts "
      "346), until the game asks for another sound on top")],
    [("Cómo se pide una pieza",
      "`suena` recibe el número en A y `pide_efecto` elige la voz: el número "
      "más bajo manda. Los números por debajo de 0x0F son efectos de una o "
      "dos voces y del 0x0F en adelante hay música de tres. Cada voz ocupa "
      "once bytes desde 0xE010 y 0xE031 guarda la copia del mezclador del "
      "PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están "
      "en la tabla de melodías (0x4DE0) pero ninguna rutina las pide con un "
      "`ld a`. Hay tres piezas cotejadas con openMSX, la 0x98, la 0x95 y la 0x92 (esta "
      "en sus 270 primeros cuadros); las demás salen del mismo motor, pero no "
      "se ha comparado cada una.",
      "How a piece is asked for",
      "`suena` takes the number in A and `pide_efecto` picks the voice: the "
      "lowest number wins. Numbers below 0x0F are one- or two-voice effects "
      "and from 0x0F up there is three-voice music. Each voice takes eleven "
      "bytes from 0xE010 and 0xE031 holds the copy of the PSG mixer, which "
      "start-up leaves at 0xB8. The tracks marked «in the table» are in the "
      "melody table (0x4DE0) but no routine asks for them with an `ld a`. "
      "Three pieces have been checked against openMSX, 0x98, 0x95 and 0x92 "
      "(the last in its first 270 frames); the rest come out of the same "
      "engine but each has not been compared.")])

CFG = dict(rom="roadfighter.rom", org=0x4000, frame=0x4BFF, pide=0x4B6E,
           ram=(0xE010, 0xE034), ram0=[(0xE031, 0xB8)],
           excluye=[0xE019, 0xE024, 0xE02F], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA, cotejado=[(0x98, 218, None), (0x95, 198, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
