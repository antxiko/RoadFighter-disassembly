# Findings

What turned up when the cartridge was taken apart. Every number here is
measured: by running the cartridge's own routines, or by dumping the
emulator's memory and comparing it byte for byte.

## The collision map is the screen itself

This cartridge stores nowhere where the road actually is. To find out whether
the car has touched the verge it **reads the screen**. The routine at 0x6D8B
works out the cell the car is in, asks the VDP for it with `SETRD` and pulls
back, with a single `in a,(c)`, whatever tile is drawn there.

Then it sorts it into bands:

| tile | what it means |
|---|---|
| below 0xCF | certain crash |
| 0xCF to 0xD8 | clear |
| 0xD9 to 0xE8 | the verge, and it needs pixel-level checking |

It is the cheapest way to make the car hit **what you can see**, whatever the
road happened to paint there. And it explains why the verge trail exists at
all: for what is *not* on screen -where to reappear, where to drop an object-
separate memory is still needed.

## A routine hidden inside its own pointer table

0x5540 does `call 05716h`, and 0x5716 lands **inside** the scenery pointer
table at 0x570C: it is its last two bytes.

Konami uses them for two things at once. Read as a word they are the table's
sixth entry. Executed they are the `ld hl,(0e046h)` that starts the routine
which advances the ring:

    ld hl,(0e046h)      where the ring is being read from
    ld bc,0ffeah        twenty-two back: one row
    add hl,bc
    ld (0e046h),hl
    ld bc,0e170h        0xE186 - 22, that is, before the start
    and a / sbc hl,bc
    jr nz,+6
    ld hl,0e380h        and then to 0xE380, which plus 22 gives 0xE396
    ld (0e046h),hl
    ld de,(0e046h) / ld hl,0e058h / ld bc,00016h / ldir

The giveaway is that the sixth entry would point at 0x462A, and 0x462A is a
`jr` inside the RLE decompressor: no scenery artwork at all. The table has
**five** entries, and what follows is already code.

These thirty-six bytes spent the whole disassembly classified as data nobody
reads. The proof that they are code is not that they can be disassembled: it is
that, declared as such, **the listing still gives back the ROM byte for byte**.

## The two builds differ by ONE byte

Two dumps of this cartridge are in circulation. They differ by **a single byte,
0x53CB**: one has 0x05, the other 0xFF.

That byte is the fifteenth segment of the **stage 5** row in the plan at
0x537D, which is six rows of sixteen bytes each closed with 0xFF and padded
with 0xFF to the end.

Measured in openMSX, forcing (0xE043) to 5 and placing the segment pointer at
the end of that row:

    with 0x05   ... plan+13 seg=0x0A -> plan+14 seg=0x05 -> plan+0 (wraps)
    with 0xFF   ... plan+13 seg=0x0A ->                     plan+0 (wraps)

So: the 0x05 version plays **fifteen** segments per cycle and the 0xFF one,
**fourteen**. The one that vanishes is segment 5, whose record at 0x5329 is
`00 04 18 08 08 28`.

**Which of the two plays harder is not claimed here, because it has not been
measured.** The "Easy" and "Hard" labels they circulate under come from the
dump, not from the ROM.

## The car has a dead band of speed

Under acceleration the car moves up the screen by 0x48 of 256 of a pixel per
frame. But not always: the routine at 0x6C93 only lets it move in two speed
bands, with a third in between where it stays put.

| speed | does it move? |
|---|---|
| below 0x18 | no |
| 0x18 to 0x50 | yes |
| 0x50 to 0x7E | **no** |
| above 0x7E | yes |

Measured, not inferred. Across 900 frames of the attract mode the car's Y sits
still at 0x8FC0 while the speed climbs from 0x51 to 0x7D, and starts moving
again the moment it passes 0x7E. 57 of the 58 comparable frames match the
prediction, and the one that does not falls exactly on the boundary between two
samples.

The same measurement yields two more things: the code's caps are genuinely
reached -the Y locks at 0x9A and the speed at 0xD7- and **the attract mode runs
with the accelerator held down**, releasing it for one frame in every 104.

## Three marks nine apart

The end of a stage is not one moment. It is three, nine units of distance
apart, which is nine ring rows:

| distance | what happens |
|---|---|
| 0x0F00 | the rival car is released |
| 0x0F09 | the finish sign is painted into the ring |
| 0x0F12 | the car crosses it: state 3, and effect 0x92 sounds |

And the sign is not always the same. The first five stages get the eleven tiles
of `CHECK POINT`; the sixth, the five of `GOAL`, three columns further right.
They read with the same rule as every other text in the cartridge -the pattern
index is the ASCII code minus 0x20- and they were confirmed by **drawing their
tiles** from the emulator's VRAM, not by assuming it.

The same trick applies to the `EMPTY` warning at 0x6B59, which is written over
the road itself when the fuel runs out, and which shifts left if it would not
fit within the ring's twenty-two columns.

## The symmetrical road comes free

Stage 3 draws the whole row from a single sixteen-bit word: each bit picks one
of two tiles. Twelve columns are asked for and then ten more, but the second
call reloads the same word from the start, because the pointer has not moved.

Columns 12 to 21 repeat the pattern of the first ten. The road comes out
symmetrical without spending one extra byte or one extra instruction.

## The level changes four things, not one

LEVEL A and LEVEL B are not a difficulty multiplier. The level, at (0xE03B), is
consulted in four places with nothing to do with each other: the sideways push
on objects (0x706D), the fuel burn (0x7374), the object spawn delay (0x6F72)
and the segment list, where the first level **removes an entire segment**,
swapping 0x0A for 9 (0x7044).

## What the cartridge saves

A handful of tricks that turn up again and again:

- **The scene step is not compared**: it is spent with chained `djnz`.
- **The tables sit right behind the `call`**, and the dispatcher recovers its
  own return address with a `pop hl` to read them. There are six.
- **`L_440C` eats its caller's return address** when its count does not reach
  zero, which is a two-level return in three instructions.
- **The lane markings are bitmaps**: twelve bits per word, each bit picking one
  of two tiles.
- **The patches chain**: every call to the paster inherits the destination the
  previous one left, and sometimes only register E changes.

## Konami's hidden mark

The last fifteen bytes of the cartridge are read by nobody: they are `RC-730`
and the title in katakana, ロードファイター, written backwards and closed with
the length -ten bytes-, the two RC digits in BCD and an 0xAA.

The format of that signature was discovered by **Manuel Pazos**, and without
his find these fifteen bytes would have stayed filed under "data nobody reads".
Our thanks.
