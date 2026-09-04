# Getting started

The repository ships the listing already generated, but what really matters is
that it can be **rebuilt from the cartridge** and that the result is the ROM
byte for byte. That is what makes the notes worth believing.

## What you need

- **Python 3** (nothing else: not a single dependency)
- **pasmo**, the Z80 assembler, for the reassembly check
- **make**
- For the checks against the machine, **openMSX**

## The cartridge

It does not travel with the repository. Put it in the root as
`roadfighter.rom`, exactly 16,384 bytes:

    6d36c9e9b6a6b93f642722dcd314834d01e519ab3a98d7e4ca257468bcaf29e1

The other build, needed only for `make coteja`, goes in as
`roadfighter_dificil.rom`:

    070fc231f979a04bb4652f7c5e585f6445758af32ffcbf60757deb1f7b5856e7

`make comprueba` verifies both.

## What `make` does

    make            traces, generates the listing, verifies and runs the tests
    make trace      follows the flow from the entry points
    make listado    writes src/roadfighter.asm
    make verify     THE PROOF: reassembles and compares against the ROM
    make sanity     what reassembly cannot catch
    make densidad   how much is commented, routine by routine
    make test       the tests
    make web        generates this site

`make verify` is what decides whether the disassembly can be trusted. Until it
is green, anything said about the cartridge is said blind.

## The tests run without the cartridge

The tests do not need the ROM. `tests/test_listado.py` rebuilds the data bytes
by reading the `defb` and `defw` rows of the listing itself, which carry their
address in the comment. That way the decompressor, the sign interpreter, the
patch paster and the road generator can all be **executed** in a bare clone,
with no cartridge and no `make`.

## How it is laid out

    src/roadfighter.asm       the listing, generated
    src/roadfighter.notes     WHAT IS UNDERSTOOD: the comments come from here
    src/roadfighter.entries   the entry points that cannot be deduced
    src/roadfighter.nocode    what is not code even though it looks like it
    tools/                    the tools
    tests/                    what keeps this from decaying

The `.asm` **is regenerated**: it is not edited. What gets edited is the
`.notes`, which is why the comments survive a re-trace.
