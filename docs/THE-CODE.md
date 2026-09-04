# The code

7,797 bytes of code and 8,587 of data. The two add up to the cartridge's
16,384, and that sum is the check: **not one byte unaccounted for**.

## The ring, which is the whole idea

The road does not scroll. What moves is **where you start reading**.

At 0xE186 there is a ring of twenty-four rows by twenty-two columns. The
routine at 0x5716 steps the pointer at (0xE046) back twenty-two places -one
row- and drops the row just built into the gap. When the pointer falls below
0xE170 it goes back to 0xE380, which plus twenty-two gives 0xE396, the end of
the ring.

The limits fit on their own, which is why they can be trusted: 0xE186 minus 22
is exactly 0xE170, and 0xE380 plus 22 is exactly 0xE396.

Then 0x573A dumps the twenty-four rows into the name table starting at 0x3801
and skipping 0x20 per row, because the screen is thirty-two columns wide and
the road only takes twenty-two. The ones left over on the right are the
dashboard.

## One new row, step by step

    0x551D  the road engine
      0x592A  fills the twenty-two column row with the background tile
      ...     THIS stage's branch paints the road on top
      0x58AF  every eight rows, pastes a road segment
      0x56F7  the roadside scenery, through one of three doors
      0x590E  records this row's verge in the trail
      0x5944  the finish sign, if it is due
      0x54AF  the loose pieces from the scenery script
      0x5716  and the row goes into the ring

## The six roads

The table at 0x5526 is indexed with (0xE043) **without subtracting one**, and
the stages run 1 to 6: entry 0 is used by nobody and therefore repeats stage
1's.

| stage | what its branch does |
|---|---|
| 1 | just the lane markings |
| 2 | pastes four columns from a cyclic list |
| 3 | pulls the whole row out of a sixteen-bit word, and the bridge |
| 4 | stores seven columns and computes the mirror by adding 0x0D |
| 5 | the same with four columns and another table |
| 6 | like 3, and also redraws the markings on top |

All six converge on the same ending, which finishes with a `pop hl` at 0x5543:
it eats the return address so as to exit straight to whoever called the
dispatcher, skipping a level.

## Stage 3's symmetrical road

The routine at 0x56CC pulls tiles out of a sixteen-bit word, one per bit,
starting from the most significant. It is asked for **twelve** columns and then
**ten** more.

But the second call enters at 0x56CE, which reloads the word from the pointer,
and the pointer has not moved. So columns 12 to 21 repeat the pattern of the
first ten. The road comes out symmetrical without spending one extra byte.

## The mirror in stages 4 and 5

Here half the road is stored and the other half computed. The seven bytes of
the left side are read again, 0x0D is added to each -that being the jump from a
tile to its mirrored version in the pattern table- and they are written
backwards from the end of the row.

## Stage 3's bridge

Four columns from the script, **seven** of tile 0xD0 in the middle and another
four from the script, from column 4 to 18. The seven in the middle are not
written one by one: 0xD0 goes into the first and an `ldir` that overlaps itself
drags it to the end. That is why there are seven and not the six the
`ld c,006h` says.

And two rows in four carry a 0xD1 in column 11, which is the dashed centre
line.

## The verge trail

At 0xE098 there are twenty-four cells, one per ring row, each holding the verge
margin in the top six bits and the scenery mode in the bottom two. Every new
row shifts them all along one place and pushes its own in at the top.

It is the memory of where the road was at each height of the screen. Without
it, an object twenty rows into its fall would not know where the edge is at its
height, and the car itself would not know where to reappear after a crash.

## The car

    0xE049          the state, and a table of eight branches at 0x6A80
    0xE04B..0xE04C  the Y, in 8.8 fixed point
    0xE04D..0xE04E  the x, in the same format
    0xE04F          the speed, capped at 0xD7

The eight states: rolling, wrecked and burning, burning fuel, leaving the
screen, skidding, spinning, waiting, and bouncing off the verge.

The Y's high byte is, as it stands, the sprite's Y in VRAM. That is not a
guess: across nine hundred frames of the attract mode the two matched without a
single exception.

## The objects

An object is sixteen bytes, and two are live at a time. Spawning goes by
**segments**: a pointer walks the sixteen-byte row belonging to the stage in
the plan at 0x537D, and each value indexes a table of fifteen records. Each
record carries six bytes, that is two objects of three fields, which are
assembled in two slots and copied whole from there into the first free hole.

All access to an object goes through two routines: 0x72F6, which fetches field
C, and 0x72E7, which adds DE to the word ending at field C. Hence the
`ld c,006h` -the Y- and the `ld c,009h` -the speed- that turn up everywhere.

## The decompressor

The graphics are packed with an RLE that writes **straight into VRAM**, with
`out (c),a` on the VDP data port:

    0x00           closes the block
    0x01..0x7F     the byte that follows, repeated that many times
    0x80           the next two bytes are a new VRAM address
    0x81..0xFF     copy verbatim the (command & 0x7F) bytes that follow

There are two doors: through 0x4611 the destination arrives in HL, and through
0x460B it lives inside the block itself, in its first two bytes. And 0x45E0
calls the decompressor three times adding 0x800 to HL, which is the geometry of
SCREEN 2: one block fills all three thirds.

The bounds of the twenty-two blocks are not estimated: `tools/rle.py` measures
them by running that same decompressor, and each one closes on its own 0x00.

## Three overlapping blocks

Three of those blocks do not end where the next one starts: they end **after**.
The cartridge reuses the tail of one as the body of the one behind it.

| block | closes at | what it shares |
|---|---|---|
| 0x5DEC | 0x5F45 | its last 32 bytes are the head of the block at 0x5F25 |
| 0x601D | 0x6022 | it swallows the block at 0x601F whole |
| 0x602D | 0x603E | it swallows the block at 0x6031 whole |

This is not a misreading: all three close on their own 0x00 and all three match
the emulator's VRAM.
