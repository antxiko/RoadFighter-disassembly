# The music

Everything you hear here comes from running the cartridge's own sound engine (`latido_del_sonido`, 0x4BFF, and `suena`, 0x4B6E, which hands it the voices; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0x98, whole, 218 frames, as the game asks for it;
- tune 0x95, whole, 198 frames, forced;
- the first 270 frames of crossing the finish line (0x92, which lasts 346), until the game asks for another sound on top.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`suena` takes the number in A and `pide_efecto` picks the voice: the lowest number wins. Numbers below 0x0F are one- or two-voice effects and from 0x0F up there is three-voice music. Each voice takes eleven bytes from 0xE010 and 0xE031 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the melody table (0x4DE0) but no routine asks for them with an `ld a`. Three pieces have been checked against openMSX, 0x98, 0x95 and 0x92 (the last in its first 270 frames); the rest come out of the same engine but each has not been compared.

## The tunes

**The tune at 0x4266** (0x98)

Asked for by `L_4266`; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_98.mp3?v=a81b0ed1"></audio>

**Crossing the finish line** (0x92)

Asked for by `cruza_la_meta`; lasts 5.8 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=59e1ec2e"></audio>

**The tune at 0x4341** (0x95)

Asked for by `L_4341`; lasts 3.3 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=9099f44b"></audio>

**Table track 0x90** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 20.6 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=d1f8a0fc"></audio>

**Table track 0x91** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.8 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=a06e832c"></audio>

**Table track 0x93** (0x93)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.8 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=e7f59c92"></audio>

**Table track 0x94** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.8 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=2d631e92"></audio>

**Table track 0x96** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=cbd83e08"></audio>

**Table track 0x97** (0x97)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=adb4c494"></audio>

**Table track 0x99** (0x99)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=b3164478"></audio>

**Table track 0x9A** (0x9A)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.3 s.

<audio controls preload="none" src="audio/musica_9A.mp3?v=9cfbf840"></audio>
