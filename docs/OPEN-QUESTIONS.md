# Open questions

The cartridge is 100 % explained -not one byte unaccounted for- and it
reassembles byte for byte. That does not mean there is nothing left to find
out. These are the loose ends, and they are here rather than glossed over on
some other page.

## Which of the two builds plays harder

It is the obvious question and it is not answered.

What **is** measured: the two differ by a single byte, 0x53CB, which is the
fifteenth segment of the stage 5 row in the plan at 0x537D. With 0x05 that
stage plays fifteen segments per cycle and with 0xFF, fourteen. The one that
vanishes is segment 5, whose record is `00 04 18 08 08 28`.

What is **not** measured: whether removing that segment makes the stage easier
or harder. One segment fewer per cycle may mean fewer cars to run into, or it
may mean the cycle repeats sooner and the remaining ones come faster. Without
playing it, or without counting the objects that actually spawn over a full
cycle, there is nothing to say.

The "Easy" and "Hard" names the two dumps circulate under come from the GoodMSX
catalogue, not from the ROM, and count as evidence of nothing here.

## Whether scenery mode 5 is ever used

The scenery pointer table at 0x570C has five entries, and the sixth word is
already code. The index comes from the low nibble of (0xE07A), so a mode with a
low nibble of 5 would run off the end of the table and jump to 0x462A, inside
the decompressor.

That the cartridge uses those two bytes as code is certain: there is an
explicit `call 05716h`, and declaring them that way still gives back the ROM
byte for byte. What is not established is whether any scenery script ever asks
for mode 5. That would mean walking the scripts from their real starting
points, and not all of those starting points are identified.

## Where the scenery scripts start

The [mode, count] pairs from 0x78C4 to 0x7C23 and from 0x7E60 to 0x7FE4 are the
scenery scripts, and the table at 0x5161 points into them. The starts actually
used are located -0x78C4 and 0x78E5, 0x7AAA, 0x7BAA, 0x7ACD, 0x7960, 0x7E60,
0x7E83, 0x7EA8, 0x7F6B and 0x7ED1- but **the end of each one is not marked**:
0x585F reads the two bytes without checking anything, and what stops it is the
stage running out.

Which means there is no telling how many pairs each script has without running
it with a whole stage in front of it.

## Why the car moves down under acceleration

It is measured that the sprite's Y grows while the accelerator is held -that
is, the car moves down the screen- until it locks at 0x9A, and that it shrinks
without it. That is a fact.

What is not known is whether that answers to a specific design idea or is just
the cheapest way to convey speed. No speculation here.

## The three overlapping blocks

It is measured that three compressed blocks close beyond their range, eating
the next block whole or in part. What is not known is whether that is
deliberate -compression exploiting the tail- or the result of whatever tool
Konami generated them with happening to leave them that way.

All three close on their own 0x00 and all three match the emulator's VRAM, so
the reading is not in doubt. The intent is.

## The trace's blind spot

There is one left, and it is declared: the `JP (HL)` at 0x404E, the generic
dispatcher. It cannot be resolved by following jumps because its destination
comes from a different table every time. All six tables are declared by hand in
the `.entries`, each with its justification, and the budget closes at 16,384
bytes with no unexplained region.
