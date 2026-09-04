# Road Fighter (Konami, 1985) — a commented disassembly

A complete, commented disassembly of the MSX1 cartridge **Road Fighter**
(Konami, catalogue number **RC-730**, 16 KB), reproducible byte for byte.

**Web: <https://antxiko.github.io/RoadFighter-disassembly/>** · [En castellano](README.es.md)

|  |  |
|---|---|
| Of the binary explained | **100%** — 0 bytes unaccounted for, of 16,384 |
| Reassembles | **byte for byte**, to the same sha256 |
| Listing commented | **55.1%** — 2,234 comments over 4,053 instructions |
| Routines below the 10% bar | **0** of 482 |

## What is in here

    src/roadfighter.asm       the listing, generated
    src/roadfighter.notes     what is understood: data blocks and comments
    src/roadfighter.entries   the entry points, each with its reason
    src/roadfighter.nocode    the ranges that are not code
    tools/                    the tracer, the generator and the drawing tools
    docs/                     the website, in English and Spanish

## Running it

The cartridge is **not** distributed here. Put it in the root as
`roadfighter.rom` (16,384 bytes, sha256 `6d36c9e9b6a6b93f642722dcd314834d01e519ab3a98d7e4ca257468bcaf29e1`)
and run:

    make comprueba      # check the dump is the right one
    make                # trace, build, reassemble, verify, test

It ends with `OK: reproducible byte a byte`, which means the listing gives back
the cartridge exactly.

## Some of what turned up

- **The collision map is the screen itself.** The game stores nowhere where the
  road is: it asks the VDP for the tile under the car and sorts it into bands.
- **A routine hidden inside its own pointer table.** `call 05716h` lands on the
  last two bytes of a table of scenery pointers, which double as the first
  instruction of the routine that advances the road.
- **The two builds differ by one byte.** 0x53CB, the fifteenth segment of stage
  5: one plays fifteen segments per cycle, the other fourteen.
- **The road does not exist — it is manufactured**, row by row, into a ring of
  24×22 in RAM. The six roads on the site are drawn by running that engine, and
  checked against openMSX across 263 steps with not one difference.
- **The car has a dead band of speed**: between 0x50 and 0x7E it does not move
  up the screen at all. Measured over 900 frames.
- **Colours sit below patterns** in video memory, the other way round from
  usual.

The full list is in [Findings](https://antxiko.github.io/RoadFighter-disassembly/FINDINGS.html),
and what is still **not** known in
[Open questions](https://antxiko.github.io/RoadFighter-disassembly/OPEN-QUESTIONS.html).

## Credit

The format of Konami's hidden signature at the end of the ROM — the `RC-730`
and the katakana title — was discovered by **Manuel Pazos**.

## Legal

This is preservation, study and documentation work. The game and its artwork
remain the property of their holders, and the cartridge image is not
distributed here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
