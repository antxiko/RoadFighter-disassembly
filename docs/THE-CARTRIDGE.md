# The cartridge

**RC-730**, 16,384 bytes, in **page 1** of the MSX. It is a plain ROM cartridge
with no mapper: the whole thing is visible from 0x4000 to 0x7FFF and there is
nothing to switch.

## The header

The first sixteen bytes are the header the MSX looks for at boot: `"AB"`, the
INIT address (**0x404F**), and STATEMENT, DEVICE and TEXT at zero, plus six
reserved bytes that are zero too.

## Everything hangs off the interrupt

INIT does not start a game loop. What it does is hook **H.KEYI** with 0x4013
and settle into a `jr $`. From there on the whole game runs inside the
interrupt hook, once per frame.

The hook carries its own reentry latch at (0xE005), because a slow frame can
catch the previous one still running.

## The memory map

    0xE000   the scene, and 0xE001 the step within it
    0xE002   the game flags (bit 6 is "game in progress")
    0xE003   the game clock, one per frame
    0xE043   the stage, 1 to 6      0xE042  the lap
    0xE046   where the road ring is being read from
    0xE049   the car's state        0xE04B..0xE04C  its Y in fixed point
    0xE04D..0xE04E  its x           0xE04F  the speed
    0xE058..0xE06D  THE NEW ROW: 22 columns
    0xE078   distance covered in the stage, 16 bits
    0xE083   the fuel
    0xE098..0xE0AF  the verge trail: one cell per ring row
    0xE0E5   the road objects, 16 bytes each
    0xE10E..0xE185  the RAM copy of the thirty sprite attributes
    0xE186..0xE395  THE RING: 24 rows of 22 columns

That 0xE10E plus 0x78 lands exactly on 0xE186 is no accident: the sprite
attribute copy ends precisely where the ring begins, which is why the two
uploads the cartridge makes to VRAM -0x34 bytes and 0x78- fit with no gap.

## The screen

SCREEN 2, with the tables somewhere unusual. The eight bytes the cartridge
loads into the VDP registers, from the table at 0x46A9, read
`02 E2 0E 7F 07 76 03 E4`:

| register | value | what ends up where |
|---|---|---|
| R2 | 0x0E | NAME table at 0x3800 |
| R3 | 0x7F | COLOUR table at **0x0000** |
| R4 | 0x07 | PATTERN table at **0x2000** |
| R5 | 0x76 | sprite ATTRIBUTES at 0x3B00 |
| R6 | 0x03 | sprite PATTERNS at 0x1800 |
| R7 | 0xE4 | on the title screen; 0xE0 in play, with a black backdrop |

Colours below patterns, the wrong way round. R3 and R4 are not addresses but a
base and a mask, and reading them as if they were gives a misleading result:
the shapes come out fine and the colours come out in stripes.

## The dispatcher

The cartridge hands out work through a nine-instruction dispatcher at 0x4045
that eats its own return address:

    add a,a / pop hl / call 0x403B / ld e,(hl) / inc hl / ld d,(hl)
    ex de,hl / jp (hl)

The `pop hl` recovers the address it was going to return to, which is exactly
where the table starts, because **the table sits right behind the `call`**.
There are six such tables: 0x4099 (the scenes), 0x50C9 (scenery per stage),
0x5526 (road per stage), 0x570C (the roadside scenery), 0x6A80 (the car's
states) and 0x70C9 (an object's states).

None of them can be deduced by following jumps, so they are declared by hand in
`src/roadfighter.entries`, each with its justification written alongside.

## The nine scenes

The index is (0xE000) and the step, (0xE001). Every scene opens with a row of
chained `djnz`: the step is not compared against anything, it is **spent**.

| scene | what it is |
|---|---|
| 0 | boot and title screen |
| 1 | the wait |
| 2 | winding up a game |
| 3 | the longest: the menu, building the road and starting up |
| 4 | the countdown, with the road already rolling |
| 5 | the game |
| 6 | the crash |
| 7 | GAME OVER |
| 8 | back to the title screen |

The table's tenth word would be 0x1310, which does not land in the ROM: those
two bytes are already the `djnz` at 0x40AB, which happens to be the table's own
first destination. That fit is what pins down the end of the table without
having to assume it.

## The hidden mark

The last fifteen bytes are read by nobody. They are `RC-730` and the title in
katakana, ロードファイター, written backwards and closed with the length, the
two RC digits in BCD and an 0xAA. The format of that signature was discovered
by **Manuel Pazos**.
