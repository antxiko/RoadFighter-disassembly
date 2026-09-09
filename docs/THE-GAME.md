# The game

*Road Fighter* is a race seen from above. You drive a car down a road that
scrolls towards you, dodging the others, keeping off the verge and not running
out of fuel. Konami published it for the MSX in 1985 under catalogue number
**RC-730**, and it is 16 KB.

![The title screen](imagenes/titulo.png)

The cartridge builds the title screen step by step. The big wordmark slides in
from both sides, which is why the word ROAD is stored **backwards** in the ROM,
with its 0xFF in front: it is read back to front as it comes in.

## Six stages, and then another lap

There are **six stages**. On clearing the sixth the counter at 0x4394 does not
stop: it sets it back to one and bumps the lap counter at 0xE042, so the game
starts over keeping track of how many times it has been completed.

Each stage has its own scenery, its own road and its own scenery script. There
are only **five sceneries for six stages**: 4 and 5 share theirs, and what
tells them apart is the tint given by the table at 0x6A69.

## LEVEL A and LEVEL B

The title screen offers two levels, and it is not a difficulty multiplier. The
level lives at (0xE03B) and gets involved in four separate places:

| where | what changes |
|---|---|
| 0x706D | whether the sideways push objects spawn with is doubled |
| 0x7374 | the fuel-burn step: 0x0180 against 0x01FF |
| 0x6F72 | the object spawn delay: seven or twelve |
| 0x7044 | **removes an entire segment**: 0x0A is swapped for 9 |

## The start line

![The start line](imagenes/salida.png)

The start screen comes from no list and no map. The routine at 0x77C8 builds it
by hand: first it fills the whole ring with grass using an `lddr` of 0x225
bytes, then it pastes eight patches one after another, each call inheriting the
destination the previous one left behind. That is why sometimes only register E
changes between one and the next.

## The six roads

None of these pictures is a capture. They are drawn by **running the
cartridge's road engine** in Python, routine by routine, and checked against
openMSX: across the 264 steps compared -forty-four per stage- the entire
528-byte ring and every generator variable came out identical to the machine's.

**They read from the bottom up**, which is how they are driven: the starting
line and the Konami sign sit at the foot of the strip, the goal at the very top.
The engine emits rows in the order they appear over the top edge of the screen,
so stacking them the other way round would leave everything taller than one row
upside down -the fir trees in stage six, for one-.

### Stage 1

![Stage 1](imagenes/pista_1.png)

Houses with their hedges, the swimming pool, parked cars, the tennis courts and
a Konami billboard near the top.

### Stage 2

![Stage 2](imagenes/pista_2.png)

The beach. The four columns on the left come from this stage's own cyclic list,
the one at 0x7DC5, walked four at a time and restarted on hitting an 0xFF.

### Stage 3

![Stage 3](imagenes/pista_3.png)

The only one that draws the whole row from a sixteen-bit word, and the only one
with road tiles of its own: 0x9B and 0x04 instead of 0x80 and 0x0F.

### Stage 4

![Stage 4](imagenes/pista_4.png)

The S-bend. Only the seven columns on one side are stored; the ones on the
other are computed by adding 0x0D to each tile.

### Stage 5

![Stage 5](imagenes/pista_5.png)

The one that tells the two builds apart: byte 0x53CB, the only difference
between them, is the fifteenth segment of this row of the plan.

### Stage 6

![Stage 6](imagenes/pista_6.png)

The last one. It is the only one that ends with **GOAL** instead of CHECK
POINT, and it brings its own set of scripts, shared with none of the others.

## The car

![The sprite patterns](imagenes/sprites.png)

The car is **two sprites in the same place**: one with the bodywork and one,
four patterns further along, with its colour. On the MSX1 a sprite carries a
single colour, so overlaying two is the only way to give it two.

The sheet also holds the explosions, the flags and the score pop-ups that
appear on overtaking: **300, 500, 800 and 1000**.
