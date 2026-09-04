# In the emulator

Looking at a picture is not enough to call it right. What settles it is dumping
the machine's memory and comparing it, byte for byte, against what the notes
claim. Everything this site says about what the cartridge does while running is
measured that way.

## The scripts

`tools/` holds four openMSX scripts. None of them sets a breakpoint except the
one that needs to: the rest work off emulated time, which is the only thing
that does not choke the emulator.

    tools/omsx_vram.tcl       dumps the 16 KB of VRAM and the VDP registers
    tools/omsx_coche.tcl      records the car's motion, frame by frame
    tools/omsx_carretera.tcl  dumps the road generator's state
    tools/omsx_etapa.tcl      the same, forcing which stage is played

Run them like this:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart roadfighter.rom -script tools/omsx_vram.tcl

## The graphics, against VRAM

`tools/graficos.py` rebuilds the screens by running the cartridge's own steps
in Python: the decompressor, the sign interpreter, the mirrors and the patch
paster. Then it is compared against what the VDP actually holds.

    TITLE SCREEN     colour, sprites, pattern and names: 0 differences in all four
    GAME SCREEN      colour 0/6144   sprites 0/2048   pattern 0/6144
                     names 2/528

The two cells that do not match are the **finish arch**, row 4, columns 6 and
7, which is animated: it alternates 0x46/0x47 with 0x48/0x49. So the two that
fail, fail because they have to.

## The road, step by step

This is the check that costs the most and is worth the most. The road is
procedural, so comparing a lone dump says nothing: there is no way to know
where in the script it was.

What does work is this. `tools/omsx_carretera.tcl` records the **entire** state
of the generator -the variables from 0xE040 to 0xE0C0 and the 528-byte ring- on
consecutive frames. Then, in Python, the state from frame N is loaded, **one
step** of the rebuilt engine is run, and the result is compared against frame
N+1.

The result, with each of the six stages forced in turn:

| stage | steps compared | identical |
|---|---|---|
| 1 | 44 | **44** |
| 2 | 44 | **44** |
| 3 | 44 | **44** |
| 4 | 44 | **44** |
| 5 | 44 | **44** |
| 6 | 43 | **43** |

Identical means the entire ring, all 528 bytes, and every generator variable.
Across the 263 steps, not one difference.

That check turned up three misreadings that only show this way: that the
routine at 0x5784 begins with an `ldi` of its own, that the bridge's `ldir`
overlaps itself and drags seven cells rather than six, and that the alternation
between the two scripts was the wrong way round.

## Forcing a stage

The attract mode picks the stage using the R register, and on a clean openMSX
boot the draw always comes out the same: stage 2. To see the other five it has
to be forced, and **where matters**.

`tools/omsx_etapa.tcl` puts a breakpoint at 0x504C, the first instruction of
`prepara_la_etapa`, and writes (0xE043) **before** the routine builds anything.
That way the scenery, the scripts and the lists are all chosen for the forced
stage and the state stays coherent.

Forcing it mid-game does not work: the scenery stays as the previous stage's
and the screen fills with garbage. Reading the segment plan does still work -it
depends only on (0xE043) and the pointer- but the captures do not.

## The car

`tools/omsx_coche.tcl` records, nine hundred times, the car's Y alongside the
accelerator and the speed. Three things come out of it:

- **(0xE04C) is the car sprite's Y**: it matched the one the VDP held in the
  attribute table across all 900 samples, without exception.
- The code's caps are genuinely reached: the Y locks at 0x9A and the speed at
  0xD7.
- The dead band of speed at 0x6C93 holds in 57 of the 58 comparable frames.

## How to play it

Any MSX1 emulator will do. With openMSX:

    openmsx -machine Philips_VG_8020 -cart roadfighter.rom

And to see the other build, the same command with `roadfighter_dificil.rom`.
The difference is in stage 5, and it is one segment.
