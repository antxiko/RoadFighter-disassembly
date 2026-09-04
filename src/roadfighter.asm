; ==========================================================================
; ROAD FIGHTER - Konami - MSX1 - cartucho RC-730 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l4291h:	equ 0x04291
l433ah:	equ 0x0433a

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x404F);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,0404fh,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ======================================================================
; CODIGO 0x4010..0x4099  (137 bytes)
; ======================================================================


L_4010:
	jp carga_el_rotulo_de_la_casa		;4010

; ----------------------------------------------------------------------
; El gancho que INIT deja en H.KEYI: se ejecuta una vez por fotograma y de el cuelga TODO el juego. Lleva su propio cerrojo de reentrada en (0xE005), porque un fotograma lento puede pillar al anterior sin terminar.
; ----------------------------------------------------------------------
manejador_de_interrupcion:
	call 0013eh		;4013   ; BIOS RDVDP - Reads VDP status register | RDVDP: leer el estado del VDP es lo que desarma la interrupcion
	di			;4016   ; el sonido se atiende con las interrupciones cerradas
	call latido_del_sonido		;4017
	ld hl,0e005h		;401a   ; el cerrojo de reentrada
	bit 0,(hl)		;401d   ; si ya hay un fotograma dentro, no se entra otra vez
	jr nz,L_402E		;401f
	inc (hl)			;4021   ; echa el cerrojo
	ei			;4022   ; y a partir de aqui ya se puede interrumpir
	call lee_el_mando_nuevo		;4023   ; lee el mando
	call latido_del_fotograma		;4026   ; el latido: sube el contador y reparte la escena
	ld a,000h		;4029   ; quita el cerrojo
	ld (0e005h),a		;402b
L_402E:
	call 0013eh		;402e   ; BIOS RDVDP - Reads VDP status register | vuelve a leer el estado del VDP
	or a			;4031   ; el bit 7 dice si hay otra interrupcion pendiente
	di			;4032
	call m,latido_del_sonido		;4033   ; y si la hay, otra pasada de sonido antes de salir
	ei			;4036
	ret			;4037
L_4038:
	jp 00047h		;4038   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP, para escribir un registro del VDP

; ----------------------------------------------------------------------
; HL += A, con el acarreo a H. Es la que indexa casi todas las tablas del cartucho.
; ----------------------------------------------------------------------
suma_a_hl:
	add a,l			;403b   ; A + L
	ld l,a			;403c
	ret nc			;403d   ; si no hubo acarreo, H se queda
	inc h			;403e   ; y si lo hubo, H sube uno
	ret			;403f

; ----------------------------------------------------------------------
; La misma, con DE.
; ----------------------------------------------------------------------
suma_a_de:
	add a,e			;4040   ; A + E
	ld e,a			;4041
	ret nc			;4042   ; si no hubo acarreo, D se queda
	inc d			;4043
	ret			;4044

; ----------------------------------------------------------------------
; EL DESPACHADOR DEL CARTUCHO. Se llama con el indice en A y la tabla de punteros PEGADA DETRAS del propio `call`: el `pop hl` no recupera una direccion de retorno, recupera la tabla. Hay seis tablas asi, y ninguna se puede seguir con un trazado estatico, que es por lo que van declaradas a mano en el .entries.
; ----------------------------------------------------------------------
despacha_por_indice:
	add a,a			;4045   ; el indice, por dos: son punteros de 16 bits
	pop hl			;4046   ; la direccion de retorno ES la tabla
	call suma_a_hl		;4047   ; HL apunta ya a la entrada que toca
	ld e,(hl)			;404a   ; saca el puntero
	inc hl			;404b
	ld d,(hl)			;404c
	ex de,hl			;404d   ; y salta a el sin volver: el `ret` de la rutina destino vuelve a quien llamo aqui
	jp (hl)			;404e

; ----------------------------------------------------------------------
; El INIT que declara la cabecera del cartucho. Monta el gancho, borra las variables y se queda parado para siempre: de aqui en adelante el juego solo avanza dentro de la interrupcion.
; ----------------------------------------------------------------------
init_del_cartucho:
	di			;404f   ; sin interrupciones mientras se monta el gancho
	im 1		;4050   ; modo 1: la interrupcion salta a 0x0038, que la BIOS desvia a H.KEYI
	ld a,0c3h		;4052   ; un 0xC3 es el `jp` que se va a escribir en H.KEYI
	ld (0fd9ah),a		;4054   ; H.KEYI (0xFD9A): el gancho que la BIOS ejecuta en cada interrupcion
	ld hl,manejador_de_interrupcion		;4057   ; y detras del `jp`, la direccion del manejador
	ld (0fd9bh),hl		;405a   ; con esto H.KEYI queda como `jp L_4013`
	ld sp,0e800h		;405d   ; la pila, justo encima de los dos kilobytes de variables
	ld hl,0e000h		;4060   ; borra de un golpe 0xE000..0xE7FF
	ld de,0e001h		;4063
	ld bc,007ffh		;4066
	ld (hl),000h		;4069   ; el byte que se replica
	ldir		;406b
	ld a,001h		;406d   ; enciende la bandera de "montando"
	ld (0e005h),a		;406f   ; (0xE005) es el mismo cerrojo que mira el manejador
	call arranca_el_hardware		;4072   ; carga los registros del VDP y limpia la VRAM entera
	xor a			;4075
	ld (0e005h),a		;4076   ; ya esta montado
	call 0013eh		;4079   ; BIOS RDVDP - Reads VDP status register | desarma la interrupcion pendiente leyendo el estado del VDP
	ei			;407c   ; y a partir de aqui manda el gancho
L_407D:
	jr L_407D		;407d   ; el bucle vacio donde INIT se queda para siempre
L_407F:
	jp suena		;407f   ; puerta al sonido, para quien solo tenga el numero de efecto

; ----------------------------------------------------------------------
; El latido. Sube el contador de fotogramas y reparte por escena. El detalle que importa: si (0xE002) NO tiene el bit 7 puesto, apila 0x43C3 ANTES de repartir, de modo que la escena vuelve alli al terminar. Ese `push` es la unica forma de llegar a 0x43C3, y sin declararlo el trazado se dejaba setenta y seis bytes.
; ----------------------------------------------------------------------
latido_del_fotograma:
	ld hl,0e003h		;4082   ; (0xE003) es el reloj del juego
	inc (hl)			;4085
	ld a,(0e002h)		;4086   ; (0xE002) trae las banderas de la partida
	add a,a			;4089   ; el bit 7 al signo
	jp m,L_4091		;408a   ; con el bit puesto, la escena no lleva continuacion
	ld hl,043c3h		;408d   ; si no, se deja 0x43C3 en la pila
	push hl			;4090   ; y la escena volvera ahi con su `ret`
L_4091:
	ld bc,(0e000h)		;4091   ; C = la escena (0xE000), B = el paso (0xE001)
	ld a,c			;4095   ; el indice del reparto es la escena
	call despacha_por_indice		;4096   ; y detras del call, las nueve entradas

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: 9 entradas, indexada por (0xE000); pegada detras del
;   call de 0x4096
;   0x4099..0x40ab  (18 bytes)
DATA_tabla_de_escenas:
	defw 040abh,0412dh,04137h,0416fh,04270h,04306h,04325h,04348h	; 4099
	defw 04373h	; 40a9  -> L_4373

; ======================================================================
; CODIGO 0x40ab..0x4112  (103 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Escena 0. Paso 1: espera a que pase medio segundo largo y arranca la musica; paso 2 y siguientes, en 0x40C0.
; ----------------------------------------------------------------------
L_40AB:
	djnz L_40C0		;40ab   ; paso 1 solamente; el resto, mas abajo
	ld a,(0e003h)		;40ad   ; el reloj del juego
	rra			;40b0   ; el bit 0 al acarreo: solo se sigue un fotograma de cada dos
	ret nc			;40b1
	call barre_la_pantalla		;40b2   ; mira si hay algo pendiente
	ret nz			;40b5
	ld de,046fch		;40b6   ; el bloque comprimido del rotulo de la casa
	call descomprime_con_destino_dentro		;40b9   ; lo suelta en la tabla de nombres
	xor a			;40bc
	jp L_4167		;40bd   ; y a esperar
L_40C0:
	djnz L_40CD		;40c0   ; paso 2 solamente
	call espera_y_sal		;40c2   ; limpia la pantalla
	call monta_la_presentacion_entera		;40c5   ; monta la presentacion entera
	ld a,020h		;40c8   ; 0x20 fotogramas de espera
	jp L_4167		;40ca
L_40CD:
	djnz L_40E6		;40cd   ; paso 3 solamente
	ld hl,0e004h		;40cf   ; la cuenta atras del paso
	dec (hl)			;40d2
	ld a,(hl)			;40d3
	cp 007h		;40d4   ; hasta que baje de 7
	jr c,L_40DE		;40d6
	call escribe_la_presentacion		;40d8   ; borra el rotulo
	jp parpadea_la_eleccion		;40db
L_40DE:
	call L_778C		;40de   ; mientras tanto, anima el rotulo
	ld a,020h		;40e1
	jp L_4167		;40e3
L_40E6:
	djnz $+52		;40e6   ; paso 4: el color del rotulo, mas abajo
	ld hl,0e004h		;40e8   ; la cuenta atras del paso
	dec (hl)			;40eb
	jr z,L_410E		;40ec   ; cuando se acaba, a la escena siguiente
	ld a,(hl)			;40ee
L_40EF:
	and 003h		;40ef   ; los dos bits de abajo del contador eligen el par de colores
	add a,a			;40f1   ; cada par son dos bytes
	ld de,04112h		;40f2   ; la tabla de cuatro pares
	call suma_a_de		;40f5   ; DE ya apunta al par que toca
	ld a,(de)			;40f8
	push de			;40f9
	ld hl,00600h		;40fa   ; el color del cuerpo del rotulo
	ld bc,000b0h		;40fd   ; 0xB0 bytes, que son 22 tiles
	call L_410B		;4100
	pop de			;4103   ; y el segundo byte del par
	inc de			;4104
	ld a,(de)			;4105
	ld hl,006b0h		;4106   ; el color de la parte de abajo
	ld c,058h		;4109   ; 0x58 bytes, once tiles
L_410B:
	jp llena_los_tres_tercios		;410b   ; FILVRM en los tres tercios
L_410E:
	xor a			;410e   ; y a la escena 0 otra vez
	jp L_42FA		;410f

; ----------------------------------------------------------------------
; DATOS colores_del_logotipo: cuatro PARES de color para el rotulo grande de
;   la presentacion; 0x40ee los indexa con `ld a,(hl) / and 003h / add a,a`
;   sobre el contador de 0xE004, y 0x40fa y 0x4106 los meten en el color de
;   0x0600 (0xB0 bytes) y de 0x06b0 (0x58). Por eso el rotulo late
;   0x4112..0x411a  (8 bytes)
DATA_colores_del_logotipo:
	defb 040h,070h	; 4112
	defb 060h,090h	; 4114
	defb 0a0h,0f0h	; 4116
	defb 060h,090h	; 4118

; ======================================================================
; CODIGO 0x411a..0x4165  (75 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Vuelve a poner los registros del VDP, limpia la pantalla y carga la fuente y el marcador. Es lo que corre entre el rotulo de la casa y el menu.
; ----------------------------------------------------------------------
monta_la_presentacion:
	call carga_los_registros_del_vdp		;411a   ; los ocho registros del VDP
	call limpia_la_pantalla		;411d   ; limpia la tabla de nombres
	ld a,01bh		;4120   ; el efecto 0x1B
	call suena		;4122
	call carga_la_fuente		;4125   ; la fuente, a patron 0x2080
	call L_48BB		;4128   ; y el resto del decorado
	jr $+63		;412b

; ----------------------------------------------------------------------
; Escena 1: solo cuenta atras. Cuando (0xE004) llega a cero, arranca la partida.
; ----------------------------------------------------------------------
L_412D:
	ld hl,0e004h		;412d   ; la cuenta atras del paso
	dec (hl)			;4130
	jp nz,parpadea_la_eleccion		;4131   ; mientras quede, sigue en la pantalla de juego
	jp pasa_a_la_escena_siguiente		;4134   ; y al acabarse, a la escena siguiente

; ----------------------------------------------------------------------
; Escena 2: el remate de una partida. Vuelca el marcador, y si no hay nada pendiente vuelve a la portada.
; ----------------------------------------------------------------------
L_4137:
	djnz L_415A		;4137   ; paso 1 solamente
	call endereza_el_coche		;4139   ; endereza el coche si venia derrapando
	call latido_de_la_partida		;413c   ; y el latido de juego entero, que aqui sigue rodando
	ld a,(0e045h)		;413f   ; la bandera de "se acabo"
	or a			;4142
	jr z,L_414A		;4143
	ld a,(0e00dh)		;4145   ; y la de demostracion
	or a			;4148
	ret z			;4149   ; si las dos estan a cero, no hay nada que hacer
L_414A:
	xor a			;414a
	ld (0e00dh),a		;414b   ; apaga la de demostracion
L_414E:
	xor a			;414e   ; escena 0: a la portada
L_414F:
	ld (0e000h),a		;414f   ; deja la escena
	ld a,018h		;4152   ; con 0x18 fotogramas de espera
	ld (0e004h),a		;4154
	jp L_4301		;4157
L_415A:
	call sortea_la_etapa		;415a   ; sortea la etapa: la demostracion no empieza siempre por la primera
	call prepara_la_etapa		;415d   ; prepara la etapa
	ld a,004h		;4160   ; y a la escena 4
	jp L_414F		;4162

; ----------------------------------------------------------------------
; DATOS datos_4165: dos bytes entre dos tramos de codigo
;   0x4165..0x4167  (2 bytes)
DATA_datos_4165:
	defb 03eh,018h	; 4165

; ======================================================================
; CODIGO 0x4167..0x4241  (218 bytes)
; ======================================================================


L_4167:
	ld (0e004h),a		;4167   ; la cuenta atras del paso que empieza
L_416A:
	ld hl,0e001h		;416a   ; y al paso siguiente: el `djnz` de la escena se comera uno mas
	inc (hl)			;416d
	ret			;416e

; ----------------------------------------------------------------------
; Escena 3, la mas larga: el menu, el montaje de la carretera y el arranque de la partida. Cada paso es un `djnz` de la fila.
; ----------------------------------------------------------------------
L_416F:
	djnz L_418C		;416f   ; paso 1: parpadea la eleccion del menu
	ld hl,0e004h		;4171   ; la cuenta atras
	dec (hl)			;4174
	jr z,L_416A		;4175   ; cuando se acaba, al paso siguiente
	ld a,(0e002h)		;4177   ; las banderas de la partida
	bit 5,a		;417a   ; el bit 5 dice cual de las dos opciones esta elegida
	ld de,04747h		;417c   ; el guion de "LEVEL A"
	jr z,L_4184		;417f
	ld de,04751h		;4181   ; o el de "LEVEL B"
L_4184:
	bit 2,(hl)		;4184   ; el bit 2 de la cuenta hace el parpadeo
	jp z,escribe_rotulo		;4186   ; escribe el rotulo
	jp L_4607		;4189   ; o lo borra, que es el mismo guion con la mascara a cero
L_418C:
	djnz L_4195		;418c   ; paso 2 solamente
	call borra_las_variables_de_partida		;418e   ; limpia el menu
	ld a,018h		;4191   ; 0x18 fotogramas
	jr L_4167		;4193
L_4195:
	djnz L_41AF		;4195   ; paso 3 solamente
	call cortina_de_sprites		;4197   ; prepara la partida y sale si no toca seguir
	ret p			;419a
	call carga_los_tiles_de_la_carretera		;419b   ; carga los tiles comunes de la carretera
	call prepara_la_etapa		;419e   ; prepara la etapa
	call dibuja_el_marcador		;41a1   ; dibuja el marcador
	call rotulo_de_la_etapa		;41a4   ; y lo rellena
	ld a,078h		;41a7   ; 0x78 fotogramas, dos segundos largos
	ld (0e004h),a		;41a9
	jp L_416A		;41ac
L_41AF:
	djnz L_41B9		;41af   ; paso 4 solamente
	call espera_y_sal		;41b1   ; limpia
	ld a,004h		;41b4   ; cuatro fotogramas
	jp L_4167		;41b6
L_41B9:
	djnz L_41C0		;41b9   ; paso 5 solamente
	ld a,01ah		;41bb
	jp L_4167		;41bd   ; 0x1A fotogramas
L_41C0:
	djnz L_41CB		;41c0   ; paso 6 solamente
	call monta_la_salida		;41c2   ; monta el paisaje de la salida en el anillo de RAM
	call vuelca_el_anillo		;41c5   ; y lo vuelca a la pantalla
	jp L_416A		;41c8
L_41CB:
	djnz L_41D5		;41cb   ; paso 7 solamente
	call monta_los_indicadores_moviles		;41cd   ; arranca el motor de la carretera
	ld a,005h		;41d0   ; cinco fotogramas
	jp L_4167		;41d2
L_41D5:
	djnz L_41E2		;41d5   ; paso 8 solamente
	call espera_y_sal		;41d7   ; limpia
	dec hl			;41da
	ld (hl),010h		;41db   ; deja 0x10 en la marca
	ld a,009h		;41dd   ; nueve fotogramas
	jp L_4167		;41df
L_41E2:
	dec b			;41e2   ; paso 9 y siguientes
	jp nz,L_4266		;41e3
	call L_5270		;41e6   ; sube los TREINTA sprites a la VRAM
	ld a,(0e003h)		;41e9   ; el reloj del juego
	bit 4,a		;41ec   ; el bit 4 del reloj elige por donde entra el coche
	ld a,0c8h		;41ee   ; 0xC8: debajo del borde de abajo, fuera de la pantalla
	jr z,L_41F4		;41f0
	ld a,080h		;41f2   ; o 0x80 si toca menos
L_41F4:
	ld (0e04ch),a		;41f4   ; (0xE04C) es la Y del sprite del coche, MEDIDA contra la VRAM del emulador
	call dibuja_el_coche		;41f7   ; arranca la etapa
	ld hl,0e003h		;41fa
	ld a,(hl)			;41fd
	and 01fh		;41fe
	ret nz			;4200   ; si no, se sale
	inc hl			;4201
	dec (hl)			;4202   ; la segunda cuenta
	ld a,(hl)			;4203
	cp 001h		;4204   ; cuando llega a uno
	jr z,$+68		;4206
	bit 0,a		;4208   ; el bit 0 alterna el efecto
	jr nz,L_4217		;420a
	cp 002h		;420c   ; y el valor 2 elige otro
	ld a,005h		;420e   ; el efecto 5
	jr nz,L_4214		;4210
	inc a			;4212   ; o el 7
	inc a			;4213
L_4214:
	call suena		;4214   ; lo suelta
L_4217:
	ld a,(0e004h)		;4217   ; la cuenta atras
	bit 0,a		;421a   ; su bit 0 elige el tile
	ld b,046h		;421c   ; el tile 0x46
	jr nz,L_4228		;421e
	ld b,044h		;4220   ; o el 0x44
	dec a			;4222
	dec a			;4223
	jr nz,L_4228		;4224
	ld b,048h		;4226   ; y el 0x48 en el ultimo paso
L_4228:
	ld a,(0e004h)		;4228   ; la cuenta otra vez
	ld hl,04241h		;422b   ; la tabla de nueve posiciones
	call suma_a_hl		;422e
	ld a,(hl)			;4231   ; el desplazamiento que toca
	ld hl,03826h		;4232   ; la fila 1, columna 6 de la tabla de nombres
	call suma_a_hl		;4235   ; corrido lo que diga la tabla
	ld a,b			;4238   ; el primer tile
	call 0004dh		;4239   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc a			;423c   ; el de al lado es el siguiente
	inc hl			;423d
	jp 0004dh		;423e   ; BIOS WRTVRM - Writes data in VRAM | y otro WRTVRM, que ya vuelve

; ----------------------------------------------------------------------
; DATOS tabla_4241: nueve bytes; los indexa 0x422a con `ld hl,04241h / call
;   L_403B / ld a,(hl)`
;   0x4241..0x424a  (9 bytes)
DATA_tabla_4241:
	defb 000h,060h,060h,040h,040h,020h,020h,000h,000h	; 4241  .``@@  ..

; ======================================================================
; CODIGO 0x424a..0x4471  (551 bytes)
; ======================================================================


L_424A:
	ld hl,0e1e3h		;424a   ; los dos tiles de la marca, en el anillo de la carretera
	ld (hl),048h		;424d
	inc hl			;424f
	ld (hl),049h		;4250
	ld a,080h		;4252   ; el coche, a media pantalla
	ld (0e04ch),a		;4254   ; (0xE04C) es la Y del sprite del coche
	call dibuja_el_coche		;4257   ; rearma el coche
	ld hl,0e000h		;425a   ; a la escena siguiente
	inc (hl)			;425d
	ld hl,0e045h		;425e   ; enciende la bandera de "se acabo"
	ld (hl),001h		;4261
	jp pasa_a_la_escena_siguiente		;4263
L_4266:
	ld a,098h		;4266   ; el efecto 0x98
	call suena		;4268
	ld a,050h		;426b   ; 0x50 fotogramas
	jp L_4167		;426d

; ----------------------------------------------------------------------
; Escena 4: la cuenta atras antes de arrancar, con la carretera ya montada.
; ----------------------------------------------------------------------
L_4270:
	djnz L_427F		;4270   ; paso 1 solamente
	call espera_y_sal		;4272   ; limpia
	ld hl,0e045h		;4275   ; enciende la bandera
	ld (hl),001h		;4278
	ld a,01ah		;427a   ; 0x1A fotogramas
	jp L_4167		;427c
L_427F:
	djnz L_4292		;427f   ; paso 2 solamente
	ld hl,0e004h		;4281   ; la cuenta atras
	dec (hl)			;4284
	ld a,030h		;4285   ; 0x30 fotogramas cuando se acabe
	jp z,L_4167		;4287
	ld hl,l4291h		;428a   ; se apila la vuelta
	push hl			;428d
	call motor_de_la_carretera		;428e   ; y mientras tanto, la carretera avanza
L_4291:
	ret			;4291
L_4292:
	djnz L_429F		;4292   ; paso 3 solamente
	call dibuja_el_coche		;4294   ; rearma el coche
	call sube_trece_sprites		;4297   ; y sube los trece primeros sprites
	ld a,028h		;429a   ; 0x28 fotogramas
	jp L_4167		;429c
L_429F:
	djnz L_42C1		;429f   ; paso 4 solamente
	call espera_y_sal		;42a1   ; limpia
	ld de,07895h		;42a4   ; los cinco tiles de "START"
	ld hl,0394ah		;42a7   ; en la fila 10, columna 10
	ld bc,00005h		;42aa
	call sube_a_la_vram		;42ad   ; los sube tal cual a la VRAM
	ld a,(0e002h)		;42b0   ; las banderas de la partida
	bit 6,a		;42b3   ; el bit 6 dice si hay partida de verdad
	jr z,L_42BC		;42b5
	ld a,007h		;42b7   ; si no lo es, suena el efecto 7
	call suena		;42b9
L_42BC:
	ld a,048h		;42bc   ; 0x48 fotogramas
	jp L_4167		;42be
L_42C1:
	djnz L_42D5		;42c1   ; paso 5 solamente
	call espera_y_sal		;42c3
	ld a,(0e002h)		;42c6   ; las banderas
	bit 6,a		;42c9   ; con partida en curso, a jugar
	jp nz,pasa_a_la_escena_siguiente		;42cb
	ld hl,00102h		;42ce   ; y si no la hay, escena 2 paso 1
	ld (0e000h),hl		;42d1
	ret			;42d4
L_42D5:
	call cortina_de_sprites		;42d5   ; paso 6 y siguientes
	ret p			;42d8
	call carga_los_tiles_de_la_carretera		;42d9   ; recarga los tiles de la carretera
	call dibuja_el_marcador		;42dc   ; dibuja el marcador
	call rotulo_de_la_etapa		;42df   ; y el rotulo de la etapa
	call sube_trece_sprites		;42e2   ; sube los trece primeros sprites
	ld a,078h		;42e5   ; 0x78 fotogramas
	ld (0e004h),a		;42e7
	jp L_416A		;42ea

; ----------------------------------------------------------------------
; Escribe "STAGE" y a continuacion el numero, que lo pone 0x44ED.
; ----------------------------------------------------------------------
rotulo_de_la_etapa:
	ld de,0471fh		;42ed   ; el guion de "STAGE"
	call escribe_rotulo		;42f0   ; lo escribe
	dec l			;42f3   ; dos casillas atras
	dec l			;42f4
	jp L_44ED		;42f5   ; y ahi va el numero

; ----------------------------------------------------------------------
; Sube (0xE000) y pone el paso a cero. Con 0x18 fotogramas de espera por la puerta de arriba, o los que traiga A por la de abajo.
; ----------------------------------------------------------------------
pasa_a_la_escena_siguiente:
	ld a,018h		;42f8   ; 0x18 fotogramas
L_42FA:
	ld (0e004h),a		;42fa   ; la cuenta atras del paso
	ld hl,0e000h		;42fd   ; la escena
	inc (hl)			;4300   ; la siguiente
L_4301:
	xor a			;4301   ; y el paso, a cero
	ld (0e001h),a		;4302
	ret			;4305

; ----------------------------------------------------------------------
; Escena 5: la partida en marcha. Si se acabo el tiempo o la vida, cambia de escena.
; ----------------------------------------------------------------------
L_4306:
	djnz L_4322		;4306   ; paso 1 solamente
	call latido_de_la_partida		;4308   ; dibuja la puntuacion
	ld a,(0e00dh)		;430b   ; la bandera de fin
	and a			;430e
	jp nz,L_4319		;430f   ; si esta puesta, se acabo
	ld a,(0e045h)		;4312   ; la de demostracion
	or a			;4315
	ret nz			;4316   ; en demostracion no se sale por aqui
	jr pasa_a_la_escena_siguiente		;4317   ; y si no, a la escena siguiente
L_4319:
	ld a,008h		;4319   ; escena 8
	call L_414F		;431b
	ld (0e004h),a		;431e   ; con la espera que traiga A
	ret			;4321
L_4322:
	jp latido_de_la_retirada		;4322   ; paso 2 y siguientes: el motor de la partida

; ----------------------------------------------------------------------
; Escena 6: el choque. Si (0xE083) no es cero, la carretera sigue rodando mientras el coche se estrella.
; ----------------------------------------------------------------------
L_4325:
	ld a,(0e083h)		;4325   ; la velocidad
	or a			;4328   ; si es cero, no hay nada que arrastrar
	jr z,L_4341		;4329
	call rearma_la_partida		;432b   ; apaga el coche
	ld a,001h		;432e   ; enciende la bandera de fin
	ld (0e045h),a		;4330
	ld hl,l433ah		;4333   ; se apila la vuelta
	push hl			;4336
	call vuelca_el_anillo		;4337   ; y la carretera sigue avanzando
L_433A:
	ld hl,00105h		;433a   ; escena 5, paso 1
	ld (0e000h),hl		;433d
	ret			;4340
L_4341:
	ld a,095h		;4341   ; el efecto 0x95
	call suena		;4343
	jr pasa_a_la_escena_siguiente		;4346   ; y a la escena siguiente

; ----------------------------------------------------------------------
; Escena 7: GAME OVER.
; ----------------------------------------------------------------------
L_4348:
	push bc			;4348   ; el paso, a salvo
	call sube_trece_sprites		;4349   ; sube los trece primeros sprites
	ld a,006h		;434c   ; el tile 6
	ld hl,03b03h		;434e   ; en 0x3B03, dentro de los atributos de sprite
	call 0004dh		;4351   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	pop bc			;4354
	djnz L_4364		;4355   ; paso 1 solamente
	call espera_y_sal		;4357   ; limpia
	ld hl,0e002h		;435a   ; las banderas
	ld a,(hl)			;435d
	and 0bfh		;435e   ; apaga el bit 6: ya no hay partida
	ld (hl),a			;4360
	jp L_414E		;4361   ; y a la portada
L_4364:
	call cortina_de_sprites		;4364   ; paso 2 y siguientes
	ret p			;4367
	ld de,0475eh		;4368   ; el guion de "GAME OVER"
	call escribe_rotulo		;436b   ; lo escribe
	ld a,0d8h		;436e   ; 0xD8 fotogramas, casi cuatro segundos
	jp L_4167		;4370

; ----------------------------------------------------------------------
; Escena 8: el final de una etapa. Rearma el marcador, dibuja la bandera de meta y pasa a la etapa siguiente.
; ----------------------------------------------------------------------
L_4373:
	push bc			;4373   ; el paso, a salvo
	call sube_trece_sprites		;4374   ; sube los trece primeros sprites
	call baja_la_aguja		;4377   ; y el paisaje
	pop bc			;437a
	djnz L_4388		;437b   ; paso 1 solamente
	call cortina_de_sprites		;437d
	ret p			;4380
	call monta_la_pantalla_de_la_meta		;4381   ; monta la calzada de la meta
	xor a			;4384   ; y a esperar
	jp L_4167		;4385
L_4388:
	djnz L_438D		;4388   ; paso 2 solamente
	jp entra_el_coche_en_la_etapa		;438a
L_438D:
	djnz L_4392		;438d   ; paso 3 solamente
	jp parpadea_el_coche		;438f
L_4392:
	djnz L_43BB		;4392   ; paso 4 y siguientes: el cambio de etapa

; ----------------------------------------------------------------------
; EL CAMBIO DE ETAPA. Sube (0xE043) y, cuando llega a SIETE, la deja en uno y sube (0xE042), que es el contador de vueltas. O sea que el cartucho tiene SEIS etapas y despues vuelve a empezar contando vueltas.
; ----------------------------------------------------------------------
	ld hl,0e043h		;4394   ; la etapa
	inc (hl)			;4397   ; una mas
	ld a,(hl)			;4398
	cp 007h		;4399   ; pasada la sexta
	ld bc,00004h		;439b   ; escena 4, paso 0
	jr nz,L_43A8		;439e   ; si no se ha pasado, se queda asi
	ld bc,00303h		;43a0   ; escena 3, paso 3
	ld a,001h		;43a3   ; y la etapa vuelve a ser la primera
	ld (hl),a			;43a5
	dec hl			;43a6   ; (0xE042), el contador de vueltas
	inc (hl)			;43a7   ; una vuelta mas
L_43A8:
	call L_414F		;43a8   ; deja el paso a cero
	ld (0e000h),bc		;43ab   ; y la escena y el paso que se eligieron
	ld (0e00dh),a		;43af
	call prepara_la_etapa		;43b2   ; prepara la etapa nueva
	ld a,06ch		;43b5   ; el tile 0x6C
	ld (0e10eh),a		;43b7   ; en el anillo de la carretera
	ret			;43ba
L_43BB:
	call espera_y_sal		;43bb   ; limpia
	ld a,018h		;43be   ; 0x18 fotogramas
	jp L_4167		;43c0

; ----------------------------------------------------------------------
; LA CONTINUACION. 0x4082 la deja en la pila antes de repartir, asi que corre DESPUES de la escena, todos los fotogramas. Lee el mando y atiende la pausa y el cambio de nivel.
; ----------------------------------------------------------------------
L_43C3:
	call lee_el_mando		;43c3   ; lee el mando
	ld hl,0e03ah		;43c6   ; (0xE03A) guarda lo que se pulso antes
	call L_46BC		;43c9   ; devuelve solo lo que se acaba de pulsar
	or a			;43cc
	ret z			;43cd   ; si no hay nada nuevo, no hay nada que hacer
	ld hl,0e004h		;43ce   ; la cuenta atras del paso
	ld (hl),000h		;43d1   ; se pone a cero
	ld l,(hl)			;43d3   ; y su valor anterior pasa a L
	ld de,0e03bh		;43d4   ; (0xE03B) es el nivel elegido
	ld b,(hl)			;43d7   ; B = lo que habia en la cuenta
	djnz L_43F3		;43d8   ; si no era uno, por otro lado
	and 030h		;43da   ; los dos bits del disparo
	jr z,L_4407		;43dc   ; sin disparo, solo cambia el nivel
	ld a,(de)			;43de   ; el nivel de ahora
	or a			;43df
	ld a,040h		;43e0   ; banderas 0x40
	jr z,L_43E6		;43e2
	ld a,060h		;43e4   ; o 0x60 si estaba en el otro
L_43E6:
	ld (0e002h),a		;43e6   ; las deja puestas
	ld (hl),003h		;43e9   ; y el paso, a tres
	inc hl			;43eb
	ld c,000h		;43ec   ; con el contador a cero
	ld (hl),c			;43ee
	dec c			;43ef
	jp L_5032		;43f0   ; y arranca
L_43F3:
	ld (hl),001h		;43f3   ; el paso, a uno
	ld a,01bh		;43f5   ; el efecto 0x1B
	call suena		;43f7
	ld a,007h		;43fa   ; siete fotogramas
	ld (0e004h),a		;43fc
	call L_49BF		;43ff   ; repinta la presentacion
	xor a			;4402   ; y deja la cuenta a cero
	ld (0e004h),a		;4403
	ret			;4406
L_4407:
	ld a,(de)			;4407   ; el nivel
	xor 001h		;4408   ; le da la vuelta: A pasa a B y B a A
	ld (de),a			;440a   ; y lo guarda
	ret			;440b

; ----------------------------------------------------------------------
; El idiom mas usado del cartucho: baja la cuenta del paso y, si NO ha llegado a cero, se come la direccion de retorno de quien llamo. O sea que quien la llama se sale a la vez, y solo sigue adelante cuando la cuenta se agota.
; ----------------------------------------------------------------------
espera_y_sal:
	ld hl,0e004h		;440c   ; la cuenta atras del paso
	dec (hl)			;440f   ; si llega a cero, se vuelve normal
	ret z			;4410
	pop hl			;4411   ; y si no, se tira el retorno de quien llamo
	ret			;4412   ; con lo que este tambien se sale

; ----------------------------------------------------------------------
; Pone a cero 0xE03F..0xE14D y deja (0xE042) a cero y (0xE043) a uno: vuelta cero, etapa uno.
; ----------------------------------------------------------------------
borra_las_variables_de_partida:
	ld hl,0e03fh		;4413   ; desde 0xE03F
	ld bc,0010fh		;4416   ; 0x10F bytes
	ld d,h			;4419
	ld e,l			;441a
	inc e			;441b
	ld (hl),000h		;441c   ; el cero que se replica
	ldir		;441e
	ld hl,0e042h		;4420   ; (0xE042), la vuelta
	xor a			;4423
	ld (hl),a			;4424   ; a cero
	inc hl			;4425
	inc a			;4426
	ld (hl),a			;4427   ; y (0xE043), la etapa, a uno
	ret			;4428

; ----------------------------------------------------------------------
; La cortina que abre y cierra la pantalla: usa la tabla de atributos de sprite para tapar por bandas. La cuenta del paso dice cuanto queda abierto, y con 0x001C0 por 32 sale la altura de la banda.
; ----------------------------------------------------------------------
cortina_de_sprites:
	ld hl,0e004h		;4429   ; la cuenta atras del paso
	dec (hl)			;442c   ; mientras sea negativa, se sale
	ret m			;442d
	ld a,017h		;442e   ; 0x17 menos lo que quede
	sub (hl)			;4430
	ld hl,001c0h		;4431   ; la base
	add a,l			;4434
	ld l,a			;4435
	add hl,hl			;4436   ; por 32
	add hl,hl			;4437
	add hl,hl			;4438
	add hl,hl			;4439
	add hl,hl			;443a
	ld a,(0e000h)		;443b   ; la escena
	cp 003h		;443e   ; la 3 es la de la partida
	ld bc,0001fh		;4440   ; 0x1F bytes
	jr z,L_444E		;4443
	ld a,(0e002h)		;4445   ; las banderas
	bit 6,a		;4448   ; el bit 6, el de partida en curso
	jr z,L_444E		;444a
	ld c,017h		;444c   ; y entonces 0x17
L_444E:
	xor a			;444e   ; con cero
	call 00056h		;444f   ; BIOS FILVRM - Fills VRAM with value | FILVRM: borra la banda
	ld hl,03b04h		;4452   ; los atributos de sprite, desde el segundo
	call L_446A		;4455   ; y les pone la Y de fuera de pantalla
	ld a,(0e000h)		;4458
	cp 003h		;445b
	call z,L_4467		;445d   ; en la partida, tambien el primero
	ld b,01ch		;4460
	ld hl,0e112h		;4462
	jr $+17		;4465
L_4467:
	ld hl,03b00h		;4467   ; el primer sprite
L_446A:
	ld a,0d0h		;446a   ; la Y 0xD0, que apaga todos los sprites de ahi abajo
	call 0004dh		;446c   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	xor a			;446f
	ret			;4470

; ----------------------------------------------------------------------
; DATOS datos_4471: cinco bytes que nadie carga con una constante
;   0x4471..0x4476  (5 bytes)
DATA_datos_4471:
	defb 006h,01ch,021h,00eh,0e1h	; 4471

; ======================================================================
; CODIGO 0x4476..0x44a5  (47 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Pone 0xC8 en la Y de B sprites, de cuatro en cuatro bytes: los deja justo debajo del borde de abajo.
; ----------------------------------------------------------------------
esconde_sprites:
	ld (hl),0c8h		;4476   ; la Y, fuera de la pantalla
	inc hl			;4478   ; y al sprite siguiente, cuatro bytes mas alla
	inc hl			;4479
	inc hl			;447a
	inc hl			;447b
	djnz esconde_sprites		;447c
	ret			;447e

; ----------------------------------------------------------------------
; Suma DE a la puntuacion, que son TRES bytes en BCD empaquetado en 0xE03F..0xE041 y por tanto seis cifras. El tope es 999999: si el ultimo `daa` desborda, se clava en 0x9999.
; ----------------------------------------------------------------------
suma_a_la_puntuacion:
	ld c,000h		;447f   ; el acarreo del tercer byte
	ld a,(0e002h)		;4481   ; las banderas de la partida
	add a,a			;4484   ; el bit 6 al signo
	ret p			;4485   ; y si no esta puesto, no se puntua
	ld hl,0e03fh		;4486   ; la puntuacion, byte bajo
	ld a,(hl)			;4489
	add a,e			;448a   ; las dos cifras de abajo
	daa			;448b   ; `daa` es lo que la mantiene en BCD
	ld (hl),a			;448c
	inc l			;448d   ; al byte siguiente
	ld a,(hl)			;448e
	adc a,d			;448f   ; con el acarreo
	daa			;4490
	ld (hl),a			;4491
	inc hl			;4492
	ld a,(hl)			;4493
	adc a,c			;4494   ; y el tercero
	daa			;4495
	ld (hl),a			;4496
	jr nc,$+16		;4497   ; si no desborda, ya esta
	ld bc,09999h		;4499   ; y si desborda, se clava
	ld (0e03ch),bc		;449c   ; en 999999
	ld (0e03dh),bc		;44a0
	ret			;44a4

; ----------------------------------------------------------------------
; DATOS datos_44a5: dos bytes entre dos tramos de codigo
;   0x44a5..0x44a7  (2 bytes)
DATA_datos_44a5:
	defb 018h,032h	; 44a5

; ======================================================================
; CODIGO 0x44a7..0x44ea  (67 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Compara la puntuacion (0xE03F..0xE041) con el record (0xE042..0xE044) de arriba abajo y, si es mayor, se lleva los tres bytes con un `lddr`.
; ----------------------------------------------------------------------
actualiza_el_record:
	ex de,hl			;44a7
	ld hl,0e044h		;44a8   ; el byte alto del record
	cp (hl)			;44ab
	jr c,L_44B7		;44ac   ; si la puntuacion no llega, no hay bonificacion
	ld a,(hl)			;44ae
	add a,005h		;44af   ; cinco mas, en BCD
	daa			;44b1
	jr nc,L_44B6		;44b2   ; y si desborda, al tope
	ld a,0ffh		;44b4
L_44B6:
	ld (hl),a			;44b6
L_44B7:
	ld b,003h		;44b7   ; tres bytes que comparar
	ld hl,0e03eh		;44b9   ; desde el byte ALTO de cada uno
	ex de,hl			;44bc
L_44BD:
	ld a,(de)			;44bd   ; la cifra de la puntuacion
	sub (hl)			;44be   ; menos la del record
	jr c,L_44C6		;44bf   ; si es menor, se acabo la comparacion
	ret nz			;44c1   ; si son distintas y no hubo prestamo, la puntuacion gana
	dec l			;44c2   ; y si son iguales, a la cifra siguiente
	dec e			;44c3
	djnz L_44BD		;44c4
L_44C6:
	ld bc,00003h		;44c6   ; tres bytes
	ld e,03eh		;44c9   ; del byte alto de la puntuacion
	ld l,041h		;44cb   ; al byte alto del record
	lddr		;44cd   ; y hacia abajo
	ret			;44cf

; ----------------------------------------------------------------------
; Monta el marcador entero: los indicadores de la derecha y los dos rotulos fijos.
; ----------------------------------------------------------------------
dibuja_el_marcador:
	call monta_los_indicadores		;44d0   ; los indicadores
	ld de,0470dh		;44d3   ; el guion de "HISCORE" y "SCORE"
	call escribe_rotulo		;44d6
L_44D9:
	ld de,0e03eh		;44d9   ; la puntuacion
	ld hl,03838h		;44dc   ; en la fila 1, columna 24
	call L_44E6		;44df
	ld l,098h		;44e2   ; y el record
	ld e,041h		;44e4
L_44E6:
	ld b,003h		;44e6   ; tres bytes de BCD
	jr $+77		;44e8

; ----------------------------------------------------------------------
; DATOS datos_44ea: tres bytes entre dos tramos de codigo
;   0x44ea..0x44ed  (3 bytes)
DATA_datos_44ea:
	defb 021h,036h,038h	; 44ea

; ======================================================================
; CODIGO 0x44ed..0x452d  (64 bytes)
; ======================================================================


L_44ED:
	ld de,0e043h		;44ed   ; la etapa
	ld b,001h		;44f0   ; un solo byte
	jr $+67		;44f2

; ----------------------------------------------------------------------
; Los cuadros de SPEED y FUEL de la derecha, mas los tiles del marco.
; ----------------------------------------------------------------------
monta_los_indicadores:
	ld hl,038b9h		;44f4   ; la fila 5, columna 25
	ld a,06fh		;44f7   ; el tile 0x6F
	ld bc,00004h		;44f9   ; cuatro casillas
	call 00056h		;44fc   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld l,0d9h		;44ff   ; la fila 6, columna 25
	ld de,0452dh		;4501   ; los cuatro tiles del cuadro
	ld bc,00004h		;4504
	call sube_a_la_vram		;4507   ; los sube tal cual
	ld l,0f9h		;450a   ; la fila 7, columna 25
	ld b,008h		;450c   ; ocho filas
L_450E:
	push bc			;450e
	ld de,04531h		;450f   ; los cuatro tiles de una fila
	ld bc,00104h		;4512   ; una fila de cuatro
	call rectangulo_de_tiles		;4515   ; y a la siguiente
	pop bc			;4518
	djnz L_450E		;4519
	ld l,0f9h		;451b   ; la fila 7, columna 25 otra vez
	ld a,072h		;451d   ; el tile 0x72
	ld c,004h		;451f   ; cuatro casillas
	call 00056h		;4521   ; BIOS FILVRM - Fills VRAM with value
	ld de,0476ah		;4524   ; el guion de la marca de la casa
	call escribe_rotulo		;4527   ; lo escribe
L_452A:
	jp L_740B		;452a   ; y a poner las cifras

; ----------------------------------------------------------------------
; DATOS datos_452d: ocho bytes que 0x4501 sube a la VRAM de cuatro en cuatro
;   (`ld de,0452dh / ld bc,00004h / call L_45A7`)
;   0x452d..0x4535  (8 bytes)
DATA_datos_452d:
	defb 070h,001h,060h,071h,070h,073h,001h,071h	; 452d  p.`qps.q

; ======================================================================
; CODIGO 0x4535..0x459d  (104 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Escribe B bytes de BCD empaquetado -dos cifras por byte- en la VRAM, del byte ALTO al bajo. La mascara de C apaga los ceros de delante: hasta que sale la primera cifra distinta de cero, `and c` con C=0 deja un espacio. En cuanto aparece una, C pasa a 0xFF y ya no se tapa nada. El ultimo byte nunca se tapa (0x4542), para que un cero se vea como cero.
; ----------------------------------------------------------------------
escribe_cifras_bcd:
	ld c,000h		;4535   ; la mascara arranca tapando
L_4537:
	ld a,(de)			;4537   ; el byte de BCD
	rra			;4538   ; la cifra de arriba a los cuatro bits de abajo
	rra			;4539
	rra			;453a
	rra			;453b
	and 00fh		;453c
	jr z,L_4542		;453e   ; si es cero, sigue tapada
	ld c,0ffh		;4540   ; y si no, se destapa para siempre
L_4542:
	dec b			;4542   ; en el ultimo byte
	jr nz,L_4547		;4543
	ld c,0ffh		;4545   ; no se tapa nada
L_4547:
	inc b			;4547
	add a,010h		;4548   ; la fuente tiene los digitos a partir del tile 0x10
	and c			;454a   ; la mascara
	call 0004dh		;454b   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;454e
	ld a,(de)			;454f   ; el mismo byte
	and 00fh		;4550   ; y ahora la cifra de abajo
	jr z,L_4556		;4552
	ld c,0ffh		;4554
L_4556:
	add a,010h		;4556
	and c			;4558
	call 0004dh		;4559   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;455c   ; el byte anterior, que es menos significativo
	inc hl			;455d
	djnz L_4537		;455e   ; y siguiente
	ret			;4560

; ----------------------------------------------------------------------
; Convierte una posicion en la direccion de su casilla en la tabla de nombres. Baja HL cinco bits arrastrando por H y remata con `or 0x38`, que es la base 0x3800 que fija R2.
; ----------------------------------------------------------------------
casilla_a_direccion:
	ld a,l			;4561   ; la parte baja
	rra			;4562   ; cinco desplazamientos, arrastrando por H
	rra			;4563
	rra			;4564
	rra			;4565
	rr h		;4566
	rra			;4568
	rr h		;4569
	rra			;456b
	rr h		;456c
	ld l,h			;456e   ; lo que quedo en H
	and 003h		;456f   ; los dos bits que sobreviven
	add a,038h		;4571   ; la tabla de nombres empieza en 0x3800
	ld h,a			;4573   ; y ya esta la direccion
	ret			;4574

; ----------------------------------------------------------------------
; B renglones de C tiles, saltando 0x20 de uno a otro: la anchura de la pantalla. Es con lo que se dibujan los cuadros del marcador.
; ----------------------------------------------------------------------
rectangulo_de_tiles:
	push bc			;4575   ; la cuenta de filas, a salvo
	ld b,000h		;4576   ; B ha de ser cero: el contador de bytes es solo C
	call sube_a_la_vram		;4578   ; sube la fila
	pop bc			;457b
	ld a,020h		;457c   ; una fila entera son 32 casillas
	call suma_a_hl		;457e   ; HL a la fila de abajo
	djnz rectangulo_de_tiles		;4581   ; y otra vez
	ret			;4583

; ----------------------------------------------------------------------
; Apaga los sprites y pone la tabla de nombres entera a cero.
; ----------------------------------------------------------------------
limpia_la_pantalla:
	call L_4467		;4584   ; esconde los sprites
	ld hl,03800h		;4587   ; la tabla de nombres
	ld bc,00300h		;458a   ; 768 casillas
	xor a			;458d
	jp 00056h		;458e   ; BIOS FILVRM - Fills VRAM with value | FILVRM

; ----------------------------------------------------------------------
; SETWRT con HL, y deja el PUERTO de datos del VDP en el C alternativo. Asi el que escriba despues solo tiene que hacer `out (c),a` sin volver a mirar nada. A se conserva con `ex af,af'`.
; ----------------------------------------------------------------------
fija_escritura:
	ex af,af'			;4591   ; A, a salvo
	call 00053h		;4592   ; BIOS SETWRT - Enables VDP to write | SETWRT: fija la direccion de escritura
	exx			;4595
	ld a,(00006h)		;4596   ; 0x0006 es donde la BIOS guarda el puerto de datos del VDP
	ld c,a			;4599   ; y se queda en el C alternativo
	exx			;459a
	ex af,af'			;459b   ; A, de vuelta
	ret			;459c

; ----------------------------------------------------------------------
; DATOS codigo_muerto_459d: diez bytes que son CODIGO -`call 0x0050 / exx / ld
;   a,(00007h) / ld c,a / exx / ret`, el SETRD gemelo del SETWRT de 0x4591- y
;   a los que no llama nadie
;   0x459d..0x45a7  (10 bytes)
DATA_codigo_muerto_459d:
	defb 0cdh,050h,000h,0d9h,03ah,007h,000h,04fh,0d9h,0c9h	; 459d  .P..:..O..

; ======================================================================
; CODIGO 0x45a7..0x45bc  (21 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Copia BC bytes de (DE) a la VRAM desde HL, sin pasar por la BIOS: SETWRT una vez y luego `out (c),a` a pelo.
; ----------------------------------------------------------------------
sube_a_la_vram:
	call 00053h		;45a7   ; BIOS SETWRT - Enables VDP to write | fija la direccion
	ld a,(00006h)		;45aa   ; el puerto de datos
	exx			;45ad
	ld c,a			;45ae
	exx			;45af
L_45B0:
	ld a,(de)			;45b0   ; el byte
	exx			;45b1
	out (c),a		;45b2   ; y al VDP
	exx			;45b4
	inc de			;45b5
	dec bc			;45b6   ; uno menos
	ld a,b			;45b7   ; hasta que BC llegue a cero
	or c			;45b8
	jr nz,L_45B0		;45b9
	ret			;45bb

; ----------------------------------------------------------------------
; DATOS codigo_muerto_45bc: diecinueve bytes que son CODIGO -la version de
;   tres tercios de L_45A7, con su `ld b,003h` y su `ld de,00800h`- y a los
;   que no llama nadie
;   0x45bc..0x45cf  (19 bytes)
DATA_codigo_muerto_45bc:
	defb 0d9h,006h,003h,0d9h,0c5h,0d5h,0cdh,0a7h,045h,011h,000h,008h,019h,0d1h,0c1h,0d9h	; 45bc  ........E.......
	defb 010h,0f1h,0c9h	; 45cc

; ======================================================================
; CODIGO 0x45cf..0x46a9  (218 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; FILVRM repetido en los TRES tercios de SCREEN 2, sumando 0x800 cada vez. En este modo cada tercio de pantalla tiene su propia copia de las tablas, asi que llenar uno solo dejaria dos tercios sin pintar.
; ----------------------------------------------------------------------
llena_los_tres_tercios:
	ld d,003h		;45cf   ; tres tercios
L_45D1:
	push bc			;45d1
	push de			;45d2
	call 00056h		;45d3   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld de,00800h		;45d6   ; el tercio siguiente esta 0x800 mas alla
	add hl,de			;45d9
	pop de			;45da
	pop bc			;45db
	dec d			;45dc   ; uno menos
	jr nz,L_45D1		;45dd
	ret			;45df

; ----------------------------------------------------------------------
; Igual, pero descomprimiendo: el MISMO bloque en los tres tercios. El `push de` / `pop de` es lo que rebobina el flujo en cada vuelta.
; ----------------------------------------------------------------------
descomprime_los_tres_tercios:
	ld b,003h		;45e0   ; tres tercios
L_45E2:
	push bc			;45e2
	push de			;45e3   ; el flujo, a salvo: se vuelve a leer entero
	call descomprime		;45e4   ; lo suelta
	ld de,00800h		;45e7   ; y el tercio siguiente
	add hl,de			;45ea
	pop de			;45eb   ; el flujo, otra vez desde el principio
	pop bc			;45ec
	djnz L_45E2		;45ed
	ret			;45ef

; ----------------------------------------------------------------------
; El interprete de rotulos. El guion llega en DE y es [destino de VRAM, palabra] seguido de indices de tile, con 0xFE para saltar a otro destino y 0xFF para terminar. La mascara de C se aplica a cada tile: con 0xFF sale el tile, y por la puerta de 0x4607, con C=0, sale un cero. O sea que la MISMA lista sirve para escribir el rotulo y para borrarlo.
; ----------------------------------------------------------------------
escribe_rotulo:
	ld c,0ffh		;45f0   ; la mascara que deja pasar el tile
L_45F2:
	ex de,hl			;45f2   ; HL pasa a ser el guion
	ld e,(hl)			;45f3   ; los dos bytes del destino
	inc hl			;45f4
	ld d,(hl)			;45f5
	ex de,hl			;45f6   ; HL, el destino; DE, el guion
	inc de			;45f7   ; y DE, ya detras del destino
L_45F8:
	ld a,(de)			;45f8   ; el byte del guion
	inc de			;45f9
	ld b,a			;45fa   ; 0xFF es -1
	inc b			;45fb
	ret z			;45fc   ; y cierra el guion
	inc b			;45fd   ; 0xFE es -2
	jr z,L_45F2		;45fe   ; y manda a leer otro destino
	and c			;4600   ; la mascara: 0xFF lo deja, 0x00 lo borra
	call 0004dh		;4601   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;4604   ; y a la casilla siguiente
	jr L_45F8		;4605
L_4607:
	ld c,000h		;4607   ; la mascara que BORRA
	jr L_45F2		;4609   ; por lo demas, la misma rutina

; ----------------------------------------------------------------------
; La segunda puerta del descompresor: el destino de VRAM va DENTRO del bloque, en sus dos primeros bytes. Es tambien a donde salta el mandato 0x80 para cambiar de destino a mitad de bloque.
; ----------------------------------------------------------------------
descomprime_con_destino_dentro:
	ex de,hl			;460b   ; HL pasa a ser el bloque
	ld e,(hl)			;460c   ; los dos bytes del destino
	inc hl			;460d
	ld d,(hl)			;460e
	ex de,hl			;460f   ; HL, el destino; DE, el bloque
	inc de			;4610   ; y DE, ya detras del destino

; ----------------------------------------------------------------------
; EL DESCOMPRESOR. Escribe directamente en la VRAM, no en memoria. Un byte de mandato: 0x00 cierra el bloque, de 0x01 a 0x7F repite el byte siguiente esa cuenta, 0x80 toma los dos bytes siguientes como destino nuevo, y de 0x81 a 0xFF copia tal cual los (mandato & 0x7F) bytes que siguen. La comparacion `and 07fh / cp b` es lo que mira el bit 7 sin tocar el mandato.
; ----------------------------------------------------------------------
descomprime:
	call fija_escritura		;4611   ; fija la escritura y prepara el puerto
L_4614:
	ld a,(de)			;4614   ; el mandato
	and a			;4615
	ret z			;4616   ; el 0x00 cierra el bloque
	inc de			;4617
	ld b,a			;4618   ; B se queda con el mandato ENTERO
	and 07fh		;4619   ; y A, solo con la cuenta
	cp b			;461b   ; si coinciden, el bit 7 estaba a cero
	jr z,L_462C		;461c   ; y entonces es una repeticion
	and a			;461e   ; con el bit 7 puesto, si la cuenta es cero
	jr z,descomprime_con_destino_dentro		;461f   ; el mandato era 0x80: destino nuevo
	ld b,a			;4621   ; y si no, la cuenta del literal
L_4622:
	ld a,(de)			;4622   ; el byte
	inc de			;4623
	exx			;4624
	out (c),a		;4625   ; al VDP
	exx			;4627
	djnz L_4622		;4628   ; tantos como diga la cuenta
	jr L_4614		;462a
L_462C:
	ld a,(de)			;462c   ; el byte que se repite
	inc de			;462d
L_462E:
	exx			;462e
	out (c),a		;462f   ; al VDP
	exx			;4631
	djnz L_462E		;4632   ; tantas veces como diga el mandato
	jr L_4614		;4634

; ----------------------------------------------------------------------
; Da la vuelta a C patrones de sprite. Un patron de 16x16 son 32 bytes: los dieciseis de la mitad izquierda y detras los de la derecha. Para verlo del reves no basta con invertir los bits, hay que CRUZAR las dos mitades, y eso es lo que hace el juego del registro E: sube dieciseis, resta 0x20 y mira su bit 4, con lo que la primera mitad cae 0x10 mas abajo y la segunda 0x10 mas arriba.
; ----------------------------------------------------------------------
espeja_patrones_de_sprite:
	push de			;4636   ; el destino del patron, a salvo
L_4637:
	ld b,010h		;4637   ; media figura, dieciseis bytes
L_4639:
	call espeja_un_byte_de_vram		;4639   ; lee, invierte y escribe
	inc hl			;463c
	inc e			;463d   ; solo E: el cruce de mitades vive en los ocho bits de abajo
	djnz L_4639		;463e
	ld a,e			;4640   ; lo que quedo en E
	sub 020h		;4641   ; treinta y dos atras
	ld e,a			;4643
	bit 4,e		;4644   ; y su bit 4 dice si falta la otra mitad
	jr z,L_4637		;4646
	pop de			;4648   ; el destino del patron
	ld a,020h		;4649   ; el patron siguiente, treinta y dos bytes mas alla
	call suma_a_de		;464b
	dec c			;464e   ; uno menos
	jr nz,espeja_patrones_de_sprite		;464f
	ret			;4651

; ----------------------------------------------------------------------
; El espejo de los tiles de fondo, y en los tres tercios. Asi el cartucho tiene la mitad derecha de la carretera sin guardarla: la fabrica dando la vuelta a la izquierda.
; ----------------------------------------------------------------------
espeja_tiles:
	ld b,003h		;4652   ; tres tercios
L_4654:
	push bc			;4654
	push hl			;4655
	push de			;4656
L_4657:
	ld b,008h		;4657   ; un tile son ocho bytes
L_4659:
	call espeja_un_byte_de_vram		;4659   ; lee, invierte y escribe
	inc hl			;465c
	inc de			;465d
	djnz L_4659		;465e
	dec c			;4660   ; C tiles
	jr nz,L_4657		;4661
	pop hl			;4663   ; el origen
	ld de,00800h		;4664   ; el tercio siguiente
	add hl,de			;4667
	ex de,hl			;4668   ; y lo mismo con el destino
	pop hl			;4669
	pop bc			;466a
	djnz L_4654		;466b
	ret			;466d

; ----------------------------------------------------------------------
; Le da la vuelta a A. Ocho veces `rr c` y `rla`: el bit que sale por abajo de C entra por arriba de A. Es el espejo de un byte de patron.
; ----------------------------------------------------------------------
invierte_los_bits:
	push bc			;466e
	ld c,a			;466f   ; el byte de partida
	ld b,008h		;4670   ; ocho bits
L_4672:
	rr c		;4672   ; el bit 0 al acarreo
	rla			;4674   ; y del acarreo al bit 0 de A, empujando
	djnz L_4672		;4675
	pop bc			;4677
	ret			;4678

; ----------------------------------------------------------------------
; Lee un byte de la VRAM en HL, le da la vuelta y lo deja en DE.
; ----------------------------------------------------------------------
espeja_un_byte_de_vram:
	call 0004ah		;4679   ; BIOS RDVRM - Reads the content of VRAM | RDVRM
	call invierte_los_bits		;467c   ; del reves
	ex de,hl			;467f   ; el destino
	call 0004dh		;4680   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	ex de,hl			;4683   ; y HL vuelve a ser el origen
	ret			;4684

; ----------------------------------------------------------------------
; Silencia el PSG, deja el efecto 0x1B, borra los 16 KB de VRAM enteros y carga los ocho registros del VDP.
; ----------------------------------------------------------------------
arranca_el_hardware:
	ld a,0b8h		;4685   ; el mandato 0xB8 al sonido
	call L_4BF6		;4687
	ld a,01bh		;468a   ; el efecto 0x1B
	call L_407F		;468c
	xor a			;468f   ; desde la direccion 0
	ld h,a			;4690
	ld l,a			;4691
	ld bc,04000h		;4692   ; los 16 KB de la VRAM
	call 00056h		;4695   ; BIOS FILVRM - Fills VRAM with value | FILVRM

; ----------------------------------------------------------------------
; Los ocho registros, del 0 al 7, de la tabla de 0x46A9. Son `02 E2 0E 7F 07 76 03 E4`: SCREEN 2, sprites de 16x16, nombres en 0x3800, COLORES en 0x0000 y PATRONES en 0x2000 -al reves del reparto habitual-, atributos de sprite en 0x3B00 y patrones de sprite en 0x1800.
; ----------------------------------------------------------------------
carga_los_registros_del_vdp:
	ld hl,046a9h		;4698   ; la tabla
	ld d,008h		;469b   ; ocho registros
	ld c,000h		;469d   ; empezando por el 0
L_469F:
	ld b,(hl)			;469f   ; el valor
	call 00047h		;46a0   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP
	inc hl			;46a3
	inc c			;46a4   ; y al registro siguiente
	dec d			;46a5
	jr nz,L_469F		;46a6
	ret			;46a8

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: los OCHO registros del VDP, que escribe el bucle de
;   0x469f: 02 E2 0E 7F 07 76 03 E4. R3=0x7F y R4=0x07 dejan los COLORES en
;   0x0000 y los PATRONES en 0x2000, al reves del reparto habitual; R5=0x76
;   los atributos de sprite en 0x3B00 y R6=0x03 sus patrones en 0x1800
;   0x46a9..0x46b1  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 46a9  .....v..

; ======================================================================
; CODIGO 0x46b1..0x46fc  (75 bytes)
; ======================================================================


L_46B1:
	ld c,007h		;46b1   ; el registro 7, el del borde y el fondo
	jp L_4038		;46b3

; ----------------------------------------------------------------------
; Lee el mando y deja en (0xE008) solo lo que se acaba de pulsar, comparandolo con lo que habia en (0xE009).
; ----------------------------------------------------------------------
lee_el_mando_nuevo:
	call lee_el_mando		;46b6   ; lee el mando
	ld hl,0e009h		;46b9   ; lo que estaba pulsado antes
L_46BC:
	ld c,(hl)			;46bc   ; lo de antes
	ld (hl),a			;46bd   ; guarda lo de ahora
	xor c			;46be   ; los que han cambiado
	and (hl)			;46bf   ; y de esos, solo los que ahora estan pulsados
	dec hl			;46c0   ; (0xE008)
	ld (hl),a			;46c1   ; ahi quedan los recien pulsados
	ret			;46c2

; ----------------------------------------------------------------------
; Junta el joystick y el teclado en un solo byte. El joystick sale del registro 14 del PSG, y las teclas de las filas 7 y 8 de la matriz se van encajando a su lado con desplazamientos, de modo que arriba quede el mismo bit se pulse donde se pulse.
; ----------------------------------------------------------------------
lee_el_mando:
	ld e,08fh		;46c3   ; el registro 15 del PSG manda en los puertos
	ld a,00fh		;46c5
	call 00093h		;46c7   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,00eh		;46ca   ; el registro 14 es el que trae el joystick
	di			;46cc   ; sin interrupciones, que el PSG es de dos pasos
	call 00096h		;46cd   ; BIOS RDPSG - Reads value from PSG-register | RDPSG
	ei			;46d0
	cpl			;46d1   ; el PSG da los bits al reves
	and 03fh		;46d2   ; y solo interesan seis
	push af			;46d4   ; a salvo
	ld a,007h		;46d5   ; la fila 7 de la matriz del teclado
	call 00141h		;46d7   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	cpl			;46da   ; tambien al reves
	rrca			;46db   ; el bit que interesa, a su sitio
	and 020h		;46dc
	ld e,a			;46de
	ld a,008h		;46df   ; la fila 8, la del cursor
	call 00141h		;46e1   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	cpl			;46e4
	rrca			;46e5   ; dos desplazamientos
	rrca			;46e6
	ld b,a			;46e7
	and 004h		;46e8   ; y se va encajando bit a bit
	or e			;46ea
	ld c,a			;46eb
	ld a,b			;46ec
	rrca			;46ed
	rrca			;46ee
	ld b,a			;46ef
	and 018h		;46f0
	or c			;46f2
	ld c,a			;46f3
	ld a,b			;46f4
	rrca			;46f5
	and 003h		;46f6
	or c			;46f8
	pop bc			;46f9   ; el joystick
	or b			;46fa   ; juntado con el teclado
	ret			;46fb

; ----------------------------------------------------------------------
; DATOS rle_46fc: a la VRAM 0x394a y 0x396c (dos tramos, mandato 0x80); 20
;   bytes de nombres. Lo carga 0x40b9
;   0x46fc..0x470d  (17 bytes)
DATA_rle_46fc:
	defb 04ah,039h,00ch,05ah,080h,06ch,039h,088h,033h,02fh,026h,034h,037h,021h,032h,025h	; 46fc  J9.Z.l9.3/&47!2%
	defb 000h	; 470c

; ----------------------------------------------------------------------
; DATOS guion_marcadores: "HISCORE" en 0x3817 y "SCORE" en 0x3877, los dos
;   rotulos fijos del marcador
;   0x470d..0x471f  (18 bytes)
DATA_guion_marcadores:
	defb 017h,038h,028h,029h,033h,023h,02fh,032h,025h,0feh,077h,038h,033h,023h,02fh,032h	; 470d  .8()3#/2%.w83#/2
	defb 025h,0ffh	; 471d

; ----------------------------------------------------------------------
; DATOS guion_stage: "STAGE" en 0x3969, el rotulo que anuncia la etapa; el
;   numero lo escribe aparte el marcador
;   0x471f..0x472a  (11 bytes)
DATA_guion_stage:
	defb 069h,039h,033h,034h,021h,027h,025h,000h,000h,000h,0ffh	; 471f  i934!'%....

; ----------------------------------------------------------------------
; DATOS guion_titulo: ":KONAMI 1985", "PLAY SELECT" y "LEVEL A" de la pantalla
;   de presentacion, en tres destinos
;   0x472a..0x4751  (39 bytes)
DATA_guion_titulo:
	defb 04ah,039h,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,015h,0feh,0abh	; 472a  J9.+/.!-).......
	defb 039h,030h,02ch,021h,039h,000h,033h,025h,02ch,025h,023h,034h,0feh,00dh,03ah,02ch	; 473a  90,!9.3%,%#4..:,
	defb 025h,036h,025h,02ch,000h,021h,0ffh	; 474a

; ----------------------------------------------------------------------
; DATOS guion_nivel_b: "LEVEL B" en 0x3a4d, la segunda opcion del menu
;   0x4751..0x475b  (10 bytes)
DATA_guion_nivel_b:
	defb 04dh,03ah,02ch,025h,036h,025h,02ch,000h,022h,0ffh	; 4751  M:,%6%,.".

; ----------------------------------------------------------------------
; DATOS guion_sin_destino: tres bytes de guion SIN su palabra de destino:
;   0x5045 entra por 0x45f8 (`ld de,0475bh / jp L_45F8`), saltandose la
;   lectura del destino y usando el que ya haya
;   0x475b..0x475e  (3 bytes)
DATA_guion_sin_destino:
	defb 01bh,01ch,0ffh	; 475b

; ----------------------------------------------------------------------
; DATOS guion_game_over: "GAME OVER" en 0x3969
;   0x475e..0x476a  (12 bytes)
DATA_guion_game_over:
	defb 069h,039h,027h,021h,02dh,025h,000h,02fh,036h,025h,032h,0ffh	; 475e  i9'!-%./6%2.

; ----------------------------------------------------------------------
; DATOS guion_marca: los patrones 0x5a..0x5f en 0x3af8: el simbolo de la casa,
;   no letras
;   0x476a..0x4773  (9 bytes)
DATA_guion_marca:
	defb 0f8h,03ah,05ah,05bh,05ch,05dh,05eh,05fh,0ffh	; 476a  .:Z[\]^_.

; ======================================================================
; CODIGO 0x4773..0x478a  (23 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La fuente del cartucho: 43 tiles a partir del 0x10, en PATRON 0x2080, y su color relleno de 0xF0 -blanco sobre transparente-. Que el 0xF0 vaya a 0x0080 es la prueba de que ahi estan los COLORES y no los patrones: como patron dejaria medio bloque pintado en cada letra.
; ----------------------------------------------------------------------
carga_la_fuente:
	call marco_de_colores		;4773   ; primero el marco de colores
	ld de,0478ah		;4776   ; el bloque comprimido de la fuente
	ld hl,02080h		;4779   ; patron 0x2080, o sea el tile 0x10
	call descomprime_los_tres_tercios		;477c
	ld a,0f0h		;477f   ; blanco sobre transparente
	ld hl,00080h		;4781   ; el color de esos mismos tiles
	ld bc,00160h		;4784   ; 0x160 bytes, cuarenta y tres tiles
	jp llena_los_tres_tercios		;4787   ; y a llenar

; ----------------------------------------------------------------------
; DATOS rle_fuente_patron: 272 bytes -> 344 de PATRON en 0x2080 (43 tiles). Lo
;   carga 0x477c, y justo detras 0x477f llena de 0xF0 el COLOR de 0x0080:
;   letras blancas sobre transparente
;   0x478a..0x489a  (272 bytes)
DATA_rle_fuente_patron:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0cch,07eh	; 478a  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 479a  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 47aa  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 47ba  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 47ca  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,000h,00fh,01fh,004h,0ffh,089h,00fh,000h	; 47da  <B....B<........
	defb 000h,0feh,0e0h,0e0h,0c0h,0c0h,080h,018h,000h,004h,000h,001h,07eh,004h,000h,097h	; 47ea  ............~...
	defb 01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h	; 47fa  .6cc.cc.~cc~cc~.
	defb 03eh,063h,060h,060h,060h,063h,03eh,009h,000h,0a1h,07fh,060h,060h,07eh,060h,060h	; 480a  >c```c>....``~``
	defb 07fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h,03eh,063h,060h,067h,063h,063h	; 481a  ...``~```.>c`gcc
	defb 03fh,000h,063h,063h,063h,07fh,063h,063h,063h,000h,03ch,005h,018h,081h,03ch,009h	; 482a  ?.ccc.ccc.<...<.
	defb 000h,088h,063h,066h,06ch,078h,07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h	; 483a  ..cflx|ng..`...c
	defb 077h,07fh,07fh,06bh,063h,063h,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh	; 484a  w..kcc.cs{.ogc.>
	defb 005h,063h,089h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h,008h,000h,092h,000h	; 485a  .c.>.~ccc~``....
	defb 07eh,063h,063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h	; 486a  ~ccb|fc.>c`>.c>.
	defb 07eh,006h,018h,009h,000h,004h,063h,08bh,036h,01ch,008h,000h,063h,063h,06bh,06bh	; 487a  ~.....c.6...cckk
	defb 07fh,077h,022h,009h,000h,087h,066h,066h,07eh,03ch,018h,018h,018h,008h,000h,000h	; 488a  .w"...ff~<......

; ======================================================================
; CODIGO 0x489a..0x490f  (117 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Borra los dieciseis primeros tiles y le da a cada uno un color distinto, del 0 al 15: el tile N queda pintado del color N. Es la paleta de trabajo con la que despues se colorean los rotulos.
; ----------------------------------------------------------------------
marco_de_colores:
	ld hl,02000h		;489a   ; los patrones de los dieciseis primeros tiles
	ld bc,00080h		;489d   ; 0x80 bytes
	xor a			;48a0   ; a cero: tiles vacios
	call llena_los_tres_tercios		;48a1
	ld hl,00000h		;48a4   ; el color del tile 0
	ld de,00008h		;48a7   ; cada tile son ocho bytes de color
	ld b,010h		;48aa   ; dieciseis tiles
L_48AC:
	push bc			;48ac
	ld bc,00008h		;48ad   ; las ocho lineas del tile
	push hl			;48b0
	call llena_los_tres_tercios		;48b1   ; todas del mismo color
	pop hl			;48b4
	add hl,de			;48b5   ; al tile siguiente
	inc a			;48b6   ; y al color siguiente
	pop bc			;48b7
	djnz L_48AC		;48b8
	ret			;48ba
L_48BB:
	ld a,00eh		;48bb   ; catorce
	ld (0e00ah),a		;48bd   ; (0xE00A) es la cuenta del barrido
	ld hl,03aaah		;48c0   ; la ultima casilla de la pantalla
	ld (0e00eh),hl		;48c3   ; (0xE00E) es por donde va
	jp L_4010		;48c6   ; y a cargar el marcador

; ----------------------------------------------------------------------
; Los 27 tiles del rotulo KONAMI, en PATRON 0x2200, con el color a 0xF0. La direccion 0x6200 lleva puesto el bit de escritura del VDP, pero SETWRT hace `and 03fh` sobre H antes de nada, asi que acaba en 0x2200.
; ----------------------------------------------------------------------
carga_el_rotulo_de_la_casa:
	ld de,0490fh		;48c9   ; el bloque comprimido
	ld hl,06200h		;48cc   ; 0x6200, que enmascarado es el patron 0x2200
	call descomprime_los_tres_tercios		;48cf
	ld hl,00200h		;48d2   ; y el color de esos tiles
	ld bc,000d8h		;48d5   ; 0xD8 bytes, veintisiete tiles
	ld a,0f0h		;48d8   ; blanco sobre transparente
	jp llena_los_tres_tercios		;48da

; ----------------------------------------------------------------------
; El barrido que borra la pantalla de abajo arriba: cada llamada sube 0x20 -una fila- y escribe tres tramos de tiles seguidos, dejando un rastro que se va comiendo la imagen.
; ----------------------------------------------------------------------
barre_la_pantalla:
	ld hl,(0e00eh)		;48dd   ; por donde va el barrido
	ld de,0ffe0h		;48e0   ; una fila hacia arriba
	add hl,de			;48e3
	ld (0e00eh),hl		;48e4
	ld a,040h		;48e7   ; el tile 0x40
	ld b,003h		;48e9   ; tres casillas
	call L_4901		;48eb
	ld bc,00b0ch		;48ee   ; el tile 0x0C, doce casillas
	call L_4901		;48f1
	ld b,c			;48f4   ; y otras doce
	call L_4901		;48f5
	xor a			;48f8   ; el resto, a cero
	call 00056h		;48f9   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld hl,0e00ah		;48fc   ; la cuenta del barrido
	dec (hl)			;48ff   ; una menos
	ret			;4900
L_4901:
	push hl			;4901   ; el sitio, a salvo
L_4902:
	call 0004dh		;4902   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;4905
	inc a			;4906   ; tiles consecutivos
	djnz L_4902		;4907
	pop de			;4909   ; el sitio de partida
	ld hl,00020h		;490a   ; una fila entera
	add hl,de			;490d   ; y devuelve la fila de abajo
	ret			;490e

; ----------------------------------------------------------------------
; DATOS rle_marcador_patron: 151 bytes -> 216 de PATRON en 0x2200 (27 tiles).
;   Lo carga 0x48cf, y 0x48d2 llena de 0xF0 el COLOR de 0x0200
;   0x490f..0x49a6  (151 bytes)
DATA_rle_marcador_patron:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 490f  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 491f  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 492f  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 493f  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 494f  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 495f  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 496f  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 497f  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 498f  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 499f

; ======================================================================
; CODIGO 0x49a6..0x4a25  (127 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Deja el fondo negro, limpia, carga la fuente y los 33 tiles del rotulo ROAD FIGHTER, y arranca el latido del color.
; ----------------------------------------------------------------------
monta_la_presentacion_entera:
	ld b,0e0h		;49a6   ; el registro 7: borde y fondo
	call L_46B1		;49a8   ; lo escribe
	call limpia_la_pantalla		;49ab   ; limpia la tabla de nombres
	call carga_la_fuente		;49ae   ; la fuente
	ld de,04a25h		;49b1   ; el bloque del rotulo grande
	ld hl,02600h		;49b4   ; patron 0x2600, o sea el tile 0xC0
	call descomprime_los_tres_tercios		;49b7
	ld a,001h		;49ba   ; el primer par de colores
	jp L_40EF		;49bc   ; y a latir
L_49BF:
	call monta_la_presentacion_entera		;49bf

; ----------------------------------------------------------------------
; El texto del menu y las dos mitades del rotulo. Los dos `call` seguidos al interprete no son un error: el primero se come el guion de 0x472A y deja DE justo en el siguiente, que es el de "LEVEL B".
; ----------------------------------------------------------------------
escribe_la_presentacion:
	ld de,0472ah		;49c2   ; el guion del titulo
	call escribe_rotulo		;49c5   ; "(C)KONAMI 1985", "PLAY SELECT" y "LEVEL A"
	call escribe_rotulo		;49c8   ; y con DE ya en el guion siguiente, "LEVEL B"
	ld a,(0e004h)		;49cb   ; la cuenta del deslizamiento
	sub 020h		;49ce   ; lo que lleva recorrido
	neg		;49d0
	add a,040h		;49d2   ; la fila 2 de la tabla de nombres
	ld l,a			;49d4
	ld h,038h		;49d5
	ld de,04b0ch		;49d7   ; la mitad de "ROAD", guardada AL REVES
	ld c,011h		;49da   ; diecisiete de ancho: por eso se recorre hacia atras
	call desliza_el_rotulo		;49dc
	ld a,(0e004h)		;49df   ; la cuenta otra vez
	add a,0c0h		;49e2   ; la fila 6
	ld l,a			;49e4
	ld h,038h		;49e5
	ld de,04b2fh		;49e7   ; y "FIGHTER", del derecho
	ld c,015h		;49ea   ; veintiuno de ancho

; ----------------------------------------------------------------------
; Pinta las tres filas del rotulo, y el SENTIDO lo decide la anchura: con C=0x15 los punteros avanzan, y con cualquier otra cosa los dos `dec` de 0x4A10 deshacen los `inc` y dejan un -1. Por eso "ROAD" esta guardado del reves, con su 0xFF por delante de la fila en vez de detras. La cuenta de (0xE004) limita cuantas casillas asoman, y asi las dos mitades entran deslizandose desde lados contrarios.
; ----------------------------------------------------------------------
desliza_el_rotulo:
	ld b,003h		;49ec   ; tres filas
L_49EE:
	push bc			;49ee   ; la cuenta de filas, a salvo
	push hl			;49ef   ; el sitio en pantalla
	push de			;49f0   ; y el sitio en los datos
	ld a,(0e004h)		;49f1   ; la cuenta del deslizamiento
	sub 020h		;49f4
	neg		;49f6
	ld b,a			;49f8   ; dice cuantas casillas asoman
L_49F9:
	ld a,(de)			;49f9   ; el tile
	inc a			;49fa   ; 0xFF es -1
	jr z,L_4A14		;49fb   ; y cierra la fila
	call 00053h		;49fd   ; BIOS SETWRT - Enables VDP to write | SETWRT
	push bc			;4a00
	ld a,(00006h)		;4a01   ; el puerto de datos del VDP
	ld c,a			;4a04
	ld a,(de)			;4a05
	out (c),a		;4a06   ; escribe el tile
	pop bc			;4a08
	inc hl			;4a09   ; adelante los dos punteros
	inc de			;4a0a
	ld a,c			;4a0b   ; la anchura
	cp 015h		;4a0c   ; veintiuno se recorre hacia delante
	jr z,L_4A14		;4a0e   ; y ya esta
	dec de			;4a10   ; y cualquier otra, hacia atras: los dos `dec` dejan un -1 neto
	dec de			;4a11
	dec hl			;4a12
	dec hl			;4a13
L_4A14:
	djnz L_49F9		;4a14   ; hasta agotar lo que asoma
	pop de			;4a16
	pop hl			;4a17
	pop bc			;4a18
	ld a,020h		;4a19   ; la fila de abajo
	call suma_a_hl		;4a1b
	ld a,c			;4a1e
	call suma_a_de		;4a1f   ; y en los datos, una fila entera
	djnz L_49EE		;4a22   ; tres veces
	ret			;4a24

; ----------------------------------------------------------------------
; DATOS rle_titulo_patron: 215 bytes -> 264 de PATRON en 0x2600 (33 tiles). Lo
;   carga 0x49b7
;   0x4a25..0x4afc  (215 bytes)
DATA_rle_titulo_patron:
	defb 002h,0ffh,083h,0c0h,0c7h,0c7h,003h,0c6h,085h,0fch,0feh,006h,0e7h,0e3h,003h,063h	; 4a25  ...............c
	defb 006h,0c6h,002h,0feh,006h,063h,002h,07fh,085h,03fh,07fh,060h,0e7h,0c7h,003h,0c6h	; 4a35  .....c...?.`....
	defb 085h,0fch,0feh,006h,0e7h,0e3h,003h,063h,003h,0c6h,085h,0c7h,0e7h,060h,07fh,03fh	; 4a45  .......c.....`.?
	defb 003h,063h,087h,0e3h,0e7h,006h,0feh,0fch,01fh,01fh,003h,018h,085h,038h,03bh,033h	; 4a55  .c...........8;3
	defb 0f8h,0f8h,003h,018h,093h,01ch,0dch,0cch,067h,06eh,0eeh,0ech,0cch,0cch,0fch,0fch	; 4a65  ........gn......
	defb 0e6h,076h,077h,037h,033h,033h,03fh,03fh,003h,0c6h,002h,0c7h,081h,0c0h,004h,0ffh	; 4a75  .vw733??........
	defb 083h,003h,0ffh,0ffh,003h,000h,002h,0feh,006h,0c6h,08dh,0fch,0feh,006h,0e7h,0e3h	; 4a85  ................
	defb 063h,063h,07fh,0ffh,0ffh,0c0h,0fch,0fch,003h,00ch,002h,0ffh,083h,001h,07fh,07fh	; 4a95  cc..............
	defb 003h,060h,006h,00ch,002h,00fh,006h,060h,002h,0e0h,003h,000h,002h,0ffh,083h,000h	; 4aa5  .`.....`........
	defb 0ffh,0ffh,002h,07fh,006h,063h,090h,0c6h,0c6h,0c7h,0c7h,0c0h,0c7h,0c7h,0c6h,063h	; 4ab5  .....c.........c
	defb 067h,0e6h,0eeh,00ch,0eeh,0e6h,067h,008h,0c6h,008h,063h,003h,036h,002h,077h,002h	; 4ac5  g.....g...c.6.w.
	defb 060h,081h,067h,003h,06ch,002h,0eeh,002h,006h,08eh,0e6h,000h,000h,0ffh,0ffh,003h	; 4ad5  `.g.l...........
	defb 0ffh,0ffh,000h,07fh,000h,000h,0ffh,0ffh,005h,063h,002h,0e3h,001h,003h,002h,0e3h	; 4ae5  .........c......
	defb 081h,063h,008h,00ch,008h,060h,000h	; 4af5

; ----------------------------------------------------------------------
; DATOS rotulo_izquierda: tres filas de 17 tiles guardadas AL REVES, cada una
;   cerrada por delante con 0xFF; la carga 0x49d7 con C=0x11
;   0x4afc..0x4b2f  (51 bytes)
DATA_rotulo_izquierda:
	defb 0ffh,000h,0c0h,0c1h,000h,0c4h,0c5h,000h,0c8h,0c9h,000h,0c0h,0c1h,000h,000h,000h	; 4afc  ................
	defb 000h,0ffh,000h,0d6h,0d7h,000h,0d8h,0d9h,000h,0dah,0dbh,000h,0d8h,0d9h,000h,000h	; 4b0c  ................
	defb 000h,000h,0ffh,000h,0c2h,0c3h,000h,0c6h,0c7h,000h,0cah,0cbh,000h,0cch,0c7h,000h	; 4b1c  ................
	defb 000h,000h,000h	; 4b2c

; ----------------------------------------------------------------------
; DATOS rotulo_derecha: tres filas de 21 tiles del derecho; la carga 0x49e7
;   con C=0x15
;   0x4b2f..0x4b6e  (63 bytes)
DATA_rotulo_derecha:
	defb 0c0h,0cdh,000h,0ceh,000h,0c4h,0c1h,000h,0ceh,0d5h,000h,0d0h,0d1h,000h,0c0h,0cdh	; 4b2f  ................
	defb 000h,0c0h,0c1h,000h,0ffh,0d6h,0dch,000h,0d8h,000h,0d8h,0ddh,000h,0d6h,0deh,000h	; 4b3f  ................
	defb 0dfh,0e0h,000h,0d6h,0dch,000h,0d6h,0d7h,000h,0ffh,0c2h,000h,000h,0c2h,000h,0c6h	; 4b4f  ................
	defb 0c7h,000h,0c2h,0c3h,000h,0d2h,0d3h,000h,0cch,0d4h,000h,0c2h,0c3h,000h,0ffh	; 4b5f  ...............

; ======================================================================
; CODIGO 0x4b6e..0x4bd2  (100 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Puerta normal al sonido: pide el efecto que trae A. El D a cero es lo que lo distingue de la puerta de 0x4B76, que la usa el propio motor.
; ----------------------------------------------------------------------
suena:
	di			;4b6e   ; con las interrupciones cerradas
	ld d,000h		;4b6f   ; la marca de "peticion de fuera"
	call pide_efecto		;4b71
	ei			;4b74
	ret			;4b75

; ----------------------------------------------------------------------
; Elige la VOZ segun el numero de efecto y, si la que le toca esta ocupada por algo de mas prioridad, no hace nada. Las tres voces son bloques de once bytes en 0xE010, 0xE01B y 0xE026.
; ----------------------------------------------------------------------
pide_efecto:
	ld c,a			;4b76   ; el efecto, a salvo
	ld b,001h		;4b77   ; una voz
	ld hl,0e012h		;4b79   ; la voz 1
	and 03fh		;4b7c   ; el numero, sin las banderas de arriba
	cp 001h		;4b7e   ; el 1 es la musica: entra siempre
	jr z,L_4BA3		;4b80
	cp 005h		;4b82   ; por debajo de 5
	jr c,L_4B94		;4b84
	cp 00fh		;4b86   ; y por debajo de 0x0F
	jr c,L_4B8E		;4b88
	inc b			;4b8a   ; si no, las TRES voces
	inc b			;4b8b
	jr L_4B97		;4b8c
L_4B8E:
	ld hl,0e01dh		;4b8e   ; la voz 2
	inc b			;4b91   ; y son dos voces
	jr L_4B97		;4b92
L_4B94:
	ld hl,0e028h		;4b94   ; la voz 3
L_4B97:
	dec d			;4b97   ; si la peticion es de dentro, no se mira la prioridad
	jr z,L_4BA3		;4b98
	ld a,(hl)			;4b9a   ; lo que suena ahora en esa voz
	and 03fh		;4b9b
	ld e,a			;4b9d   ; y su numero
	ld a,c			;4b9e
	and 03fh		;4b9f   ; el que se pide
	cp e			;4ba1   ; el numero MAS BAJO manda
	ret c			;4ba2   ; y si el nuevo es mayor, se descarta
L_4BA3:
	and 03fh		;4ba3   ; el numero limpio
	add a,a			;4ba5   ; por dos: son punteros
	ld de,04de0h		;4ba6   ; la tabla de melodias. Va desde 0x4DE0 y no desde 0x4DE2 porque el indice empieza en uno: el efecto 0 es el silencio y su entrada no existe
	call suma_a_de		;4ba9
	dec hl			;4bac   ; al principio del bloque de la voz
	dec hl			;4bad
	push hl			;4bae
	ld hl,0eb0dh		;4baf   ; el patron de ruido
	ld (0e032h),hl		;4bb2   ; (0xE032)
	ld hl,0ee0dh		;4bb5   ; y el otro
	ld (0e034h),hl		;4bb8
	pop hl			;4bbb
L_4BBC:
	ld (hl),001h		;4bbc   ; la voz, en marcha
	inc hl			;4bbe
	ld (hl),001h		;4bbf
	inc hl			;4bc1
	ld (hl),c			;4bc2   ; con su numero de efecto
	inc hl			;4bc3
	ld a,(de)			;4bc4   ; y el puntero a la melodia
	ld (hl),a			;4bc5
	inc hl			;4bc6
	inc de			;4bc7
	ld a,(de)			;4bc8
	ld (hl),a			;4bc9
	ld a,007h		;4bca   ; once bytes por voz: cuatro ya escritos y siete de salto
	add a,l			;4bcc
	ld l,a			;4bcd
	inc de			;4bce
	djnz L_4BBC		;4bcf   ; y la voz siguiente, si eran varias
	ret			;4bd1

; ----------------------------------------------------------------------
; DATOS datos_4bd2: quince bytes que nadie carga con una constante
;   0x4bd2..0x4be1  (15 bytes)
DATA_datos_4bd2:
	defb 0ddh,07eh,002h,0c5h,016h,001h,0cdh,076h,04bh,0c1h,008h,0ddh,077h,009h,0c9h	; 4bd2  .~.....vK...w..

; ======================================================================
; CODIGO 0x4be1..0x4dd6  (501 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Toca el registro 7 del PSG, el que dice que canales suenan. Con D distinto de cero apaga los tres bits de la voz, y con D a cero los enciende.
; ----------------------------------------------------------------------
enciende_o_apaga_canales:
	ld a,(0e031h)		;4be1   ; lo que hay ahora en el registro 7
	ld e,a			;4be4
	ld a,c			;4be5   ; el numero de voz
	cp 001h		;4be6   ; la voz 1 no se corre
	jr z,L_4BEB		;4be8
	dec a			;4bea
L_4BEB:
	rlca			;4beb   ; tres bits por voz
	rlca			;4bec
	rlca			;4bed
	dec d			;4bee   ; si la peticion venia de fuera
	jr z,L_4BF5		;4bef
	cpl			;4bf1   ; apaga esos bits
	and e			;4bf2
	jr L_4BF6		;4bf3
L_4BF5:
	or e			;4bf5   ; y si no, los enciende
L_4BF6:
	ld (0e031h),a		;4bf6   ; (0xE031) es la copia del registro 7
	ld e,a			;4bf9
	ld a,007h		;4bfa   ; el registro 7 del PSG
	jp 00093h		;4bfc   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG

; ----------------------------------------------------------------------
; El motor, una vez por fotograma: recorre las TRES voces, que son bloques de once bytes desde 0xE010.
; ----------------------------------------------------------------------
latido_del_sonido:
	ld a,(0e031h)		;4bff   ; la copia del registro 7
	call L_4BF6		;4c02   ; la vuelve a escribir
	ld c,001h		;4c05   ; la voz 1
	ld ix,0e010h		;4c07   ; el primer bloque de voz
	exx			;4c0b
	ld b,003h		;4c0c   ; tres voces
	ld de,0000bh		;4c0e   ; once bytes de una a otra
L_4C11:
	exx			;4c11
	ld a,(ix+002h)		;4c12   ; el estado de la voz
	cp 001h		;4c15   ; el 1 es "recien arrancada"
	jr z,ruido_del_motor		;4c17
	or a			;4c19
	call nz,latido_de_una_voz		;4c1a   ; y si no es cero, hay algo que sonar
L_4C1D:
	inc c			;4c1d   ; dos canales por voz
	inc c			;4c1e
	exx			;4c1f
	add ix,de		;4c20   ; al bloque siguiente
	djnz L_4C11		;4c22
	ret			;4c24

; ----------------------------------------------------------------------
; El sonido del coche. El periodo NO es fijo: sale de la velocidad de (0xE04F) a base de desplazamientos, con tres tramos -por debajo de 0x30, de 0x30 a 0x7D y de 0x7E arriba- y un sumando distinto en cada uno. Por eso el motor sube de tono al acelerar.
; ----------------------------------------------------------------------
ruido_del_motor:
	ld iy,0e034h		;4c25   ; el segundo generador de ruido
	ld a,(0e003h)		;4c29   ; el reloj del juego
	and 003h		;4c2c   ; uno de cada cuatro fotogramas
	bit 0,a		;4c2e
	jr nz,L_4C85		;4c30   ; en los impares, solo el volumen
	cp 002h		;4c32
	jr z,L_4C81		;4c34   ; y en el 2, el otro generador
	ld a,(0e04fh)		;4c36   ; la velocidad
	ld h,000h		;4c39
	ld l,a			;4c3b
	ld e,l			;4c3c
	ld d,h			;4c3d
	add hl,hl			;4c3e   ; por cuatro
	add hl,hl			;4c3f
	ld a,(0e038h)		;4c40   ; (0xE038) dice si el coche esta en marcha
	cp 000h		;4c43
	jr z,L_4C67		;4c45
	ld a,(0e04fh)		;4c47   ; la velocidad otra vez
	cp 07eh		;4c4a   ; a partir de 0x7E, el tramo de arriba
	jr nc,L_4C57		;4c4c
	cp 030h		;4c4e   ; de 0x30 a 0x7D, el de en medio
	jr nc,L_4C6D		;4c50
	add hl,hl			;4c52   ; y por debajo, por ocho
	add hl,hl			;4c53
	add hl,hl			;4c54
	jr L_4C7E		;4c55
L_4C57:
	ld a,(0e038h)		;4c57
	cp 000h		;4c5a
	jr nz,L_4C61		;4c5c
	add hl,hl			;4c5e   ; por dos
	jr L_4C67		;4c5f
L_4C61:
	add hl,de			;4c61   ; mas la velocidad
	ld de,004b0h		;4c62   ; y el sumando del tramo alto
	jr L_4C7D		;4c65
L_4C67:
	add hl,hl			;4c67   ; por dos
	ld de,00300h		;4c68   ; y el sumando de parado
	jr L_4C7D		;4c6b
L_4C6D:
	ld a,(0e04fh)		;4c6d   ; la velocidad
	sub 030h		;4c70   ; lo que pasa de 0x30
	ld l,a			;4c72
	ld h,000h		;4c73
	add hl,hl			;4c75   ; por dieciseis
	add hl,hl			;4c76
	add hl,hl			;4c77
	add hl,hl			;4c78
	ld e,000h		;4c79   ; y el sumando del tramo de en medio
	ld d,005h		;4c7b
L_4C7D:
	add hl,de			;4c7d   ; el periodo, montado
L_4C7E:
	ld (0e036h),hl		;4c7e   ; (0xE036) lo guarda
L_4C81:
	ld iy,0e032h		;4c81   ; el primer generador de ruido
L_4C85:
	ld de,(0e036h)		;4c85   ; el periodo del motor
	ld h,(iy+000h)		;4c89   ; y el del generador
	ld l,(iy+001h)		;4c8c
	sbc hl,de		;4c8f   ; la diferencia es lo que suena
	call escribe_el_periodo		;4c91   ; lo escribe en el PSG
	ld a,(0e083h)		;4c94   ; la velocidad del coche
	cp 010h		;4c97   ; por debajo de 0x10 casi no hay ruido
	jr c,L_4CAE		;4c99
	ld a,(0e028h)		;4c9b   ; lo que suena en la voz 3
	cp 003h		;4c9e
	jr z,L_4CAE		;4ca0
	cp 00ah		;4ca2
	jr z,L_4CB2		;4ca4
	cp 00dh		;4ca6
	jr z,L_4CB2		;4ca8
	ld e,00dh		;4caa   ; el volumen alto del motor
	jr L_4CB4		;4cac
L_4CAE:
	ld e,009h		;4cae   ; el volumen bajo
	jr L_4CB4		;4cb0
L_4CB2:
	ld e,000h		;4cb2   ; o nada
L_4CB4:
	ld a,008h		;4cb4   ; el registro 8 del PSG, el volumen del canal A
	call 00093h		;4cb6   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	jp L_4C1D		;4cb9

; ----------------------------------------------------------------------
; Lo que le toca a UNA voz en este fotograma: gasta la duracion de la nota que suena y, cuando se agota, lee el mandato siguiente de su melodia.
; ----------------------------------------------------------------------
latido_de_una_voz:
	bit 6,a		;4cbc   ; el bit 6 del efecto
	ld d,001h		;4cbe   ; apagar
	call z,enciende_o_apaga_canales		;4cc0   ; si no esta puesto, apaga los canales de la voz
	ld a,(ix+002h)		;4cc3   ; el numero de efecto
	or a			;4cc6
	jp m,L_4D35		;4cc7   ; con el bit 7 puesto, la melodia lleva mandatos largos
	dec (ix+000h)		;4cca   ; la duracion de la nota
	ret nz			;4ccd   ; mientras quede, no se lee nada mas

; ----------------------------------------------------------------------
; Saca el mandato siguiente de la melodia. El nibble de arriba dice que es: 0x2x fija cuanto dura una nota, 0x1x toca el ruido, 0xFF cierra la melodia, y cualquier otro es una NOTA -el nibble de arriba, el volumen; el de abajo y el byte que sigue, el periodo-.
; ----------------------------------------------------------------------
lee_el_mandato:
	ld l,(ix+003h)		;4cce   ; por donde va la melodia
	ld h,(ix+004h)		;4cd1
	ld a,(hl)			;4cd4   ; el mandato
	cp 0ffh		;4cd5   ; 0xFF cierra
	jr z,L_4D25		;4cd7
	bit 7,(ix+002h)		;4cd9   ; con el bit 7 del efecto, van los mandatos largos
	jp nz,mandatos_largos		;4cdd
	and 0f0h		;4ce0   ; el nibble de arriba
	cp 020h		;4ce2   ; el mandato 0x2x
	jr nz,L_4CED		;4ce4
	ld a,(hl)			;4ce6   ; su argumento
	and 00fh		;4ce7
	ld (ix+001h),a		;4ce9   ; fija cuanto dura una nota
	inc hl			;4cec   ; y al mandato siguiente
L_4CED:
	ld a,(hl)			;4ced   ; el mandato
	and 0f0h		;4cee
	cp 010h		;4cf0   ; el 0x1x
	jr nz,L_4D03		;4cf2
	ld a,(hl)			;4cf4   ; los cinco bits de abajo
	and 01fh		;4cf5
	ld e,a			;4cf7
	ld a,006h		;4cf8   ; el registro 6 del PSG, el periodo del ruido
	call 00093h		;4cfa   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld d,000h		;4cfd   ; encender
	call enciende_o_apaga_canales		;4cff   ; y enciende los canales de la voz
	inc hl			;4d02
L_4D03:
	ld a,(hl)			;4d03   ; el mandato
	and 0f0h		;4d04
	ld b,a			;4d06   ; el nibble de arriba, a B
	xor (hl)			;4d07   ; y el de abajo, a D
	ld d,a			;4d08
	inc hl			;4d09
	ld e,(hl)			;4d0a   ; el byte que sigue completa el periodo
	call guarda_la_marcha		;4d0b   ; guarda por donde va la melodia
	ex de,hl			;4d0e
	call escribe_el_periodo		;4d0f   ; y escribe el periodo
	ld a,b			;4d12
	rrca			;4d13   ; el nibble de arriba, abajo
	rrca			;4d14
	rrca			;4d15
	rrca			;4d16
L_4D17:
	ld h,a			;4d17   ; el volumen de partida
	ld a,(ix+001h)		;4d18   ; cuanto dura una nota
	ld (ix+000h),a		;4d1b   ; arranca la cuenta
	add a,002h		;4d1e   ; dos mas
	ld (ix+008h),a		;4d20   ; para el decaimiento
	jr L_4D57		;4d23
L_4D25:
	xor a			;4d25   ; se acabo la melodia
	ld (ix+009h),a		;4d26
	ld d,001h		;4d29   ; apagar
	call enciende_o_apaga_canales		;4d2b   ; apaga los canales
	xor a			;4d2e
	ld (ix+002h),a		;4d2f   ; y la voz queda libre
	ld h,a			;4d32
	jr L_4D57		;4d33
L_4D35:
	dec (ix+000h)		;4d35   ; la cuenta de la nota
	jp z,lee_el_mandato		;4d38   ; y al agotarse, el mandato siguiente
	dec (ix+008h)		;4d3b   ; la cuenta del decaimiento
	ld a,(ix+008h)		;4d3e
	cp (ix+000h)		;4d41   ; cuando alcanza a la de la nota
	jr nz,L_4D4B		;4d44
	cp 003h		;4d46   ; y quedan menos de tres
	jr c,L_4D4E		;4d48
	ret			;4d4a
L_4D4B:
	dec (ix+008h)		;4d4b   ; una mas
L_4D4E:
	ld a,(ix+007h)		;4d4e   ; el volumen
	dec a			;4d51   ; uno menos
	ret m			;4d52   ; y en cuanto se pasa de cero, se acabo
	ld (ix+007h),a		;4d53
	ld h,a			;4d56
L_4D57:
	ld a,c			;4d57   ; el numero de canal
	rrca			;4d58
	add a,088h		;4d59   ; los registros 8, 9 y 10 son los de volumen
	ld e,h			;4d5b   ; el volumen
	jp 00093h		;4d5c   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG

; ----------------------------------------------------------------------
; Los tres mandatos de arriba, que solo aparecen en las melodias con el bit 7 puesto en su numero: 0xDx fija el multiplicador de duracion, 0xFx el escalon del volumen y 0xEx la octava. Van encadenados, asi que una nota puede traer los tres.
; ----------------------------------------------------------------------
mandatos_largos:
	ld a,(hl)			;4d5f   ; el mandato
	and 0f0h		;4d60
	cp 0d0h		;4d62   ; el 0xDx
	ld a,(hl)			;4d64
	jr nz,L_4D6E		;4d65
	and 00fh		;4d67   ; su argumento
	ld (ix+00ah),a		;4d69   ; el multiplicador de duracion
	inc hl			;4d6c
	ld a,(hl)			;4d6d   ; y el mandato siguiente
L_4D6E:
	cp 0f0h		;4d6e   ; el 0xFx
	jr c,L_4D79		;4d70
	and 00fh		;4d72   ; su argumento
	ld (ix+006h),a		;4d74   ; el escalon del volumen
	inc hl			;4d77
	ld a,(hl)			;4d78
L_4D79:
	cp 0e0h		;4d79   ; el 0xEx
	jr c,L_4D84		;4d7b
	and 00fh		;4d7d   ; su argumento
	ld (ix+005h),a		;4d7f   ; la octava
	inc hl			;4d82
	ld a,(hl)			;4d83
L_4D84:
	and 00fh		;4d84   ; el nibble de abajo del mandato
	ld b,a			;4d86
	ld a,(ix+00ah)		;4d87   ; el multiplicador
	jr z,L_4D91		;4d8a
L_4D8C:
	add a,(ix+00ah)		;4d8c   ; la duracion sale de multiplicar sumando
	djnz L_4D8C		;4d8f
L_4D91:
	ld (ix+001h),a		;4d91   ; y esa es la de la nota
	ld a,(hl)			;4d94   ; el mandato
	call guarda_la_marcha		;4d95   ; guarda por donde va la melodia
	and 0f0h		;4d98   ; el nibble de arriba, abajo
	rrca			;4d9a
	rrca			;4d9b
	rrca			;4d9c
	rrca			;4d9d
	ld b,a			;4d9e   ; el volumen de partida
	sub 00ch		;4d9f   ; doce menos
	ld (ix+007h),a		;4da1   ; el escalon del decaimiento
	jr z,L_4DAC		;4da4   ; si daba cero
	ld a,(ix+006h)		;4da6   ; se usa el del mandato 0xFx
	ld (ix+007h),a		;4da9
L_4DAC:
	call L_4D17		;4dac   ; y a sonar
	ld a,b			;4daf

; ----------------------------------------------------------------------
; De numero de nota a periodo del PSG. La tabla de 0x4DD6 son los DOCE semitonos de una octava, y cada `add hl,hl` la baja una octava mas.
; ----------------------------------------------------------------------
nota_a_periodo:
	ld hl,04dd6h		;4db0   ; los doce semitonos
	call suma_a_hl		;4db3   ; el que toca
	ld l,(hl)			;4db6   ; el periodo
	ld h,000h		;4db7
	ld a,(ix+005h)		;4db9   ; la octava
	or a			;4dbc
	jr z,escribe_el_periodo		;4dbd   ; sin octava, se queda como esta
	ld b,a			;4dbf
L_4DC0:
	add hl,hl			;4dc0   ; y cada vuelta, una octava mas baja
	djnz L_4DC0		;4dc1

; ----------------------------------------------------------------------
; Suelta el periodo en los dos registros del canal: el alto en C y el bajo en C-1. C vale 1, 3 o 5, o sea los pares (0,1), (2,3) y (4,5) del PSG.
; ----------------------------------------------------------------------
escribe_el_periodo:
	ld a,c			;4dc3   ; el registro alto
	ld e,h			;4dc4
	call 00093h		;4dc5   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,c			;4dc8
	dec a			;4dc9   ; y el de al lado, el bajo
	ld e,l			;4dca
	jp 00093h		;4dcb   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG

; ----------------------------------------------------------------------
; Adelanta el puntero de la melodia y lo deja en el bloque de la voz.
; ----------------------------------------------------------------------
guarda_la_marcha:
	inc hl			;4dce   ; al byte siguiente
	ld (ix+003h),l		;4dcf   ; y ahi queda por donde va
	ld (ix+004h),h		;4dd2
	ret			;4dd5

; ----------------------------------------------------------------------
; DATOS tabla_de_notas: los doce semitonos de una octava; 0x4db0 la indexa y
;   0x4dc0 la desplaza una octava por cada `add hl,hl`
;   0x4dd6..0x4de2  (12 bytes)
DATA_tabla_de_notas:
	defb 06bh,065h,05fh,05ah,054h,050h,04ch,047h,043h,040h,03ch,039h	; 4dd6  ke_ZTPLGC@<9

; ----------------------------------------------------------------------
; DATOS tabla_de_melodias: 29 punteros a las melodias; las tres ultimas
;   entradas apuntan al final (0x5027), o sea que estan vacias
;   0x4de2..0x4e1c  (58 bytes)
DATA_tabla_de_melodias:
	defw 04e1ch,04e1dh,04e2fh,04e47h,04e5bh,04e71h,04e87h,04e9dh	; 4de2
	defw 04eb3h,04ec2h,04ed1h,04ee4h,04ee5h,04eefh,04ef9h,04f20h	; 4df2
	defw 04f3dh,04f3eh,04f5ah,04f76h,04f8fh,04fa9h,04fc3h,04fd4h	; 4e02
	defw 04ff0h,0500eh,05027h,05027h,05027h	; 4e12

; ----------------------------------------------------------------------
; DATOS melodia_00: 1 bytes; entrada 0 de la tabla de 0x4de2
;   0x4e1c..0x4e1d  (1 bytes)
DATA_melodia_00:
	defb 0ffh	; 4e1c

; ----------------------------------------------------------------------
; DATOS melodia_01: 18 bytes; entrada 1 de la tabla de 0x4de2
;   0x4e1d..0x4e2f  (18 bytes)
DATA_melodia_01:
	defb 027h,0c0h,061h,0c0h,0c1h,0c0h,031h,0c0h,061h,0c0h,061h,0c0h,061h,0c0h,031h,0c0h	; 4e1d  '.a...1.a.a.a.1.
	defb 061h,0ffh	; 4e2d

; ----------------------------------------------------------------------
; DATOS melodia_02: 24 bytes; entrada 2 de la tabla de 0x4de2
;   0x4e2f..0x4e47  (24 bytes)
DATA_melodia_02:
	defb 024h,0d0h,060h,0b0h,0a0h,0a0h,060h,090h,0a0h,070h,060h,080h,0a0h,060h,060h,070h	; 4e2f  $.`...`..p`..``p
	defb 0a0h,060h,060h,060h,0a0h,050h,060h,0ffh	; 4e3f  .```.P`.

; ----------------------------------------------------------------------
; DATOS melodia_03: 20 bytes; entrada 3 de la tabla de 0x4de2
;   0x4e47..0x4e5b  (20 bytes)
DATA_melodia_03:
	defb 021h,0c4h,000h,0d4h,003h,0e5h,000h,0e4h,003h,0f4h,000h,0f4h,000h,0e4h,003h,0d4h	; 4e47  !...............
	defb 000h,0c4h,003h,0ffh	; 4e57

; ----------------------------------------------------------------------
; DATOS melodia_04: 22 bytes; entrada 4 de la tabla de 0x4de2
;   0x4e5b..0x4e71  (22 bytes)
DATA_melodia_04:
	defb 022h,0b1h,001h,0c1h,001h,0c1h,001h,0c1h,001h,0b1h,001h,0a1h,001h,091h,001h,081h	; 4e5b  "...............
	defb 001h,071h,001h,061h,001h,0ffh	; 4e6b

; ----------------------------------------------------------------------
; DATOS melodia_05: 22 bytes; entrada 5 de la tabla de 0x4de2
;   0x4e71..0x4e87  (22 bytes)
DATA_melodia_05:
	defb 022h,0b1h,003h,0c1h,003h,0c1h,003h,0c1h,003h,0b1h,003h,0a1h,003h,091h,003h,081h	; 4e71  "...............
	defb 003h,071h,003h,061h,003h,0ffh	; 4e81

; ----------------------------------------------------------------------
; DATOS melodia_06: 22 bytes; entrada 6 de la tabla de 0x4de2
;   0x4e87..0x4e9d  (22 bytes)
DATA_melodia_06:
	defb 026h,0c0h,080h,0d0h,080h,0d0h,080h,0d0h,080h,0c0h,080h,0b0h,080h,0a0h,080h,090h	; 4e87  &...............
	defb 080h,080h,080h,070h,080h,0ffh	; 4e97

; ----------------------------------------------------------------------
; DATOS melodia_07: 22 bytes; entrada 7 de la tabla de 0x4de2
;   0x4e9d..0x4eb3  (22 bytes)
DATA_melodia_07:
	defb 026h,0c0h,082h,0d0h,082h,0d0h,082h,0d0h,082h,0c0h,082h,0b0h,082h,0a0h,082h,090h	; 4e9d  &...............
	defb 082h,080h,082h,070h,082h,0ffh	; 4ead

; ----------------------------------------------------------------------
; DATOS melodia_08: 15 bytes; entrada 8 de la tabla de 0x4de2
;   0x4eb3..0x4ec2  (15 bytes)
DATA_melodia_08:
	defb 025h,0a1h,044h,0a1h,04ah,0b1h,054h,0c1h,064h,027h,0b1h,074h,091h,084h,0ffh	; 4eb3  %.D.J.T.d'.t...

; ----------------------------------------------------------------------
; DATOS melodia_09: 15 bytes; entrada 9 de la tabla de 0x4de2
;   0x4ec2..0x4ed1  (15 bytes)
DATA_melodia_09:
	defb 025h,0a1h,060h,0a1h,066h,0b1h,070h,0c1h,080h,027h,0b1h,0a0h,091h,0b0h,0ffh	; 4ec2  %.`.f.p..'.....

; ----------------------------------------------------------------------
; DATOS melodia_10: 19 bytes; entrada 10 de la tabla de 0x4de2
;   0x4ed1..0x4ee4  (19 bytes)
DATA_melodia_10:
	defb 021h,0c0h,060h,0c0h,06fh,0c0h,067h,0c0h,062h,0c0h,06ch,0c0h,06fh,0c0h,068h,0ffh	; 4ed1  !.`.o.g.b.l.o.h.
	defb 0c0h,060h,0ffh	; 4ee1

; ----------------------------------------------------------------------
; DATOS melodia_11: 1 bytes; entrada 11 de la tabla de 0x4de2
;   0x4ee4..0x4ee5  (1 bytes)
DATA_melodia_11:
	defb 0ffh	; 4ee4

; ----------------------------------------------------------------------
; DATOS melodia_12: 10 bytes; entrada 12 de la tabla de 0x4de2
;   0x4ee5..0x4eef  (10 bytes)
DATA_melodia_12:
	defb 021h,0c0h,09ah,0b0h,0a5h,0a0h,092h,070h,092h,0ffh	; 4ee5  !......p..

; ----------------------------------------------------------------------
; DATOS melodia_13: 10 bytes; entrada 13 de la tabla de 0x4de2
;   0x4eef..0x4ef9  (10 bytes)
DATA_melodia_13:
	defb 021h,0c0h,092h,0b0h,0a1h,0a0h,094h,090h,094h,0ffh	; 4eef  !.........

; ----------------------------------------------------------------------
; DATOS melodia_14: 39 bytes; entrada 14 de la tabla de 0x4de2
;   0x4ef9..0x4f20  (39 bytes)
DATA_melodia_14:
	defb 021h,01fh,0d6h,0c0h,0d6h,090h,0c6h,0c0h,0e5h,005h,0c6h,0c0h,0f5h,094h,0f5h,0d0h	; 4ef9  !...............
	defb 0d5h,0d0h,0d5h,0d0h,027h,0c5h,0d0h,0b5h,0d0h,0a5h,0d0h,029h,095h,0d0h,085h,050h	; 4f09  ....'......)...P
	defb 075h,0e0h,065h,070h,055h,0d0h,0ffh	; 4f19

; ----------------------------------------------------------------------
; DATOS melodia_15: 29 bytes; entrada 15 de la tabla de 0x4de2
;   0x4f20..0x4f3d  (29 bytes)
DATA_melodia_15:
	defb 021h,01fh,0e6h,040h,0d7h,000h,0a6h,043h,0f6h,0d0h,023h,0e6h,050h,0d6h,050h,027h	; 4f20  !..@...C..#.P.P'
	defb 0c6h,030h,086h,050h,076h,050h,066h,050h,056h,050h,046h,050h,0ffh	; 4f30  .0.PvPfPVPFP.

; ----------------------------------------------------------------------
; DATOS melodia_16: 1 bytes; entrada 16 de la tabla de 0x4de2
;   0x4f3d..0x4f3e  (1 bytes)
DATA_melodia_16:
	defb 0ffh	; 4f3d

; ----------------------------------------------------------------------
; DATOS melodia_17: 28 bytes; entrada 17 de la tabla de 0x4de2
;   0x4f3e..0x4f5a  (28 bytes)
DATA_melodia_17:
	defb 0d7h,0fch,0e2h,011h,010h,064h,080h,0a2h,0b0h,0a0h,080h,0a7h,0d3h,011h,060h,0d7h	; 4f3e  .....d........`.
	defb 0e1h,011h,0d3h,011h,0d7h,027h,020h,040h,020h,040h,069h,0ffh	; 4f4e  .....' @ @i.

; ----------------------------------------------------------------------
; DATOS melodia_18: 28 bytes; entrada 18 de la tabla de 0x4de2
;   0x4f5a..0x4f76  (28 bytes)
DATA_melodia_18:
	defb 0d7h,0fbh,0e3h,0b1h,0b0h,0a4h,0b0h,0e2h,012h,030h,030h,030h,017h,0d3h,0c2h,0d7h	; 4f5a  .........000....
	defb 0a0h,0d3h,0c1h,0d7h,0a0h,097h,090h,0b0h,090h,0b0h,0a9h,0ffh	; 4f6a  ............

; ----------------------------------------------------------------------
; DATOS melodia_19: 25 bytes; entrada 19 de la tabla de 0x4de2
;   0x4f76..0x4f8f  (25 bytes)
DATA_melodia_19:
	defb 0d7h,0fch,0e3h,0c2h,061h,060h,061h,060h,065h,0c1h,060h,061h,060h,065h,0c1h,060h	; 4f76  ....a`a`e.`a`e.`
	defb 061h,060h,065h,0c1h,060h,061h,060h,063h,0ffh	; 4f86  a`e.`a`c.

; ----------------------------------------------------------------------
; DATOS melodia_20: 26 bytes; entrada 20 de la tabla de 0x4de2
;   0x4f8f..0x4fa9  (26 bytes)
DATA_melodia_20:
	defb 0d8h,0fbh,0e1h,050h,020h,050h,090h,0a0h,090h,050h,000h,030h,0e2h,0a0h,0e1h,030h	; 4f8f  ...P P...P.0...0
	defb 070h,0d7h,0a3h,0d1h,093h,0a3h,0d8h,0e0h,007h,0ffh	; 4f9f  p.........

; ----------------------------------------------------------------------
; DATOS melodia_21: 26 bytes; entrada 21 de la tabla de 0x4de2
;   0x4fa9..0x4fc3  (26 bytes)
DATA_melodia_21:
	defb 0d8h,0fbh,0e1h,000h,0e2h,090h,0e1h,000h,050h,070h,050h,000h,0e2h,090h,0a0h,050h	; 4fa9  ........PpP....P
	defb 0a0h,030h,0d7h,073h,0d1h,053h,073h,0d8h,097h,0ffh	; 4fb9  .0.s.Ss...

; ----------------------------------------------------------------------
; DATOS melodia_22: 17 bytes; entrada 22 de la tabla de 0x4de2
;   0x4fc3..0x4fd4  (17 bytes)
DATA_melodia_22:
	defb 0d8h,0fch,0e3h,051h,091h,0a1h,091h,031h,071h,0d7h,0a3h,0d1h,003h,023h,0d8h,057h	; 4fc3  ...Q...1q....#.W
	defb 0ffh	; 4fd3

; ----------------------------------------------------------------------
; DATOS melodia_23: 28 bytes; entrada 23 de la tabla de 0x4de2
;   0x4fd4..0x4ff0  (28 bytes)
DATA_melodia_23:
	defb 0d3h,0fbh,0e1h,041h,0c3h,041h,03bh,0e2h,0b1h,0e1h,011h,031h,0c1h,031h,041h,031h	; 4fd4  ...A.A;....1.1A1
	defb 0c1h,011h,0c1h,0e2h,0b1h,0c1h,0e1h,031h,0c1h,0d8h,018h,0ffh	; 4fe4  .......1....

; ----------------------------------------------------------------------
; DATOS melodia_24: 30 bytes; entrada 24 de la tabla de 0x4de2
;   0x4ff0..0x500e  (30 bytes)
DATA_melodia_24:
	defb 0d3h,0fbh,0e1h,011h,0c3h,011h,0e2h,06bh,060h,0c0h,060h,0c0h,061h,0c1h,060h,0c0h	; 4ff0  .......k`.`.a.`.
	defb 060h,0c0h,061h,0c1h,061h,0c1h,061h,0c1h,061h,0c1h,0d8h,0fdh,068h,0ffh	; 5000  `.a.a.a.a...h.

; ----------------------------------------------------------------------
; DATOS melodia_25: 25 bytes; entrada 25 de la tabla de 0x4de2
;   0x500e..0x5027  (25 bytes)
DATA_melodia_25:
	defb 0d3h,0fch,0e3h,061h,0c3h,061h,0bbh,0b0h,0c0h,0b0h,0c0h,0b1h,0c1h,0b0h,0c0h,0b0h	; 500e  ...a.a..........
	defb 0c0h,0b1h,0c1h,0b1h,0c1h,0b1h,0c1h,0b1h,0ffh	; 501e  .........

; ----------------------------------------------------------------------
; DATOS relleno_5027: el byte al que apuntan las tres ultimas entradas vacias
;   de la tabla de melodias
;   0x5027..0x5028  (1 bytes)
DATA_relleno_5027:
	defb 0ffh	; 5027

; ======================================================================
; CODIGO 0x5028..0x50be  (150 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La manita del menu, que va y viene. El bit 3 de la cuenta hace el parpadeo, y (0xE03B) dice sobre cual de las dos opciones esta: 0x3A0A es LEVEL A y 0x3A4A, LEVEL B. La de abajo se borra siempre, escribiendo el mismo guion con la mascara a cero.
; ----------------------------------------------------------------------
parpadea_la_eleccion:
	ld hl,0e004h		;5028   ; la cuenta atras del paso
	bit 3,(hl)		;502b   ; su bit 3
	ld c,0ffh		;502d   ; la mascara que deja el tile
	jr nz,L_5032		;502f
	inc c			;5031   ; o la que lo borra
L_5032:
	ld hl,03a0ah		;5032   ; el sitio de LEVEL A
	ld de,03a4ah		;5035   ; y el de LEVEL B
	ld a,(0e03bh)		;5038   ; el nivel elegido
	or a			;503b
	jr z,L_503F		;503c
	ex de,hl			;503e   ; si es el B, se cambian
L_503F:
	push de			;503f   ; el otro sitio, a salvo
	call L_5046		;5040   ; dibuja la manita donde toca
	pop hl			;5043   ; y en el otro
	ld c,000h		;5044   ; la borra
L_5046:
	ld de,0475bh		;5046   ; los dos tiles de la manita
	jp L_45F8		;5049   ; entra al interprete SIN leer destino: ya lo trae HL

; ----------------------------------------------------------------------
; Deja lista una etapa: borra las variables de juego, monta el arcen, elige el guion de carretera segun la vuelta y coloca el puntero del plan de la etapa. El anillo del paisaje arranca en 0xE186.
; ----------------------------------------------------------------------
prepara_la_etapa:
	ld hl,0e048h		;504c   ; las variables de la partida
	ld de,0e049h		;504f
	ld bc,0034eh		;5052   ; 0x34E bytes
	ld (hl),000h		;5055
	ldir		;5057
	call borra_los_objetos		;5059   ; borra los objetos de la carretera
	ld hl,0e098h		;505c   ; la fila nueva del anillo
	ld de,0e099h		;505f
	ld (hl),020h		;5062   ; el tile 0x20
	ld c,017h		;5064   ; veintitres casillas
	ldir		;5066
	ld hl,0e042h		;5068   ; el contador de vueltas
	ld a,(hl)			;506b
	or a			;506c
	jr nz,L_5078		;506d   ; si ya se ha dado una vuelta, el guion duro
	inc hl			;506f   ; la etapa
	ld a,(hl)			;5070
	ld hl,050beh		;5071   ; el guion normal
	cp 006h		;5074   ; salvo en la sexta
	jr nz,L_507B		;5076
L_5078:
	ld hl,050dch		;5078   ; que lleva el mismo que a partir de la segunda vuelta
L_507B:
	ld (0e0b2h),hl		;507b   ; (0xE0B2) es el guion elegido
	call monta_el_paisaje_de_la_etapa		;507e   ; monta el paisaje de esta etapa
	ld a,008h		;5081   ; ocho
	ld (0e07dh),a		;5083   ; (0xE07D) es el margen del arcen
	call arranca_las_variables_de_carrera		;5086   ; rearma los objetos
	ld a,0d0h		;5089   ; 0xD0, la velocidad de arranque
	ld (0e083h),a		;508b
	ld a,(0e043h)		;508e   ; la etapa
	dec a			;5091
	ld hl,05191h		;5092   ; el tile de fondo de cada etapa
	call suma_a_hl		;5095
	ld a,(hl)			;5098   ; y su byte
	ld (0e089h),a		;5099   ; a (0xE089)
	ld a,(0e043h)		;509c   ; la etapa otra vez
	dec a			;509f
	ld l,a			;50a0   ; por dieciseis
	ld h,000h		;50a1
	add hl,hl			;50a3
	add hl,hl			;50a4
	add hl,hl			;50a5
	add hl,hl			;50a6
	ld de,0537dh		;50a7   ; el plan de las seis etapas
	add hl,de			;50aa   ; la fila que toca
	ld (0e0bdh),hl		;50ab   ; (0xE0BD), por donde va el plan
	call pasa_al_tramo_siguiente		;50ae   ; y saca el primer tramo
	ld a,004h		;50b1   ; cuatro
	ld (0e086h),a		;50b3
	ld de,0e186h		;50b6   ; el anillo del paisaje empieza aqui
	ld (0e046h),de		;50b9   ; (0xE046) es la ventana del anillo
	ret			;50bd

; ----------------------------------------------------------------------
; DATOS relleno_50be: un byte entre dos tramos de codigo
;   0x50be..0x50bf  (1 bytes)
DATA_relleno_50be:
	defb 0ffh	; 50be

; ======================================================================
; CODIGO 0x50bf..0x50c9  (10 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Reparte por etapa: cada una tiene su propia mezcla de listas de calzada y de paisaje. La tabla de seis entradas va pegada detras del `call`.
; ----------------------------------------------------------------------
monta_el_paisaje_de_la_etapa:
	call elige_los_guiones_de_la_etapa		;50bf   ; los tres guiones de esta etapa
	ld a,(0e043h)		;50c2   ; la etapa
	dec a			;50c5
	call despacha_por_indice		;50c6   ; una rama por etapa

; ----------------------------------------------------------------------
; DATOS tabla_por_etapa: 6 entradas, desde 0x50c6 con el indice en (0xE043)
;   0x50c9..0x50d5  (12 bytes)
DATA_tabla_por_etapa:
	defw 050e7h,050e8h,050efh,0510ah,05122h,050d5h	; 50c9

; ======================================================================
; CODIGO 0x50d5..0x50dc  (7 bytes)
; ======================================================================


L_50D5:
	ld hl,07fe4h		;50d5   ; la lista de lineas separadas
	ld (0e090h),hl		;50d8   ; (0xE090) es la de la calzada
	ret			;50db

; ----------------------------------------------------------------------
; DATOS datos_50dc: once bytes que carga 0x5078
;   0x50dc..0x50e7  (11 bytes)
DATA_datos_50dc:
	defb 001h,000h,004h,000h,006h,001h,007h,001h,00eh,000h,000h	; 50dc  ...........

; ======================================================================
; CODIGO 0x50e7..0x5116  (47 bytes)
; ======================================================================


L_50E7:
	ret			;50e7   ; hay etapas que no cambian nada
L_50E8:
	ld hl,07dc5h		;50e8   ; las columnas del arcen
	ld (0e08ah),hl		;50eb   ; (0xE08A) es la que arma la fila nueva
	ret			;50ee
L_50EF:
	ld hl,07c85h		;50ef   ; la lista de lineas juntas
	ld (0e090h),hl		;50f2
	ld hl,07c54h		;50f5   ; y el paisaje B
	ld (0e06fh),hl		;50f8   ; (0xE06F) es el paisaje
	ld a,001h		;50fb
	ld (0e07ch),a		;50fd   ; la marca de alternancia
	ld (0e08ah),a		;5100
	ld hl,07aa1h		;5103   ; un guion de paisaje propio
	ld (0e0b2h),hl		;5106
	ret			;5109
L_510A:
	ld hl,05116h		;510a   ; doce bytes de golpe
	ld de,0e08ah		;510d   ; sobre 0xE08A y los que siguen
	ld bc,0000ch		;5110
	ldir		;5113
	ret			;5115

; ----------------------------------------------------------------------
; DATOS datos_5116: doce bytes que carga 0x510a
;   0x5116..0x5122  (12 bytes)
DATA_datos_5116:
	defb 07ch,07eh,001h,001h,000h,000h,057h,07eh,03fh,001h,0c5h,07dh	; 5116  |~....W~?..}

; ======================================================================
; CODIGO 0x5122..0x5161  (63 bytes)
; ======================================================================


L_5122:
	call L_510A		;5122   ; lo mismo que la etapa anterior
	ld hl,07d8ah		;5125   ; y ademas otro arcen
	ld (0e08ah),hl		;5128
	ld hl,0010eh		;512b   ; y su cuenta
	ld (0e092h),hl		;512e
	ret			;5131

; ----------------------------------------------------------------------
; Copia a 0xE071 los TRES punteros de guion de paisaje de esta etapa, de la tabla de 0x5161, y saca el primer par [modo, cuenta].
; ----------------------------------------------------------------------
elige_los_guiones_de_la_etapa:
	ld a,(0e043h)		;5132   ; la etapa
	dec a			;5135
	add a,a			;5136   ; por seis: tres punteros de dos bytes
	ld b,a			;5137
	add a,a			;5138
	add a,b			;5139
	ld hl,05161h		;513a   ; la tabla de guiones
	call suma_a_hl		;513d
	ld bc,00006h		;5140   ; los seis bytes
	ld de,0e071h		;5143   ; a 0xE071
	ldir		;5146
	ld a,001h		;5148   ; la marca de arranque
	ld (0e07fh),a		;514a
	ld hl,(0e071h)		;514d   ; el primer puntero
	ld de,0e07ah		;5150   ; el par [modo, cuenta]
	ld c,002h		;5153
	ldir		;5155
	ld (0e071h),hl		;5157   ; y ahi queda por donde va
	ld hl,05998h		;515a   ; el paisaje de la salida
	ld (0e06fh),hl		;515d   ; (0xE06F)
	ret			;5160

; ----------------------------------------------------------------------
; DATOS guiones_por_etapa: SEIS registros de tres punteros, uno por etapa; los
;   indexa 0x5132 con `ld a,(0e043h) / dec a / add a,a / ld b,a / add a,a /
;   add a,b`, o sea 0x5161 + 6*(etapa-1), y copia los seis bytes a 0xE071. Las
;   etapas 2 y 3 llevan los MISMOS tres punteros
;   0x5161..0x5185  (36 bytes)
DATA_guiones_por_etapa:
	defw 078c4h,078e5h,07960h,07aaah,07baah,07acdh,07aaah,07baah	; 5161
	defw 07acdh,07e83h,078e5h,07960h,07e60h,078e5h,07960h,07ea8h	; 5171
	defw 07f6bh,07ed1h	; 5181

; ----------------------------------------------------------------------
; DATOS plantilla_de_los_tres_sprites: doce bytes que 0x520D copia a 0xE10E:
;   la aguja del cuadro de mandos (Y 0xE0, x 0xD0, patron 0x6C, color 6) y los
;   DOS sprites del coche, los dos en la Y 0x80 y la x 0x52. Cotejado con la
;   copia que el emulador tiene en marcha, byte a byte
;   0x5185..0x5191  (12 bytes)
DATA_plantilla_de_los_tres_sprites:
	defb 0e0h,0d0h,06ch,006h,080h,052h,000h,001h,080h,052h,000h,006h	; 5185  ..l..R...R..

; ----------------------------------------------------------------------
; DATOS tile_de_fondo_por_etapa: seis bytes, uno por etapa: el tile con el que
;   0x592A llena la fila nueva antes de que la calzada pinte lo suyo. Lo
;   indexa 0x5092 con (0xE043) menos uno
;   0x5191..0x5197  (6 bytes)
DATA_tile_de_fondo_por_etapa:
	defb 0a0h,0c5h,0abh,006h,009h,080h	; 5191

; ======================================================================
; CODIGO 0x5197..0x51c1  (42 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Rellena las dos barras del cuadro de mandos -velocidad y gasolina- con bloques de cuatro bytes, ocho filas cada una y 0x18 de separacion.
; ----------------------------------------------------------------------
monta_los_indicadores_moviles:
	ld de,0e11ah		;5197   ; la primera barra
	ld bc,00551h		;519a   ; su color y su tile
	call L_51A5		;519d
	ld e,042h		;51a0   ; la segunda
	ld bc,00665h		;51a2
L_51A5:
	ld a,008h		;51a5   ; ocho filas
L_51A7:
	push bc			;51a7   ; la cuenta, a salvo
	ld hl,051c1h		;51a8   ; los cuatro bytes de una fila
	ld b,002h		;51ab   ; dos por fila
L_51AD:
	push bc			;51ad
	ld (de),a			;51ae   ; la altura
	inc de			;51af
	ex de,hl			;51b0
	ld (hl),c			;51b1   ; y el tile
	ex de,hl			;51b2
	inc de			;51b3
	ldi		;51b4   ; y detras los dos de la tabla
	ldi		;51b6
	pop bc			;51b8
	djnz L_51AD		;51b9
	add a,018h		;51bb   ; la fila siguiente, 0x18 mas abajo
	pop bc			;51bd
	djnz L_51A7		;51be
	ret			;51c0

; ----------------------------------------------------------------------
; DATOS datos_51c1: cuatro bytes que carga 0x51a8
;   0x51c1..0x51c5  (4 bytes)
DATA_datos_51c1:
	defb 000h,001h,004h,004h	; 51c1

; ======================================================================
; CODIGO 0x51c5..0x5219  (84 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Vuelve a dejarlo todo en su sitio despues de un choque: los objetos, la velocidad, el coche y el plan de tramos.
; ----------------------------------------------------------------------
rearma_la_partida:
	call arranca_las_variables_de_carrera		;51c5   ; los objetos
	call pon_el_coche_sobre_la_calzada		;51c8   ; y lo vuelve a poner sobre la calzada
	call dibuja_el_coche		;51cb   ; el coche
	call esconde_los_sprites_de_juego		;51ce   ; esconde los sprites
	xor a			;51d1
	ld (0e0b9h),a		;51d2   ; (0xE0B9) es el tramo que se esta usando
	jp pasa_al_tramo_siguiente		;51d5   ; y saca el tramo siguiente

; ----------------------------------------------------------------------
; Pone 0xC8 en los 0x31 bytes de 0xE11A: la copia en RAM de los atributos de sprite, con todos fuera de la pantalla.
; ----------------------------------------------------------------------
esconde_los_sprites_de_juego:
	ld hl,0e11ah		;51d8   ; la copia de los atributos
	ld de,0e11bh		;51db
	ld bc,00030h		;51de   ; 0x31 bytes
	ld (hl),0c8h		;51e1   ; la Y de fuera de pantalla
	ldir		;51e3

; ----------------------------------------------------------------------
; Pone a cero los 0x45 bytes de 0xE0C1: los cuatro objetos de carretera y su contador.
; ----------------------------------------------------------------------
borra_los_objetos:
	ld hl,0e0c1h		;51e5   ; los objetos
	ld de,0e0c2h		;51e8
	ld bc,00044h		;51eb   ; 0x45 bytes
	ld (hl),000h		;51ee
	ldir		;51f0
	ret			;51f2

; ----------------------------------------------------------------------
; Saca la x del coche del arcen: (0xE0AD) es la casilla 22 de las veinticuatro de la cola del arcen, la que corresponde a la altura a la que va el coche; por dos, redondeada a ocho y mas 0x20 da la columna en pixeles. Asi el coche reaparece SIEMPRE sobre la calzada, este esta donde este.
; ----------------------------------------------------------------------
pon_el_coche_sobre_la_calzada:
	ld a,(0e0adh)		;51f3   ; la casilla 22 de la cola del arcen, la de la altura del coche
	add a,a			;51f6   ; por dos
	and 0f8h		;51f7   ; redondeada a ocho
	add a,020h		;51f9   ; mas 0x20
	ld (0e04eh),a		;51fb
	ret			;51fe

; ----------------------------------------------------------------------
; Copia las dos plantillas: once bytes a 0xE049 y doce a 0xE10E.
; ----------------------------------------------------------------------
arranca_las_variables_de_carrera:
	ld hl,05219h		;51ff   ; la primera plantilla
	ld de,0e049h		;5202
	ld bc,0000bh		;5205   ; once bytes
	ldir		;5208
	call dibuja_el_coche		;520a   ; rearma el coche
	ld hl,05185h		;520d   ; la segunda plantilla
	ld de,0e10eh		;5210
	ld bc,0000ch		;5213   ; doce bytes
	ldir		;5216
	ret			;5218

; ----------------------------------------------------------------------
; DATOS datos_5219: once bytes que carga 0x51ff
;   0x5219..0x5224  (11 bytes)
DATA_datos_5219:
	defb 000h,000h,000h,080h,000h,052h,000h,000h,000h,000h,000h	; 5219  .....R.....

; ======================================================================
; CODIGO 0x5224..0x530f  (235 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Lo que corre en cada fotograma de juego: marcador, paisaje, objetos y coche.
; ----------------------------------------------------------------------
latido_de_la_partida:
	call sube_trece_sprites		;5224   ; sube los trece primeros sprites a la VRAM
	call baja_la_aguja		;5227   ; el paisaje
	call mueve_los_objetos		;522a   ; los objetos de la carretera
	call mueve_el_rival		;522d   ; y el coche
	call remate_del_choque		;5230
	call mueve_el_coche		;5233
	call gasta_gasolina		;5236
	call cuentakilometros		;5239
	call cruza_la_meta		;523c
	call mira_los_choques		;523f
	call puntua_el_recorrido		;5242
	call baja_la_gasolina		;5245
	call pisa_el_acelerador		;5248
	call frena_si_va_muy_rapido		;524b
	jp L_44D9		;524e

; ----------------------------------------------------------------------
; A los 0x0F12 de recorrido se acaba la etapa: el coche pasa al estado 3 y suena el efecto 0x92. Es el tercero de los tres hitos del final -a 0x0F00 se suelta el rival, a 0x0F09 se pinta el arco de meta en el anillo y aqui se cruza-, y por eso los tres estan a nueve de distancia: nueve filas de anillo.
; ----------------------------------------------------------------------
cruza_la_meta:
	ld hl,(0e078h)		;5251   ; lo recorrido
	ld bc,00f12h		;5254   ; el hito del final
	and a			;5257
	sbc hl,bc		;5258
	ret c			;525a   ; antes de eso, nada
	ld a,(0e002h)		;525b   ; las banderas de la partida
	bit 6,a		;525e   ; en demostracion no suena
	ld a,092h		;5260   ; el efecto de la meta
	call nz,suena		;5262
	ld a,003h		;5265   ; el estado 3
	ld (0e049h),a		;5267   ; al coche
	ret			;526a

; ----------------------------------------------------------------------
; Las dos puertas del volcado de sprites: 0x34 bytes son los trece primeros y 0x78 los treinta, o sea la copia entera. Van de 0xE10E a 0x3B00, que es donde R5=0x76 pone la tabla de atributos.
; ----------------------------------------------------------------------
sube_trece_sprites:
	ld bc,00034h		;526b   ; los trece primeros
	jr L_5273		;526e
L_5270:
	ld bc,00078h		;5270   ; o los treinta enteros
L_5273:
	ld de,0e10eh		;5273   ; la copia en RAM
	ld hl,03b00h		;5276   ; la tabla de atributos de sprite
	call sube_a_la_vram		;5279
	ret			;527c

; ----------------------------------------------------------------------
; El latido de cuando ya no se juega: sigue volcando los sprites y moviendo lo que quedaba en la carretera, pero en vez de leer el mando va retirando los sprites hacia arriba.
; ----------------------------------------------------------------------
latido_de_la_retirada:
	call L_5270		;527d   ; los treinta sprites
	call mueve_el_coche		;5280
	call pisa_el_acelerador		;5283
	call cuentakilometros		;5286
	call puntua_el_recorrido		;5289
	jp L_528F		;528c
L_528F:
	ld b,00bh		;528f   ; once sprites
	ld hl,0e116h		;5291   ; desde el tercero

; ----------------------------------------------------------------------
; Retira los sprites de once en once: a cada uno le quita SEIS de la Y hasta dejarlo en la franja 0xC0..0xDF, que es donde el VDP ya no lo pinta. Como el coche ocupa dos sprites -la carroceria y su color- la Y se escribe tambien cuatro bytes mas alla. Cuando el ULTIMO llega a la franja, y solo entonces, se pasa al paso siguiente de la escena.
; ----------------------------------------------------------------------
retira_los_sprites:
	inc hl			;5294   ; al byte de la Y
	inc hl			;5295
	inc hl			;5296
	inc hl			;5297
	ld a,(hl)			;5298   ; la Y de ahora
	sub 0c0h		;5299   ; contra la franja de aparcado
	cp 020h		;529b
	jr c,L_52AB		;529d   ; ya esta fuera
	ld a,(hl)			;529f   ; y si no, seis mas arriba
	sub 006h		;52a0
	ld (hl),a			;52a2
	inc hl			;52a3   ; el sprite siguiente lleva la misma Y
	inc hl			;52a4
	inc hl			;52a5
	inc hl			;52a6
	ld (hl),a			;52a7
L_52A8:
	djnz retira_los_sprites		;52a8   ; y al siguiente
	ret			;52aa
L_52AB:
	ld a,b			;52ab   ; que numero de sprite era
	cp 001h		;52ac   ; si es el ultimo, se acabo la retirada
	jp z,L_416A		;52ae
	ld a,004h		;52b1   ; cuatro bytes por sprite
	call suma_a_hl		;52b3   ; al siguiente
	jr L_52A8		;52b6

; ----------------------------------------------------------------------
; La demostracion no empieza siempre por la primera etapa: se sortea entre la 1, la 2 y la 3 con el registro R de refresco de la memoria sumado al reloj del juego. El `cp 004h` deja el cuatro fuera, asi que nunca salen la 4, la 5 ni la 6.
; ----------------------------------------------------------------------
sortea_la_etapa:
	xor a			;52b8   ; la vuelta, a cero
	ld hl,0e042h		;52b9
	ld (hl),a			;52bc
	ld a,r		;52bd   ; R, el contador de refresco: el azar del cartucho
	add a,h			;52bf
	ld c,a			;52c0
	ld a,(0e003h)		;52c1   ; mas el reloj del juego
	add a,c			;52c4
	and 003h		;52c5   ; uno de cuatro
	inc a			;52c7   ; del 1 al 4
	cp 004h		;52c8   ; y el 4 no vale
	jr nz,L_52CE		;52ca
	ld a,001h		;52cc   ; se queda en la primera
L_52CE:
	inc hl			;52ce   ; (0xE043), la etapa
	ld (hl),a			;52cf
	ret			;52d0

; ----------------------------------------------------------------------
; Con el coche en el estado 4 -derrapando- y el derrape ya por debajo de 0x15, mete 0x0C en (0xE008): los DOS bits de girar a la vez. Es lo unico que escribe ahi aparte de la lectura del mando, y L_6A70 lo copia tal cual a (0xE048).
; ----------------------------------------------------------------------
endereza_el_coche:
	ld a,(0e049h)		;52d1   ; el estado del coche
	cp 004h		;52d4   ; solo si venia derrapando
	jr nz,L_52E4		;52d6
	ld a,(0e0b1h)		;52d8   ; lo que queda de derrape
	cp 015h		;52db   ; y solo cuando ya se esta acabando
	jr nc,L_52E4		;52dd
	ld a,00ch		;52df   ; los dos bits de girar
	ld (0e008h),a		;52e1   ; al mando, como si se pulsaran

; ----------------------------------------------------------------------
; Mira si el coche se ha salido de la calzada. El borde sale de la casilla 19 de la cola del arcen, (0xE0AA): por ocho y mas 0x1A da la columna en pixeles. Si el coche esta a menos de siete de ahi, no pasa nada; si se ha ido, deja marcado en (0xE009) el bit del lado por el que se fue, con el bit 4 siempre puesto. Y (0xE009) es lo que `lee_el_mando_nuevo` toma por PULSADO ANTES, de modo que lo que se escriba aqui no contara como recien pulsado en el fotograma que viene.
; ----------------------------------------------------------------------
L_52E4:
	ld a,(0e0aah)		;52e4   ; la casilla 19 de la cola del arcen
	and 0fch		;52e7   ; quitando el modo, que va en los dos bits de abajo
	add a,a			;52e9   ; por ocho: cada casilla son ocho pixeles
	add a,01ah		;52ea   ; y el ajuste
	ld c,a			;52ec
	ld a,(0e04eh)		;52ed   ; la x del coche
	sub c			;52f0
	add a,001h		;52f1   ; con un pixel de margen
	cp 007h		;52f3   ; dentro de siete, se da por bueno
	jr c,L_530C		;52f5
	ld a,(0e04eh)		;52f7   ; la x, otra vez
	cp c			;52fa   ; por que lado se ha ido
	ld b,008h		;52fb   ; por la izquierda
	jr c,L_5301		;52fd
	ld b,004h		;52ff   ; o por la derecha
L_5301:
	ld a,(0e009h)		;5301   ; lo que habia pulsado antes
	or b			;5304
L_5305:
	ld b,010h		;5305   ; el bit 4, siempre
	or b			;5307
	ld (0e009h),a		;5308   ; y ahi queda
	ret			;530b
L_530C:
	xor a			;530c   ; dentro de la calzada no se marca nada
	jr L_5305		;530d

; ----------------------------------------------------------------------
; DATOS datos_530f: los dos bytes justo antes de la tabla de tramos
;   0x530f..0x5311  (2 bytes)
DATA_datos_530f:
	defb 03eh,004h	; 530f

; ----------------------------------------------------------------------
; DATOS tabla_de_tramos: 15 registros de 6 bytes, indexados por el valor de la
;   lista de la etapa (0x704e: 0x5311 + 6*(v-1)); cada registro arma DOS
;   objetos de 16 bytes en 0xE0C3 y 0xE0D3
;   0x5311..0x536b  (90 bytes)
DATA_tabla_de_tramos:
	defb 000h,004h,020h,000h,008h,028h	; 5311
	defb 000h,004h,010h,001h,010h,028h	; 5317
	defb 000h,004h,018h,000h,008h,018h	; 531d
	defb 000h,004h,028h,000h,008h,018h	; 5323
	defb 000h,004h,018h,008h,008h,028h	; 5329
	defb 000h,004h,028h,001h,008h,020h	; 532f
	defb 002h,004h,028h,000h,008h,020h	; 5335
	defb 000h,004h,028h,003h,008h,020h	; 533b
	defb 006h,004h,018h,000h,008h,030h	; 5341
	defb 000h,004h,030h,007h,008h,01ch	; 5347
	defb 002h,004h,028h,003h,008h,020h	; 534d
	defb 004h,004h,028h,002h,008h,020h	; 5353
	defb 004h,004h,028h,005h,008h,020h	; 5359
	defb 005h,004h,018h,005h,008h,028h	; 535f
	defb 003h,004h,028h,003h,008h,020h	; 5365

; ----------------------------------------------------------------------
; DATOS tabla_536b: 18 bytes; la carga 0x6ffe
;   0x536b..0x537d  (18 bytes)
DATA_tabla_536b:
	defb 001h,00ch,001h,004h,001h,004h,001h,00dh,00bh,001h,00bh,001h,001h,008h,001h,008h	; 536b  ................
	defb 00fh,00dh	; 537b

; ----------------------------------------------------------------------
; DATOS plan_de_las_etapas: SEIS filas de 16 bytes, una por etapa; lista
;   ciclica de tramos cerrada en 0xFF. **La UNICA diferencia entre las dos
;   compilaciones esta en 0x53CB**, el decimoquinto tramo de la etapa 5
;   0x537d..0x53dd  (96 bytes)
DATA_plan_de_las_etapas:
	defb 001h,002h,004h,005h,002h,003h,004h,008h,002h,006h,005h,004h,002h,001h,003h,0ffh	; 537d  ................
	defb 001h,002h,008h,004h,005h,001h,00fh,008h,001h,008h,005h,00bh,00fh,0ffh,0ffh,0ffh	; 538d  ................
	defb 002h,008h,006h,00fh,005h,00ah,003h,002h,00ah,008h,007h,005h,008h,006h,00ah,0ffh	; 539d  ................
	defb 001h,002h,009h,008h,005h,00ah,002h,00ah,008h,009h,005h,00ah,003h,00ah,008h,0ffh	; 53ad  ................
	defb 00fh,00ah,006h,00bh,00fh,00bh,005h,00bh,008h,006h,00fh,00ah,006h,00ah,005h,0ffh	; 53bd  ................
	defb 001h,004h,008h,00fh,008h,00fh,005h,00ah,00eh,008h,00fh,002h,00ah,00fh,00ah,0ffh	; 53cd  ................

; ======================================================================
; CODIGO 0x53dd..0x54f9  (284 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Mete en juego el objeto de 0xE105, el unico que no sale del reparto normal de tramos: hacen falta 0x0F00 de recorrido, que el tramo en curso sea del tipo 7 y que el coche siga entero. Se coloca contra la Y del coche -(0xE04C), menos 0x10 y menos 0xB8- y su carril sale del hueco 6 con cuatro de margen.
; ----------------------------------------------------------------------
suelta_el_rival:
	ld hl,(0e078h)		;53dd   ; lo recorrido
	ld bc,00f00h		;53e0   ; antes de 0x0F00 no aparece
	and a			;53e3
	sbc hl,bc		;53e4
	ret nc			;53e6   ; y si no llega, nada
	ld hl,(0e0bfh)		;53e7   ; el tramo en curso
	ld a,(hl)			;53ea
	cp 007h		;53eb   ; solo en los del tipo 7
	ret nz			;53ed
	ld a,(0e049h)		;53ee   ; el estado del coche
	dec a			;53f1
	ret z			;53f2   ; si esta fuera de juego, tampoco
	ld c,006h		;53f3   ; el hueco 6
	call campo_del_objeto		;53f5   ; busca sitio
	ld a,(0e04ch)		;53f8   ; la Y del coche
	sub 010h		;53fb
	sub (hl)			;53fd   ; contra la posicion del hueco
	sub 0b8h		;53fe
	add a,020h		;5400
	ret nc			;5402   ; si no cabe, se deja
	ld a,(hl)			;5403   ; la posicion del hueco
	add a,030h		;5404   ; corrida 0x30
	ld b,a			;5406
	inc hl			;5407
	inc hl			;5408
	ld a,(hl)			;5409   ; y su carril
	add a,004h		;540a   ; cuatro mas
	ld c,a			;540c
	ld e,c			;540d
	ld d,000h		;540e
	ld a,(0e04eh)		;5410   ; la x del coche
	ld h,d			;5413
	ld l,a			;5414
	and a			;5415
	sbc hl,de		;5416   ; menos la del hueco
	add hl,hl			;5418   ; por cuatro
	add hl,hl			;5419
	ex de,hl			;541a
	ld hl,0e105h		;541b   ; el bloque del rival
	ld a,(hl)			;541e
	dec a			;541f   ; si ya esta ocupado
	ret z			;5420   ; no se toca
	ld (hl),001h		;5421   ; en marcha
	inc hl			;5423
	inc hl			;5424
	ld (hl),b			;5425   ; la fila
	inc hl			;5426
	inc hl			;5427
	ld (hl),c			;5428   ; la columna
	inc hl			;5429
	ld (hl),090h		;542a   ; el patron 0x90
	inc hl			;542c
	ld (hl),003h		;542d   ; el color 3
	inc hl			;542f
	ld (hl),e			;5430   ; y la velocidad con que se acerca
	inc hl			;5431
	ld (hl),d			;5432
	ret			;5433

; ----------------------------------------------------------------------
; Lo adelanta un poco cada fotograma, mira si ha chocado con el coche del jugador y deja su sprite en la copia de atributos de 0xE13E. Con el motor sonando, cada ocho fotogramas suelta el efecto 4.
; ----------------------------------------------------------------------
mueve_el_rival:
	ld hl,0e105h		;5434   ; el bloque del rival
	ld a,(hl)			;5437
	or a			;5438
	ret z			;5439   ; si no esta en juego, nada
	inc hl			;543a
	inc hl			;543b
	ld a,(hl)			;543c   ; su posicion
	cp 0c0h		;543d   ; pasada 0xC0 se ha ido
	jr nc,retira_al_rival		;543f
	ld a,(0e002h)		;5441   ; las banderas de la partida
	bit 6,a		;5444   ; el bit 6, partida de verdad
	jr z,L_5456		;5446
	push hl			;5448
	ld a,(0e003h)		;5449   ; el reloj del juego
	and 007h		;544c   ; uno de cada ocho
	jr nz,L_5455		;544e
	ld a,004h		;5450   ; el efecto 4
	call suena		;5452
L_5455:
	pop hl			;5455
L_5456:
	ld a,(0e04ch)		;5456   ; la Y del coche
	sub (hl)			;5459   ; contra la posicion del rival
	sub 008h		;545a
	add a,018h		;545c   ; y con margen de 0x18
	jr nc,L_546C		;545e   ; si no se tocan, se mueve y ya
	inc hl			;5460
	inc hl			;5461
	ld a,(0e04eh)		;5462   ; la x del coche
	sub (hl)			;5465   ; contra su carril
	sub 008h		;5466
	add a,010h		;5468   ; con margen de 0x10
	jr c,L_54A9		;546a   ; y si tambien coinciden, hay choque
L_546C:
	ld hl,0e10ah		;546c   ; su velocidad vertical
	ld e,(hl)			;546f
	inc hl			;5470
	ld d,(hl)			;5471
	ld hl,(0e106h)		;5472   ; la posicion, en dos bytes
	add hl,de			;5475
	ld (0e106h),hl		;5476   ; y avanza
	ld hl,0e10ch		;5479   ; su velocidad horizontal
	ld e,(hl)			;547c
	inc hl			;547d
	ld d,(hl)			;547e
	ld hl,(0e108h)		;547f   ; la otra posicion
	add hl,de			;5482
	ld (0e108h),hl		;5483
	ld hl,0e107h		;5486   ; los bytes enteros de las dos posiciones
	ld de,0e13eh		;5489   ; a la copia de atributos de sprite
	ldi		;548c
	inc hl			;548e
	ldi		;548f
	ld a,(0e003h)		;5491   ; el reloj del juego
	and 00ch		;5494   ; dos bits
	add a,06ch		;5496   ; eligen el patron entre 0x6C y 0x78: asi la figura se anima
	ld (de),a			;5498
	inc de			;5499
	ld a,008h		;549a   ; y el color 8
	ld (de),a			;549c
	ret			;549d

; ----------------------------------------------------------------------
; Lo saca de juego y esconde su sprite poniendole la Y a 0xE0.
; ----------------------------------------------------------------------
retira_al_rival:
	ld hl,0e105h		;549e   ; el bloque del rival
	ld (hl),000h		;54a1   ; fuera de juego
	ld a,0e0h		;54a3   ; la Y de fuera de pantalla
	ld (0e13eh),a		;54a5
	ret			;54a8
L_54A9:
	call retira_al_rival		;54a9   ; lo retira
	jp L_6F18		;54ac   ; y da parte del choque

; ----------------------------------------------------------------------
; Lee el guion de paisaje de (0xE0B2), que son pares [distancia, tramo], y cuando lo recorrido alcanza la distancia arranca un tramo nuevo: cuatro bytes de la tabla de 0x54F9, dos filas de ellos, y el margen sale del arcen de (0xE098).
; ----------------------------------------------------------------------
arma_el_paisaje:
	ld hl,0e0b4h		;54af   ; (0xE0B4) es lo que queda del tramo de ahora
	ld a,(hl)			;54b2
	or a			;54b3
	jr nz,L_54E0		;54b4   ; mientras quede, se sigue con el
	ld hl,(0e0b2h)		;54b6   ; el guion de paisaje
	ld a,(0e079h)		;54b9   ; lo recorrido
	cp (hl)			;54bc   ; si no llega a la distancia del par, nada
	ret nz			;54bd
	inc hl			;54be
	ld a,(hl)			;54bf   ; el tramo que toca
	inc hl			;54c0
	ld (0e0b2h),hl		;54c1   ; y el guion avanza al par siguiente
	ld hl,054f9h		;54c4   ; la tabla de tramos de paisaje
	add a,a			;54c7   ; por cuatro
	add a,a			;54c8
	call suma_a_hl		;54c9
	ld (0e0b5h),hl		;54cc   ; (0xE0B5), por donde va el tramo
	ld a,002h		;54cf   ; dos filas
	ld (0e0b4h),a		;54d1   ; (0xE0B4)
	ld a,(0e098h)		;54d4   ; el arcen
	rra			;54d7   ; sus bits de arriba
	rra			;54d8
	and 03fh		;54d9
	add a,002h		;54db   ; mas dos
	ld (0e0b7h),a		;54dd   ; (0xE0B7) es la columna donde cae
L_54E0:
	ld hl,(0e0b5h)		;54e0   ; por donde va el tramo
	ld a,(0e0b7h)		;54e3   ; la columna
	ld de,0e058h		;54e6   ; la fila nueva del anillo
	call suma_a_de		;54e9   ; corrida a esa columna
	ld bc,00002h		;54ec   ; dos bytes
	ldir		;54ef
	ld (0e0b5h),hl		;54f1   ; y el tramo avanza
	ld hl,0e0b4h		;54f4
	dec (hl)			;54f7   ; una fila menos
	ret			;54f8

; ----------------------------------------------------------------------
; DATOS datos_54f9: ocho bytes que carga 0x54c4
;   0x54f9..0x5501  (8 bytes)
DATA_datos_54f9:
	defb 076h,077h,074h,075h,07ah,07bh,078h,079h	; 54f9  vwtuz{xy

; ======================================================================
; CODIGO 0x5501..0x5526  (37 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Tres puntos por cada vez que cambia el bit 0 de lo recorrido: es la puntuacion por distancia.
; ----------------------------------------------------------------------
puntua_el_recorrido:
	ld a,(0e049h)		;5501   ; el estado del coche
	dec a			;5504
	ret z			;5505   ; fuera de juego no se puntua
	ld b,001h		;5506   ; el bit que se vigila
	ld a,(0e078h)		;5508   ; lo recorrido
	and b			;550b
	ld d,a			;550c
	ld hl,0e07eh		;550d   ; y como estaba
	ld a,(hl)			;5510
	and b			;5511
	xor d			;5512
	ret z			;5513   ; si no ha cambiado, nada
	ld a,(hl)			;5514
	xor b			;5515
	ld (hl),a			;5516   ; lo apunta
	ld de,00003h		;5517   ; tres puntos
	call suma_a_la_puntuacion		;551a   ; a la puntuacion

; ----------------------------------------------------------------------
; El reparto de la carretera POR ETAPA: la tabla de siete entradas de 0x5526 se indexa con (0xE043) directamente, sin restar uno, y por eso su primera entrada apunta al mismo sitio que la segunda. Cada etapa tiene su propia mezcla de calzada y paisaje.
; ----------------------------------------------------------------------
motor_de_la_carretera:
	call llena_la_fila_de_fondo		;551d   ; el paisaje base
	ld a,(0e043h)		;5520   ; la etapa
	call despacha_por_indice		;5523   ; y detras del call, las siete ramas

; ----------------------------------------------------------------------
; DATOS tabla_de_subestados: 7 entradas, desde 0x5523 con el indice en
;   (0xE043); las dos primeras van al mismo sitio
;   0x5526..0x5534  (14 bytes)
DATA_tabla_de_subestados:
	defw 05534h,05534h,05545h,05563h,055e9h,05642h,056ach	; 5526

; ======================================================================
; CODIGO 0x5534..0x569c  (360 bytes)
; ======================================================================


L_5534:
	call pega_un_tramo_de_calzada		;5534   ; las lineas de la calzada
L_5537:
	call L_56F7		;5537   ; el paisaje de los lados
L_553A:
	call pinta_el_rotulo_de_meta		;553a   ; y el rotulo de meta, si toca
	call arma_el_paisaje		;553d   ; el guion de paisaje
	call corre_el_anillo		;5540   ; y el remate
	pop hl			;5543   ; se come la vuelta: sale a quien llamo al reparto
	ret			;5544

; ----------------------------------------------------------------------
; La calzada de la ETAPA 2: sobre la de siempre pega CUATRO columnas que salen de una lista ciclica, la de 0x7DC5, que se recorre de cuatro en cuatro y vuelve a empezar en cuanto se topa con un 0xFF.
; ----------------------------------------------------------------------
calzada_de_la_etapa_2:
	call pega_un_tramo_de_calzada		;5545   ; la calzada de siempre
	ld hl,(0e08ah)		;5548   ; por donde va la lista
	ld a,(hl)			;554b   ; el byte de cierre
	inc a			;554c
	jr nz,L_5555		;554d   ; si no lo es, sigue
	ld hl,07dc5h		;554f   ; y si lo es, vuelta al principio
	ld (0e08ah),hl		;5552
L_5555:
	ld de,0e058h		;5555   ; al principio de la fila nueva
	ld bc,00004h		;5558   ; cuatro columnas
	ldir		;555b
	ld (0e08ah),hl		;555d   ; y ahi queda la lista
	jp L_5537		;5560

; ----------------------------------------------------------------------
; La calzada de la ETAPA 3, la unica que se dibuja entera desde BITS: veintidos columnas sacadas de una sola palabra de 16 bits, doce por un lado y diez por otro. Como la segunda pasada vuelve a cargar la MISMA palabra desde el principio, las columnas 12 a 21 repiten el dibujo de las diez primeras: la calzada sale simetrica sin gastar un byte de mas. La lista es la de 0x7C85 y se recorre de dos en dos.
; ----------------------------------------------------------------------
calzada_de_la_etapa_3:
	ld de,0e058h		;5563   ; al principio de la fila nueva
	call L_56CC		;5566   ; las doce primeras columnas
	ld b,00ah		;5569   ; y diez mas
	call L_56CE		;556b
	ld hl,(0e090h)		;556e   ; por donde va la lista
	inc hl			;5571   ; la palabra siguiente
	inc hl			;5572
	ld (0e090h),hl		;5573
	ld a,(hl)			;5576   ; el byte de cierre
	inc a			;5577
	jr nz,L_5580		;5578
	ld hl,07c85h		;557a   ; vuelta al principio
	ld (0e090h),hl		;557d

; ----------------------------------------------------------------------
; El otro guion de la etapa 3, el que pega el puente. Cuando se acaba -0xFF- retrocede 0x30 y alterna entre los dos que hay, el de 0x7C23 y el de 0x7C54, cada uno con su cuenta y su paso. Ese vaiven es lo que hace que el puente se repita.
; ----------------------------------------------------------------------
L_5580:
	ld hl,(0e06fh)		;5580   ; por donde va el guion
	ld a,(hl)			;5583   ; el byte de cierre
	inc a			;5584
	jr nz,L_55B3		;5585   ; si no lo es, a copiar
	ld bc,0ffd0h		;5587   ; 0x30 atras
	add hl,bc			;558a
	ld (0e06fh),hl		;558b
	ld hl,0e08ah		;558e   ; la cuenta del guion
	dec (hl)			;5591   ; mientras quede, se alarga
	jr nz,L_55E4		;5592
	ld de,0e07ch		;5594   ; la bandera del vaiven
	ld a,(de)			;5597
	and 001h		;5598   ; se le da la vuelta
	xor 001h		;559a
	ld (de),a			;559c
	ld de,07c23h		;559d   ; el primer guion
	ld bc,00601h		;55a0   ; seis filas, de una en una
	and a			;55a3
	jr z,L_55AB		;55a4
	ld de,07c54h		;55a6   ; o el segundo
	ld c,010h		;55a9   ; de dieciseis en dieciseis
L_55AB:
	ld (0e06fh),de		;55ab   ; y ahi queda
	ld (0e08ah),bc		;55af

; ----------------------------------------------------------------------
; El puente propiamente dicho: cuatro columnas del guion, SEIS de tile 0xD0 en medio y otras cuatro del guion. Y dos filas de cada cuatro llevan un 0xD1 en la columna 11, que es la raya discontinua del centro de la calzada.
; ----------------------------------------------------------------------
L_55B3:
	ld de,0e05ch		;55b3   ; la columna 4 de la fila nueva
	ld bc,00004h		;55b6   ; cuatro columnas
	ld hl,(0e06fh)		;55b9   ; el guion
	ldir		;55bc
	push hl			;55be
	ld c,006h		;55bf   ; seis mas
	ld h,d			;55c1
	ld l,e			;55c2
	ld (hl),0d0h		;55c3   ; el tile del centro del puente
	inc de			;55c5
	ldir		;55c6   ; repetido
	pop hl			;55c8
	ld c,004h		;55c9   ; y otras cuatro del guion
	ldir		;55cb
	ld (0e06fh),hl		;55cd   ; ahi queda el guion
	ld hl,0e08ch		;55d0   ; la cuenta de filas
	inc (hl)			;55d3
	ld a,(hl)			;55d4
	and 003h		;55d5   ; una de cada cuatro
	cp 002h		;55d7   ; en dos de las cuatro, nada
	jp nc,L_553A		;55d9
	ld hl,0e063h		;55dc   ; la columna 11
	ld (hl),0d1h		;55df   ; la raya del centro
	jp L_553A		;55e1
L_55E4:
	inc hl			;55e4   ; al 0xFF le sigue la cuenta
	ld (hl),006h		;55e5   ; seis filas
	jr L_55B3		;55e7

; ----------------------------------------------------------------------
; La calzada de la ETAPA 4: siete columnas del perfil y su ESPEJO al otro lado. Los siete bytes se vuelven a leer, se les suma 0x0D -que es el salto de un tile a su version espejada- y se escriben HACIA ATRAS desde el final de la fila. Media calzada guardada, la otra media calculada.
; ----------------------------------------------------------------------
calzada_de_la_etapa_4:
	call L_5600		;55e9   ; las siete columnas de la izquierda
	ld bc,0fff9h		;55ec   ; siete atras, a releerlas
	add hl,bc			;55ef
	ld b,007h		;55f0   ; las siete
	ld de,0e06eh		;55f2   ; el final de la fila
L_55F5:
	ld a,(hl)			;55f5   ; el tile de la izquierda
	add a,00dh		;55f6   ; su version espejada
	ld (de),a			;55f8   ; al otro lado
	dec de			;55f9   ; y hacia atras
	inc hl			;55fa
	djnz L_55F5		;55fb
	jp L_5537		;55fd

; ----------------------------------------------------------------------
; El guion de perfiles de las etapas 4 y 5. Un byte trae dos cosas: los dos bits de abajo eligen uno de los cuatro perfiles de la tabla de 0x569C y los seis de arriba dicen cuantas filas dura. Cada perfil empieza por su propia cuenta de repeticion y detras van sus filas de siete bytes.
; ----------------------------------------------------------------------
L_5600:
	ld hl,0e08dh		;5600   ; lo que le queda al perfil
	dec (hl)			;5603   ; mientras quede, se repite
	jr nz,L_5633		;5604
	dec hl			;5606   ; lo que le queda al tramo
	dec (hl)			;5607
	jr nz,L_561A		;5608   ; mientras quede, el mismo perfil
	ld hl,(0e08ah)		;560a   ; por donde va el guion
	inc hl			;560d
	ld (0e08ah),hl		;560e
	ld a,(hl)			;5611   ; el byte
	rra			;5612   ; los seis bits de arriba
	rra			;5613
	and 03fh		;5614
	ld de,0e08ch		;5616   ; son la cuenta del tramo
	ld (de),a			;5619
L_561A:
	ld hl,(0e08ah)		;561a   ; el byte, otra vez
	ld a,(hl)			;561d
	and 003h		;561e   ; los dos de abajo eligen
	add a,a			;5620   ; por dos: son punteros
	ld hl,0569ch		;5621   ; la tabla de perfiles
	call suma_a_hl		;5624
	ld a,(hl)			;5627   ; el perfil
	inc hl			;5628
	ld h,(hl)			;5629
	ld l,a			;562a
	ld de,0e08dh		;562b   ; el primer byte es su cuenta
	ldi		;562e
	ld (0e08eh),hl		;5630   ; y ahi empieza
L_5633:
	ld de,0e058h		;5633   ; al principio de la fila nueva
	ld bc,00007h		;5636   ; siete columnas
	ld hl,(0e08eh)		;5639   ; por donde va el perfil
	ldir		;563c
	ld (0e08eh),hl		;563e   ; y ahi queda
	ret			;5641

; ----------------------------------------------------------------------
; La calzada de la ETAPA 5: el mismo guion de perfiles que la 4 pero con la tabla de 0x56A4 y CUATRO columnas al otro lado en vez de siete. El tipo 3 es el unico que no escribe nada: se salta el espejo y solo adelanta el puntero.
; ----------------------------------------------------------------------
calzada_de_la_etapa_5:
	call L_56F7		;5642   ; el paisaje de los lados
	call L_5600		;5645   ; y la calzada
	ld hl,(0e094h)		;5648   ; por donde va este otro guion
	ld a,(hl)			;564b   ; el byte de cierre
	inc a			;564c
	jr nz,L_5676		;564d
	ld hl,0e092h		;564f   ; lo que le queda al tramo
	dec (hl)			;5652
	ld hl,(0e090h)		;5653   ; por donde va la lista
	jr nz,L_5665		;5656   ; mientras quede, el mismo
	inc hl			;5658   ; el byte siguiente
	ld (0e090h),hl		;5659
	ld a,(hl)			;565c
	ld b,a			;565d
	rra			;565e   ; los seis de arriba
	rra			;565f
	and 03fh		;5660
	ld (0e092h),a		;5662   ; son la cuenta
L_5665:
	ld a,(hl)			;5665   ; los dos de abajo eligen
	and 003h		;5666
	add a,a			;5668   ; por dos: son punteros
	ld hl,056a4h		;5669   ; la tabla de perfiles
	call suma_a_hl		;566c
	ld a,(hl)			;566f
	inc hl			;5670
	ld h,(hl)			;5671
	ld l,a			;5672
	ld (0e094h),hl		;5673   ; y ahi queda
L_5676:
	exx			;5676   ; el juego alterno de registros, para no perder HL
	ld hl,(0e090h)		;5677   ; por donde va la lista
	ld a,(hl)			;567a
	and 003h		;567b   ; el tipo
	cp 003h		;567d   ; el 3 no escribe nada
	exx			;567f
	jr nz,L_568B		;5680
	ld (0e094h),hl		;5682
	ld bc,00004h		;5685   ; solo adelanta cuatro
	add hl,bc			;5688
	jr L_5696		;5689
L_568B:
	ld b,004h		;568b   ; cuatro columnas
	ld de,0e06eh		;568d   ; desde el final de la fila
L_5690:
	ld a,(hl)			;5690   ; el tile
	ld (de),a			;5691
	dec de			;5692   ; y hacia atras
	inc hl			;5693
	djnz L_5690		;5694
L_5696:
	ld (0e094h),hl		;5696   ; ahi queda el perfil
	jp L_553A		;5699

; ----------------------------------------------------------------------
; DATOS datos_569c: ocho bytes que carga 0x5621
;   0x569c..0x56a4  (8 bytes)
DATA_datos_569c:
	defb 092h,07ch,0a1h,07ch,0b0h,07ch,07ch,07dh	; 569c  .|.|.||}

; ----------------------------------------------------------------------
; DATOS datos_56a4: ocho bytes que carga 0x5669
;   0x56a4..0x56ac  (8 bytes)
DATA_datos_56a4:
	defb 094h,07dh,0c5h,07dh,026h,07eh,094h,07dh	; 56a4  .}.}&~.}

; ======================================================================
; CODIGO 0x56ac..0x570c  (96 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La calzada de la ETAPA 6: como la 3, la fila entera desde una palabra de bits, con la lista de 0x7FE4. La diferencia es la salida: vuelve por L_5534, que rehace las lineas de la calzada ENCIMA de lo que se acaba de pintar.
; ----------------------------------------------------------------------
calzada_de_la_etapa_6:
	ld de,0e058h		;56ac   ; al principio de la fila nueva
	call L_56CC		;56af   ; las doce primeras columnas
	ld b,00ah		;56b2   ; y diez mas
	call L_56CE		;56b4
	ld hl,(0e090h)		;56b7   ; por donde va la lista
	inc hl			;56ba   ; de dos en dos
	inc hl			;56bb
	ld (0e090h),hl		;56bc
	ld a,(hl)			;56bf   ; el byte de cierre
	inc a			;56c0
	jr nz,L_56C9		;56c1
	ld hl,07fe4h		;56c3   ; vuelta al principio
	ld (0e090h),hl		;56c6
L_56C9:
	jp L_5534		;56c9   ; y a rehacer las lineas encima

; ----------------------------------------------------------------------
; De una palabra de 16 bits saca B tiles, uno por bit, empezando por el de mas peso: el 1 pinta la calzada y el 0 el borde. La palabra se lee AL REVES -primero el byte alto- y no se toca en memoria, asi que llamar dos veces seguidas repite el mismo dibujo desde el principio.
; ----------------------------------------------------------------------
L_56CC:
	ld b,00ch		;56cc   ; doce por defecto
L_56CE:
	ld hl,(0e090h)		;56ce   ; por donde va la lista
	ld a,(hl)			;56d1   ; el byte alto va primero
	inc hl			;56d2
	ld l,(hl)			;56d3
	ld h,a			;56d4
L_56D5:
	ld a,(0e043h)		;56d5   ; la etapa
	cp 003h		;56d8   ; la 3 tiene sus propios tiles
	jr z,L_56EB		;56da
	sla l		;56dc   ; saca el bit de mas peso
	rl h		;56de
	ld a,080h		;56e0   ; con el 1, la calzada
	jr c,L_56E6		;56e2
	ld a,00fh		;56e4   ; con el 0, el borde
L_56E6:
	ld (de),a			;56e6   ; a la fila nueva
	inc de			;56e7
	djnz L_56D5		;56e8   ; y el bit siguiente
	ret			;56ea
L_56EB:
	sla l		;56eb   ; el bit de mas peso
	rl h		;56ed
	ld a,09bh		;56ef   ; los tiles de la etapa 3
	jr c,L_56E6		;56f1
	ld a,004h		;56f3
	jr L_56E6		;56f5
L_56F7:
	ld a,(0e07ah)		;56f7
	cp 0feh		;56fa
	jr nz,L_5701		;56fc
	call monta_el_paisaje_de_la_etapa		;56fe
L_5701:
	call apunta_el_arcen_de_esta_fila		;5701
	ld a,(0e07ah)		;5704
	and 00fh		;5707
	call despacha_por_indice		;5709

; ----------------------------------------------------------------------
; DATOS tabla_de_paisaje: CINCO entradas, desde 0x5709 con el nibble bajo de
;   (0xE07A). No son seis: la sexta palabra seria 0x462A, que cae en la ROM
;   pero apunta a un `jr` de dentro del descompresor RLE. Esos dos bytes son
;   ya el `ld hl,(0e046h)` de L_5716, la rutina que 0x5540 llama con `call
;   05716h`
;   0x570c..0x5716  (10 bytes)
DATA_tabla_de_paisaje:
	defw 05768h,05810h,05810h,057a7h,057a7h	; 570c

; ======================================================================
; CODIGO 0x5716..0x5808  (242 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; CADA FOTOGRAMA, LA CARRETERA AVANZA AQUI. Retrocede el puntero del anillo veintidos posiciones -una fila entera- y mete en el hueco que queda la fila nueva de 0xE058. No se mueve un solo byte de paisaje: lo que se mueve es por donde empieza a leerse, y el volcado a la pantalla ya hace el resto. Los limites cuadran con la geometria que estaba medida: 0xE186 menos 22 da 0xE170, que es lo que se compara, y 0xE380 mas 22 da 0xE396, el final del anillo.
; ----------------------------------------------------------------------
corre_el_anillo:
	ld hl,(0e046h)		;5716   ; por donde va el anillo
	ld bc,0ffeah		;5719   ; veintidos atras: una fila
	add hl,bc			;571c
	ld (0e046h),hl		;571d   ; y ahi queda
	ld bc,0e170h		;5720   ; 0xE186 menos 22: antes del principio
	and a			;5723
	sbc hl,bc		;5724
	jr nz,L_572E		;5726   ; si no se ha pasado, se queda
	ld hl,0e380h		;5728   ; y si se ha pasado, al final del anillo
	ld (0e046h),hl		;572b
L_572E:
	ld de,(0e046h)		;572e   ; por donde va ahora
	ld hl,0e058h		;5732   ; la fila nueva
	ld bc,00016h		;5735   ; veintidos columnas
	ldir		;5738   ; y al anillo

; ----------------------------------------------------------------------
; Vuelca el anillo entero a la tabla de nombres: veinticuatro filas de VEINTIDOS columnas desde 0x3801, saltando 0x20 por fila porque la pantalla tiene 32. El anillo se recorre desde (0xE046), y al llegar a 0xE396 vuelve a 0xE186: eso es lo que hace que la carretera parezca no acabarse nunca. Las cinco columnas que sobran a cada lado son el marcador, que no se toca.
; ----------------------------------------------------------------------
vuelca_el_anillo:
	ld hl,03801h		;573a   ; la fila de arriba de la carretera
	ld a,018h		;573d   ; veinticuatro filas
	ld de,(0e046h)		;573f   ; por donde va el anillo
L_5743:
	ex af,af'			;5743   ; la cuenta, a salvo
	call 00053h		;5744   ; BIOS SETWRT - Enables VDP to write
	ld a,(00006h)		;5747   ; el puerto de datos del VDP
	ld c,a			;574a
	ld b,016h		;574b   ; veintidos columnas
L_574D:
	ld a,(de)			;574d   ; el byte del anillo
	out (c),a		;574e   ; y al VDP
	inc de			;5750
	djnz L_574D		;5751
	ld a,0e3h		;5753   ; el final del anillo
	cp d			;5755
	jr nz,L_5760		;5756
	ld a,096h		;5758
	cp e			;575a
	jr nz,L_5760		;575b
	ld de,0e186h		;575d   ; vuelta al principio: 0xE186
L_5760:
	ld c,020h		;5760   ; 32 bytes por fila de pantalla
	add hl,bc			;5762
	ex af,af'			;5763   ; la cuenta, de vuelta
	dec a			;5764
	jr nz,L_5743		;5765   ; y la fila siguiente
	ret			;5767

; ----------------------------------------------------------------------
; La tercera puerta del paisaje, la de los tramos anchos: copia un tile de borde y detras un tramo de tres, seis o nueve bytes segun los dos bits del nibble alto del modo. Al agotarse la cuenta de (0xE07B) se pasa al par siguiente del guion.
; ----------------------------------------------------------------------
arma_la_fila_de_un_tramo:
	ld hl,0e07bh		;5768   ; la cuenta del tramo
	dec (hl)			;576b
	jp z,pasa_al_tramo_de_paisaje_siguiente		;576c   ; al acabarse, el par siguiente del guion
	ld hl,(0e06fh)		;576f   ; por donde va el paisaje
	ld a,(hl)			;5772   ; el byte de cierre
	inc a			;5773
	jr nz,L_577C		;5774
	ld hl,05998h		;5776   ; vuelta al principio
	ld (0e06fh),hl		;5779
L_577C:
	ld a,(0e07dh)		;577c   ; el margen del arcen
	ld de,0e058h		;577f   ; la fila nueva
	add a,e			;5782   ; corrida ese margen
	ld e,a			;5783
L_5784:
	ldi		;5784   ; el tile del borde
	ld a,(0e07ah)		;5786   ; el modo
	rra			;5789   ; su nibble alto
	rra			;578a
	rra			;578b
	rra			;578c
	and 003h		;578d
	ld b,a			;578f   ; uno de cuatro
	sub 002h		;5790   ; dos menos, del reves
	neg		;5792
	ld c,a			;5794
	add a,a			;5795   ; por tres
	add a,c			;5796
	call suma_a_hl		;5797   ; y eso se salta
	inc b			;579a   ; uno mas
	ld a,b			;579b
	add a,a			;579c   ; por tres, otra vez
	add a,b			;579d
	ld c,a			;579e
	ld b,000h		;579f
	ldir		;57a1   ; el tramo
	ld (0e06fh),hl		;57a3   ; y ahi queda
	ret			;57a6

; ----------------------------------------------------------------------
; Arma la fila nueva del anillo: un byte de la tabla de 0x5808 -elegido por los tres bits de abajo de la cuenta- y detras un tramo del paisaje, tan largo como diga (0xE081). Al agotarse la cuenta se cambia de paisaje, y el nuevo sale de la tabla de punteros de 0x593A indexada con el nibble bajo del modo.
; ----------------------------------------------------------------------
arma_la_fila_del_paisaje:
	ld hl,05808h		;57a7   ; la tabla de ocho bytes
	ld a,(0e07bh)		;57aa   ; la cuenta del tramo
	and 007h		;57ad   ; sus tres bits de abajo
	call suma_a_hl		;57af
	ld a,(0e07dh)		;57b2   ; el margen del arcen
	ld de,0e058h		;57b5   ; la fila nueva
	add a,e			;57b8   ; corrida ese margen
	ld e,a			;57b9
	ldi		;57ba   ; el byte del borde
	ld hl,(0e06fh)		;57bc   ; por donde va el paisaje
	ld a,(0e081h)		;57bf   ; lo ancho que es
	ld c,a			;57c2
	sub 009h		;57c3   ; nueve menos
	neg		;57c5
	call suma_a_hl		;57c7   ; y ahi empieza
	ld b,000h		;57ca
	ldir		;57cc   ; el tramo entero
	inc hl			;57ce   ; dos bytes de salto
	inc hl			;57cf
	ld (0e06fh),hl		;57d0   ; y ahi queda por donde va
	ld hl,0e07bh		;57d3   ; la cuenta del tramo
	ld a,(hl)			;57d6
	sub 001h		;57d7   ; una menos
	ld (hl),a			;57d9
	jp m,pasa_al_tramo_de_paisaje_siguiente		;57da   ; y al pasarse, el par siguiente del guion
	ld a,(hl)			;57dd
	and 007h		;57de   ; uno de cada ocho
	ret nz			;57e0
	ld a,(hl)			;57e1
	and a			;57e2
	ret z			;57e3   ; y no cuando se acaba
	ld a,(0e07ah)		;57e4   ; el modo
	ld hl,0e081h		;57e7   ; la anchura
	inc (hl)			;57ea   ; una mas
	and 00fh		;57eb   ; el nibble bajo del modo
	cp 003h		;57ed   ; con el 3 se ensancha
	jr z,L_57F3		;57ef
	dec (hl)			;57f1   ; y si no, se estrecha
	dec (hl)			;57f2
L_57F3:
	ld a,(0e07ah)		;57f3   ; el modo
	ld b,a			;57f6
	and 00fh		;57f7   ; su nibble bajo
	add a,a			;57f9   ; por dos: son punteros
	ld hl,0593ah		;57fa   ; la tabla de paisajes
	call suma_a_hl		;57fd
	ld a,(hl)			;5800   ; el elegido
	inc hl			;5801
	ld h,(hl)			;5802
	ld l,a			;5803
	ld (0e06fh),hl		;5804   ; y a partir de ahi se lee
	ret			;5807

; ----------------------------------------------------------------------
; DATOS datos_5808: ocho bytes que carga 0x57a7
;   0x5808..0x5810  (8 bytes)
DATA_datos_5808:
	defb 0e7h,0e7h,0e6h,0e7h,0e7h,0e7h,0e6h,0e7h	; 5808  ........

; ======================================================================
; CODIGO 0x5810..0x58ab  (155 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La otra puerta, la de los tramos de una sola columna: en vez de copiar un tramo entero copia UN byte, y el margen de (0xE07D) es el que se va abriendo o cerrando.
; ----------------------------------------------------------------------
arma_la_fila_estrecha:
	ld hl,0e07bh		;5810   ; la cuenta del tramo
	dec (hl)			;5813
	jr z,L_5852		;5814   ; al agotarse, el par siguiente
	ld a,(hl)			;5816
	and 007h		;5817   ; uno de cada ocho
	jr nz,L_583E		;5819
	ld a,(0e07ah)		;581b   ; el modo
	and 00fh		;581e
	ld hl,0e07dh		;5820   ; el margen
	inc (hl)			;5823   ; uno mas
	cp 002h		;5824   ; con el 2 se abre
	jr z,L_582A		;5826
	dec (hl)			;5828   ; y si no, se cierra
	dec (hl)			;5829
L_582A:
	ld a,(0e07ah)		;582a   ; el modo
	ld b,a			;582d
	and 00fh		;582e
	add a,a			;5830   ; por dos
	ld hl,0593ah		;5831   ; la tabla de paisajes
	call suma_a_hl		;5834
	ld a,(hl)			;5837
	inc hl			;5838
	ld h,(hl)			;5839
	ld l,a			;583a
	ld (0e06fh),hl		;583b   ; y ese es el paisaje
L_583E:
	ld hl,(0e06fh)		;583e   ; por donde va
	ld a,(0e07dh)		;5841   ; el margen
	ld de,0e058h		;5844   ; la fila nueva
	add a,e			;5847
	ld e,a			;5848
	ldi		;5849   ; un solo byte
	call L_5784		;584b   ; el resto de la fila
	ld (0e06fh),hl		;584e   ; y ahi queda por donde va
	ret			;5851
L_5852:
	ld a,(0e07ah)		;5852   ; el modo
	and 00fh		;5855
	ld hl,0e07dh		;5857   ; el margen
	cp 001h		;585a   ; con el 1 se queda
	jr z,pasa_al_tramo_de_paisaje_siguiente		;585c
	inc (hl)			;585e   ; y si no, se abre uno

; ----------------------------------------------------------------------
; Saca del guion de paisaje el par siguiente -[modo, cuenta]- y monta el tramo: el nibble bajo del modo elige el dibujo en la tabla de 0x593A y, si vale 2, ademas cierra el arcen una casilla. Solo los modos 3 y 4 tienen anchura propia, que sale de la tabla de cuatro bytes de 0x58AB sumando el nibble alto.
; ----------------------------------------------------------------------
pasa_al_tramo_de_paisaje_siguiente:
	ld hl,(0e071h)		;585f   ; por donde va el guion
	ld de,0e07ah		;5862   ; el modo y su cuenta
	ld bc,00002h		;5865
	ldir		;5868
	ld (0e071h),hl		;586a   ; y ahi queda el guion
	ld a,(0e07ah)		;586d   ; el modo
	ld b,a			;5870
	and 00fh		;5871   ; su nibble bajo
	cp 002h		;5873   ; con el 2 se cierra el arcen
	jr nz,L_587B		;5875
	ld hl,0e07dh		;5877   ; el margen
	dec (hl)			;587a
L_587B:
	add a,a			;587b   ; por dos: son punteros
	ld hl,0593ah		;587c   ; la tabla de paisajes
	call suma_a_hl		;587f
	ld a,(hl)			;5882   ; el dibujo
	inc hl			;5883
	ld h,(hl)			;5884
	ld l,a			;5885
	ld (0e06fh),hl		;5886   ; y ahi arranca
	ld a,b			;5889   ; el modo, otra vez
	and 00fh		;588a
	sub 003h		;588c   ; solo el 3 y el 4
	cp 002h		;588e
	jp nc,L_56F7		;5890   ; los demas no tienen anchura propia
	ex af,af'			;5893   ; el nibble bajo, a salvo
	ld a,b			;5894
	rra			;5895   ; y el nibble alto
	rra			;5896
	rra			;5897
	rra			;5898
	and 00fh		;5899
	ld b,a			;589b
	ex af,af'			;589c
	add a,b			;589d   ; los dos juntos
	ld hl,058abh		;589e   ; la tabla de anchuras
	call suma_a_hl		;58a1
	ld a,(hl)			;58a4
	ld (0e081h),a		;58a5   ; lo ancho que sale el tramo
	jp L_56F7		;58a8

; ----------------------------------------------------------------------
; DATOS tabla_58ab: cuatro bytes (04 07 06 09) que 0x589e indexa con el nibble
;   alto del modo mas lo que quede en A
;   0x58ab..0x58af  (4 bytes)
DATA_tabla_58ab:
	defb 004h,007h,006h,009h	; 58ab

; ======================================================================
; CODIGO 0x58af..0x593a  (139 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PEGADOR DE TRAMOS DE CALZADA. Cada OCHO filas del anillo se coge un byte del guion de (0xE073): el nibble bajo elige un tramo en la tabla de esta etapa y el nibble alto, por dos, dice en que columna va. El tramo empieza por sus dos medidas -lo ancho y cuantas veces se repite- y detras van sus filas seguidas, que se van gastando una por fila de anillo. Un 0xFF en el guion no lo cierra: deja la cuenta en ocho y sigue con lo que hubiera.
; ----------------------------------------------------------------------
pega_un_tramo_de_calzada:
	ld hl,0e07fh		;58af   ; la cuenta de las ocho filas
	dec (hl)			;58b2
	jr z,L_58BF		;58b3   ; al agotarse, el tramo siguiente
	ld hl,0e086h		;58b5   ; las veces que se repite
	ld a,(hl)			;58b8
	cp 001h		;58b9   ; la ultima no se descuenta
	ret z			;58bb
	dec (hl)			;58bc   ; una menos
	jr L_58EC		;58bd
L_58BF:
	ld (hl),008h		;58bf   ; la cuenta, de vuelta a ocho
	ld hl,(0e073h)		;58c1   ; por donde va el guion
	inc hl			;58c4   ; el byte siguiente
	ld (0e073h),hl		;58c5
	ld a,(hl)			;58c8   ; el byte
	inc a			;58c9   ; si es 0xFF, no hay tramo
	jr z,L_58E7		;58ca
	dec a			;58cc   ; deshace el `inc a`
	and 00fh		;58cd   ; su nibble bajo
	add a,a			;58cf   ; por dos: son punteros
	ld hl,(0e075h)		;58d0   ; la tabla de tramos de la etapa
	call suma_a_hl		;58d3
	ld a,(hl)			;58d6   ; el tramo
	inc hl			;58d7
	ld h,(hl)			;58d8
	ld l,a			;58d9
	ld b,(hl)			;58da   ; lo ancho que es
	inc hl			;58db
	ld c,(hl)			;58dc   ; y cuantas veces se repite
	ld (0e085h),bc		;58dd   ; los dos juntos
	inc hl			;58e1
	ld (0e087h),hl		;58e2   ; y ahi empiezan sus filas
	jr L_58EC		;58e5
L_58E7:
	ld a,008h		;58e7   ; con el 0xFF, ocho de golpe
	ld (0e086h),a		;58e9
L_58EC:
	ld hl,(0e073h)		;58ec   ; por donde va el guion
	ld a,(hl)			;58ef   ; si es 0xFF, no hay nada que pegar
	inc a			;58f0
	ret z			;58f1
	dec a			;58f2
	rra			;58f3   ; el nibble alto
	rra			;58f4
	rra			;58f5
	rra			;58f6
	and 00fh		;58f7
	add a,a			;58f9   ; por dos
	ld de,0e058h		;58fa   ; la fila nueva
	add a,e			;58fd   ; y esa es la columna
	ld e,a			;58fe
	ld a,(0e085h)		;58ff   ; lo ancho que es
	ld c,a			;5902
	ld b,000h		;5903
	ld hl,(0e087h)		;5905   ; por donde va el tramo
	ldir		;5908   ; a la fila nueva
	ld (0e087h),hl		;590a   ; y ahi queda
	ret			;590d

; ----------------------------------------------------------------------
; Corre la cola del arcen una casilla hacia abajo y mete la nueva por arriba, con el margen en los seis bits de arriba y el modo en los dos de abajo. Es la MEMORIA de por donde iba la calzada en cada una de las veinticuatro filas: sin ella, un objeto que lleva veinte filas cayendo no sabria a que altura esta el borde.
; ----------------------------------------------------------------------
apunta_el_arcen_de_esta_fila:
	ld hl,0e0aeh		;590e   ; la ultima casilla
	ld de,0e0afh		;5911   ; una mas abajo
	ld bc,00017h		;5914   ; veintitres casillas
	lddr		;5917   ; todas hacia abajo
	ld a,(0e07ah)		;5919   ; el modo
	and 003h		;591c   ; sus dos bits de abajo
	ld c,a			;591e
	ld a,(0e07dh)		;591f   ; el margen
	sla a		;5922   ; a los seis bits de arriba
	sla a		;5924
	or c			;5926
	inc hl			;5927   ; la primera casilla, la de arriba
	ld (hl),a			;5928   ; y ahi queda la fila nueva
	ret			;5929

; ----------------------------------------------------------------------
; Deja la fila nueva entera del tile de fondo de (0xE089), los veintidos bytes: es el lienzo sobre el que las seis calzadas pintan lo suyo.
; ----------------------------------------------------------------------
llena_la_fila_de_fondo:
	ld hl,0e058h		;592a   ; la fila nueva
	ld de,0e059h		;592d
	ld a,(0e089h)		;5930   ; el tile del fondo
	ld (hl),a			;5933
	ld bc,00015h		;5934   ; veintiuna copias mas
	ldir		;5937
	ret			;5939

; ----------------------------------------------------------------------
; DATOS tabla_de_paisajes: cinco punteros a los tiles del paisaje; los indexa
;   0x587c con el nibble bajo del modo
;   0x593a..0x5944  (10 bytes)
DATA_tabla_de_paisajes:
	defw 05998h,059c1h,05a19h,05a1bh,059c3h	; 593a

; ======================================================================
; CODIGO 0x5944..0x596d  (41 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; A los 0x0F09 de recorrido EXACTOS pinta el rotulo de meta en el anillo, seis columnas dentro de la fila que sigue a la de arriba. En la etapa 6 no es el mismo: en vez de los once tiles de CHECK POINT van los cinco de GOAL, tres columnas mas a la derecha. Como la comparacion es de igualdad y no de mayor o igual, solo se pinta una vez.
; ----------------------------------------------------------------------
pinta_el_rotulo_de_meta:
	ld hl,(0e078h)		;5944   ; lo recorrido
	ld bc,00f09h		;5947   ; el hito del rotulo
	and a			;594a
	sbc hl,bc		;594b
	ret nz			;594d   ; y solo justo en ese
	ld hl,(0e046h)		;594e   ; por donde va el anillo
	ld bc,0001ch		;5951   ; una fila y seis columnas
	add hl,bc			;5954
	ex de,hl			;5955
	ld hl,0596dh		;5956   ; CHECK POINT
	ld c,00bh		;5959   ; once tiles
	ld a,(0e043h)		;595b   ; la etapa
	cp 006h		;595e   ; la sexta es la ultima
	jr nz,L_596A		;5960
	ld hl,05978h		;5962   ; y ahi pone GOAL
	ld c,005h		;5965   ; cinco tiles
	inc de			;5967   ; tres columnas mas a la derecha
	inc de			;5968
	inc de			;5969
L_596A:
	ldir		;596a   ; al anillo
	ret			;596c

; ----------------------------------------------------------------------
; DATOS rotulo_check_point: "CHECK POINT" en tiles: el indice de patron es el
;   ASCII menos 0x20, y DIBUJADO desde la VRAM del emulador sale la frase
;   entera. Lo pega 0x5956 al llegar a 0x0F09 de recorrido
;   0x596d..0x5978  (11 bytes)
DATA_rotulo_check_point:
	defb 023h,028h,025h,023h,02bh,000h,030h,02fh,029h,02eh,034h	; 596d  #(%#+.0/).4

; ----------------------------------------------------------------------
; DATOS rotulo_goal: "GOAL" y un tile en blanco: lo que se lee al rematar la
;   SEXTA etapa, en vez de CHECK POINT. Lo pega 0x5962, tres columnas mas a la
;   derecha
;   0x5978..0x597d  (5 bytes)
DATA_rotulo_goal:
	defb 027h,02fh,021h,02ch,03bh	; 5978

; ======================================================================
; CODIGO 0x597d..0x5998  (27 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La aguja del cuadro de mandos: lo recorrido por cuatro, el byte de arriba, y 0x6C menos eso es la Y del PRIMER sprite. O sea que la aguja va bajando segun se avanza en la etapa. Cada dieciseis fotogramas, ademas, le da la vuelta al bit 2 y al 1 de su color: eso es lo que la hace parpadear.
; ----------------------------------------------------------------------
baja_la_aguja:
	ld hl,(0e078h)		;597d   ; lo recorrido
	add hl,hl			;5980   ; por cuatro
	add hl,hl			;5981
	ld a,h			;5982   ; y el byte de arriba
	ld hl,0e10eh		;5983   ; el primer sprite de la copia
	sub 06ch		;5986   ; 0x6C menos eso
	neg		;5988
	ld (hl),a			;598a   ; y esa es su Y
	ld l,011h		;598b   ; el color de ese sprite
	ld a,(0e003h)		;598d   ; el reloj del juego
	and 00fh		;5990   ; uno de cada dieciseis
	ret nz			;5992
	ld a,006h		;5993   ; los dos bits del color
	xor (hl)			;5995   ; se les da la vuelta
	ld (hl),a			;5996
	ret			;5997

; ----------------------------------------------------------------------
; DATOS paisaje_de_salida: 40 bytes y su 0xFF; es el que 0x515a y 0x5776 ponen
;   en (0xE06F) al empezar
;   0x5998..0x59c1  (41 bytes)
DATA_paisaje_de_salida:
	defb 0e7h,0d0h,0d0h,0d1h,0d0h,0d0h,0d1h,0d0h,0d0h,0dfh,0e6h,0d0h,0d0h,0d0h,0d0h,0d0h	; 5998  ................
	defb 0d0h,0d0h,0d0h,0deh,0e7h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0dfh,0e7h,0d0h	; 59a8  ................
	defb 0d0h,0d1h,0d0h,0d0h,0d1h,0d0h,0d0h,0dfh,0ffh	; 59b8  .........

; ----------------------------------------------------------------------
; DATOS paisaje_1: entrada 1 de la tabla de 0x593a
;   0x59c1..0x59c3  (2 bytes)
DATA_paisaje_1:
	defb 0f2h,0e7h	; 59c1

; ----------------------------------------------------------------------
; DATOS paisaje_4: entrada 4 de la tabla de 0x593a
;   0x59c3..0x5a19  (86 bytes)
DATA_paisaje_4:
	defb 0d0h,0d0h,0d1h,0d0h,0d0h,0d1h,0d0h,0d0h,0dfh,0f8h,0e5h,0d0h,0d0h,0d0h,0d0h,0d0h	; 59c3  ................
	defb 0d0h,0d0h,0d0h,0e0h,0f7h,0e4h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0ech,0f6h	; 59d3  ................
	defb 0e3h,0d0h,0d0h,0d8h,0d0h,0d0h,0d8h,0d0h,0d9h,0edh,0f5h,0e2h,0d0h,0d3h,0d7h,0d0h	; 59e3  ................
	defb 0d3h,0d7h,0d0h,0dah,0eeh,0f4h,0e1h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0dbh,0efh	; 59f3  ................
	defb 0f3h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0dch,0f0h,0e8h,0d0h,0d0h,0d6h,0d0h	; 5a03  ................
	defb 0d0h,0d6h,0d0h,0d0h,0ddh,0f1h	; 5a13

; ----------------------------------------------------------------------
; DATOS paisaje_2: entrada 2 de la tabla de 0x593a
;   0x5a19..0x5a1b  (2 bytes)
DATA_paisaje_2:
	defb 0e7h,0d0h	; 5a19

; ----------------------------------------------------------------------
; DATOS paisaje_3: entrada 3 de la tabla de 0x593a
;   0x5a1b..0x5a71  (86 bytes)
DATA_paisaje_3:
	defb 0d0h,0d1h,0d0h,0d0h,0d1h,0d0h,0d0h,0dfh,0f2h,0e8h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h	; 5a1b  ................
	defb 0d0h,0d0h,0ddh,0f1h,0f3h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0dch,0f0h,0f4h	; 5a2b  ................
	defb 0e1h,0d0h,0d4h,0d0h,0d0h,0d4h,0d0h,0d0h,0dbh,0efh,0f5h,0e2h,0d0h,0d3h,0d7h,0d0h	; 5a3b  ................
	defb 0d3h,0d7h,0d0h,0dah,0eeh,0f6h,0e3h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d9h,0edh	; 5a4b  ................
	defb 0f7h,0e4h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0d0h,0ech,0f8h,0e5h,0d0h,0d0h,0d2h	; 5a5b  ................
	defb 0d0h,0d0h,0d2h,0d0h,0d0h,0e0h	; 5a6b

; ----------------------------------------------------------------------
; DATOS rle_sprites_1800: 292 bytes -> los 320 primeros de la tabla de
;   PATRONES DE SPRITE (0x1800, que fija R6=0x03): diez patrones de 16x16. El
;   destino va dentro del bloque. Lo carga 0x6931
;   0x5a71..0x5b95  (292 bytes)
DATA_rle_sprites_1800:
	defb 000h,018h,006h,000h,09ch,001h,003h,006h,000h,000h,003h,001h,000h,000h,003h,000h	; 5a71  ................
	defb 008h,014h,014h,004h,004h,0c6h,0e6h,036h,006h,006h,0e6h,0d6h,014h,004h,0e0h,003h	; 5a81  .......6........
	defb 007h,003h,00bh,002h,00fh,003h,007h,083h,00fh,00bh,00bh,003h,00fh,082h,0e0h,0f8h	; 5a91  ................
	defb 004h,0fch,081h,0feh,003h,0f6h,003h,0feh,002h,0fch,08bh,0f8h,003h,000h,000h,001h	; 5aa1  ................
	defb 003h,000h,000h,006h,003h,001h,006h,000h,096h,0e0h,004h,014h,0d4h,0e6h,006h,006h	; 5ab1  ................
	defb 036h,0e6h,0c6h,006h,004h,014h,014h,00ch,018h,00fh,00fh,00bh,00bh,00fh,00fh,003h	; 5ac1  6...............
	defb 007h,002h,00fh,003h,00bh,083h,007h,003h,0f8h,003h,0fch,002h,0feh,003h,0f6h,002h	; 5ad1  ................
	defb 0feh,004h,0fch,081h,0f8h,005h,000h,08bh,007h,001h,000h,008h,00ch,006h,043h,020h	; 5ae1  ..............C 
	defb 011h,00ch,007h,004h,000h,0a0h,001h,085h,0c9h,0e3h,066h,02ch,028h,018h,038h,070h	; 5af1  ..........f,(.8p
	defb 0c0h,080h,000h,001h,003h,003h,006h,007h,01fh,03fh,06fh,05fh,07fh,07fh,03fh,01fh	; 5b01  .........?o_..?.
	defb 00fh,007h,0f8h,0dch,0beh,07eh,004h,0ffh,088h,0feh,0fch,0e8h,0d8h,0f8h,0f0h,0c0h	; 5b11  .....~..........
	defb 080h,004h,000h,082h,001h,089h,003h,098h,085h,089h,001h,000h,07fh,01fh,006h,000h	; 5b21  ................
	defb 082h,00ch,080h,003h,0c0h,085h,080h,01ch,002h,0fch,0c0h,005h,000h,082h,0fch,0e7h	; 5b31  ................
	defb 005h,0ffh,084h,0dfh,0fch,07fh,01fh,005h,000h,082h,07ch,0eeh,005h,0ffh,095h,0feh	; 5b41  ..........|.....
	defb 07eh,0fch,0c0h,000h,000h,010h,020h,040h,086h,08ch,018h,010h,001h,003h,017h,018h	; 5b51  ~..... @........
	defb 00ch,00eh,007h,003h,005h,000h,002h,040h,002h,0c0h,08bh,080h,000h,000h,081h,043h	; 5b61  .......@.......C
	defb 006h,0fch,0f8h,01eh,03bh,07dh,003h,0ffh,089h,0dfh,07fh,03fh,017h,01fh,00fh,00fh	; 5b71  ....;}.....?....
	defb 007h,003h,003h,000h,002h,080h,08ch,0e0h,0f0h,0f8h,0ech,0f6h,0fah,0feh,0ffh,0ffh	; 5b81  ................
	defb 0feh,0fch,0f8h,000h	; 5b91

; ----------------------------------------------------------------------
; DATOS rle_sprites_1a00: 599 bytes -> 800 de PATRONES DE SPRITE en 0x1a00:
;   veinticinco patrones de 16x16. El destino va dentro del bloque. Lo carga
;   0x6942
;   0x5b95..0x5dec  (599 bytes)
DATA_rle_sprites_1a00:
	defb 000h,01ah,0f3h,000h,040h,031h,018h,056h,00bh,086h,003h,01dh,033h,002h,026h,008h	; 5b95  ....@1.V....3.&.
	defb 014h,008h,000h,000h,052h,004h,0a0h,0d1h,0f4h,0d8h,0b0h,0e8h,0edh,060h,030h,018h	; 5ba5  ....R........`0.
	defb 008h,004h,002h,000h,044h,033h,03fh,05eh,09fh,037h,01fh,03fh,077h,00ah,067h,00eh	; 5bb5  ....D3?^.7.?w.g.
	defb 01ch,03ah,040h,082h,0d6h,0dch,0f4h,0f9h,0f6h,0fch,0ffh,0fch,0fdh,0fdh,0f8h,0dch	; 5bc5  .:@.............
	defb 0deh,046h,043h,000h,002h,009h,002h,028h,013h,00ch,012h,04ah,010h,029h,004h,020h	; 5bd5  .FC....(...J.). 
	defb 002h,010h,000h,000h,080h,010h,0aah,0d4h,000h,0c4h,06ch,044h,0e0h,002h,0c0h,008h	; 5be5  ..........lD....
	defb 090h,020h,000h,000h,01ah,039h,002h,06eh,017h,0cfh,093h,04eh,01eh,02fh,046h,0e8h	; 5bf5  . ...9.n...N./F.
	defb 062h,017h,003h,040h,09ah,01ch,08ch,0eeh,0d4h,060h,0f5h,06fh,0e4h,0fah,0b2h,0d1h	; 5c05  b..@.....`.o....
	defb 04ch,09ch,0bah,003h,000h,082h,010h,003h,004h,000h,081h,007h,009h,000h,08bh,008h	; 5c15  L...............
	defb 0c0h,000h,028h,028h,008h,0ech,004h,004h,016h,006h,003h,016h,08dh,000h,007h,017h	; 5c25  ..((............
	defb 00fh,00dh,00bh,00bh,00dh,007h,01fh,01ch,01bh,01fh,003h,017h,085h,000h,0e0h,0e8h	; 5c35  ................
	defb 0f0h,0b0h,003h,0f8h,081h,0ech,002h,0fch,005h,0feh,00fh,000h,081h,007h,00bh,016h	; 5c45  ................
	defb 003h,006h,082h,00eh,0fch,00bh,017h,085h,01fh,01ch,013h,01fh,007h,00ch,0feh,084h	; 5c55  ................
	defb 03eh,0ceh,0feh,0fch,005h,000h,087h,007h,006h,006h,007h,006h,006h,007h,009h,000h	; 5c65  >...............
	defb 087h,0c0h,060h,040h,080h,040h,060h,0c0h,006h,000h,092h,03ch,06eh,0dfh,0dfh,0ffh	; 5c75  ..`@.@`....<n...
	defb 0ffh,06fh,06fh,03fh,01fh,00fh,007h,003h,001h,000h,000h,078h,0fch,004h,0feh,002h	; 5c85  .oo?.......x....
	defb 0fch,085h,0f8h,0f0h,0e0h,0c0h,080h,004h,000h,084h,007h,00ch,009h,00ah,004h,008h	; 5c95  ................
	defb 082h,00ch,007h,006h,000h,082h,0c0h,060h,006h,020h,082h,060h,0c0h,007h,000h,083h	; 5ca5  .......`. .`....
	defb 003h,006h,005h,004h,007h,081h,003h,008h,000h,081h,080h,006h,0c0h,081h,080h,009h	; 5cb5  ................
	defb 000h,083h,001h,003h,007h,003h,00fh,081h,007h,009h,000h,086h,0c0h,0e0h,0a0h,060h	; 5cc5  ...............`
	defb 0c0h,080h,00bh,000h,085h,007h,00dh,00bh,00fh,007h,00bh,000h,081h,0e0h,003h,0f0h	; 5cd5  ................
	defb 081h,0e0h,005h,000h,005h,000h,086h,003h,006h,007h,007h,003h,001h,00ah,000h,083h	; 5ce5  ................
	defb 080h,0c0h,060h,003h,0f0h,081h,0e0h,00ah,000h,083h,001h,003h,002h,005h,000h,083h	; 5cf5  ..`.............
	defb 004h,003h,000h,002h,010h,003h,004h,084h,0e6h,0f6h,016h,006h,002h,016h,086h,006h	; 5d05  ................
	defb 004h,00ch,0f0h,003h,006h,003h,005h,082h,007h,003h,003h,007h,002h,005h,085h,006h	; 5d15  ................
	defb 007h,004h,003h,0f0h,002h,0f8h,003h,0fch,081h,0f6h,006h,0feh,083h,0fch,00ch,0f0h	; 5d25  ................
	defb 005h,000h,083h,001h,003h,006h,003h,000h,08dh,001h,003h,000h,000h,007h,000h,000h	; 5d35  ................
	defb 010h,014h,004h,0c4h,0e6h,036h,003h,006h,002h,0e6h,085h,014h,004h,0f0h,003h,007h	; 5d45  .....6..........
	defb 004h,00dh,002h,00fh,002h,007h,082h,00fh,00dh,004h,00fh,082h,0e0h,0f0h,004h,0f8h	; 5d55  ................
	defb 002h,0feh,002h,0f0h,006h,0f8h,086h,000h,001h,003h,007h,005h,001h,00bh,000h,085h	; 5d65  ................
	defb 040h,060h,070h,050h,040h,00ah,000h,082h,003h,007h,005h,00fh,084h,00eh,004h,009h	; 5d75  @`pP@...........
	defb 00fh,002h,00bh,085h,00dh,00fh,00ch,0e0h,0f0h,004h,0f8h,085h,0fch,034h,014h,0cch	; 5d85  .............4..
	defb 0fch,002h,0ech,002h,0f8h,081h,018h,004h,000h,089h,063h,094h,014h,014h,064h,014h	; 5d95  ..........c...d.
	defb 014h,094h,063h,007h,000h,081h,018h,007h,0a4h,081h,018h,007h,000h,081h,0f3h,003h	; 5da5  ..c.............
	defb 084h,085h,0e4h,014h,014h,094h,063h,007h,000h,081h,018h,007h,0a4h,081h,018h,006h	; 5db5  ......c.........
	defb 000h,081h,063h,003h,094h,081h,064h,003h,094h,081h,063h,007h,000h,081h,018h,007h	; 5dc5  ..c...d...c.....
	defb 0a4h,081h,018h,007h,000h,082h,048h,0d5h,006h,055h,081h,0e8h,007h,000h,081h,088h	; 5dd5  ......H..U......
	defb 007h,054h,081h,088h,004h,000h,000h	; 5de5

; ----------------------------------------------------------------------
; DATOS rle_patron_2200: 345 bytes -> los 512 de PATRON de 0x2200 a 0x2400 (64
;   tiles). Lo carga 0x68b0. OJO: sus ultimos 32 bytes son tambien el arranque
;   del bloque siguiente
;   0x5dec..0x5f45  (345 bytes)
DATA_rle_patron_2200:
	defb 008h,0feh,008h,07fh,010h,0ffh,0b0h,0ffh,0fch,0f8h,0f0h,0f0h,0f0h,0f8h,0fch,0ffh	; 5dec  ................
	defb 03fh,01fh,00fh,00fh,00fh,01fh,03fh,0ffh,0fch,0f8h,0f0h,0f0h,0f0h,0f8h,0fch,0ffh	; 5dfc  ?.....?.........
	defb 03fh,01fh,00fh,00fh,00fh,01fh,03fh,0ffh,0fch,0f8h,0f0h,0f0h,0f0h,0f8h,0fch,0ffh	; 5e0c  ?.....?.........
	defb 03fh,01fh,00fh,00fh,00fh,01fh,03fh,008h,000h,084h,0efh,0e3h,0c0h,0c3h,002h,0bfh	; 5e1c  ?.....?.........
	defb 083h,07fh,080h,000h,002h,0ffh,002h,000h,002h,0ffh,002h,000h,002h,0ffh,002h,000h	; 5e2c  ................
	defb 002h,0ffh,005h,000h,004h,0ffh,081h,000h,008h,0ffh,083h,0fch,0f0h,0e0h,002h,0c0h	; 5e3c  ................
	defb 002h,080h,086h,0ffh,03fh,00fh,007h,003h,0fch,002h,0feh,002h,080h,002h,0c0h,084h	; 5e4c  ....?...........
	defb 0e0h,0f0h,0fch,0ffh,002h,0feh,002h,0fch,083h,007h,00fh,03fh,003h,0ffh,086h,0dfh	; 5e5c  ...........?....
	defb 0ffh,0ffh,0fdh,0ffh,0dfh,00ch,0f0h,004h,000h,088h,0ffh,000h,0ffh,000h,0ffh,000h	; 5e6c  ................
	defb 0ffh,000h,008h,003h,008h,0c0h,086h,000h,07bh,042h,07bh,00ah,07ah,003h,000h,085h	; 5e7c  ........{B{.z...
	defb 0ddh,051h,0ddh,011h,01dh,003h,000h,085h,0dch,016h,0d2h,016h,0dch,003h,000h,085h	; 5e8c  .Q..............
	defb 00eh,008h,00eh,008h,008h,003h,000h,085h,097h,094h,097h,094h,067h,003h,000h,004h	; 5e9c  ............g...
	defb 040h,081h,070h,002h,000h,084h,060h,07ch,07fh,07ch,004h,060h,008h,00fh,008h,0f0h	; 5eac  @.p...`|.|.`....
	defb 008h,00fh,008h,0ffh,008h,0f0h,008h,00fh,008h,0ffh,008h,0f0h,008h,00fh,008h,0ffh	; 5ebc  ................
	defb 008h,0f0h,008h,00fh,008h,0ffh,008h,0f0h,006h,000h,002h,0ffh,008h,0c0h,008h,003h	; 5ecc  ................
	defb 002h,0ffh,006h,000h,008h,003h,004h,000h,081h,001h,002h,003h,081h,007h,003h,000h	; 5edc  ................
	defb 085h,0f0h,0f8h,0cch,0eeh,0f6h,002h,007h,088h,033h,023h,00bh,01bh,019h,000h,0f6h	; 5eec  .........3#.....
	defb 0eeh,002h,0fch,084h,0f8h,0f0h,0c0h,000h,003h,000h,0bdh,003h,007h,007h,00fh,00fh	; 5efc  ................
	defb 000h,000h,0f0h,0f8h,0feh,0e7h,0e7h,0f7h,00fh,06fh,047h,007h,017h,037h,073h,021h	; 5f0c  .........oG..7s!
	defb 0ffh,0f7h,0eeh,0feh,0fch,0f8h,0e0h,0c0h,000h,016h,02fh,084h,0ffh,000h,044h,0ffh	; 5f1c  ........../...D.
	defb 006h,02fh,0b0h,04ah,00ah,04ah,00ah,04ah,00ah,04ah,00ah,04ah,00ah,04ah,00ah,04ah	; 5f2c  ./.J.J.J.J.J.J.J
	defb 00ah,04ah,00ah,040h,000h,040h,000h,040h,000h	; 5f3c  .J.@.@.@.

; ----------------------------------------------------------------------
; DATOS rle_color_0200: cola del bloque de 0x5f25, que el cartucho carga al
;   COLOR de 0x0200 desde 0x68b9
;   0x5f45..0x5fec  (167 bytes)
DATA_rle_color_0200:
	defb 040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,042h,002h,042h,002h,042h,002h	; 5f45  @.@.@.@.@.B.B.B.
	defb 042h,002h,042h,002h,042h,002h,042h,002h,042h,002h,008h,000h,007h,02fh,081h,0f0h	; 5f55  B.B.B.B.B..../..
	defb 008h,089h,008h,068h,008h,020h,008h,0e0h,008h,02ah,005h,02dh,003h,0d0h,008h,02dh	; 5f65  ...h. ...*.-...-
	defb 004h,0a0h,004h,02ah,008h,02bh,010h,012h,008h,014h,002h,0efh,002h,0edh,002h,0efh	; 5f75  ...*.+..........
	defb 002h,0edh,002h,0efh,002h,0edh,002h,0efh,002h,0edh,030h,0f0h,008h,0d0h,011h,040h	; 5f85  ..........0....@
	defb 097h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h	; 5f95  ..@.@.@.@.@.@.@.
	defb 040h,0f0h,040h,0f0h,040h,0f0h,040h,0f0h,003h,040h,085h,0f0h,040h,0f0h,040h,0f0h	; 5fa5  @.@.@.@..@..@.@.
	defb 003h,040h,085h,0f0h,040h,0f0h,040h,0f0h,003h,040h,085h,0f0h,040h,0f0h,040h,0f0h	; 5fb5  .@..@.@..@..@.@.
	defb 005h,040h,083h,0f0h,040h,0f0h,005h,040h,083h,0f0h,040h,0f0h,005h,040h,083h,0f0h	; 5fc5  .@..@..@..@..@..
	defb 040h,0f0h,007h,040h,081h,0f0h,007h,040h,081h,0f0h,007h,040h,081h,0f0h,020h,070h	; 5fd5  @..@...@...@.. p
	defb 008h,0f0h,020h,01eh,020h,05eh,000h	; 5fe5

; ----------------------------------------------------------------------
; DATOS rle_patron_2680: 11 bytes -> 40 de PATRON en 0x2680. Lo carga 0x68c2
;   0x5fec..0x5ff7  (11 bytes)
DATA_rle_patron_2680:
	defb 008h,0ffh,008h,0e7h,008h,0cfh,008h,0feh,008h,0fch,000h	; 5fec  ...........

; ----------------------------------------------------------------------
; DATOS rle_patron_26c8: 17 bytes -> 64 de PATRON en 0x26c8. Lo carga 0x68e8
;   0x5ff7..0x6008  (17 bytes)
DATA_rle_patron_26c8:
	defb 008h,0feh,008h,0fch,008h,0f8h,008h,0f0h,008h,0e0h,008h,0c0h,008h,0c0h,008h,080h	; 5ff7  ................
	defb 000h	; 6007

; ----------------------------------------------------------------------
; DATOS rle_patron_2748: 21 bytes -> 80 de PATRON en 0x2748. Lo carga 0x690e
;   0x6008..0x601d  (21 bytes)
DATA_rle_patron_2748:
	defb 008h,07eh,008h,03ch,008h,018h,008h,003h,008h,007h,008h,00fh,008h,01fh,008h,03fh	; 6008  .~.<...........?
	defb 008h,07fh,008h,0ffh,000h	; 6018

; ----------------------------------------------------------------------
; DATOS rle_color_0680: 5 bytes -> 40 de COLOR en 0x0680. Lo carga 0x68cb.
;   SOLAPE: no cierra en 0x601F sino en 0x6022, o sea que sus tres ultimos
;   bytes son el bloque entero de 0x601F. Solo se declaran aqui los dos que
;   son suyos, para que el presupuesto no los cuente dos veces
;   0x601d..0x601f  (2 bytes)
DATA_rle_color_0680:
	defb 008h,0eeh	; 601d

; ----------------------------------------------------------------------
; DATOS rle_color_06a8: 3 bytes -> 32 de COLOR en 0x06a8. Lo carga 0x68df
;   0x601f..0x6022  (3 bytes)
DATA_rle_color_06a8:
	defb 020h,0efh,000h	; 601f

; ----------------------------------------------------------------------
; DATOS rle_color_06c8: 11 bytes -> 64 de COLOR; lo cargan 0x68f1 (a 0x06c8) y
;   0x6905 (a 0x0708), el mismo bloque en dos sitios
;   0x6022..0x602d  (11 bytes)
DATA_rle_color_06c8:
	defb 01dh,0efh,003h,0e0h,00dh,0efh,003h,0e0h,010h,0efh,000h	; 6022  ...........

; ----------------------------------------------------------------------
; DATOS rle_color_0748: 17 bytes -> 88 de COLOR en 0x0748. Lo carga 0x6917.
;   SOLAPE: no cierra en 0x6031 sino en 0x603E, o sea que sus trece ultimos
;   bytes son el bloque entero de 0x6031. Solo se declaran aqui los cuatro que
;   son suyos, para que el presupuesto no los cuente dos veces
;   0x602d..0x6031  (4 bytes)
DATA_rle_color_0748:
	defb 015h,02fh,003h,020h	; 602d

; ----------------------------------------------------------------------
; DATOS rle_color_0798: 13 bytes -> 64 de COLOR en 0x0798. Lo carga 0x692b
;   0x6031..0x603e  (13 bytes)
DATA_rle_color_0798:
	defb 005h,02fh,003h,020h,01dh,02fh,003h,020h,010h,02fh,008h,020h,000h	; 6031  ./. ./. ./. .

; ----------------------------------------------------------------------
; DATOS decorado_1_patron: 394 bytes -> 496 de PATRON en 0x2400. Etapa 1
;   0x603e..0x61c8  (394 bytes)
DATA_decorado_1_patron:
	defb 09ah,0bch,07eh,0bbh,07fh,018h,081h,0cbh,07eh,0ffh,07fh,03fh,01fh,00fh,007h,003h	; 603e  ..~.....~..?....
	defb 001h,000h,001h,003h,007h,00fh,01fh,03fh,07fh,0e3h,0e3h,004h,0ffh,002h,0e3h,008h	; 604e  .......?........
	defb 080h,09ah,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,07fh,03fh,01fh,00fh,007h,003h	; 605e  .......?...?....
	defb 001h,000h,03fh,09fh,00fh,00fh,08fh,01fh,01fh,0bfh,0ffh,0ffh,010h,01fh,006h,0ffh	; 606e  ..?.............
	defb 002h,000h,006h,0ffh,002h,0c0h,006h,0ffh,08fh,018h,06ch,0bah,0dfh,0bfh,0dfh,0bdh	; 607e  ..........l.....
	defb 06ah,0ffh,0ffh,0a3h,0c1h,000h,0c1h,0efh,003h,0ffh,002h,080h,081h,0ffh,003h,081h	; 608e  j...............
	defb 085h,001h,0ffh,001h,001h,0ffh,003h,001h,008h,0ffh,085h,000h,0ffh,001h,001h,0ffh	; 609e  ................
	defb 00bh,081h,002h,001h,081h,0ffh,005h,001h,009h,0ffh,082h,080h,0ffh,005h,000h,084h	; 60ae  ................
	defb 0ffh,001h,0ffh,001h,004h,000h,009h,0ffh,082h,001h,0ffh,005h,000h,08eh,0ffh,07fh	; 60be  ................
	defb 03fh,01fh,00fh,007h,003h,000h,0ffh,0ffh,0efh,0e7h,0e3h,0f3h,004h,0ffh,08eh,0fch	; 60ce  ?...............
	defb 0f8h,0f0h,0e0h,0c0h,000h,0fch,0f8h,0f0h,0e0h,0c0h,080h,080h,000h,003h,0ffh,096h	; 60de  ................
	defb 0f3h,0e3h,0e7h,0efh,0ffh,03fh,01fh,00fh,007h,003h,003h,001h,000h,000h,004h,020h	; 60ee  .....?......... 
	defb 000h,000h,040h,002h,000h,0ffh,006h,0c0h,082h,0f0h,000h,006h,0feh,003h,000h,003h	; 60fe  ..@.............
	defb 020h,083h,01ch,000h,000h,003h,0ffh,005h,0aah,084h,0ffh,03fh,00fh,003h,003h,018h	; 610e   ..........?....
	defb 085h,000h,0ffh,0fch,0f0h,0c0h,003h,018h,081h,000h,005h,0aah,003h,0ffh,081h,000h	; 611e  ................
	defb 003h,018h,085h,003h,00fh,03fh,0ffh,000h,003h,018h,09ch,0c0h,0f0h,0fch,0ffh,0fdh	; 612e  .....?..........
	defb 0f8h,0f0h,0f9h,0ffh,0f4h,0f8h,0f1h,0ffh,07fh,03fh,07fh,0ffh,0ffh,03fh,07fh,0ffh	; 613e  .........?...?..
	defb 0c9h,0c3h,0c7h,0c2h,0c8h,07fh,007h,003h,0ffh,083h,088h,0aah,08ah,005h,0ffh,083h	; 614e  ................
	defb 0cch,0adh,095h,003h,0ffh,08ah,0f7h,0ffh,017h,057h,057h,0feh,0e0h,0ffh,0ffh,03fh	; 615e  .........WW....?
	defb 003h,01fh,086h,03fh,0ffh,01ch,0ffh,080h,088h,004h,080h,08dh,038h,0ffh,001h,001h	; 616e  ...?........8...
	defb 009h,001h,041h,001h,080h,084h,080h,080h,0a0h,003h,080h,0abh,001h,009h,001h,001h	; 617e  ..A.............
	defb 021h,001h,001h,009h,03fh,0f8h,0e0h,0c0h,0c1h,081h,08dh,087h,0fch,01fh,007h,083h	; 618e  !...?...........
	defb 023h,001h,0a1h,0c1h,083h,086h,080h,0c0h,0c1h,0e0h,0f8h,03fh,091h,089h,041h,003h	; 619e  #..........?..A.
	defb 003h,007h,01fh,0fch,0ffh,07fh,07fh,00bh,03fh,085h,07fh,0ffh,088h,080h,080h,005h	; 61ae  ........?.......
	defb 0ffh,083h,001h,041h,001h,009h,0ffh,004h,000h,000h	; 61be  ...A......

; ----------------------------------------------------------------------
; DATOS decorado_1_color: 177 bytes -> 496 de COLOR en 0x0400. Etapa 1
;   0x61c8..0x6279  (177 bytes)
DATA_decorado_1_color:
	defb 002h,02ch,002h,02fh,081h,02ch,003h,00ch,008h,057h,008h,045h,008h,07fh,008h,0f4h	; 61c8  .,./.,...W.E....
	defb 008h,057h,008h,045h,030h,020h,003h,0a2h,003h,0afh,002h,0a2h,008h,020h,085h,080h	; 61d8  .W.E0 ....... ..
	defb 0f0h,0f8h,0f8h,0f0h,00bh,0f8h,085h,080h,0f0h,080h,080h,0f0h,003h,080h,018h,0f8h	; 61e8  ................
	defb 002h,080h,081h,0f0h,005h,080h,010h,0f8h,083h,0f0h,080h,0f0h,005h,080h,008h,0f8h	; 61f8  ................
	defb 008h,089h,007h,08eh,081h,090h,008h,086h,008h,098h,008h,08eh,008h,068h,008h,0b2h	; 6208  .............h..
	defb 004h,025h,003h,024h,085h,020h,052h,052h,050h,050h,004h,040h,008h,045h,003h,020h	; 6218  .%.$. RRPP.@.E. 
	defb 005h,0efh,004h,0beh,004h,06eh,004h,0beh,004h,06eh,005h,0efh,003h,020h,004h,06eh	; 6228  .....n...n... .n
	defb 004h,0aeh,004h,06eh,004h,0aeh,005h,02dh,003h,02ah,008h,020h,006h,0f4h,002h,0f2h	; 6238  ...n...-.*. ....
	defb 007h,0f4h,081h,020h,007h,0f4h,081h,020h,006h,0f4h,002h,0f2h,008h,020h,081h,0f2h	; 6248  ... ... ..... ..
	defb 007h,0f7h,081h,0f2h,017h,0f7h,081h,0f2h,007h,0f7h,081h,0f0h,00eh,0f7h,081h,0f2h	; 6258  ................
	defb 007h,0f7h,081h,0f0h,010h,020h,004h,0f7h,004h,020h,004h,0f7h,004h,020h,008h,028h	; 6268  ..... ... ... .(
	defb 000h	; 6278

; ----------------------------------------------------------------------
; DATOS decorado_2_patron: 307 bytes -> 392 de PATRON en 0x2400. Etapa 2
;   0x6279..0x63ac  (307 bytes)
DATA_decorado_2_patron:
	defb 003h,002h,002h,008h,003h,002h,003h,000h,002h,080h,003h,000h,0afh,000h,006h,003h	; 6279  ................
	defb 001h,001h,01ch,027h,003h,000h,000h,006h,03eh,072h,0c0h,09ch,0feh,007h,00ch,018h	; 6289  ...'....>r......
	defb 018h,038h,030h,0f0h,0f0h,071h,0f9h,0c3h,0a7h,0fch,0e3h,01fh,0ffh,09fh,0cfh,04bh	; 6299  .80..q.........K
	defb 087h,087h,013h,0dbh,097h,0ffh,0ffh,0fch,0e0h,0c0h,0e0h,0fch,003h,0ffh,085h,03fh	; 62a9  ...............?
	defb 0fch,0feh,0fch,03fh,004h,0ffh,08ah,0e1h,080h,0c6h,0bch,0fdh,0fdh,0bch,0feh,080h	; 62b9  ...?............
	defb 0e1h,006h,0ffh,08ah,0c3h,0fch,0feh,0e7h,0e7h,0f7h,0e7h,0feh,0fch,0c3h,008h,0ffh	; 62c9  ................
	defb 006h,07fh,005h,0ffh,08ah,001h,007h,00fh,01fh,00fh,007h,001h,000h,0ffh,091h,003h	; 62d9  ................
	defb 011h,084h,091h,0ffh,0ffh,07fh,005h,03fh,0a6h,07fh,0ffh,0ffh,0fch,0f0h,0e0h,0c0h	; 62e9  .......?........
	defb 0c0h,080h,080h,000h,0c0h,0f0h,0f8h,0fch,0fch,0feh,0feh,07fh,07fh,03fh,03fh,01fh	; 62f9  .............??.
	defb 00fh,003h,000h,0feh,0feh,0fch,0fch,0f8h,0f0h,0c0h,000h,0ffh,03fh,00fh,003h,004h	; 6309  ............?...
	defb 000h,084h,0ffh,0fch,0f0h,0c0h,004h,000h,008h,030h,008h,00ch,004h,000h,084h,003h	; 6319  .........0......
	defb 00fh,03fh,0ffh,004h,000h,086h,0c0h,0f0h,0fch,0ffh,0ffh,0fbh,010h,01fh,086h,0ffh	; 6329  .?..............
	defb 0fbh,0ffh,0ffh,0efh,0ffh,003h,000h,08dh,002h,000h,020h,002h,000h,0c0h,0c0h,000h	; 6339  .......... .....
	defb 002h,000h,020h,000h,000h,008h,0f0h,004h,000h,088h,003h,00fh,03fh,0ffh,0ffh,03fh	; 6349  .. .........?..?
	defb 00fh,003h,005h,000h,08bh,0c0h,0f0h,0fch,0feh,0ffh,0b0h,0b6h,000h,003h,00fh,03fh	; 6359  ...............?
	defb 004h,07fh,003h,0b6h,085h,086h,0ffh,0ffh,080h,0b6h,008h,07fh,004h,0b6h,002h,0ffh	; 6369  ................
	defb 08ah,087h,0e9h,0efh,0eeh,0e9h,087h,003h,00fh,03fh,0ffh,004h,07fh,084h,03fh,00fh	; 6379  .........?....?.
	defb 003h,000h,008h,0aah,081h,0ffh,006h,0c0h,082h,0f0h,0ffh,006h,0feh,089h,000h,0ffh	; 6389  ................
	defb 0d6h,000h,0d6h,000h,0d6h,0ffh,0ffh,008h,0feh,088h,01fh,0bfh,0bfh,01fh,0bfh,0bfh	; 6399  ................
	defb 01fh,0bfh,000h	; 63a9

; ----------------------------------------------------------------------
; DATOS rle_patron_2588: 133 bytes -> 192 de PATRON en 0x2588. Lo carga
;   0x6992, solo en la etapa 2
;   0x63ac..0x6431  (133 bytes)
DATA_rle_patron_2588:
	defb 003h,007h,003h,003h,002h,001h,003h,003h,003h,001h,007h,000h,003h,001h,003h,003h	; 63ac  ................
	defb 003h,007h,002h,00fh,003h,01fh,003h,03fh,002h,07fh,003h,03fh,003h,01fh,002h,00fh	; 63bc  .......?...?....
	defb 003h,0fch,003h,0feh,005h,0ffh,003h,0feh,005h,0ffh,003h,0feh,005h,0fch,003h,0f8h	; 63cc  ................
	defb 002h,0f0h,005h,0ffh,003h,0feh,003h,0f8h,085h,0f0h,0c0h,080h,000h,000h,003h,0fch	; 63dc  ................
	defb 087h,0f8h,0e0h,0c0h,080h,080h,07fh,03fh,003h,01fh,002h,03fh,089h,07fh,0c0h,0e0h	; 63ec  .......?...?....
	defb 0f8h,0fch,0fch,0feh,0feh,0ffh,003h,0fch,003h,0feh,002h,0ffh,08bh,0c7h,0e1h,0f9h	; 63fc  ................
	defb 0fch,0fch,0feh,0ffh,0feh,0fdh,0fch,0fch,003h,0f9h,082h,0f1h,0f3h,003h,0ffh,004h	; 640c  ................
	defb 0feh,002h,0fdh,002h,0fch,002h,0feh,003h,0ffh,083h,000h,002h,020h,003h,000h,082h	; 641c  ............ ...
	defb 044h,000h,018h,0ffh,000h	; 642c

; ----------------------------------------------------------------------
; DATOS decorado_2_color: 153 bytes -> 584 de COLOR en 0x0400. Etapa 2
;   0x6431..0x64ca  (153 bytes)
DATA_decorado_2_color:
	defb 003h,08bh,002h,048h,003h,08bh,008h,01bh,010h,0cbh,006h,06bh,002h,060h,004h,0bch	; 6431  ...H.......k.`..
	defb 00ch,0b0h,004h,0bdh,081h,0b8h,006h,0bdh,085h,0d0h,080h,0d0h,0bdh,0bdh,004h,0b0h	; 6441  ................
	defb 081h,0bch,006h,0cfh,081h,0bch,008h,0b0h,002h,0c0h,004h,0cfh,002h,0c0h,014h,0b0h	; 6451  ................
	defb 008h,05bh,007h,05fh,009h,0b0h,008h,0bfh,004h,0dbh,004h,0d0h,008h,0dbh,005h,0f0h	; 6461  .[._............
	defb 003h,0fbh,008h,069h,008h,068h,008h,0e9h,008h,0e8h,008h,069h,008h,068h,002h,0bfh	; 6471  ...i.h.....i.h..
	defb 010h,0b0h,006h,0bfh,002h,000h,006h,0fbh,002h,0b0h,006h,0fbh,010h,075h,008h,0e5h	; 6481  .............u..
	defb 006h,098h,002h,09fh,008h,068h,008h,09fh,008h,069h,00ch,09fh,004h,089h,008h,068h	; 6491  .....h...i.....h
	defb 008h,0efh,005h,0b9h,002h,0b6h,085h,0b0h,0b9h,0b9h,090h,090h,003h,060h,081h,000h	; 64a1  .............`..
	defb 004h,0b4h,004h,0b0h,008h,0b4h,008h,0b0h,030h,0bfh,038h,07fh,008h,0f7h,030h,07fh	; 64b1  ........0.8...0.
	defb 008h,0fbh,008h,070h,008h,0f0h,008h,0b0h,000h	; 64c1  ...p.....

; ----------------------------------------------------------------------
; DATOS decorado_3_patron: 269 bytes -> 352 de PATRON en 0x2400. Etapa 3
;   0x64ca..0x65d7  (269 bytes)
DATA_decorado_3_patron:
	defb 010h,0f0h,004h,000h,084h,008h,00ch,00ch,006h,005h,000h,083h,014h,03bh,07fh,004h	; 64ca  .............;..
	defb 000h,084h,020h,076h,0ffh,0ffh,008h,00fh,002h,0f8h,096h,0fch,0feh,0ffh,0ffh,0fch	; 64da  .. v............
	defb 0f8h,0feh,0feh,0fch,0fdh,0f8h,0f9h,0f4h,0f1h,07fh,07fh,0bfh,0bfh,040h,080h,000h	; 64ea  .............@..
	defb 01fh,004h,0efh,004h,00fh,084h,0fch,0f8h,0f0h,0f0h,003h,0e0h,081h,0f0h,008h,00eh	; 64fa  ................
	defb 082h,07ch,078h,006h,070h,002h,00fh,003h,0cfh,003h,00fh,08ah,0f8h,0fch,0feh,0fch	; 650a  .|x.p...........
	defb 0feh,0ffh,0ffh,0fch,00fh,00fh,003h,0cfh,09bh,00fh,0f0h,0f0h,0f8h,0f0h,0fch,0f8h	; 651a  ................
	defb 0feh,0fch,0fch,0feh,0f1h,0f4h,0f9h,0f8h,0fdh,0fch,0feh,0feh,01fh,0e0h,080h,0bfh	; 652a  ................
	defb 03fh,03fh,07fh,07fh,008h,00fh,08ch,003h,001h,001h,000h,030h,070h,060h,000h,0ffh	; 653a  ??.........0p`..
	defb 03fh,01bh,008h,004h,000h,002h,0ffh,083h,0fdh,0b8h,008h,003h,000h,00eh,0f0h,002h	; 654a  ?...............
	defb 000h,008h,0f0h,006h,000h,002h,00fh,004h,0ffh,084h,0efh,0dfh,0dfh,0ffh,004h,000h	; 655a  ................
	defb 088h,00ch,07fh,0ffh,0ffh,0f3h,0f8h,0f9h,07fh,003h,0ffh,083h,01fh,0feh,0feh,003h	; 656a  ................
	defb 0fch,096h,002h,001h,000h,080h,080h,0c0h,040h,0e0h,060h,0d0h,070h,03fh,007h,001h	; 657a  ........@.`.p?..
	defb 007h,00fh,01fh,01fh,00fh,0feh,03eh,01eh,005h,00eh,008h,070h,085h,01fh,00fh,00fh	; 658a  ......>....p....
	defb 007h,00fh,003h,007h,006h,00eh,0aeh,01eh,03eh,003h,007h,007h,01fh,007h,00fh,007h	; 659a  ........>.......
	defb 00fh,007h,007h,001h,002h,003h,003h,001h,001h,070h,0d0h,060h,0e0h,040h,0c0h,080h	; 65aa  .........p.`.@..
	defb 080h,0c0h,0e0h,0e0h,080h,0c0h,0e0h,0f0h,0e0h,0ffh,0ffh,04fh,066h,001h,000h,00fh	; 65ba  ...........Of...
	defb 00fh,0ffh,0fch,0f0h,080h,004h,000h,006h,070h,082h,078h,07ch,000h	; 65ca  ........p.x|.

; ----------------------------------------------------------------------
; DATOS decorado_3_color: 110 bytes -> 352 de COLOR en 0x0400. Etapa 3
;   0x65d7..0x6645  (110 bytes)
DATA_decorado_3_color:
	defb 006h,047h,002h,040h,008h,047h,018h,0f4h,007h,074h,081h,07fh,008h,04fh,008h,0f7h	; 65d7  .G.@.G...t...O..
	defb 004h,07eh,081h,0efh,009h,07fh,082h,00fh,007h,008h,04fh,018h,07fh,008h,04fh,006h	; 65e7  .~........O...O.
	defb 07fh,002h,0f0h,008h,04fh,008h,0f7h,083h,0bfh,0f4h,0f4h,005h,0efh,083h,07bh,074h	; 65f7  ....O.........{t
	defb 074h,005h,07eh,018h,0f4h,081h,0f7h,005h,047h,002h,040h,010h,070h,008h,040h,008h	; 6607  t.~.....G.@.p.@.
	defb 04fh,008h,0e0h,008h,04fh,081h,05fh,004h,057h,003h,07eh,008h,07fh,008h,04fh,008h	; 6617  O...O._.W.~...O.
	defb 05eh,008h,07fh,008h,04fh,008h,05eh,008h,04fh,083h,0e5h,0e4h,074h,004h,075h,081h	; 6627  ^...O.^.O...t.u.
	defb 0f5h,008h,07fh,008h,0f4h,006h,0e0h,002h,040h,008h,0f4h,008h,07fh,000h	; 6637  ........@.....

; ----------------------------------------------------------------------
; DATOS decorado_45_patron: 82 bytes -> 104 de PATRON en 0x2400. Etapas 4 y 5,
;   que comparten decorado
;   0x6645..0x6697  (82 bytes)
DATA_decorado_45_patron:
	defb 0b0h,08bh,0aeh,0bfh,08bh,0dbh,05ah,0eeh,08dh,0ffh,05fh,03fh,09fh,07fh,0bfh,06fh	; 6645  ......Z..._?...o
	defb 0bfh,0bdh,0ech,080h,0eeh,080h,0deh,0fbh,080h,067h,095h,0e4h,0b1h,0f2h,0f9h,0eah	; 6655  .........g......
	defb 0f4h,008h,020h,002h,0b7h,07fh,07ah,020h,084h,0e9h,0f4h,0d2h,0e9h,0abh,0d9h,027h	; 6665  .. ...z .......'
	defb 0efh,004h,03fh,006h,07fh,002h,03fh,084h,01fh,00fh,007h,007h,003h,003h,004h,001h	; 6675  ..?...?.........
	defb 003h,000h,002h,001h,002h,003h,004h,001h,002h,003h,084h,007h,00fh,01fh,03fh,010h	; 6685  ..............?.
	defb 0ffh,000h	; 6695

; ----------------------------------------------------------------------
; DATOS rle_patron_24d0: 160 bytes -> 184 de PATRON en 0x24d0. Lo carga
;   0x69de, en las etapas 4 y 5
;   0x6697..0x6737  (160 bytes)
DATA_rle_patron_24d0:
	defb 003h,0f0h,099h,0f3h,0e3h,0e3h,0c1h,081h,0ffh,0ebh,0bdh,0bfh,0eeh,0ech,001h,007h	; 6697  ................
	defb 0f6h,0bfh,0bbh,0ddh,000h,07fh,0ffh,0e0h,0fbh,0bfh,0edh,000h,004h,0ffh,090h,0feh	; 66a7  ................
	defb 0deh,0dbh,0ebh,000h,0feh,0ffh,007h,01fh,03fh,03fh,0feh,0fch,0f0h,080h,0e0h,003h	; 66b7  ........??......
	defb 00fh,003h,03fh,002h,07fh,002h,001h,003h,003h,088h,001h,000h,000h,001h,003h,003h	; 66c7  ..?.............
	defb 007h,007h,003h,003h,003h,0ffh,082h,0f8h,007h,003h,0ffh,003h,07eh,081h,000h,004h	; 66d7  ............~...
	defb 07eh,003h,0ffh,082h,01fh,0e0h,003h,0ffh,083h,080h,0c0h,0c0h,002h,0e0h,003h,0c0h	; 66e7  ~...............
	defb 002h,080h,003h,0c0h,083h,080h,000h,000h,008h,07eh,002h,0feh,003h,0fch,003h,0f0h	; 66f7  .........~......
	defb 002h,07fh,003h,03fh,003h,00fh,090h,007h,001h,0f0h,0feh,0bfh,0f7h,0f6h,0dfh,0e0h	; 6707  ...?............
	defb 0ffh,07fh,0edh,0ffh,0f6h,0bfh,0bfh,005h,0ffh,093h,0f7h,0ffh,0bdh,007h,0ffh,0feh	; 6717  ................
	defb 000h,0b7h,0ffh,06dh,0fdh,0e0h,080h,00fh,003h,001h,0c0h,0c0h,0e0h,008h,07eh,000h	; 6727  ...m..........~.

; ----------------------------------------------------------------------
; DATOS decorado_45_color: 39 bytes -> 104 de COLOR en 0x0400. Etapas 4 y 5
;   0x6737..0x675e  (39 bytes)
DATA_decorado_45_color:
	defb 081h,06ch,006h,0c0h,004h,06ch,083h,060h,06ch,060h,005h,06ch,087h,0cbh,06ch,0cbh	; 6737  .l...l.`l`.l..l.
	defb 0cbh,06ch,060h,060h,006h,0c0h,003h,0ach,081h,0c3h,004h,0c6h,007h,0c0h,081h,060h	; 6747  .l``...........`
	defb 028h,096h,008h,090h,008h,060h,000h	; 6757

; ----------------------------------------------------------------------
; DATOS rle_color_04d0: 100 bytes -> 184 de COLOR en 0x04d0. Lo carga 0x69e7
;   0x675e..0x67c2  (100 bytes)
DATA_rle_color_04d0:
	defb 003h,06eh,005h,069h,006h,0c0h,002h,0e0h,005h,0c0h,002h,0e0h,081h,0e6h,004h,0c0h	; 675e  .n.i............
	defb 003h,0e0h,081h,060h,005h,0c0h,002h,0e0h,081h,0e6h,005h,06ch,083h,069h,0e9h,0e9h	; 676e  ...`.......l.i..
	defb 003h,09eh,005h,096h,010h,069h,003h,060h,082h,06fh,016h,003h,060h,004h,06fh,081h	; 677e  .....i.`.o..`.o.
	defb 01fh,007h,06fh,081h,016h,003h,06fh,010h,069h,008h,06fh,005h,096h,003h,09eh,005h	; 678e  ..o...o.i.o.....
	defb 096h,003h,09eh,002h,0e0h,006h,0c0h,083h,0e6h,0e6h,0ech,005h,0c0h,081h,060h,003h	; 679e  ..............`.
	defb 0e0h,081h,000h,003h,0c0h,083h,0e6h,0e6h,0e0h,005h,0c0h,002h,0e9h,003h,096h,003h	; 67ae  ................
	defb 026h,008h,08eh,000h	; 67be

; ----------------------------------------------------------------------
; DATOS rle_color_0588: 19 bytes -> 192 de COLOR en 0x0588. Lo carga 0x69af
;   0x67c2..0x67d5  (19 bytes)
DATA_rle_color_0588:
	defb 030h,096h,038h,056h,008h,065h,010h,056h,020h,05fh,008h,099h,008h,050h,008h,060h	; 67c2  0.8V.e.V _...P.`
	defb 008h,090h,000h	; 67d2

; ----------------------------------------------------------------------
; DATOS decorado_6_patron: 176 bytes -> 200 de PATRON en 0x2400. Etapa 6
;   0x67d5..0x6885  (176 bytes)
DATA_decorado_6_patron:
	defb 002h,000h,082h,01ch,062h,004h,000h,002h,001h,087h,002h,00ah,007h,001h,039h,00fh	; 67d5  ....b.........9.
	defb 000h,002h,040h,089h,080h,0c0h,010h,070h,0c0h,001h,0cfh,03bh,002h,002h,006h,08ah	; 67e5  ..@....p...;....
	defb 00eh,01fh,038h,0e0h,098h,0e0h,008h,013h,03eh,0e5h,088h,002h,003h,007h,005h,00eh	; 67f5  ..8.....>.......
	defb 01fh,005h,00eh,003h,000h,08ah,080h,0c0h,0e0h,080h,0e0h,03fh,00bh,01dh,077h,01fh	; 6805  ...........?..w.
	defb 003h,003h,088h,0f8h,0d0h,038h,0fch,0b0h,0fch,0e0h,01fh,004h,0ffh,087h,027h,00fh	; 6815  .....8........'.
	defb 03fh,0ffh,0ffh,0a3h,0c0h,003h,080h,002h,0c0h,093h,0ffh,00fh,007h,003h,00fh,007h	; 6825  ?...............
	defb 007h,00fh,0ffh,033h,001h,001h,003h,001h,001h,003h,0e0h,0c0h,0c0h,003h,080h,002h	; 6835  ...3............
	defb 0c0h,093h,00fh,007h,007h,00bh,003h,007h,007h,00fh,007h,0fbh,09bh,099h,0f9h,0f9h	; 6845  ................
	defb 003h,003h,067h,003h,003h,003h,001h,002h,006h,083h,0e0h,0c0h,0c0h,003h,080h,091h	; 6855  ..g.............
	defb 0c6h,0ffh,007h,007h,00fh,00bh,007h,007h,00fh,0ffh,007h,003h,003h,001h,001h,003h	; 6865  ................
	defb 033h,005h,0ffh,00eh,01fh,006h,0ffh,002h,000h,006h,0ffh,002h,0e0h,006h,0ffh,000h	; 6875  3...............

; ----------------------------------------------------------------------
; DATOS decorado_6_color: 37 bytes -> 200 de COLOR en 0x0400. Etapa 6
;   0x6885..0x68aa  (37 bytes)
DATA_decorado_6_color:
	defb 008h,07fh,01ch,08fh,004h,0efh,015h,0cfh,003h,06fh,005h,0cfh,00bh,0feh,00ah,06fh	; 6885  .........o.....o
	defb 006h,0efh,008h,06eh,008h,06fh,008h,0efh,010h,06eh,008h,06fh,006h,0efh,002h,06fh	; 6895  ...n.o...n.o...o
	defb 008h,06eh,028h,0f0h,000h	; 68a5

; ======================================================================
; CODIGO 0x68aa..0x6a51  (423 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Los tiles comunes a todas las etapas. Se ven dos cosas: que los COLORES estan en 0x0000 y los PATRONES en 0x2000 -al reves del reparto habitual, porque asi lo dejan R3=0x7F y R4=0x07-, y que la mitad derecha de la calzada no se guarda: se fabrica con el espejo de 0x4652 a partir de la izquierda.
; ----------------------------------------------------------------------
carga_los_tiles_de_la_carretera:
	ld de,05dech		;68aa   ; los 64 tiles de calzada
	ld hl,02200h		;68ad   ; al patron 0x2200
	call descomprime_los_tres_tercios		;68b0
	ld de,05f25h		;68b3   ; y su color. OJO: este bloque empieza DENTRO del anterior, y sus 32 primeros bytes son los ultimos de aquel
	ld hl,00200h		;68b6   ; al color 0x0200
	call descomprime_los_tres_tercios		;68b9
	ld hl,02680h		;68bc   ; el patron 0x2680
	ld de,05fech		;68bf   ; cinco tiles mas
	call descomprime_los_tres_tercios		;68c2
	ld hl,00680h		;68c5   ; su color
	ld de,0601dh		;68c8
	call descomprime_los_tres_tercios		;68cb
	ld hl,02688h		;68ce   ; cuatro tiles de la izquierda
	ld de,026a8h		;68d1   ; a la derecha
	ld c,004h		;68d4
	call espeja_tiles		;68d6   ; dandoles la vuelta
	ld hl,006a8h		;68d9   ; y el color de esos
	ld de,0601fh		;68dc
	call descomprime_los_tres_tercios		;68df
	ld hl,026c8h		;68e2   ; el patron 0x26C8
	ld de,05ff7h		;68e5
	call descomprime_los_tres_tercios		;68e8
	ld hl,006c8h		;68eb
	ld de,06022h		;68ee
	call descomprime_los_tres_tercios		;68f1
	ld hl,026c8h		;68f4   ; ocho tiles mas
	ld de,02708h		;68f7   ; al otro lado
	ld c,008h		;68fa
	call espeja_tiles		;68fc   ; del reves
	ld hl,00708h		;68ff   ; y el MISMO bloque de color otra vez
	ld de,06022h		;6902
	call descomprime_los_tres_tercios		;6905
	ld hl,02748h		;6908   ; el patron 0x2748
	ld de,06008h		;690b
	call descomprime_los_tres_tercios		;690e
	ld hl,00748h		;6911
	ld de,0602dh		;6914
	call descomprime_los_tres_tercios		;6917
	ld hl,02760h		;691a   ; seis tiles
	ld de,02798h		;691d   ; espejados
	ld c,006h		;6920
	call espeja_tiles		;6922
	ld hl,00798h		;6925
	ld de,06031h		;6928
	call descomprime_los_tres_tercios		;692b
	ld de,05a71h		;692e   ; los diez primeros patrones de sprite
	call descomprime_con_destino_dentro		;6931   ; que llevan el destino dentro
	ld hl,01880h		;6934   ; seis figuras de 16x16
	ld de,01950h		;6937   ; a su version espejada
	ld c,006h		;693a
	call espeja_patrones_de_sprite		;693c   ; cruzando las dos mitades de cada una
	ld de,05b95h		;693f   ; y los veinticinco patrones de sprite que faltan
	call descomprime_con_destino_dentro		;6942
	call tono_del_decorado		;6945   ; el tono del decorado de esta etapa
	ld a,(0e043h)		;6948   ; la etapa
	dec a			;694b
	jp z,carga_el_decorado		;694c   ; la 1 solo lleva su decorado
	dec a			;694f
	jr z,L_6989		;6950   ; la 2, decorado y un tramo mas
	dec a			;6952
	jp z,carga_el_decorado		;6953   ; la 3, solo decorado
	dec a			;6956
	jp z,L_6995		;6957   ; la 4
	dec a			;695a
	jp z,L_6995		;695b   ; y la 5, que comparten todo
	call carga_el_decorado		;695e   ; la 6: decorado y despues un retoque de color
	ld hl,006c8h		;6961   ; el color de 0x06C8
	ld bc,00100h		;6964   ; 0x100 bytes

; ----------------------------------------------------------------------
; El retoque de la etapa 6: recorre 256 bytes de color y a todos los que tengan un 0x0F de fondo se lo cambia por un 7. Se lee de la VRAM y se vuelve a escribir, byte a byte.
; ----------------------------------------------------------------------
L_6967:
	push bc			;6967
	push hl			;6968
	call 0004ah		;6969   ; BIOS RDVRM - Reads the content of VRAM | RDVRM
	ld b,a			;696c   ; el color, a salvo
	and 00fh		;696d   ; el fondo
	cp 00fh		;696f   ; solo si es blanco
	jr nz,L_6979		;6971
	ld a,b			;6973   ; se conserva la tinta
	and 0f0h		;6974
	or 007h		;6976   ; y el fondo pasa a ser el 7
	ld b,a			;6978
L_6979:
	ld a,b			;6979
	ld bc,00001h		;697a   ; un byte
	call llena_los_tres_tercios		;697d   ; y lo devuelve a los tres tercios
	pop hl			;6980
	pop bc			;6981
	inc hl			;6982   ; el siguiente
	dec bc			;6983
	ld a,b			;6984
	or c			;6985
	jr nz,L_6967		;6986   ; hasta los 256
	ret			;6988

; ----------------------------------------------------------------------
; La etapa 2: su decorado y ademas los tiles de 0x63AC en el patron 0x2588.
; ----------------------------------------------------------------------
L_6989:
	call carga_el_decorado		;6989   ; el decorado de la etapa
	ld de,063ach		;698c   ; y un tramo mas de calzada
	ld hl,02588h		;698f   ; en el patron 0x2588
	jp descomprime_los_tres_tercios		;6992

; ----------------------------------------------------------------------
; Las etapas 4 y 5, que comparten decorado. Se ve el mismo truco tres veces: cargar la mitad y fabricar la otra con el espejo.
; ----------------------------------------------------------------------
L_6995:
	ld de,063ach		;6995   ; los tiles de 0x63AC
	ld hl,02400h		;6998   ; al patron 0x2400
	call descomprime_los_tres_tercios		;699b
	ld hl,02400h		;699e   ; y de ahi
	ld de,02588h		;69a1   ; al 0x2588
	ld c,018h		;69a4   ; veinticuatro tiles
	call espeja_tiles		;69a6   ; del reves
	ld de,067c2h		;69a9   ; su color
	ld hl,00588h		;69ac
	call descomprime_los_tres_tercios		;69af
	ld de,06645h		;69b2   ; encima, el decorado de la etapa
	ld hl,02400h		;69b5
	call descomprime_los_tres_tercios		;69b8
	ld de,02468h		;69bb   ; y otra vez el espejo
	ld hl,02400h		;69be
	ld c,00dh		;69c1   ; trece tiles
	call espeja_tiles		;69c3
	ld de,06737h		;69c6   ; el color, el mismo bloque
	ld hl,00400h		;69c9
	call descomprime_los_tres_tercios		;69cc
	ld de,06737h		;69cf   ; en los dos sitios
	ld hl,00468h		;69d2
	call descomprime_los_tres_tercios		;69d5
	ld de,06697h		;69d8   ; un tramo mas de patron
	ld hl,024d0h		;69db
	call descomprime_los_tres_tercios		;69de
	ld de,0675eh		;69e1   ; con su color
	ld hl,004d0h		;69e4
	call descomprime_los_tres_tercios		;69e7
	ld a,(0e043h)		;69ea   ; la etapa
	cp 004h		;69ed   ; y solo en la cuarta, dos retoques de color mas
	ret nz			;69ef
	ld a,066h		;69f0
	ld hl,00430h		;69f2
	ld bc,00038h		;69f5
	call llena_los_tres_tercios		;69f8
	ld a,066h		;69fb
	ld hl,00498h		;69fd
	ld bc,00038h		;6a00
	jp llena_los_tres_tercios		;6a03

; ----------------------------------------------------------------------
; Le da a los dieciseis tiles de 0x0748 el tono de la etapa, que sale de la tabla de 0x6A69. Se queda el nibble BAJO de cada byte -el fondo- y le mete el tono en el alto. Detalle: la tabla se indexa con la etapa SIN restarle uno, asi que su primer byte no lo usa nadie.
; ----------------------------------------------------------------------
tono_del_decorado:
	ld a,(0e043h)		;6a06   ; la etapa
	ld hl,06a69h		;6a09   ; la tabla de tonos
	call suma_a_hl		;6a0c
	ld a,(hl)			;6a0f   ; el tono
	ld (0e09dh),a		;6a10   ; a (0xE09D)
	ld hl,00748h		;6a13   ; el color de esos tiles
	ld b,080h		;6a16   ; 128 bytes, dieciseis tiles
L_6A18:
	push bc			;6a18   ; el byte
	push hl			;6a19
	call 0004ah		;6a1a   ; BIOS RDVRM - Reads the content of VRAM | RDVRM
	and 00fh		;6a1d   ; se queda el fondo
	ld b,a			;6a1f
	ld a,(0e09dh)		;6a20   ; el tono de la etapa
	or b			;6a23   ; y va en la tinta
	ld bc,00001h		;6a24   ; un byte
	call llena_los_tres_tercios		;6a27   ; a los tres tercios
	pop hl			;6a2a
	pop bc			;6a2b
	inc hl			;6a2c   ; el siguiente
	djnz L_6A18		;6a2d
	ret			;6a2f

; ----------------------------------------------------------------------
; El decorado de ESTA etapa: dos punteros de la tabla de 0x6A51, cuatro bytes por etapa. El primero al patron de 0x2400 y el segundo al color de 0x0400. Las etapas 4 y 5 apuntan a los mismos dos, asi que de seis etapas solo hay CINCO decorados distintos.
; ----------------------------------------------------------------------
carga_el_decorado:
	ld a,(0e043h)		;6a30   ; la etapa
	dec a			;6a33
	add a,a			;6a34   ; por cuatro: dos punteros
	add a,a			;6a35
	ld hl,06a51h		;6a36   ; la tabla de decorados
	call suma_a_hl		;6a39
	ld e,(hl)			;6a3c   ; el primer puntero
	inc hl			;6a3d
	ld d,(hl)			;6a3e
	push hl			;6a3f   ; la tabla, a salvo
	ld hl,02400h		;6a40   ; al patron 0x2400
	call descomprime_los_tres_tercios		;6a43
	pop hl			;6a46   ; la tabla
	inc hl			;6a47
	ld e,(hl)			;6a48   ; y el segundo puntero
	inc hl			;6a49
	ld d,(hl)			;6a4a
	ld hl,00400h		;6a4b   ; al color 0x0400
	jp descomprime_los_tres_tercios		;6a4e

; ----------------------------------------------------------------------
; DATOS tabla_de_decorados: seis registros de cuatro bytes, dos punteros por
;   etapa; la indexa 0x6a36
;   0x6a51..0x6a69  (24 bytes)
DATA_tabla_de_decorados:
	defb 03eh,060h,0c8h,061h	; 6a51
	defb 079h,062h,031h,064h	; 6a55
	defb 0cah,064h,0d7h,065h	; 6a59
	defb 045h,066h,037h,067h	; 6a5d
	defb 045h,066h,037h,067h	; 6a61
	defb 0d5h,067h,085h,068h	; 6a65

; ----------------------------------------------------------------------
; DATOS color_del_decorado: un byte por etapa, indexado SIN restar uno
;   (0x6a09: `ld a,(0e043h) / ld hl,06a69h`), asi que el primero no se usa.
;   L_6A18 lo mete en el nibble alto de los 128 bytes de color de 0x0748,
;   dejando el bajo: verde, amarillo, transparente, rojo oscuro, rojo claro y
;   blanco
;   0x6a69..0x6a70  (7 bytes)
DATA_color_del_decorado:
	defb 000h,020h,0b0h,000h,060h,090h,0f0h	; 6a69

; ======================================================================
; CODIGO 0x6a70..0x6a80  (16 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; La puerta de todo lo que le pasa al coche. Guarda el giro que se acaba de pulsar -si lo hay- y despacha por (0xE049) con la tabla de 0x6A80, que va pegada detras del `call` como las otras cinco del cartucho.
; ----------------------------------------------------------------------
mueve_el_coche:
	ld a,(0e008h)		;6a70   ; lo recien pulsado
	and 00ch		;6a73   ; solo los dos bits de girar
	ld hl,0e048h		;6a75   ; el ultimo giro
	jr z,L_6A7B		;6a78   ; si no se ha pulsado nada, se deja el de antes
	ld (hl),a			;6a7a
L_6A7B:
	inc hl			;6a7b   ; (0xE049), el estado
	ld a,(hl)			;6a7c
	call despacha_por_indice		;6a7d   ; y detras del call, las ocho ramas

; ----------------------------------------------------------------------
; DATOS tabla_6a80: 8 entradas, desde 0x6a7d
;   0x6a80..0x6a90  (16 bytes)
DATA_tabla_6a80:
	defw 06a90h,06abbh,06b05h,06b5eh,06b90h,06c05h,06c31h,06c3ah	; 6a80

; ======================================================================
; CODIGO 0x6a90..0x6b59  (201 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El estado 0, el normal: el coche va rodando. Gira si el mando lo pide -y solo si el giro pulsado coincide con el que ya llevaba, que es lo que evita el cambio brusco-, deja sonando el motor y se dibuja de frente.
; ----------------------------------------------------------------------
coche_rodando:
	call mira_el_borde		;6a90   ; mira el borde y los choques
	ld a,(0e055h)		;6a93   ; hacia donde va girado
	add a,a			;6a96   ; por cuatro
	add a,a			;6a97
	and 00ch		;6a98
	ld c,a			;6a9a
	ld a,(0e009h)		;6a9b   ; lo que hay pulsado
	and 00ch		;6a9e   ; los dos bits de girar
	and c			;6aa0   ; y solo si coincide con el giro que llevaba
	call nz,gira_el_coche		;6aa1   ; entonces se mueve de lado
	ld a,(0e002h)		;6aa4   ; las banderas de la partida
	bit 6,a		;6aa7   ; en demostracion no suena
	jr z,L_6AB4		;6aa9
	ld a,(0e010h)		;6aab   ; si no hay otro efecto sonando
	or a			;6aae
	ld a,001h		;6aaf   ; el motor
	call z,suena		;6ab1
L_6AB4:
	xor a			;6ab4   ; de frente
L_6AB5:
	ld (0e053h),a		;6ab5   ; hacia donde queda girado
	jp dibuja_el_coche		;6ab8

; ----------------------------------------------------------------------
; El estado 1: el coche ya ha reventado y esta ardiendo. Cada ocho fotogramas baja la cuenta de (0xE04A) y en el paso 0x0B suelta el efecto 0x4F; al llegar a cero pasa al estado 6. El `pop hl` de la entrada se come la vuelta, asi que esto no regresa a quien despacho.
; ----------------------------------------------------------------------
coche_reventado:
	pop hl			;6abb   ; se come la vuelta
	ld a,(0e003h)		;6abc   ; el reloj del juego
	and 007h		;6abf   ; uno de cada ocho
	ret nz			;6ac1
	ld hl,0e04ah		;6ac2   ; la cuenta de la quema
	dec (hl)			;6ac5   ; una menos
	jr z,L_6ADF		;6ac6   ; al acabarse, se retira
	ld a,(hl)			;6ac8
	cp 00bh		;6ac9   ; el paso en el que suena
	ld a,008h		;6acb   ; el dibujo del coche ardiendo
	jr z,L_6AD6		;6acd
	inc a			;6acf   ; el paso siguiente
	cp (hl)			;6ad0
	ret nz			;6ad1
	ld a,009h		;6ad2   ; y ahi cambia de dibujo
	jr L_6AB5		;6ad4
L_6AD6:
	push af			;6ad6
	ld a,04fh		;6ad7   ; el efecto de la quema
	call suena		;6ad9
	pop af			;6adc
	jr L_6AB5		;6add

; ----------------------------------------------------------------------
; El remate de la quema: frena de golpe restando 0x14 a la velocidad -con suelo en cero-, pasa al estado 6 y da 0x10 fotogramas de espera. Si todavia queda velocidad, se sale por el `pop hl`.
; ----------------------------------------------------------------------
L_6ADF:
	call L_6AF4		;6adf   ; frena de golpe
	ld a,006h		;6ae2   ; el estado 6
	ld (0e049h),a		;6ae4
	ld a,010h		;6ae7   ; y 0x10 fotogramas de espera
	ld (0e004h),a		;6ae9
	ld a,(0e083h)		;6aec   ; lo que quede de velocidad
	or a			;6aef
	jr z,se_acabo_la_gasolina		;6af0   ; si ya es cero, se ha acabado la gasolina
	pop hl			;6af2   ; y si no, se come la vuelta
	ret			;6af3
L_6AF4:
	ld hl,0e083h		;6af4   ; la velocidad
	ld a,(hl)			;6af7
	sub 014h		;6af8   ; 0x14 menos
	jr nc,L_6AFD		;6afa   ; si no se pasa, se queda
	xor a			;6afc   ; y si se pasa, a cero
L_6AFD:
	ld (hl),a			;6afd
L_6AFE:
	xor a			;6afe
	ld (0e0b8h),a		;6aff   ; el efecto que sonaba
L_6B02:
	jp L_452A		;6b02

; ----------------------------------------------------------------------
; El estado 2: como el 0 pero ademas gastando gasolina. Cada fotograma baja (0xE04F), la velocidad, y cuando se acaba se pasa al aviso de EMPTY.
; ----------------------------------------------------------------------
coche_gastandose:
	ld a,(0e083h)		;6b05   ; lo que quede de velocidad
	or a			;6b08
	jp nz,L_6C2C		;6b09   ; con velocidad, sigue rodando
	call coche_rodando		;6b0c   ; el coche normal
	ld hl,0e04fh		;6b0f   ; la velocidad
	ld a,(hl)			;6b12
	dec a			;6b13   ; una menos
	cp 0f0h		;6b14   ; y si se ha pasado de cero
	jr nc,se_acabo_la_gasolina		;6b16
	ld (hl),a			;6b18
	jp L_6C73		;6b19   ; y si no, sigue

; ----------------------------------------------------------------------
; Se acabo la gasolina. Suena el efecto 0x1B y se escribe EMPTY sobre la propia calzada, en la casilla del coche: la direccion sale de la posicion, y el `and 01fh / cp 012h` la corre a la izquierda si el rotulo no cabria dentro de las veintidos columnas del anillo. Despues, 0x80 fotogramas de espera y estado 6.
; ----------------------------------------------------------------------
se_acabo_la_gasolina:
	ld a,(0e028h)		;6b1c   ; si hay otro efecto sonando, no
	or a			;6b1f
	ret nz			;6b20
	ld a,01bh		;6b21   ; el efecto de la gasolina
	call suena		;6b23
	ld hl,0e04eh		;6b26   ; la x del coche
	ld b,(hl)			;6b29
	dec hl			;6b2a   ; y su Y
	dec hl			;6b2b
	ld a,(hl)			;6b2c
	sub 010h		;6b2d   ; 0x10 mas arriba
	ld l,a			;6b2f
	ld a,b			;6b30
	sub 008h		;6b31   ; y ocho a la izquierda
	ld h,a			;6b33
	call casilla_a_direccion		;6b34   ; de casilla a direccion de VRAM
	ld a,l			;6b37
	and 01fh		;6b38   ; la columna
	cp 012h		;6b3a   ; si pasa de la 18, no cabe
	jr c,L_6B44		;6b3c
	ld a,l			;6b3e   ; y se clava en la 18
	and 0e0h		;6b3f
	or 012h		;6b41
	ld l,a			;6b43
L_6B44:
	ld de,06b59h		;6b44   ; el rotulo EMPTY
	ld bc,00005h		;6b47   ; cinco tiles
	call sube_a_la_vram		;6b4a   ; a la pantalla
	ld a,080h		;6b4d   ; 0x80 fotogramas de espera
	ld (0e004h),a		;6b4f
	ld a,006h		;6b52   ; y el estado 6
	ld (0e049h),a		;6b54
	pop hl			;6b57   ; se come la vuelta
	ret			;6b58

; ----------------------------------------------------------------------
; DATOS rotulo_empty: "EMPTY" en tiles (el ASCII menos 0x20): el aviso de que
;   se acabo la gasolina. Lo escribe 0x6B4A sobre la propia calzada, en la
;   casilla del coche
;   0x6b59..0x6b5e  (5 bytes)
DATA_rotulo_empty:
	defb 025h,02dh,030h,034h,039h	; 6b59

; ======================================================================
; CODIGO 0x6b5e..0x6e3f  (737 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El estado 3: el coche se va de la pantalla. Baja la Y de cuatro en cuatro hasta meterla en la franja 0xC8..0xCF, que es donde el VDP ya no lo pinta, y entonces -si no queda ningun rival en juego- enciende la bandera de demostracion.
; ----------------------------------------------------------------------
coche_retirandose:
	pop hl			;6b5e   ; se come la vuelta
	call L_44D9		;6b5f
	ld a,080h		;6b62   ; los dos rivales, fuera
	ld (0e0eeh),a		;6b64
	ld (0e0feh),a		;6b67
	call L_6AB4		;6b6a   ; de frente
	xor a			;6b6d   ; y sin velocidad
	ld (0e04fh),a		;6b6e
	ld hl,0e04ch		;6b71   ; la Y del coche
	ld a,(hl)			;6b74
	sub 0c8h		;6b75   ; contra la franja de aparcado
	cp 008h		;6b77
	jr c,L_6B80		;6b79   ; ya esta fuera
	ld a,(hl)			;6b7b
	sub 004h		;6b7c   ; cuatro mas
	ld (hl),a			;6b7e
	ret			;6b7f
L_6B80:
	ld a,(0e0e6h)		;6b80   ; el primer rival
	or a			;6b83
	ret nz			;6b84   ; si sigue en juego, se espera
	ld a,(0e0f6h)		;6b85   ; y el segundo
	or a			;6b88
	ret nz			;6b89
	ld a,001h		;6b8a   ; la bandera de demostracion
	ld (0e00dh),a		;6b8c
	ret			;6b8f

; ----------------------------------------------------------------------
; El estado 4: el coche derrapa. (0xE0B1) es lo que le queda; al agotarse pasa al 7 -o al 0 si la velocidad no llega a 0xA0-, y mientras dura se va de lado y solo se endereza pulsando hacia el lado CONTRARIO al que se fue.
; ----------------------------------------------------------------------
coche_derrapando:
	ld hl,0e0b1h		;6b90   ; lo que queda de derrape
	dec (hl)			;6b93   ; mientras quede, sigue derrapando
	jr nz,L_6BB0		;6b94
	ld a,(0e054h)		;6b96   ; por que lado se fue
	or a			;6b99
	ld a,007h		;6b9a   ; por un lado, siete
	jr z,L_6BA0		;6b9c
	ld a,001h		;6b9e   ; por el otro, uno
L_6BA0:
	ld (hl),a			;6ba0
	ld a,007h		;6ba1   ; el estado 7
	ld hl,0e049h		;6ba3
	ld (hl),a			;6ba6
	ld a,(0e04fh)		;6ba7   ; la velocidad
	cp 0a0h		;6baa   ; por debajo de 0xA0 no hay trompo
	ret nc			;6bac
	ld (hl),000h		;6bad   ; y se vuelve al estado 0
	ret			;6baf
L_6BB0:
	call vete_de_lado		;6bb0   ; se va de lado
	call mira_el_borde		;6bb3   ; y de paso mira el borde
	call dibuja_el_coche		;6bb6
	ld a,(0e002h)		;6bb9   ; las banderas de la partida
	bit 6,a		;6bbc   ; en demostracion no suena
	jr z,L_6BCA		;6bbe
	ld a,(0e003h)		;6bc0   ; el reloj
	and 003h		;6bc3   ; uno de cada cuatro
	ld a,00dh		;6bc5   ; el efecto del derrape
	call z,suena		;6bc7
L_6BCA:
	ld a,(0e054h)		;6bca   ; por que lado se fue
	and a			;6bcd
	ld a,(0e008h)		;6bce   ; lo que se acaba de pulsar
	jr z,L_6BD8		;6bd1
	and 004h		;6bd3   ; se fue por un lado: se corrige con el otro
	ret z			;6bd5
	jr L_6BDB		;6bd6
L_6BD8:
	and 008h		;6bd8   ; o al reves
	ret z			;6bda
L_6BDB:
	xor a			;6bdb   ; y vuelve al estado 0
	ld (0e049h),a		;6bdc
	jp L_6AB5		;6bdf

; ----------------------------------------------------------------------
; Empuja el coche de lado durante el derrape: la fuerza sale de (0xE051) menos 0x0C, y si se fue por el otro lado se le da la vuelta al signo con el complemento a dos. El dibujo tambien cambia: el 7 o el 1 segun el lado.
; ----------------------------------------------------------------------
vete_de_lado:
	ld a,007h		;6be2   ; el dibujo de un lado
	ld (0e053h),a		;6be4
	ld a,(0e051h)		;6be7   ; lo que dura el trompo
	sub 00ch		;6bea   ; menos 0x0C
	ld e,a			;6bec
	ld d,000h		;6bed
	ld a,(0e054h)		;6bef   ; por que lado se fue
	and a			;6bf2
	jr z,L_6BFF		;6bf3
	ld a,001h		;6bf5   ; el dibujo del otro lado
	ld (0e053h),a		;6bf7
	dec d			;6bfa   ; el signo, negativo
	ld a,e			;6bfb
	cpl			;6bfc   ; complemento a dos
	ld e,a			;6bfd
	inc de			;6bfe
L_6BFF:
	ld hl,(0e04dh)		;6bff   ; la x del coche
	jp L_6E18		;6c02   ; y ahi se le suma

; ----------------------------------------------------------------------
; El estado 5: el trompo. (0xE004) dice lo que dura y (0xE051) lo que gira, que va bajando: el coche da vueltas cada vez mas despacio hasta pararse. Al acabarse pasa al estado 2 -o al 0 si ya no queda velocidad-.
; ----------------------------------------------------------------------
coche_en_trompo:
	ld hl,0e004h		;6c05   ; lo que dura el trompo
	dec (hl)			;6c08   ; al acabarse, se sale
	jr z,L_6C24		;6c09
	ld hl,0e051h		;6c0b   ; lo que gira
	ld a,(hl)			;6c0e
	and a			;6c0f   ; si ya es cero, no baja mas
	jr z,L_6C13		;6c10
	dec (hl)			;6c12   ; y si no, una menos
L_6C13:
	ld a,(hl)			;6c13   ; lo que gira
	ld hl,(0e04dh)		;6c14   ; la x del coche
	srl a		;6c17   ; la mitad
	ld e,a			;6c19
	ld a,(0e055h)		;6c1a   ; hacia donde va girado
	rra			;6c1d   ; su bit de abajo dice el sentido
	call L_6E0B		;6c1e   ; y ahi se mueve
	jp dibuja_el_coche		;6c21
L_6C24:
	ld a,(0e083h)		;6c24   ; lo que quede de velocidad
	and a			;6c27
	ld a,002h		;6c28   ; el estado 2
	jr z,L_6C2D		;6c2a
L_6C2C:
	xor a			;6c2c   ; o el 0, sin velocidad
L_6C2D:
	ld (0e049h),a		;6c2d
	ret			;6c30

; ----------------------------------------------------------------------
; El estado 6: no hace nada mas que esperar y apagar la bandera de fin de partida. Es el estado en el que se queda el coche mientras la escena remata.
; ----------------------------------------------------------------------
coche_esperando:
	pop hl			;6c31   ; se come la vuelta
	call espera_y_sal		;6c32   ; espera y sale
	xor a			;6c35
	ld (0e045h),a		;6c36   ; la bandera de "se acabo"
	ret			;6c39

; ----------------------------------------------------------------------
; El estado 7: el coche rebota contra el borde. Cada cuatro fotogramas suena el efecto 0x0B y la cuenta de (0xE0B1) sube o baja segun el lado; los tres bits de abajo de esa cuenta son el dibujo, o sea que el coche va cambiando de postura solo. Si de paso toca otra vez el borde, se va al remate del golpe.
; ----------------------------------------------------------------------
coche_rebotando:
	call vete_de_lado		;6c3a   ; se va de lado
	ld a,(0e003h)		;6c3d   ; el reloj
	and 003h		;6c40   ; uno de cada cuatro
	ld hl,0e0b1h		;6c42   ; la cuenta del rebote
	jr nz,L_6C57		;6c45
	push hl			;6c47
	ld a,00bh		;6c48   ; el efecto del golpe
	call suena		;6c4a
	pop hl			;6c4d
	ld a,(0e054h)		;6c4e   ; por que lado se fue
	dec (hl)			;6c51   ; una menos
	or a			;6c52
	jr z,L_6C57		;6c53
	inc (hl)			;6c55   ; o dos mas, por el otro lado
	inc (hl)			;6c56
L_6C57:
	ld a,(hl)			;6c57   ; la cuenta
	and 007h		;6c58   ; sus tres bits de abajo son el dibujo
	call L_6AB5		;6c5a
	ld hl,0e04ch		;6c5d   ; la Y del coche
	call busca_el_borde_de_la_calzada		;6c60   ; mira el borde
	ret nc			;6c63   ; si no lo toca, se queda asi
	jp L_6F18		;6c64   ; y si lo toca, al remate del golpe

; ----------------------------------------------------------------------
; Sin el boton pulsado: la velocidad baja de una en una y el coche se mueve hacia atras en la pantalla, 0x48 de 256 por fotograma, mientras el byte alto de la Y no llegue a 0xF8.
; ----------------------------------------------------------------------
suelta_el_acelerador:
	call esta_rodando		;6c67   ; solo en los estados de rodar
	ret z			;6c6a
	ld hl,0e04fh		;6c6b   ; la velocidad
	ld a,(hl)			;6c6e
	and a			;6c6f   ; si ya es cero, no baja mas
	ret z			;6c70
	dec a			;6c71   ; una menos
	ld (hl),a			;6c72
L_6C73:
	xor a			;6c73   ; el acelerador, apagado
	ld (0e038h),a		;6c74
	ld hl,(0e04bh)		;6c77   ; la Y en punto fijo
	ld a,h			;6c7a
	cp 0f8h		;6c7b   ; hasta el tope de arriba
	jp nc,dibuja_el_coche		;6c7d
	call deja_moverse		;6c80   ; y solo en las franjas de velocidad que dejan
	ret nc			;6c83
	ld bc,0ffb8h		;6c84   ; 0x48 de 256 hacia atras
	jr L_6CCA		;6c87

; ----------------------------------------------------------------------
; Dice si el coche esta en uno de los estados en los que se rueda de verdad: no el 1, no el 2 y no el 5. Devuelve con el cero puesto cuando NO se rueda.
; ----------------------------------------------------------------------
esta_rodando:
	ld a,(0e049h)		;6c89   ; el estado
	dec a			;6c8c   ; el 1 no
	ret z			;6c8d
	dec a			;6c8e   ; el 2 tampoco
	ret z			;6c8f
	cp 005h		;6c90   ; y el 5, el trompo
	ret			;6c92

; ----------------------------------------------------------------------
; EL FILTRO DEL DESPLAZAMIENTO VERTICAL, y no es lineal: por debajo de 0x18 el coche no se mueve, entre 0x18 y 0x50 si, entre 0x50 y 0x7E otra vez no, y por encima de 0x7E si. Esa franja muerta de en medio esta MEDIDA en el emulador: la Y se clava en 0x8FC0 mientras la velocidad va de 0x51 a 0x7D y vuelve a moverse en cuanto pasa de 0x7E.
; ----------------------------------------------------------------------
deja_moverse:
	ld a,(0e04fh)		;6c93   ; la velocidad
	cp 018h		;6c96   ; por debajo de 0x18, quieto
	ccf			;6c98
	ret nc			;6c99
	cp 050h		;6c9a   ; de 0x18 a 0x50, se mueve
	ret c			;6c9c
	cp 07eh		;6c9d   ; de 0x50 a 0x7E, quieto otra vez
	ccf			;6c9f
	ret			;6ca0

; ----------------------------------------------------------------------
; Con el boton pulsado: la velocidad sube de una en una hasta el tope de 0xD7 -MEDIDO: la demostracion lo alcanza y ahi se queda- y el coche avanza en la pantalla, 0x48 de 256 por fotograma, mientras el byte alto de la Y no llegue a 0x9A. Ese tope tambien esta medido.
; ----------------------------------------------------------------------
pisa_el_acelerador:
	call esta_rodando		;6ca1   ; solo en los estados de rodar
	ret z			;6ca4
	ld a,(0e009h)		;6ca5   ; lo que hay pulsado
	and 010h		;6ca8   ; el bit 4 es el acelerador
	jr z,suelta_el_acelerador		;6caa   ; sin el, se suelta
	ld hl,0e04fh		;6cac   ; la velocidad
	ld a,(hl)			;6caf
	cp 0d7h		;6cb0   ; el tope
	ret nc			;6cb2
	inc a			;6cb3   ; una mas
	ld (hl),a			;6cb4
	ld a,001h		;6cb5   ; el acelerador, encendido
	ld (0e038h),a		;6cb7
	ld hl,(0e04bh)		;6cba   ; la Y en punto fijo
	ld a,h			;6cbd
	cp 09ah		;6cbe   ; hasta el tope de 0x9A
	jp nc,dibuja_el_coche		;6cc0
	call deja_moverse		;6cc3   ; y solo en las franjas de velocidad que dejan
	ret nc			;6cc6
	ld bc,00048h		;6cc7   ; 0x48 de 256 hacia delante
L_6CCA:
	add hl,bc			;6cca   ; a la Y
	ld (0e04bh),hl		;6ccb   ; y ahi queda
	jp dibuja_el_coche		;6cce

; ----------------------------------------------------------------------
; Mira si el coche esta tocando el borde de la calzada. Si no, deja 0xFF en (0xE055); si si, deja la casilla y decide que pasa: con velocidad de 0xA0 para arriba, el golpe gordo; por debajo, trompo de 0x18 fotogramas con (0xE051) a 0xBC.
; ----------------------------------------------------------------------
mira_el_borde:
	ld hl,0e04ch		;6cd1   ; la Y del coche
	call busca_el_borde_de_la_calzada		;6cd4   ; busca el borde
	ld hl,0e055h		;6cd7   ; la casilla tocada
	ld (hl),0ffh		;6cda   ; 0xFF: no hay nada
	ret nc			;6cdc   ; si no toca, se acabo
	ld (hl),b			;6cdd   ; y si toca, la casilla
	call L_6D09		;6cde   ; que clase de golpe es
	ret nc			;6ce1
	ld hl,00c01h		;6ce2   ; estado 1 y cuenta 0x0C
	ld (0e049h),hl		;6ce5
	ld a,(0e04fh)		;6ce8   ; la velocidad
	cp 0a0h		;6ceb   ; de 0xA0 para arriba, el golpe gordo
	jp nc,L_6D04		;6ced
	ld a,005h		;6cf0   ; y si no, el estado 5
	ld (0e049h),a		;6cf2
	ld a,0bch		;6cf5   ; con 0xBC de giro
	ld (0e051h),a		;6cf7
	ld a,018h		;6cfa   ; 0x18 fotogramas de trompo
	ld (0e004h),a		;6cfc
	xor a			;6cff   ; y de frente
	ld (0e053h),a		;6d00
	ret			;6d03
L_6D04:
	pop hl			;6d04   ; se come DOS vueltas
	pop hl			;6d05
	jp L_6F1E		;6d06

; ----------------------------------------------------------------------
; Clasifica el golpe por el tile que se ha leido de la pantalla: los cuatro primeros de la tanda mandan al derrape -estado 4, con 0x20 de cuenta- y los cuatro siguientes solo cortan la velocidad a 0x20 y sueltan el efecto. Devuelve con el cero puesto cuando se ha ocupado del golpe el mismo.
; ----------------------------------------------------------------------
L_6D09:
	ld a,d			;6d09   ; el tile del golpe
	sub 074h		;6d0a
	cp 008h		;6d0c   ; ocho tiles de margen
	ccf			;6d0e
	ret c			;6d0f
	cp 004h		;6d10   ; los cuatro primeros
	jr nc,L_6D20		;6d12
	ld a,004h		;6d14   ; el estado 4
	ld (0e049h),a		;6d16
	ld a,020h		;6d19   ; con 0x20 de derrape
	ld (0e0b1h),a		;6d1b
	and a			;6d1e
	ret			;6d1f
L_6D20:
	ld a,020h		;6d20   ; la velocidad, cortada a 0x20
	ld (0e04fh),a		;6d22
	call L_6B02		;6d25
	and a			;6d28
	ret			;6d29

; ----------------------------------------------------------------------
; El borde de la IZQUIERDA. Lee el tile que hay cuatro pixeles a la izquierda del coche y, si esta en la tanda del arcen, afina hasta el pixel: redondea la x a la casilla y compara la parte que sobra. El 0xEC es un tile con su propia forma, y por eso se mira aparte.
; ----------------------------------------------------------------------
L_6D2A:
	ld b,00ch		;6d2a   ; cuatro pixeles a la izquierda
	call lee_el_tile_de_la_pantalla		;6d2c   ; lee el tile de la pantalla
	ret nc			;6d2f   ; si no hay borde, nada
	ld a,b			;6d30
	cp 0cfh		;6d31   ; los tiles llenos chocan siempre
	jr c,L_6D49		;6d33
	sub 0d9h		;6d35   ; y los del arcen se afinan
	cp 008h		;6d37
	jr nc,L_6D4D		;6d39
L_6D3B:
	ld a,c			;6d3b   ; la x del coche
	push af			;6d3c
	add a,00ch		;6d3d   ; redondeada a la casilla
	and 0f8h		;6d3f
	ld c,a			;6d41
	pop af			;6d42
	sub c			;6d43   ; lo que sobra
	add a,b			;6d44
	sub 0d4h		;6d45   ; contra el ancho del tile
	jr c,L_6D85		;6d47   ; si no llega, no hay golpe
L_6D49:
	ld b,001h		;6d49   ; golpe por la izquierda
	jr L_6D89		;6d4b
L_6D4D:
	ld a,b			;6d4d
	cp 0ech		;6d4e   ; el tile de forma propia
	jr nz,L_6D49		;6d50
	ld b,0e0h		;6d52   ; con su margen
	jr L_6D3B		;6d54

; ----------------------------------------------------------------------
; El borde de la DERECHA, igual que el de la izquierda pero al reves y con sus propios tiles: aqui el de forma propia es el 0xF3.
; ----------------------------------------------------------------------
L_6D56:
	ld b,004h		;6d56   ; cuatro pixeles a la derecha
	call lee_el_tile_de_la_pantalla		;6d58   ; lee el tile de la pantalla
	ret nc			;6d5b   ; si no hay borde, nada
	ld a,b			;6d5c
	cp 0fch		;6d5d   ; los tiles llenos chocan siempre
	jr nc,L_6D78		;6d5f
	sub 0e1h		;6d61   ; y los del arcen se afinan
	cp 008h		;6d63
	jr nc,L_6D7C		;6d65
L_6D67:
	ld a,c			;6d67   ; la x del coche
	push af			;6d68
	add a,004h		;6d69   ; redondeada a la casilla
	and 0f8h		;6d6b
	ld c,a			;6d6d
	ld a,b			;6d6e   ; el nibble bajo del tile
	and 00fh		;6d6f
	ld b,a			;6d71
	pop af			;6d72
	add a,004h		;6d73   ; cuatro mas
	sub c			;6d75
	sub b			;6d76
	ret nc			;6d77
L_6D78:
	ld b,002h		;6d78   ; golpe por la derecha
	jr L_6D89		;6d7a
L_6D7C:
	ld a,b			;6d7c
	cp 0f3h		;6d7d   ; el tile de forma propia
	jr nz,L_6D78		;6d7f
	ld b,0e1h		;6d81
	jr L_6D67		;6d83
L_6D85:
	ld b,000h		;6d85   ; sin golpe
	and a			;6d87
	ret			;6d88
L_6D89:
	scf			;6d89   ; con golpe
	ret			;6d8a

; ----------------------------------------------------------------------
; EL DETECTOR DE CHOQUES, y no usa geometria: LEE LA PANTALLA. Calcula la casilla en la que esta el coche, la pide al VDP con SETRD y se trae el tile que hay puesto ahi. Despues lo clasifica por tandas -por debajo de 0xCF hay golpe seguro, de 0xCF a 0xD8 esta libre, de 0xD9 a 0xE8 es el borde y hay que afinar-. Es la manera mas barata de que el coche choque con lo que se VE, sea lo que sea lo que la carretera haya pintado ahi.
; ----------------------------------------------------------------------
lee_el_tile_de_la_pantalla:
	ld a,(hl)			;6d8b   ; la Y del coche
	inc hl			;6d8c
	inc hl			;6d8d
	ld h,(hl)			;6d8e   ; y su x
	add a,004h		;6d8f   ; cuatro pixeles al lado
	ld l,a			;6d91
	sub 0c0h		;6d92   ; la vuelta del anillo
	jr c,L_6D9E		;6d94
	cp 018h		;6d96   ; con la Y en la franja de arriba
	ld l,000h		;6d98   ; la fila de arriba
	jr nc,L_6D9E		;6d9a
	ld l,0b8h		;6d9c   ; o la de abajo
L_6D9E:
	ld a,h			;6d9e   ; la x
	ld c,a			;6d9f
	add a,b			;6da0   ; corrida lo que diga B
	ld h,a			;6da1
	call casilla_a_direccion		;6da2   ; de casilla a direccion de VRAM
	call 00050h		;6da5   ; BIOS SETRD - Enables VDP to read | y se lo pide al VDP
	ld a,(00007h)		;6da8   ; el puerto de datos
	exx			;6dab
	ld c,a			;6dac
	in a,(c)		;6dad   ; el tile que hay puesto ahi
	exx			;6daf
	ld b,a			;6db0
	ld d,a			;6db1
	cp 0cfh		;6db2   ; por debajo de 0xCF, golpe seguro
	jr c,L_6D89		;6db4
	cp 0d9h		;6db6   ; de 0xCF a 0xD8, libre
	jr c,L_6D85		;6db8
	sub 0d9h		;6dba   ; y de 0xD9 en adelante
	cp 010h		;6dbc   ; dieciseis tiles de borde
	jr nc,L_6D89		;6dbe
	ret			;6dc0

; ----------------------------------------------------------------------
; De la Y del coche saca la fila del anillo, va a buscar a la cola del arcen el margen que le corresponde a esa fila y lo pasa a pixeles: por dos, redondeado a ocho y mas 0x20. Comparado con la x del coche, dice por que lado hay que mirar el borde.
; ----------------------------------------------------------------------
busca_el_borde_de_la_calzada:
	push hl			;6dc1   ; la Y, a salvo
	ld a,(hl)			;6dc2
	ld b,a			;6dc3
	sub 0c0h		;6dc4   ; la vuelta del anillo
	jr c,L_6DD0		;6dc6
	ld b,000h		;6dc8   ; con la Y en la franja de arriba
	cp 010h		;6dca   ; dieciseis lineas
	jr nc,L_6DD0		;6dcc
	ld b,0b8h		;6dce   ; o la fila de abajo
L_6DD0:
	ld a,b			;6dd0
	ld de,0e098h		;6dd1   ; la cola del arcen
	rra			;6dd4   ; la Y entre ocho: la fila
	rra			;6dd5
	rra			;6dd6
	and 01fh		;6dd7
	call suma_a_de		;6dd9   ; y esa es su casilla
	ld a,(de)			;6ddc
	add a,a			;6ddd   ; por dos
	and 0f8h		;6dde   ; redondeado a ocho
	add a,020h		;6de0   ; mas el ajuste
	inc hl			;6de2   ; la x del coche
	inc hl			;6de3
	cp (hl)			;6de4
	pop hl			;6de5
	jp nc,L_6D56		;6de6   ; a la derecha del borde
	jp L_6D2A		;6de9   ; o a la izquierda

; ----------------------------------------------------------------------
; Mueve el coche de lado. La fuerza sale de (0xE051): sin trompo es cero y con trompo, la mitad mas ocho. Si estan pulsados LOS DOS giros a la vez -que es lo que deja 0x52D1- manda el ultimo que se pulso. Y la suma va al doble, porque L_6E14 desplaza DE antes de sumarlo.
; ----------------------------------------------------------------------
gira_el_coche:
	ld hl,(0e04dh)		;6dec   ; la x del coche
	ld a,(0e051h)		;6def   ; lo que dura el trompo
	or a			;6df2
	jr z,L_6DF9		;6df3   ; sin trompo, la fuerza normal
	srl a		;6df5   ; la mitad
	add a,008h		;6df7   ; y ocho mas
L_6DF9:
	ld e,a			;6df9
	ld a,(0e009h)		;6dfa   ; lo que hay pulsado
	ld b,a			;6dfd
	and 00ch		;6dfe   ; los dos bits de girar
	cp 00ch		;6e00   ; si estan los dos
	jr nz,L_6E08		;6e02
	ld a,(0e048h)		;6e04   ; manda el ultimo que se pulso
	and b			;6e07
L_6E08:
	rra			;6e08   ; el bit del sentido, al acarreo
	rra			;6e09
	rra			;6e0a
L_6E0B:
	ld d,000h		;6e0b   ; sin signo
	jr nc,L_6E14		;6e0d   ; hacia un lado
	dec d			;6e0f   ; y hacia el otro, negativo
	ld a,e			;6e10
	cpl			;6e11   ; complemento a dos
	ld e,a			;6e12
	inc de			;6e13
L_6E14:
	sla e		;6e14   ; por dos
	rl d		;6e16
L_6E18:
	add hl,de			;6e18   ; a la x
	ld (0e04dh),hl		;6e19   ; y ahi queda
	ret			;6e1c

; ----------------------------------------------------------------------
; Deja el coche en la copia de atributos de sprite de 0xE112. El patron sale de la tabla de 0x6E3F indexada con (0xE053), que es hacia donde esta girado, y se escriben DOS sprites: el de la carroceria y, cuatro patrones mas alla, el de su color.
; ----------------------------------------------------------------------
dibuja_el_coche:
	ld hl,06e3fh		;6e1d   ; la tabla de patrones del coche
	ld a,(0e053h)		;6e20   ; hacia donde va girado
	ld b,000h		;6e23
	ld c,a			;6e25
	add hl,bc			;6e26   ; el patron que le toca
	ld a,(hl)			;6e27
	ld hl,0e04ch		;6e28   ; la posicion del coche
	ld c,(hl)			;6e2b
	inc hl			;6e2c
	inc hl			;6e2d
	ld b,(hl)			;6e2e   ; y su carril
	ld hl,0e112h		;6e2f   ; la copia de atributos de sprite
	call L_6E37		;6e32
	add a,004h		;6e35   ; el segundo sprite va cuatro patrones mas alla
L_6E37:
	ld (hl),c			;6e37   ; la fila
	inc hl			;6e38
	ld (hl),b			;6e39   ; la columna
	inc hl			;6e3a
	ld (hl),a			;6e3b   ; el patron
	inc hl			;6e3c
	inc hl			;6e3d   ; y salta al sprite siguiente
	ret			;6e3e

; ----------------------------------------------------------------------
; DATOS datos_6e3f: once bytes que carga 0x6e1d
;   0x6e3f..0x6e4a  (11 bytes)
DATA_datos_6e3f:
	defb 000h,010h,018h,020h,008h,038h,030h,028h,040h,048h,068h	; 6e3f  ... .80(@Hh

; ======================================================================
; CODIGO 0x6e4a..0x70c9  (639 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Recorre los objetos de la carretera desde el primero mirando si alguno toca al coche.
; ----------------------------------------------------------------------
mira_los_choques:
	ld a,(0e049h)		;6e4a   ; el estado del coche
	dec a			;6e4d
	ret z			;6e4e   ; fuera de juego no hay choque que valga
	ld hl,0e0e4h		;6e4f   ; el indice de objeto
	xor a			;6e52
	ld (hl),a			;6e53   ; desde el primero

; ----------------------------------------------------------------------
; Un objeto: bloques de dieciseis bytes desde 0xE0E5. Se compara la posicion con margen 0x20 y el carril con margen 0x16, y si coinciden las dos hay contacto. El carril tambien dice por que LADO se ha tocado, que es lo que decide hacia donde sale despedido.
; ----------------------------------------------------------------------
L_6E54:
	ld hl,0e0e4h		;6e54   ; el indice
	ld a,(hl)			;6e57
	push af			;6e58   ; a salvo
	inc hl			;6e59
	add a,a			;6e5a   ; por dieciseis
	add a,a			;6e5b
	add a,a			;6e5c
	add a,a			;6e5d
	ld b,000h		;6e5e
	ld c,a			;6e60
	add hl,bc			;6e61
	ld (0e0bfh),hl		;6e62   ; (0xE0BF) apunta al objeto
	pop af			;6e65
	ld b,a			;6e66   ; el indice, otra vez
	ld hl,(0e0bfh)		;6e67
	inc hl			;6e6a   ; su tipo
	ld a,(hl)			;6e6b
	or a			;6e6c
	jp z,L_6F0A		;6e6d   ; si es cero, el hueco esta libre
	ld a,b			;6e70
	call sitio_del_sprite		;6e71   ; busca sus coordenadas
	ld a,(0e04ch)		;6e74   ; la posicion del coche
	sub (hl)			;6e77   ; contra la del objeto
	sub 010h		;6e78   ; con margen de 0x20
	add a,020h		;6e7a
	inc hl			;6e7c
	jp nc,L_6F0A		;6e7d   ; si no se solapan, al objeto siguiente
	ld a,(0e04eh)		;6e80   ; el carril del coche
	sub (hl)			;6e83   ; contra el del objeto
	ld c,000h		;6e84   ; por que lado queda
	jr nc,L_6E89		;6e86
	inc c			;6e88   ; por el otro
L_6E89:
	sub 00ah		;6e89   ; margen de 0x16
	add a,016h		;6e8b
	jp nc,L_6F0A		;6e8d   ; y si tampoco, al siguiente
	ld a,c			;6e90
	ld (0e054h),a		;6e91   ; (0xE054) guarda el lado del golpe
	ld a,(0e0e4h)		;6e94   ; el indice del objeto
	cp 003h		;6e97   ; el tercero es el que mata
	jp z,L_6F18		;6e99
	ld hl,(0e0bfh)		;6e9c   ; el objeto
	ld a,(hl)			;6e9f
	sub 006h		;6ea0   ; los tipos 6 y 7
	cp 002h		;6ea2
	jp c,L_6F18		;6ea4   ; tampoco perdonan
	inc hl			;6ea7
	ld (hl),001h		;6ea8   ; el objeto pasa a estar tocado
	inc hl			;6eaa
	ld (hl),005h		;6eab   ; con su cuenta
	ld a,009h		;6ead   ; nueve bytes mas alla
	call suma_a_hl		;6eaf
	inc hl			;6eb2
	ld a,c			;6eb3   ; el lado del golpe
	and a			;6eb4
	ld (hl),003h		;6eb5   ; sale hacia un lado
	jr nz,L_6EBB		;6eb7
	ld (hl),0fdh		;6eb9   ; o hacia el otro

; ----------------------------------------------------------------------
; El golpe. Deja al coche derrapando -estado 4- y, si lo que se toco era del tipo 8, lo retira y arranca la fase de choque de (0xE0B8).
; ----------------------------------------------------------------------
L_6EBB:
	ld hl,0e049h		;6ebb   ; el estado del coche
	ld a,(hl)			;6ebe
	cp 007h		;6ebf   ; el 7 es el de ya estar chocando
	jr z,L_6F15		;6ec1
	ld a,(0e054h)		;6ec3   ; el lado del golpe
	xor 001h		;6ec6   ; al contrario
	ld hl,(0e0bfh)		;6ec8
	inc hl			;6ecb
	call L_7352		;6ecc   ; empuja al objeto
	ld a,020h		;6ecf   ; 0x20
	ld (0e0b1h),a		;6ed1   ; (0xE0B1) es lo que dura el derrape
	ld a,004h		;6ed4   ; derrapando
	ld (0e049h),a		;6ed6
	call dibuja_el_coche		;6ed9   ; y se redibuja
	ld hl,(0e0bfh)		;6edc
	ld a,(hl)			;6edf   ; el tipo del objeto
	cp 008h		;6ee0   ; solo el 8 se retira
	ret nz			;6ee2
	ld hl,0e0e3h		;6ee3   ; (0xE0E3) los cuenta
	dec (hl)			;6ee6
	call L_6BDB		;6ee7   ; lo apunta
	ld hl,(0e0bfh)		;6eea
	inc hl			;6eed
	ld (hl),000h		;6eee   ; el hueco queda libre
	ld a,(0e0e4h)		;6ef0   ; el indice del objeto
	add a,a			;6ef3   ; por ocho
	add a,a			;6ef4
	add a,a			;6ef5
	ld hl,0e11ah		;6ef6   ; la copia de atributos de sprite
	call suma_a_hl		;6ef9
	ld (hl),0e0h		;6efc   ; la Y de fuera de pantalla
	inc hl			;6efe
	inc hl			;6eff
	inc hl			;6f00
	inc hl			;6f01
	ld (hl),0e0h		;6f02   ; y la del segundo sprite
	ld hl,0e0b8h		;6f04   ; la fase del choque
	ld (hl),001h		;6f07   ; arranca
	ret			;6f09
L_6F0A:
	ld hl,0e0e4h		;6f0a   ; el indice
	inc (hl)			;6f0d   ; el siguiente
	ld a,(hl)			;6f0e
	cp 003h		;6f0f   ; y hasta el tercero
	jp nz,L_6E54		;6f11
	ret			;6f14
L_6F15:
	ld (hl),000h		;6f15   ; el coche vuelve a estar entero
	ret			;6f17
L_6F18:
	ld hl,00c01h		;6f18   ; estado 1, con 0x0C de cuenta
	ld (0e049h),hl		;6f1b
L_6F1E:
	xor a			;6f1e   ; y la velocidad, a cero
	ld (0e04fh),a		;6f1f
	jp L_6AFE		;6f22

; ----------------------------------------------------------------------
; Por encima de 0xB8 de velocidad, apaga el segundo objeto del par.
; ----------------------------------------------------------------------
frena_si_va_muy_rapido:
	ld a,(0e04fh)		;6f25   ; la velocidad
	cp 0b8h		;6f28   ; por debajo de 0xB8, nada
	ret c			;6f2a
	ld hl,0e0c1h		;6f2b   ; el primer objeto
	ld a,(hl)			;6f2e
	and a			;6f2f
	ret z			;6f30   ; si esta vacio, tampoco
	inc hl			;6f31
	ld (hl),000h		;6f32   ; y apaga el que sigue

; ----------------------------------------------------------------------
; El reparto: recorre las dos ranuras de 0xE0C3 y, de las que ya estan armadas, va bajando la cuenta de su campo +3 -a fotograma por vez, o a doble si la velocidad no llega a 0xC8- hasta que llega a cero. Entonces el objeto sale a la carretera.
; ----------------------------------------------------------------------
reparte_los_objetos:
	ld hl,0e0c2h		;6f34   ; la ranura que toca
	ld a,(hl)			;6f37
	add a,a			;6f38   ; por dieciseis
	add a,a			;6f39
	add a,a			;6f3a
	add a,a			;6f3b
	inc hl			;6f3c
	ld b,000h		;6f3d
	ld c,a			;6f3f
	add hl,bc			;6f40
	ld (0e0bfh),hl		;6f41   ; y ahi queda apuntada
	inc hl			;6f44
	ld a,(hl)			;6f45   ; su estado
	and a			;6f46
	jr z,L_6F5D		;6f47   ; sin armar, a la ranura siguiente
	inc hl			;6f49
	inc hl			;6f4a
	ld a,(hl)			;6f4b   ; la cuenta que falta para soltarlo
	and a			;6f4c
	jr z,L_6F67		;6f4d   ; a cero: se suelta
	ld a,(0e04fh)		;6f4f   ; la velocidad
	cp 0c8h		;6f52   ; a partir de 0xC8, cada fotograma
	jr nc,L_6F5C		;6f54
	ld a,(0e003h)		;6f56   ; y por debajo, uno de cada dos
	rra			;6f59
	jr nc,L_6F5D		;6f5a
L_6F5C:
	dec (hl)			;6f5c   ; una menos
L_6F5D:
	ld hl,0e0c2h		;6f5d   ; la ranura
	inc (hl)			;6f60   ; la siguiente
	ld a,002h		;6f61   ; y son dos
	cp (hl)			;6f63
	jr nz,reparte_los_objetos		;6f64
	ret			;6f66

; ----------------------------------------------------------------------
; Una ranura que ya ha cumplido su cuenta. Antes de soltar el objeto se le pone otra vez la cuenta de espera, que depende del NIVEL: siete en el segundo y doce en el primero.
; ----------------------------------------------------------------------
L_6F67:
	ld a,(0e0c2h)		;6f67   ; la ranura
	or a			;6f6a
	ld hl,0e0c6h		;6f6b   ; la segunda
	jr nz,L_6F72		;6f6e
	ld l,0d6h		;6f70   ; o la primera
L_6F72:
	ld a,(0e03bh)		;6f72   ; el nivel
	dec a			;6f75
	ld a,007h		;6f76   ; en el segundo, siete
	jr z,L_6F7C		;6f78
	ld a,00ch		;6f7a   ; y en el primero, doce
L_6F7C:
	ld (hl),a			;6f7c
	xor a			;6f7d

; ----------------------------------------------------------------------
; Busca un hueco libre entre los dos objetos en juego: mira el campo +1 de cada uno y se queda con el primero que este a cero. Si los dos estan ocupados, el objeto no sale y la ranura se vuelve a intentar en el fotograma siguiente.
; ----------------------------------------------------------------------
L_6F7E:
	push af			;6f7e   ; el numero de hueco, a salvo
	ld hl,0e0e5h		;6f7f   ; el primer objeto
	add a,a			;6f82   ; por dieciseis
	add a,a			;6f83
	add a,a			;6f84
	add a,a			;6f85
	ld b,000h		;6f86
	add a,001h		;6f88   ; el campo +1
	ld c,a			;6f8a
	add hl,bc			;6f8b
	ld a,(hl)			;6f8c   ; su estado
	and a			;6f8d
	jr z,L_6F98		;6f8e   ; a cero: hueco libre
	pop af			;6f90
	inc a			;6f91   ; el hueco siguiente
	cp 002h		;6f92   ; y son dos
	jr nz,L_6F7E		;6f94
	jr L_6F5D		;6f96   ; los dos ocupados: se deja para luego

; ----------------------------------------------------------------------
; Coloca el objeto en la carretera. La Y sale del arcen de la fila de arriba -(0xE098)- por ocho, y despues se le va restando ocho a la x mientras el objeto siga cayendo fuera de la calzada: asi ninguno aparece encima del arcen.
; ----------------------------------------------------------------------
L_6F98:
	pop af			;6f98   ; el hueco elegido
	ld (0e0b0h),a		;6f99   ; apuntado
	push hl			;6f9c
	ld c,004h		;6f9d   ; el campo +4
	call campo_del_objeto		;6f9f
	ld c,(hl)			;6fa2
	ld a,(0e098h)		;6fa3   ; el arcen de la fila de arriba
	rra			;6fa6   ; sin el modo
	rra			;6fa7
	and 01fh		;6fa8
	add a,a			;6faa   ; por ocho
	add a,a			;6fab
	add a,a			;6fac
	add a,c			;6fad   ; mas lo que traia el campo
	inc hl			;6fae
	inc hl			;6faf
	ld (hl),000h		;6fb0   ; el campo +6, a cero
	inc hl			;6fb2
	inc hl			;6fb3
	ld (hl),a			;6fb4   ; y ahi va la Y
	dec hl			;6fb5
	dec hl			;6fb6
L_6FB7:
	push hl			;6fb7
	call busca_el_borde_de_la_calzada		;6fb8   ; mira si cae sobre la calzada
	pop hl			;6fbb
	jr nc,L_6FC8		;6fbc   ; si cae dentro, ya esta
	inc hl			;6fbe
	inc hl			;6fbf
	ld a,(hl)			;6fc0   ; y si no, ocho pixeles adentro
	sub 008h		;6fc1
	ld (hl),a			;6fc3
	dec hl			;6fc4
	dec hl			;6fc5
	jr L_6FB7		;6fc6   ; y se vuelve a mirar

; ----------------------------------------------------------------------
; El COLOR del objeto: por norma 0xF0, pero los tipos 2 y 5 llevan 0xBF -y solo si no estamos en la escena 6, la del choque-. Con el nivel a cero se le fuerza el tipo 0.
; ----------------------------------------------------------------------
L_6FC8:
	ld hl,(0e0bfh)		;6fc8   ; el objeto que se estaba armando
	ld d,(hl)			;6fcb   ; su tipo
	ld a,(0e03bh)		;6fcc   ; el nivel
	or a			;6fcf
	jr nz,L_6FD3		;6fd0
	ld d,a			;6fd2   ; en el primero, el tipo 0
L_6FD3:
	ld c,006h		;6fd3   ; el campo +6
	call campo_del_objeto		;6fd5
	ld a,d			;6fd8
	cp 002h		;6fd9   ; el tipo 2
	ld (hl),0f0h		;6fdb   ; el color de siempre
	jr z,L_6FE3		;6fdd
	cp 005h		;6fdf   ; o el 5
	jr nz,L_6FEC		;6fe1
L_6FE3:
	ld a,(0e000h)		;6fe3   ; la escena
	cp 006h		;6fe6   ; en la del choque, no
	jr z,L_6FEC		;6fe8
	ld (hl),0bfh		;6fea   ; y a esos dos, el otro color

; ----------------------------------------------------------------------
; Copia la ranura entera -los dieciseis bytes- al hueco, deja su campo +1 a cero y le pone al sprite los dos colores que le tocan por tipo, sacados de la tabla de 0x536B. Si todavia quedan objetos por soltar en este tramo, vuelve al reparto; si no, se pasa al tramo siguiente.
; ----------------------------------------------------------------------
L_6FEC:
	ld hl,(0e0bfh)		;6fec   ; el objeto
	pop de			;6fef   ; el hueco
	dec de			;6ff0
	ld bc,00010h		;6ff1   ; los dieciseis bytes
	ldir		;6ff4
	ld hl,(0e0bfh)		;6ff6   ; el objeto, otra vez
	ld a,(hl)			;6ff9   ; su tipo
	inc hl			;6ffa
	ld (hl),000h		;6ffb   ; y el campo +1, a cero
	add a,a			;6ffd   ; por dos: son pares
	ld hl,0536bh		;6ffe   ; la tabla de colores por tipo
	call suma_a_hl		;7001
	ld a,(0e0b0h)		;7004   ; el numero de hueco
	add a,a			;7007   ; por ocho
	add a,a			;7008
	add a,a			;7009
	add a,003h		;700a   ; y tres, que es donde va el color
	ld de,0e11ah		;700c   ; la copia de atributos de sprite
	call suma_a_de		;700f
	ldi		;7012   ; el color del primer sprite
	inc de			;7014
	inc de			;7015
	inc de			;7016
	ldi		;7017   ; y el del segundo, cuatro mas alla
	ld hl,0e0c1h		;7019   ; los que quedan del tramo
	dec (hl)			;701c
	jp nz,L_6F5D		;701d   ; si queda alguno, sigue el reparto

; ----------------------------------------------------------------------
; Avanza (0xE0BD) por la lista ciclica de tramos de la etapa, y al topar con el 0xFF vuelve al principio de la fila de esa etapa en el plan de 0x537D. **Aqui es donde se nota la diferencia entre las dos compilaciones**: el byte 0x53CB pertenece a esta lista, y si es 0xFF la etapa 5 juega catorce tramos por ciclo en vez de quince.
; ----------------------------------------------------------------------
pasa_al_tramo_siguiente:
	ld hl,(0e0bdh)		;7020   ; por donde va la lista
	inc hl			;7023   ; el tramo siguiente
	ld (0e0bdh),hl		;7024
	ld a,(hl)			;7027   ; el byte de cierre
	inc a			;7028
	jr nz,L_703D		;7029   ; si no lo es, sigue
	ld a,(0e043h)		;702b   ; la etapa
	dec a			;702e
	ld l,a			;702f
	ld h,000h		;7030
	add hl,hl			;7032   ; por dieciseis: una fila por etapa
	add hl,hl			;7033
	add hl,hl			;7034
	add hl,hl			;7035
	ld de,0537dh		;7036   ; el plan de las etapas
	add hl,de			;7039
	ld (0e0bdh),hl		;703a   ; y vuelta al principio de su fila

; ----------------------------------------------------------------------
; Arma el tramo: el valor de la lista indexa la tabla de quince registros de 0x5311, que van de seis en seis. Con el nivel a cero el tramo 0x0A se cambia por el 9: el primer nivel se salta uno de los quince.
; ----------------------------------------------------------------------
L_703D:
	ld a,(0e03bh)		;703d   ; el nivel
	or a			;7040
	ld a,(hl)			;7041   ; el tramo
	jr nz,L_7049		;7042
	cp 00ah		;7044   ; el tramo 0x0A
	jr nz,L_7049		;7046
	dec a			;7048   ; en el primer nivel, el 9
L_7049:
	dec a			;7049   ; la tabla arranca en el 1
	add a,a			;704a   ; por dos
	ld b,a			;704b
	add a,a			;704c
	add a,b			;704d   ; y por tres: seis por registro
	ld hl,05311h		;704e   ; la tabla de tramos
	call suma_a_hl		;7051
	ex de,hl			;7054
	ld hl,0e0c1h		;7055   ; dos objetos por tramo
	ld (hl),002h		;7058
	inc hl			;705a   ; y la ranura, la primera
	ld (hl),000h		;705b
	inc hl			;705d
	ex de,hl			;705e

; ----------------------------------------------------------------------
; Vuelca los tres campos de un registro en su ranura. El del medio -lo que el objeto se mueve de lado- se DOBLA si el nivel no es el segundo, y la velocidad de arranque sale de la etapa: 0x80 por norma, 0x6C en la tercera y 0xE4 para los tipos 2 y 5.
; ----------------------------------------------------------------------
L_705F:
	ex af,af'			;705f   ; el tipo, a salvo
	ld a,(hl)			;7060
	ex af,af'			;7061
	ldi		;7062   ; el tipo, al objeto
	ld a,001h		;7064   ; el campo +1, a uno
	ld (de),a			;7066
	inc de			;7067
	inc de			;7068
	ld a,(0e03bh)		;7069   ; el nivel
	dec a			;706c
	ld a,(hl)			;706d   ; lo que se mueve de lado
	jr z,L_7071		;706e
	add a,a			;7070   ; doblado, salvo en el segundo nivel
L_7071:
	ld (de),a			;7071   ; al campo +3
	inc de			;7072
	inc hl			;7073
	ldi		;7074   ; y lo que se mueve hacia delante
	ex de,hl			;7076
	ld bc,00004h		;7077   ; cuatro campos mas alla
	add hl,bc			;707a
	ex af,af'			;707b   ; el tipo, de vuelta
	ld b,a			;707c
	ld a,(0e043h)		;707d   ; la etapa
	cp 003h		;7080   ; la tercera va mas despacio
	ld (hl),080h		;7082   ; la velocidad de siempre
	jr nz,L_7088		;7084
	ld (hl),06ch		;7086   ; y la de la tercera
L_7088:
	ld a,b			;7088
	cp 002h		;7089   ; los tipos 2
	jr z,L_7091		;708b
	cp 005h		;708d   ; y 5
	jr nz,L_7093		;708f
L_7091:
	ld (hl),0e4h		;7091   ; van mucho mas rapido
L_7093:
	ex af,af'			;7093   ; el tipo, otra vez
	inc hl			;7094
	ld (hl),000h		;7095   ; el campo siguiente, a cero
	ld bc,00006h		;7097   ; y al objeto siguiente
	add hl,bc			;709a
	ex de,hl			;709b
	exx			;709c
	ld hl,0e0c2h		;709d   ; la ranura
	inc (hl)			;70a0   ; la siguiente
	ld a,002h		;70a1
	cp (hl)			;70a3   ; y son dos
	exx			;70a4
	jr nz,L_705F		;70a5
	ret			;70a7

; ----------------------------------------------------------------------
; Recorre los dos objetos en juego y despacha cada uno por su campo +1 con la tabla de ocho de 0x70C9. El detalle: 0x728A se APILA antes del `call`, de modo que sea cual sea la rama, todas vuelven ahi.
; ----------------------------------------------------------------------
mueve_los_objetos:
	xor a			;70a8   ; desde el primero
	ld (0e0e4h),a		;70a9
L_70AC:
	ld hl,0e0e4h		;70ac   ; el objeto que toca
	ld a,(hl)			;70af
	inc hl			;70b0
	add a,a			;70b1   ; por dieciseis
	add a,a			;70b2
	add a,a			;70b3
	add a,a			;70b4
	ld c,a			;70b5
	ld b,000h		;70b6
	add hl,bc			;70b8
	ld (0e0bfh),hl		;70b9   ; y ahi queda apuntado
	inc hl			;70bc
	ld a,(hl)			;70bd   ; su estado
	and a			;70be
	jp z,L_7298		;70bf   ; a cero: hueco libre
	ld hl,0728ah		;70c2   ; la vuelta, apilada a mano
	push hl			;70c5
	call despacha_por_indice		;70c6   ; y detras del call, las ocho ramas

; ----------------------------------------------------------------------
; DATOS tabla_de_objetos: 8 entradas, desde 0x70c6; antes se apila 0x728A como
;   direccion de retorno
;   0x70c9..0x70d9  (16 bytes)
DATA_tabla_de_objetos:
	defw 07289h,070d9h,071a2h,071c6h,070d9h,07209h,0728ah,07209h	; 70c9

; ======================================================================
; CODIGO 0x70d9..0x72af  (470 bytes)
; ======================================================================


L_70D9:
	call L_72B8		;70d9
	call L_71C6		;70dc
	call suelta_el_rival		;70df
	call L_716D		;70e2

; ----------------------------------------------------------------------
; El latido de un objeto suelto: se mueve, mira si choca, y su empuje lateral sale del arcen de SU fila -no de la del coche-, con la fuerza del campo +9 contra la velocidad del jugador. Los dos bits de abajo del arcen dicen hacia donde.
; ----------------------------------------------------------------------
L_70E5:
	call L_72FE		;70e5   ; mira si toca al coche
	call L_7123		;70e8   ; y si toca el borde
	call L_7154		;70eb   ; lo mueve hacia delante
	ld c,006h		;70ee   ; el campo +6, su Y
	call campo_del_objeto		;70f0
	sub 0c0h		;70f3   ; la vuelta del anillo
	cp 040h		;70f5
	ld a,000h		;70f7   ; la fila de arriba
	jr c,L_7101		;70f9
	ld a,(hl)			;70fb   ; y si no, la fila que le toca
	rra			;70fc
	rra			;70fd
	rra			;70fe
	and 01fh		;70ff
L_7101:
	ld c,a			;7101
	ld hl,0e098h		;7102   ; la cola del arcen
	add hl,bc			;7105
	ld d,(hl)			;7106   ; el arcen de su fila
	ld c,009h		;7107   ; el campo +9, su velocidad
	call campo_del_objeto		;7109
	ld a,d			;710c
	and 003h		;710d   ; los dos bits del modo
	ld c,a			;710f
	jp z,L_7289		;7110   ; sin modo no se mueve de lado
	ld a,(0e04fh)		;7113   ; la velocidad del jugador
	sub (hl)			;7116   ; contra la suya
	jr nc,L_711B		;7117
	neg		;7119   ; en valor absoluto
L_711B:
	add a,a			;711b   ; por dos
	ld e,a			;711c
	ld d,000h		;711d
	ld a,c			;711f
	jp L_7145		;7120

; ----------------------------------------------------------------------
; Pasados los 0x0F09 de recorrido -o sea, con la meta ya pintada- los objetos que estan sobre el borde se apartan: se les pone el campo +0xF a cero y se les da un empuje de 0x02F0 hacia dentro.
; ----------------------------------------------------------------------
L_7123:
	ld hl,(0e078h)		;7123   ; lo recorrido
	and a			;7126
	ld bc,00f09h		;7127   ; el hito de la meta
	and a			;712a
	sbc hl,bc		;712b
	ret nc			;712d   ; antes de eso, nada
	ld c,006h		;712e   ; el campo +6
	call campo_del_objeto		;7130
	call busca_el_borde_de_la_calzada		;7133   ; mira el borde
	ret nc			;7136   ; si no lo toca, nada
	ld hl,(0e0bfh)		;7137   ; el objeto
	ld de,0000fh		;713a
	add hl,de			;713d
	ld (hl),000h		;713e   ; el campo +0xF, a cero
	ld e,0f0h		;7140   ; el empuje
	ld d,002h		;7142
	ld a,b			;7144
L_7145:
	dec a			;7145   ; el lado
L_7146:
	jr nz,L_714F		;7146
	ld a,d			;7148   ; hacia el otro lado
	cpl			;7149   ; complemento a dos
	ld d,a			;714a
	ld a,e			;714b
	cpl			;714c
	ld e,a			;714d
	inc de			;714e
L_714F:
	ld c,008h		;714f   ; y al campo +8, la x
	jp suma_al_campo		;7151

; ----------------------------------------------------------------------
; Lo mueve hacia delante: la diferencia entre la velocidad del jugador y la suya, por ocho, sumada a su Y. Por eso los que van mas despacio que el coche bajan por la pantalla y los que van mas rapido suben.
; ----------------------------------------------------------------------
L_7154:
	ld c,009h		;7154   ; el campo +9, su velocidad
	call campo_del_objeto		;7156
	ld e,(hl)			;7159
	inc hl			;715a
	ld d,(hl)			;715b
	ld h,b			;715c
	ld a,(0e04fh)		;715d   ; la velocidad del jugador
	ld l,a			;7160
	and a			;7161
	sbc hl,de		;7162   ; menos la suya
	add hl,hl			;7164   ; por ocho
	add hl,hl			;7165
	add hl,hl			;7166
	ex de,hl			;7167
L_7168:
	ld c,006h		;7168   ; y al campo +6, la Y
	jp suma_al_campo		;716a

; ----------------------------------------------------------------------
; Solo para los objetos del tipo 3: si el coche se le acerca a menos de 0x20 por delante, el objeto se pone a huir hacia el lado contrario al que viene el coche -campo +0xE- y pasa al estado 5.
; ----------------------------------------------------------------------
L_716D:
	ld hl,(0e0bfh)		;716d   ; el objeto
	ld a,(hl)			;7170   ; su tipo
	cp 003h		;7171   ; solo el 3
	ret nz			;7173
	ld bc,00006h		;7174   ; el campo +6, su Y
	add hl,bc			;7177
	ld a,(0e04ch)		;7178   ; la Y del coche
	sub 040h		;717b   ; 0x40 por delante
	cp (hl)			;717d
	ret c			;717e   ; si esta mas lejos, nada
	ld b,a			;717f
	ld a,(hl)			;7180
	add a,020h		;7181   ; y 0x20 por detras
	cp b			;7183
	ret c			;7184
	inc hl			;7185
	inc hl			;7186
	ld a,(0e04eh)		;7187   ; la x del coche
	cp (hl)			;718a   ; contra la suya
	push af			;718b
	ld bc,00006h		;718c
	add hl,bc			;718f
	pop af			;7190
	ld a,001h		;7191   ; se aparta hacia un lado
	jr nc,L_7196		;7193
	dec a			;7195   ; o hacia el otro
L_7196:
	ld (hl),a			;7196   ; al campo +0xE
	inc hl			;7197
	ld (hl),020h		;7198   ; con 0x20 de cuenta
	ld a,005h		;719a   ; y al estado 5
L_719C:
	ld hl,(0e0bfh)		;719c   ; el objeto
	inc hl			;719f
	ld (hl),a			;71a0   ; su estado nuevo
	ret			;71a1

; ----------------------------------------------------------------------
; El estado 5, el del objeto que huye: mientras le quede cuenta en el campo +0xF se aparta a un lado y frena; al agotarse o al tocar el borde, vuelve al estado 1.
; ----------------------------------------------------------------------
L_71A2:
	ld c,006h		;71a2   ; el campo +6
	call campo_del_objeto		;71a4   ; mira el borde
	call busca_el_borde_de_la_calzada		;71a7
	jr c,L_71C2		;71aa   ; si lo toca, se acabo
	ld c,00fh		;71ac   ; el campo +0xF
	call campo_del_objeto		;71ae
	dec (hl)			;71b1   ; una menos
	jr z,L_71C2		;71b2   ; al agotarse, tambien
	dec hl			;71b4
	ld a,(hl)			;71b5   ; hacia que lado se aparta
	ld de,00100h		;71b6   ; un pixel entero
	call L_7145		;71b9
	ld de,0ff00h		;71bc   ; y frena
	jp L_7168		;71bf
L_71C2:
	ld a,001h		;71c2   ; vuelve al estado 1
	jr L_719C		;71c4

; ----------------------------------------------------------------------
; El choque de un objeto CONTRA EL OTRO. Solo lo mira el que va a mas de 0xD7 de velocidad, y con margenes distintos por eje: 0x20 a lo largo y 0x10 a lo ancho. Los dos pasan al estado 7 con 0x18 de cuenta, cada uno apartandose hacia su lado.
; ----------------------------------------------------------------------
L_71C6:
	ld c,009h		;71c6   ; el campo +9, su velocidad
	call campo_del_objeto		;71c8
	ex de,hl			;71cb
	ld a,(de)			;71cc
	cp 0d7h		;71cd   ; por debajo de 0xD7 no choca con nadie
	ret c			;71cf
	dec de			;71d0
	ld a,(0e0e4h)		;71d1   ; cual de los dos se esta mirando
	ld hl,0e0e5h		;71d4   ; el primer objeto
	and a			;71d7
	jr nz,L_71DC		;71d8
	ld l,0f5h		;71da   ; o el segundo
L_71DC:
	ld c,008h		;71dc   ; el campo +8, la x
	add hl,bc			;71de
	ld c,(hl)			;71df
	ld a,(de)			;71e0   ; la del otro
	ld b,a			;71e1
	sub (hl)			;71e2
	sub 010h		;71e3   ; con 0x20 de margen
	add a,020h		;71e5
	ret nc			;71e7   ; si no se solapan, nada
	dec hl			;71e8
	dec hl			;71e9
	dec de			;71ea
	dec de			;71eb
	ld a,(de)			;71ec   ; la Y del otro
	sub 028h		;71ed   ; con 0x10 de margen
	sub (hl)			;71ef
	sub 008h		;71f0
	add a,010h		;71f2
	ret nc			;71f4   ; y si tampoco, nada
	ld a,c			;71f5   ; por que lado se ha tocado
	cp b			;71f6
	ld a,000h		;71f7
	jr nc,L_71FC		;71f9
	inc a			;71fb
L_71FC:
	ex de,hl			;71fc   ; el otro objeto
	ld bc,00008h		;71fd
	add hl,bc			;7200
	ld (hl),a			;7201   ; el lado por el que sale
	inc hl			;7202
	ld (hl),018h		;7203   ; con 0x18 de cuenta
	ld a,007h		;7205   ; y al estado 7
	jr L_719C		;7207

; ----------------------------------------------------------------------
; El estado 7, el del objeto que rebota: se aparta a un lado mientras le quede cuenta en el campo +0xE, con empuje 0xB8 si es del tipo 5 y 0xA0 si no. Al acabarse, vuelve al estado 1.
; ----------------------------------------------------------------------
L_7209:
	ld hl,(0e0bfh)		;7209   ; el objeto
	inc hl			;720c
	ld d,(hl)			;720d   ; su tipo
	ld bc,0000eh		;720e   ; el campo +0xE
	add hl,bc			;7211
	dec (hl)			;7212   ; una menos
	jp m,L_71C2		;7213   ; al pasarse de cero, se acabo
	dec hl			;7216
	ld a,d			;7217
	ld de,000b8h		;7218   ; el empuje del tipo 5
	cp 005h		;721b
	jr z,L_7221		;721d
	ld e,0a0h		;721f   ; y el de los demas
L_7221:
	ld a,(hl)			;7221   ; hacia que lado
	or a			;7222
	call L_7146		;7223
	jp L_70E5		;7226   ; y sigue con el latido normal

; ----------------------------------------------------------------------
; Dibuja el objeto, y los de los tipos 6 y 7 llevan un segundo sprite 0x10 pixeles mas abajo: son los que ocupan dos casillas de alto.
; ----------------------------------------------------------------------
L_7229:
	call L_724B		;7229   ; el primer sprite
	ex af,af'			;722c
	cp 006h		;722d   ; el tipo 6
	jr z,L_7234		;722f
	cp 007h		;7231   ; o el 7
	ret nz			;7233
L_7234:
	ld a,b			;7234   ; 0x10 pixeles mas abajo
	add a,010h		;7235
	ld b,a			;7237
	ex af,af'			;7238
	add a,004h		;7239   ; y cuatro patrones mas alla
	ld hl,0e132h		;723b   ; el sitio del segundo sprite
	call L_727D		;723e
	dec hl			;7241
	ld (hl),008h		;7242   ; su color
	ld bc,0fffch		;7244
	add hl,bc			;7247
	ld (hl),001h		;7248   ; y el del primero
	ret			;724a

; ----------------------------------------------------------------------
; Deja el objeto en la copia de atributos de sprite. Los tipos 2 y 4 PARPADEAN: cada cuatro fotogramas se les sube la Y en uno, que es lo que hace que se vean temblando. Con la Y en 0xD0 no se escribe nada, porque 0xD0 es el valor que le dice al VDP que ahi se acaban los sprites.
; ----------------------------------------------------------------------
L_724B:
	ld hl,(0e0bfh)		;724b   ; el objeto
	ex af,af'			;724e
	ld a,(hl)			;724f   ; su tipo
	ld e,a			;7250
	ex af,af'			;7251
	ld bc,00006h		;7252   ; el campo +6, su Y
	add hl,bc			;7255
	ld b,(hl)			;7256
	ld a,e			;7257
	cp 002h		;7258   ; el tipo 2
	jr z,L_7260		;725a
	cp 004h		;725c   ; o el 4
	jr nz,L_7268		;725e
L_7260:
	ld a,(0e003h)		;7260   ; el reloj
	and 003h		;7263   ; uno de cada cuatro
	jr nz,L_7268		;7265
	inc b			;7267   ; y un pixel mas abajo
L_7268:
	inc hl			;7268
	inc hl			;7269
	ld c,(hl)			;726a   ; el campo +8, su x
	ld a,(0e0e4h)		;726b   ; cual de los dos es
	call sitio_del_sprite		;726e   ; su sitio en la copia
	ld a,b			;7271
	cp 0d0h		;7272   ; 0xD0 le corta al VDP la lista de sprites
	ret z			;7274
	ld a,e			;7275
	ld de,072afh		;7276   ; la tabla de patrones por tipo
	call suma_a_de		;7279
	ld a,(de)			;727c
L_727D:
	call L_7282		;727d   ; el primer sprite
	add a,004h		;7280   ; y el segundo, cuatro patrones mas alla
L_7282:
	ld (hl),b			;7282   ; la fila
	inc hl			;7283
	ld (hl),c			;7284   ; la columna
	inc hl			;7285
	ld (hl),a			;7286   ; el patron
	inc hl			;7287
	inc hl			;7288   ; y al sprite siguiente
L_7289:
	ret			;7289

; ----------------------------------------------------------------------
; La vuelta comun de las ocho ramas, la que se apilo antes del `call`. Dibuja el objeto y, si su Y ha entrado en la franja 0xC3..0xCE, lo retira: le pone 0xDF de Y y lo deja libre.
; ----------------------------------------------------------------------
L_728A:
	call L_7229		;728a   ; dibujalo
	ld c,006h		;728d   ; el campo +6, su Y
	call campo_del_objeto		;728f
	sub 0c3h		;7292   ; la franja de retirada
	cp 00ch		;7294
	jr c,L_72A4		;7296   ; si ha entrado, se retira
L_7298:
	ld hl,0e0e4h		;7298   ; cual se estaba mirando
	inc (hl)			;729b   ; el siguiente
	ld a,(hl)			;729c
	dec hl			;729d
	cp 002h		;729e   ; y son dos
	jp nz,L_70AC		;72a0
	ret			;72a3
L_72A4:
	ld (hl),0dfh		;72a4   ; fuera de la pantalla
	xor a			;72a6
	call L_719C		;72a7   ; y el hueco, libre
	call L_7229		;72aa   ; dibujado por ultima vez
	jr L_7298		;72ad

; ----------------------------------------------------------------------
; DATOS datos_72af: nueve bytes que carga 0x7276
;   0x72af..0x72b8  (9 bytes)
DATA_datos_72af:
	defb 07ch,000h,000h,084h,08ch,08ch,050h,050h,060h	; 72af  |.....PP`

; ======================================================================
; CODIGO 0x72b8..0x73fc  (324 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El aviso de que viene un objeto del tipo 1: si el coche esta a menos de ocho pixeles de el y va a mas de 0x90, suena el efecto 9. En demostracion no suena.
; ----------------------------------------------------------------------
L_72B8:
	ld a,(0e002h)		;72b8   ; las banderas de la partida
	bit 6,a		;72bb   ; en demostracion no
	ret z			;72bd
	ld a,(0e049h)		;72be   ; el estado del coche
	dec a			;72c1   ; reventado, no
	ret z			;72c2
	dec a			;72c3   ; ni en trompo
	dec a			;72c4
	ret z			;72c5
	ld hl,(0e0bfh)		;72c6   ; el objeto
	ld a,(hl)			;72c9   ; su tipo
	dec a			;72ca   ; solo el 1
	ret nz			;72cb
	ld a,006h		;72cc   ; el campo +6, su Y
	call suma_a_hl		;72ce
	ld a,(0e04ch)		;72d1   ; la Y del coche
	sub 034h		;72d4   ; con ocho pixeles de margen
	sub (hl)			;72d6
	sub 008h		;72d7
	add a,008h		;72d9
	ret nc			;72db   ; si esta mas lejos, nada
	ld a,(0e04fh)		;72dc   ; la velocidad
	cp 090h		;72df   ; por debajo de 0x90, tampoco
	ret c			;72e1
	ld a,009h		;72e2   ; el efecto del aviso
	jp suena		;72e4

; ----------------------------------------------------------------------
; Le suma DE a la palabra de 16 bits que acaba en el campo C del objeto en curso. Junto con L_72F6 es todo el acceso a los objetos que hay en el cartucho: por eso el `ld c,006h` -la Y- y el `ld c,009h` -la velocidad- salen por todas partes.
; ----------------------------------------------------------------------
suma_al_campo:
	call campo_del_objeto		;72e7   ; el campo
	push hl			;72ea
	ld a,(hl)			;72eb   ; su byte alto
	dec hl			;72ec
	ld l,(hl)			;72ed   ; y el bajo
	ld h,a			;72ee
	add hl,de			;72ef   ; la suma
	ex de,hl			;72f0
	pop hl			;72f1
	ld (hl),d			;72f2   ; y ahi queda
	dec hl			;72f3
	ld (hl),e			;72f4
	ret			;72f5

; ----------------------------------------------------------------------
; Traeme el campo C del objeto que se esta mirando. Deja HL apuntandolo y su valor en A.
; ----------------------------------------------------------------------
campo_del_objeto:
	ld b,000h		;72f6
	ld hl,(0e0bfh)		;72f8   ; el objeto en curso
	add hl,bc			;72fb   ; mas el numero de campo
	ld a,(hl)			;72fc
	ret			;72fd

; ----------------------------------------------------------------------
; El choque de un objeto CONTRA EL COCHE, con margenes 0x20 a lo largo y 0x14 a lo ancho. Solo lo miran los que van a 0xD7 o mas.
; ----------------------------------------------------------------------
L_72FE:
	ld hl,(0e0bfh)		;72fe
	inc hl			;7301
	ld a,(hl)			;7302   ; su estado
	or a			;7303
	ret z			;7304   ; libre, nada
	ld c,009h		;7305   ; el campo +9, su velocidad
	call campo_del_objeto		;7307
	cp 0d7h		;730a   ; por debajo de 0xD7 no golpea
	ret c			;730c
	dec hl			;730d
	dec hl			;730e
	dec hl			;730f
	ld a,(0e0e4h)		;7310   ; cual se esta mirando
	ld de,0e0ebh		;7313   ; el primer objeto
	or a			;7316
	jr nz,L_731B		;7317
	ld e,0fbh		;7319   ; o el segundo
L_731B:
	ld a,(de)			;731b   ; su Y
	sub (hl)			;731c
	sub 010h		;731d   ; con 0x20 de margen
	add a,020h		;731f
	ret nc			;7321   ; si no se solapan, nada
	inc hl			;7322
	inc hl			;7323
	inc de			;7324
	inc de			;7325
	ld a,(de)			;7326   ; y ahora la x
	sub (hl)			;7327
	sub 00ah		;7328   ; con 0x14
	add a,014h		;732a
	ret nc			;732c   ; si tampoco, nada
	ld a,(de)			;732d
	sub (hl)			;732e
	ld a,001h		;732f   ; por que lado ha sido
	jr c,L_7334		;7331
	xor a			;7333
L_7334:
	ex de,hl			;7334   ; el otro
	ld bc,0fff9h		;7335   ; siete campos atras
	add hl,bc			;7338
	call L_7352		;7339   ; mira que le pasa al coche
	ret z			;733c
	dec a			;733d
	ld hl,(0e0bfh)		;733e   ; el objeto
	inc hl			;7341
	ld (hl),002h		;7342   ; al estado 2
	xor 001h		;7344   ; y hacia el lado contrario
	push af			;7346
	ld c,00eh		;7347   ; el campo +0xE
	call campo_del_objeto		;7349
	pop af			;734c
	ld (hl),a			;734d   ; el lado
	inc hl			;734e
	ld (hl),010h		;734f   ; con 0x10 de cuenta
	ret			;7351

; ----------------------------------------------------------------------
; Lo que le pasa al COCHE cuando un objeto le golpea: si estaba en un estado de rodar -6 o 7- no pasa nada, y si no, pasa al estado 2 con 0x0C de cuenta y apartandose hacia el lado del golpe.
; ----------------------------------------------------------------------
L_7352:
	ld b,a			;7352
	dec hl			;7353   ; el estado del coche
	ld a,(hl)			;7354
	sub 006h		;7355   ; los estados 6 y 7
	cp 002h		;7357
	inc hl			;7359
	ret c			;735a   ; en esos no pasa nada
	ld a,(hl)			;735b   ; y si ya estaba tocado, tampoco
	or a			;735c
	ret z			;735d
	ld a,b			;735e
	ld (hl),002h		;735f   ; al estado 2
	ld bc,0000dh		;7361   ; trece campos mas alla
	add hl,bc			;7364
	ld (hl),a			;7365   ; el lado del golpe
	inc hl			;7366
	ld (hl),00ch		;7367   ; con 0x0C de cuenta
	inc a			;7369
	ret			;736a

; ----------------------------------------------------------------------
; El sitio que le toca al objeto A en la copia de atributos de sprite: ocho bytes por objeto desde 0xE11A, o sea dos sprites cada uno.
; ----------------------------------------------------------------------
sitio_del_sprite:
	add a,a			;736b   ; por ocho
	add a,a			;736c
	add a,a			;736d
	ld hl,0e11ah		;736e   ; la copia de atributos
	jp suma_a_hl		;7371

; ----------------------------------------------------------------------
; Sube el contador de 0xE056 con un paso que depende del NIVEL: 0x0180 en el primero y 0x01FF en el segundo. En el segundo se gasta mas deprisa. Con el coche reventado no cuenta.
; ----------------------------------------------------------------------
gasta_gasolina:
	ld a,(0e049h)		;7374   ; el estado del coche
	dec a			;7377
	ret z			;7378   ; reventado, no cuenta
	ld bc,001ffh		;7379   ; el paso del segundo nivel
	ld a,(0e03bh)		;737c   ; el nivel
	or a			;737f
	jr nz,L_7384		;7380
	ld c,080h		;7382   ; y el del primero, mas corto
L_7384:
	ld hl,(0e056h)		;7384   ; el contador
	add hl,bc			;7387
	ld (0e056h),hl		;7388   ; y ahi queda
	ret			;738b

; ----------------------------------------------------------------------
; EL CUENTAKILOMETROS: suma la velocidad a (0xE077) y, cada vez que ese byte desborda, sube uno lo recorrido de (0xE078). Asi la etapa se mide en distancia y no en tiempo: los 0x0F12 del final llegan antes si se va rapido. De paso guarda la velocidad en (0xE051), salvo en trompo, que es cuando ese hueco lo usa el giro.
; ----------------------------------------------------------------------
cuentakilometros:
	ld hl,0e077h		;738c   ; la fraccion de lo recorrido
	ld a,(0e04fh)		;738f   ; la velocidad
	add a,(hl)			;7392   ; sumada
	ld (hl),a			;7393
	jr nc,L_73A0		;7394   ; sin desbordar, nada mas
	ld de,00001h		;7396
	ld hl,(0e078h)		;7399   ; lo recorrido
	add hl,de			;739c   ; uno mas
	ld (0e078h),hl		;739d
L_73A0:
	ld a,(0e049h)		;73a0   ; el estado del coche
	cp 005h		;73a3   ; en trompo (0xE051) es el giro
	ld a,(0e04fh)		;73a5   ; y si no, la velocidad
	jr z,barra_de_velocidad		;73a8
	ld (0e051h),a		;73aa   ; se guarda ahi

; ----------------------------------------------------------------------
; La aguja de SPEED, dibujada de arriba abajo en la columna 0x3AD8: la velocidad se parte en tramos de 0x20 y cada tramo pinta tres tiles de la tabla de 0x73FC, subiendo 0x20 de VRAM por fila. Lo que sobra se rellena con los tres tiles de 0x7408 hasta llegar a la fila 0x39.
; ----------------------------------------------------------------------
barra_de_velocidad:
	ld a,(0e04fh)		;73ad   ; la velocidad
	ld l,0d8h		;73b0   ; la columna de SPEED
L_73B2:
	ld h,03ah		;73b2   ; la fila de abajo
	or a			;73b4
	jr z,L_73F1		;73b5   ; a cero no se pinta nada
	push af			;73b7
	and 0e0h		;73b8   ; los tres bits de arriba
L_73BA:
	sub 020h		;73ba   ; un tramo de 0x20
	jr c,L_73D4		;73bc   ; y si no llega, lo que quede
	ld de,073fch		;73be   ; los tiles de la barra
	push af			;73c1
	ld a,009h		;73c2   ; los tres ultimos: la barra llena
	call suma_a_de		;73c4
	ld bc,00003h		;73c7   ; tres tiles por fila
	call sube_a_la_vram		;73ca
	ld bc,0ffe0h		;73cd   ; una fila mas arriba
	add hl,bc			;73d0
	pop af			;73d1
	jr L_73BA		;73d2
L_73D4:
	pop af			;73d4   ; lo que quedaba
	rra			;73d5   ; en tramos de ocho
	rra			;73d6
	rra			;73d7
	and 003h		;73d8   ; uno de cuatro
	ld b,a			;73da
	add a,a			;73db   ; por tres
	add a,b			;73dc
	ld de,073fch		;73dd   ; los tiles de la barra
	call suma_a_de		;73e0
	ld bc,00003h		;73e3   ; tres tiles
	call sube_a_la_vram		;73e6
L_73E9:
	ld bc,0ffe0h		;73e9   ; una fila mas arriba
	add hl,bc			;73ec
	ld a,039h		;73ed   ; hasta la fila 0x39
	cp h			;73ef
	ret z			;73f0
L_73F1:
	ld de,07408h		;73f1   ; y el resto, en blanco
	ld bc,00003h		;73f4
	call sube_a_la_vram		;73f7
	jr L_73E9		;73fa

; ----------------------------------------------------------------------
; DATOS tiles_de_la_barra: doce tiles en 0x73fc para la barra vertical de
;   0x73ba, de tres en tres y subiendo de 0x20 en 0x20, mas los tres de 0x7408
;   que rellenan el resto
;   0x73fc..0x740b  (15 bytes)
DATA_tiles_de_la_barra:
	defb 06ch,06dh,06eh	; 73fc
	defb 069h,06ah,06bh	; 73ff
	defb 066h,067h,068h	; 7402
	defb 063h,064h,065h	; 7405
	defb 061h,004h,062h	; 7408

; ======================================================================
; CODIGO 0x740b..0x7475  (106 bytes)
; ======================================================================


L_740B:
	call barra_de_velocidad		;740b
	jp L_7444		;740e

; ----------------------------------------------------------------------
; EL DEPOSITO. Cada vez que el bit 5 de (0xE057) cambia -o sea, cada 0x20 pasos del contador de 0x7374- baja uno (0xE083), y al llegar a cero el coche pasa al estado 2, el que gasta velocidad hasta pararse. Con menos de 0x10 en el deposito suena el efecto 2, que es el aviso de reserva.
; ----------------------------------------------------------------------
baja_la_gasolina:
	ld a,(0e057h)		;7411   ; el contador
	ld b,020h		;7414   ; su bit 5
	and b			;7416
	ld d,a			;7417
	ld hl,0e084h		;7418   ; y como estaba
	ld a,(hl)			;741b
	and b			;741c
	xor d			;741d   ; si no ha cambiado, nada
	ret z			;741e
	ld a,(hl)			;741f
	xor b			;7420   ; se apunta
	ld (hl),a			;7421
	dec hl			;7422
	ld a,(hl)			;7423   ; el deposito
	and a			;7424   ; vacio ya
	jr z,L_742C		;7425
	dec (hl)			;7427   ; uno menos
	ld a,(hl)			;7428
	or a			;7429   ; y si se acaba de vaciar
	jr nz,L_7431		;742a
L_742C:
	ld hl,0e049h		;742c   ; el estado del coche
	ld (hl),002h		;742f   ; al 2
L_7431:
	call L_7444		;7431   ; dibuja el deposito
	ld a,(0e083h)		;7434   ; lo que queda
	cp 010h		;7437   ; de 0x10 para arriba, sin aviso
	ret nc			;7439
	ld a,(0e028h)		;743a   ; si hay otro efecto sonando, tampoco
	or a			;743d
	ret nz			;743e
	ld a,002h		;743f   ; el aviso de reserva
	jp suena		;7441
L_7444:
	ld a,(0e083h)		;7444   ; el deposito
	ld l,0dbh		;7447   ; la columna de FUEL
	jp L_73B2		;7449   ; la misma barra que la velocidad

; ----------------------------------------------------------------------
; Monta la pantalla del final de etapa: descomprime sus patrones en 0x2400 y sus colores en 0x0400, pega el rectangulo de 21 por 5 tiles y copia los ocho bytes de 0x7475 sobre las variables del coche, que lo dejan en la Y 0xA8 y la x 0x63.
; ----------------------------------------------------------------------
monta_la_pantalla_de_la_meta:
	ld hl,02400h		;744c   ; los patrones
	ld de,074bch		;744f
	call descomprime_los_tres_tercios		;7452   ; los tres tercios
	ld hl,00400h		;7455   ; y los colores
	ld de,07638h		;7458
	call descomprime_los_tres_tercios		;745b
	ld hl,0382bh		;745e   ; la tabla de nombres
	ld de,076ech		;7461
	ld bc,01505h		;7464   ; 21 filas de 5
	call rectangulo_de_tiles		;7467
	ld hl,07475h		;746a   ; las variables del coche
	ld de,0e04ch		;746d
	ld c,008h		;7470   ; ocho bytes
	ldir		;7472
	ret			;7474

; ----------------------------------------------------------------------
; DATOS datos_7475: ocho bytes que 0x746a copia a 0xE04C con un ldir de ocho
;   0x7475..0x747d  (8 bytes)
DATA_datos_7475:
	defb 0a8h,000h,063h,000h,000h,000h,000h,00ah	; 7475  ..c.....

; ======================================================================
; CODIGO 0x747d..0x74b6  (57 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; El paso 2 del final de etapa: baja la Y del coche de uno en uno -o sea, lo sube por la pantalla- hasta que iguale el byte de su etapa en la tabla de 0x74B6. Como esos bytes van bajando de etapa en etapa -0x8B, 0x71, 0x54, 0x3A, 0x1B, 0x00-, cada etapa lo hace subir un trecho mas largo.
; ----------------------------------------------------------------------
entra_el_coche_en_la_etapa:
	call dibuja_el_coche		;747d   ; dibujalo
	ld a,(0e043h)		;7480   ; la etapa
	dec a			;7483
	ld de,074b6h		;7484   ; la tabla de alturas
	call suma_a_de		;7487
	ld a,(de)			;748a
	ld hl,0e04ch		;748b
	dec (hl)			;748e   ; un pixel mas arriba
	cp (hl)			;748f   ; hasta la altura de su etapa
	ret nz			;7490
	xor a			;7491
	jp L_4167		;7492   ; y al paso siguiente

; ----------------------------------------------------------------------
; El paso 3: el coche parpadea. El bit 4 de la cuenta atras alterna su Y entre 0xC8 -fuera, debajo del borde- y la altura de su etapa, asi que se enciende y se apaga cada dieciseis fotogramas hasta que la cuenta se agota.
; ----------------------------------------------------------------------
parpadea_el_coche:
	call dibuja_el_coche		;7495   ; dibujalo
	ld hl,0e004h		;7498   ; la cuenta atras
	dec (hl)			;749b   ; al acabarse, al paso siguiente
	jr z,L_74B3		;749c
	bit 4,(hl)		;749e   ; el bit 4
	ld a,0c8h		;74a0   ; con el puesto, fuera de la pantalla
	jr nz,L_74AF		;74a2
	ld a,(0e043h)		;74a4   ; y sin el, a la altura de su etapa
	dec a			;74a7
	ld de,074b6h		;74a8
	call suma_a_de		;74ab
	ld a,(de)			;74ae
L_74AF:
	ld (0e04ch),a		;74af   ; la Y del coche
	ret			;74b2
L_74B3:
	jp L_416A		;74b3

; ----------------------------------------------------------------------
; DATOS altura_del_coche_por_etapa: seis bytes, uno por etapa: 0x8B 0x71 0x54
;   0x3A 0x1B 0x00. Es la Y en la que el coche se planta al rematar la etapa:
;   0x747D, el paso 2 de la escena de fin, baja (0xE04C) de uno en uno -o sea,
;   sube el coche por la pantalla- hasta igualar el byte de esa etapa.
;   (0xE04C) es la Y del sprite, MEDIDA contra la VRAM del emulador, no una
;   cuenta atras
;   0x74b6..0x74bc  (6 bytes)
DATA_altura_del_coche_por_etapa:
	defb 08bh,071h,054h,03ah,01bh,000h	; 74b6

; ----------------------------------------------------------------------
; DATOS rle_patron_2400_c: 380 bytes -> 408 de PATRON en 0x2400 (51 tiles). Lo
;   carga 0x7452
;   0x74bc..0x7638  (380 bytes)
DATA_rle_patron_2400_c:
	defb 085h,028h,074h,038h,054h,028h,005h,000h,088h,040h,004h,000h,000h,020h,000h,060h	; 74bc  .(t8T(...@... .`
	defb 0e0h,005h,0c0h,093h,0e0h,000h,080h,00ch,048h,038h,024h,001h,000h,060h,060h,070h	; 74cc  ........H8$..``p
	defb 030h,030h,038h,018h,018h,00fh,00dh,003h,00fh,084h,0f8h,080h,008h,004h,005h,07fh	; 74dc  008.............
	defb 09ah,008h,000h,01ch,00ch,00ch,00eh,006h,007h,003h,003h,000h,040h,000h,000h,0bdh	; 74ec  ............@...
	defb 029h,0dfh,0b2h,000h,000h,002h,000h,0f0h,0e0h,0e0h,0c0h,004h,003h,088h,0f8h,0f9h	; 74fc  )...............
	defb 0f1h,0f1h,000h,000h,002h,000h,004h,0ffh,002h,000h,08eh,002h,000h,00fh,00fh,01fh	; 750c  ................
	defb 01fh,0c1h,088h,0ebh,0c1h,0ebh,0c1h,0ebh,0c1h,004h,0fch,087h,0f8h,0f9h,0f1h,0f3h	; 751c  ................
	defb 003h,003h,007h,003h,003h,002h,001h,003h,01fh,003h,03fh,002h,01fh,0b2h,0ebh,0c1h	; 752c  ..........?.....
	defb 0ebh,0c1h,0ebh,088h,0c1h,07fh,0e3h,0e7h,0e7h,0c7h,0cfh,0cfh,08fh,09fh,001h,001h	; 753c  ................
	defb 003h,003h,007h,007h,003h,003h,00fh,00fh,01fh,01fh,03fh,07fh,03fh,01fh,001h,024h	; 754c  ..........?.?..$
	defb 042h,009h,025h,085h,082h,030h,09fh,027h,027h,09fh,08bh,093h,025h,0c5h,09fh,01fh	; 755c  B.%..0.''...%...
	defb 005h,03fh,088h,01fh,03fh,0bfh,0e7h,0efh,0cfh,09bh,0f7h,003h,09fh,091h,08fh,0cfh	; 756c  .?..?...........
	defb 0cfh,0c7h,0e7h,0e7h,0feh,0fdh,0f3h,0f8h,0feh,0f3h,0e7h,0f8h,036h,0c9h,08ah,005h	; 757c  ............6...
	defb 0ffh,005h,0e7h,083h,066h,0e7h,066h,004h,0e7h,0a9h,066h,0e7h,066h,0e7h,0c0h,0f0h	; 758c  ....f.f...f.f...
	defb 0bch,0deh,0deh,0fch,0fch,0f8h,000h,004h,080h,090h,0c1h,0c0h,080h,008h,0e3h,0f3h	; 759c  ................
	defb 0f1h,0f9h,0f9h,0f1h,0f3h,0f3h,028h,098h,07eh,0b4h,010h,020h,060h,01ch,0f8h,0ech	; 75ac  ......(.~.. `...
	defb 0e6h,0e7h,0ffh,003h,0feh,002h,000h,08eh,082h,0c0h,0c0h,080h,084h,000h,0e3h,0e7h	; 75bc  ................
	defb 0e7h,0c7h,0cfh,0cfh,08fh,09fh,003h,0ffh,005h,0c7h,084h,0ech,0dch,0f8h,0f0h,004h	; 75cc  ................
	defb 0ffh,002h,007h,002h,080h,004h,0ffh,082h,09fh,01fh,005h,03fh,086h,01fh,020h,000h	; 75dc  ...........?.. .
	defb 082h,000h,0ffh,003h,0c3h,003h,0ffh,003h,0c3h,002h,0ffh,002h,0f8h,002h,0feh,09ch	; 75ec  ................
	defb 0ffh,0e3h,0e3h,0ffh,0e3h,0f3h,0f1h,0f9h,0f8h,0f8h,0fch,0fch,000h,000h,080h,080h	; 75fc  ................
	defb 0c0h,0e0h,0e0h,0f8h,09fh,09fh,08fh,0cfh,0cfh,0c7h,0e7h,0e7h,004h,0fch,09ch,0f8h	; 760c  ................
	defb 0f9h,0f1h,0f3h,0e3h,0e7h,0e7h,0c7h,0cfh,0cfh,08fh,09fh,0ffh,0f8h,0f8h,0ffh,0f8h	; 761c  ................
	defb 0f8h,0ffh,0ffh,014h,03eh,014h,03eh,014h,03eh,014h,03eh,000h	; 762c  ....>.>.>.>.

; ----------------------------------------------------------------------
; DATOS rle_color_0400_c: 180 bytes -> 408 de COLOR en 0x0400. Lo carga 0x745b
;   0x7638..0x76ec  (180 bytes)
DATA_rle_color_0400_c:
	defb 008h,02fh,008h,07fh,008h,0efh,002h,07fh,004h,09fh,002h,07fh,008h,0efh,005h,06fh	; 7638  ./.............o
	defb 081h,0f0h,003h,07fh,005h,0f0h,002h,07fh,008h,0efh,004h,07fh,004h,06ch,004h,07fh	; 7648  .............l..
	defb 004h,069h,004h,0efh,004h,09eh,004h,07fh,004h,090h,004h,07fh,004h,056h,081h,061h	; 7658  .i...........V.a
	defb 007h,091h,008h,09eh,008h,069h,008h,056h,006h,091h,082h,061h,069h,008h,09eh,008h	; 7668  .....i.V...ai...
	defb 069h,008h,056h,003h,09ch,083h,01ch,09ch,01ch,00ah,09ch,008h,09eh,088h,09ch,091h	; 7678  i.V.............
	defb 09ch,091h,09ch,09ch,091h,091h,008h,09eh,088h,09ch,091h,09ch,09ch,091h,09ch,09ch	; 7688  ................
	defb 091h,004h,09ch,004h,040h,004h,09eh,081h,04eh,003h,07eh,004h,04eh,003h,07eh,081h	; 7698  ....@...N.~.N.~.
	defb 04eh,008h,07fh,008h,0fbh,008h,0beh,004h,0cbh,003h,06bh,081h,01bh,008h,07fh,008h	; 76a8  N.........k.....
	defb 0fbh,008h,0beh,008h,0bdh,004h,07fh,004h,020h,084h,05bh,04bh,0fbh,0fbh,004h,020h	; 76b8  ........ .[K... 
	defb 008h,0beh,004h,0fbh,002h,029h,002h,028h,004h,029h,004h,028h,006h,02fh,082h,02eh	; 76c8  .....).(.).(./..
	defb 02fh,008h,02eh,008h,0fbh,004h,0beh,014h,02eh,002h,027h,002h,025h,081h,027h,003h	; 76d8  /.........'.%.'.
	defb 025h,008h,019h,000h	; 76e8

; ----------------------------------------------------------------------
; DATOS rectangulo_de_nombres: 21 filas de 5 tiles que 0x7467 escribe en la
;   tabla de nombres desde 0x382b, con L_4575 (`ld bc,01505h`), saltando 0x20
;   por fila
;   0x76ec..0x7755  (105 bytes)
DATA_rectangulo_de_nombres:
	defb 080h,081h,082h,083h,080h	; 76ec
	defb 080h,081h,084h,080h,083h	; 76f1
	defb 085h,086h,087h,085h,086h	; 76f6
	defb 088h,089h,08ah,08bh,08ch	; 76fb
	defb 08dh,009h,092h,093h,094h	; 7700
	defb 0b2h,009h,097h,08fh,090h	; 7705
	defb 091h,009h,099h,093h,094h	; 770a
	defb 095h,098h,092h,09ah,095h	; 770f
	defb 095h,096h,097h,09ah,095h	; 7714
	defb 095h,096h,099h,09ah,095h	; 7719
	defb 09bh,09bh,09ch,09bh,09bh	; 771e
	defb 004h,004h,09dh,004h,004h	; 7723
	defb 004h,004h,09dh,004h,004h	; 7728
	defb 004h,004h,09dh,004h,004h	; 772d
	defb 0adh,0a1h,0a0h,0a1h,00bh	; 7732
	defb 09eh,09fh,0a4h,0a1h,0a1h	; 7737
	defb 0a2h,0a3h,0a8h,0a5h,0a1h	; 773c
	defb 0a6h,0a7h,0aeh,0a9h,0a9h	; 7741
	defb 0abh,0abh,0ach,0aah,0b1h	; 7746
	defb 0aah,0aah,0afh,0b1h,0abh	; 774b
	defb 0b1h,0abh,0b0h,0abh,0aah	; 7750

; ======================================================================
; CODIGO 0x7755..0x7791  (60 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Lo que pasa despues de un golpe: se recupera la velocidad, se apunta la bonificacion segun cuantos rivales se habian pasado y suena el efecto 3.
; ----------------------------------------------------------------------
remate_del_choque:
	ld a,(0e0b8h)		;7755   ; (0xE0B8) es la fase del choque
	dec a			;7758
	jr z,L_775F		;7759   ; la primera
	dec a			;775b
	jr z,$+58		;775c   ; la segunda, mas abajo
	ret			;775e
L_775F:
	ld hl,0e083h		;775f   ; la velocidad
	ld a,(hl)			;7762
	add a,020h		;7763   ; 0x20 mas
	ld b,0d7h		;7765   ; con tope en 0xD7
	cp b			;7767
	jr c,L_776B		;7768   ; y si se pasa
	ld a,b			;776a   ; se queda en el tope
L_776B:
	ld (hl),a			;776b
	call L_7444		;776c   ; rearma el coche
	ld hl,0e0b8h		;776f   ; la fase del choque
	inc (hl)			;7772   ; una mas
	inc hl			;7773
	inc (hl)			;7774
	inc hl			;7775
	ld (hl),060h		;7776   ; el tile 0x60
	dec hl			;7778
	ld a,(hl)			;7779   ; los rivales pasados
	cp 004h		;777a   ; con tope en cuatro
	jr c,L_7780		;777c
	ld a,004h		;777e
L_7780:
	ld hl,07791h		;7780   ; la tabla de bonificaciones
	call suma_a_hl		;7783
	ld d,(hl)			;7786   ; el byte alto de los puntos
	ld e,000h		;7787
	call suma_a_la_puntuacion		;7789   ; a la puntuacion
L_778C:
	ld a,003h		;778c   ; el efecto 3
	jp suena		;778e

; ----------------------------------------------------------------------
; DATOS datos_7791: cinco bytes que carga 0x7780
;   0x7791..0x7796  (5 bytes)
DATA_datos_7791:
	defb 000h,003h,005h,008h,010h	; 7791

; ======================================================================
; CODIGO 0x7796..0x785b  (197 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; Mientras dura la cuenta de (0xE0BA), pone el sprite del aviso de puntos encima del coche. El patron sale de (0xE0B9) por cuatro mas 0x94, con tope en tres: son los rotulos de 300, 500, 800 y 1000.
; ----------------------------------------------------------------------
dibuja_el_aviso:
	ld hl,0e0bah		;7796   ; la cuenta del aviso
	dec (hl)			;7799
	jr z,L_77BE		;779a   ; al agotarse, se retira
	ld de,0e13ah		;779c   ; la copia de atributos de sprite
	ld hl,0e112h		;779f   ; la posicion del coche
	ld a,(hl)			;77a2
	sub 010h		;77a3   ; 0x10 mas arriba
	ld (de),a			;77a5
	inc de			;77a6
	inc hl			;77a7
	ldi		;77a8   ; y su columna
	ld a,(0e0b9h)		;77aa   ; los rivales pasados
	dec a			;77ad
	cp 004h		;77ae   ; con tope en cuatro
	jr c,L_77B4		;77b0
	ld a,003h		;77b2
L_77B4:
	add a,a			;77b4   ; por cuatro
	add a,a			;77b5
	add a,094h		;77b6   ; el primer patron de los avisos
	ld (de),a			;77b8
	inc de			;77b9
	ld a,006h		;77ba   ; y el color 6
	ld (de),a			;77bc
	ret			;77bd
L_77BE:
	dec hl			;77be   ; lo retira
	dec hl			;77bf
	ld (hl),000h		;77c0
	ld hl,0e13ah		;77c2   ; la Y de fuera de pantalla
	ld (hl),0e0h		;77c5
	ret			;77c7

; ----------------------------------------------------------------------
; El paisaje de la SALIDA, montado a mano retal a retal. Primero llena el anillo entero de hierba con un `lddr` de 0x225 bytes y despues va pegando los ocho retales, heredando cada llamada el DE que dejo la anterior: por eso a veces solo se le cambia E. Rehecho paso a paso en tools/graficos.py, sale igual que la maquina salvo dos casillas del arco de meta, que estan animadas.
; ----------------------------------------------------------------------
monta_la_salida:
	ld hl,0e3abh		;77c8   ; la ultima casilla del anillo
	ld de,0e3aah		;77cb
	ld (hl),0a0h		;77ce   ; el tile de hierba
	ld bc,00225h		;77d0   ; 0x225 bytes
	lddr		;77d3   ; replicado hacia atras: llena el anillo entero
	ld hl,07875h		;77d5   ; la calzada, siete de ancho por cuatro de alto
	ld e,08eh		;77d8   ; en la columna 8
	ld a,006h		;77da   ; repetida seis veces: veinticuatro filas
	call pega_un_retal		;77dc
	ld hl,078b2h		;77df   ; el arcen con sus postes
	ld de,0e198h		;77e2   ; en la columna 18
	call pega_un_retal		;77e5
	dec d			;77e8   ; la fila de arriba
	ld e,0b3h		;77e9   ; y la columna 45
	call pega_un_retal		;77eb
	ld hl,078a5h		;77ee   ; los postes sueltos
	ld e,036h		;77f1   ; en la columna 0x36
	ld a,00fh		;77f3   ; quince veces
	call pega_un_retal		;77f5
	ld l,e			;77f8   ; donde quedo
	ld h,d			;77f9
	inc de			;77fa
	ld (hl),04eh		;77fb   ; el tile 0x4E
	ld c,004h		;77fd   ; cinco veces
	ldir		;77ff
	ld a,056h		;7801   ; y el 0x56 detras
	ld (de),a			;7803
	ld hl,078beh		;7804   ; un tile suelto
	ld de,0e251h		;7807
	ld a,00eh		;780a   ; catorce veces
	call pega_un_retal		;780c
	ld hl,0785bh		;780f   ; el arco de la meta
	ld de,0e18ah		;7812   ; en la columna 4
	call pega_un_retal		;7815
	ld hl,0789fh		;7818   ; otro poste
	ld e,006h		;781b
	ld a,00dh		;781d   ; trece veces
	call pega_un_retal		;781f
	inc de			;7822
	ld l,e			;7823
	ld h,d			;7824
	inc de			;7825
	ld (hl),04eh		;7826   ; el tile 0x4E
	ld c,002h		;7828   ; tres veces
	ldir		;782a
	ld hl,07893h		;782c   ; el rotulo de "START"
	ld e,031h		;782f   ; en la columna 0x31
	call pega_un_retal		;7831
	ld hl,078ach		;7834   ; y los dos ultimos
	ld e,067h		;7837
	call pega_un_retal		;7839
	ld de,0e338h		;783c   ; en la columna 0x338: cae dentro del pegador que sigue

; ----------------------------------------------------------------------
; EL PEGADOR DE RETALES. El retal empieza por sus dos medidas y detras van los tiles seguidos. El `ld a,016h / sub c` es lo que fija la anchura del anillo: VEINTIDOS columnas, no las 32 de la pantalla. Y el `dec a / jr nz` del final repite el mismo retal hacia abajo tantas veces como diga A, que es como se alarga un tramo de carretera sin gastar bytes.
; ----------------------------------------------------------------------
pega_un_retal:
	push hl			;783f   ; el retal, a salvo
	ld b,(hl)			;7840   ; el alto
	inc hl			;7841
	ld c,(hl)			;7842   ; y el ancho
	inc hl			;7843
L_7844:
	push bc			;7844
	ex af,af'			;7845   ; la cuenta de repeticiones, a salvo
	ld a,016h		;7846   ; veintidos columnas tiene el anillo
	sub c			;7848   ; menos el ancho: lo que sobra de fila
	ld b,000h		;7849   ; el contador de bytes es solo C
	ldir		;784b   ; la fila
	ld c,a			;784d   ; lo que sobra
	ex af,af'			;784e
	ex de,hl			;784f   ; el destino salta al renglon siguiente
	add hl,bc			;7850
	ex de,hl			;7851
	pop bc			;7852
	djnz L_7844		;7853   ; tantas filas como diga el alto
	pop hl			;7855   ; el retal, otra vez desde el principio
	dec a			;7856   ; una repeticion menos
	jr nz,pega_un_retal		;7857
	inc a			;7859   ; y sale con A a uno, que es lo que espera el que llame despues
	ret			;785a

; ----------------------------------------------------------------------
; DATOS retal_meta: 4 x 6, el arco de la meta; lo carga 0x780f
;   0x785b..0x7875  (26 bytes)
DATA_retal_meta:
	defb 006h,004h,0a0h,042h,042h,0a0h,040h,046h,047h,041h,040h,046h,047h,041h,040h,046h	; 785b  ...BB.@FGA@FGA@F
	defb 047h,041h,040h,046h,047h,041h,0a0h,043h,043h,0a0h	; 786b  GA@FGA.CC.

; ----------------------------------------------------------------------
; DATOS retal_calzada: 7 x 4, la calzada con su linea central; lo carga 0x77d5
;   0x7875..0x7893  (30 bytes)
DATA_retal_calzada:
	defb 004h,007h,058h,0d0h,0d0h,0d1h,0d0h,0d0h,059h,058h,0d0h,0d0h,0d1h,0d0h,0d0h,059h	; 7875  ..X.....YX.....Y
	defb 058h,0d0h,0d0h,0d0h,0d0h,0d0h,059h,058h,0d0h,0d0h,0d0h,0d0h,0d0h,059h	; 7885  X.....YX.....Y

; ----------------------------------------------------------------------
; DATOS retal_start: 5 x 2, el rotulo "START" sobre la calzada; lo carga
;   0x782c
;   0x7893..0x789f  (12 bytes)
DATA_retal_start:
	defb 002h,005h,033h,034h,021h,032h,034h,04fh,04fh,04fh,04fh,04fh	; 7893  ..34!24OOOOO

; ----------------------------------------------------------------------
; DATOS retal_789f: 4 x 1, una tira de cuatro tiles de una sola fila; lo carga
;   0x7818
;   0x789f..0x78a5  (6 bytes)
DATA_retal_789f:
	defb 001h,004h,04ch,04ch,04ch,04dh	; 789f

; ----------------------------------------------------------------------
; DATOS retal_78a5: 5 x 1; lo carga 0x77ee
;   0x78a5..0x78ac  (7 bytes)
DATA_retal_78a5:
	defb 001h,005h,04ch,04ch,04dh,04dh,04dh	; 78a5

; ----------------------------------------------------------------------
; DATOS retal_78ac: 2 x 2; lo carga 0x7834
;   0x78ac..0x78b2  (6 bytes)
DATA_retal_78ac:
	defb 002h,002h,050h,051h,052h,053h	; 78ac

; ----------------------------------------------------------------------
; DATOS retal_arcen: 2 x 5, el arcen con sus postes; lo carga 0x77df
;   0x78b2..0x78be  (12 bytes)
DATA_retal_arcen:
	defb 005h,002h,0a0h,04bh,0a0h,0a0h,04bh,0a0h,0a0h,0a0h,0a0h,04bh	; 78b2  ...K..K....K

; ----------------------------------------------------------------------
; DATOS retal_78be: 1 x 1; lo carga 0x7804
;   0x78be..0x78c1  (3 bytes)
DATA_retal_78be:
	defb 001h,001h,055h	; 78be

; ----------------------------------------------------------------------
; DATOS retal_78c1: 1 x 1, el ultimo de los retales
;   0x78c1..0x78c4  (3 bytes)
DATA_retal_78c1:
	defb 001h,001h,04eh	; 78c1

; ----------------------------------------------------------------------
; DATOS guiones_de_paisaje: los pares [modo][cuenta] a los que apunta la tabla
;   de 0x5161. Los arranques que se usan de verdad son 0x78c4 y 0x78e5 (etapa
;   1), 0x7aaa, 0x7baa y 0x7acd (etapas 2 y 3) y 0x7960 (etapas 1, 4 y 5). El
;   final de cada guion NO esta marcado: 0x585f lee los dos bytes sin
;   comprobar nada, y lo que corta es que se acabe la etapa
;   0x78c4..0x7c23  (863 bytes)
DATA_guiones_de_paisaje:
	defb 010h,019h,011h,021h,013h,018h,020h,051h,022h,031h,020h,081h,021h,031h,020h,0a9h	; 78c4  ...!.. Q"1 .!1 .
	defb 022h,029h,020h,021h,021h,039h,020h,059h,022h,031h,020h,061h,024h,018h,010h,019h	; 78d4  ") !!9 Y"1 a$...
	defb 0feh,094h,015h,094h,000h,097h,097h,072h,076h,094h,004h,086h,087h,0ffh,081h,081h	; 78e4  .......rv.......
	defb 004h,081h,085h,097h,086h,004h,0a4h,005h,000h,0ffh,000h,010h,024h,005h,027h,011h	; 78f4  ............$.'.
	defb 011h,014h,021h,034h,017h,007h,0ffh,010h,000h,014h,010h,000h,005h,014h,024h,0a4h	; 7904  ..!4..........$.
	defb 0a4h,094h,085h,086h,004h,086h,086h,004h,097h,087h,0a4h,004h,0a4h,094h,004h,0a4h	; 7914  ................
	defb 0ffh,081h,081h,081h,004h,081h,097h,014h,017h,007h,0ffh,000h,010h,024h,010h,000h	; 7924  .............$..
	defb 005h,014h,094h,0a4h,097h,0ffh,072h,072h,086h,072h,0a4h,076h,085h,076h,085h,081h	; 7934  ......rr.r.v.v..
	defb 081h,094h,087h,097h,014h,005h,0a4h,000h,000h,000h,0ffh,001h,001h,0a4h,014h,017h	; 7944  ................
	defb 005h,0a4h,007h,0ffh,000h,000h,005h,0a4h,014h,0ffh,0ffh,0ffh,070h,079h,0a3h,079h	; 7954  ............py.y
	defb 0cfh,079h,011h,07ah,011h,07ah,02bh,07ah,05dh,07ah,083h,07ah,007h,007h,080h,080h	; 7964  .y.z.z+z]z.z....
	defb 080h,080h,080h,080h,087h,080h,087h,08ch,08bh,08ah,080h,087h,080h,087h,085h,086h	; 7974  ................
	defb 089h,0a0h,0a0h,080h,087h,083h,084h,089h,0a0h,0a0h,080h,087h,081h,082h,088h,080h	; 7984  ................
	defb 087h,080h,087h,0a0h,0a0h,0a0h,080h,087h,080h,080h,080h,080h,080h,080h,087h,007h	; 7994  ................
	defb 006h,008h,096h,097h,098h,099h,008h,008h,093h,094h,095h,093h,008h,008h,08fh,090h	; 79a4  ................
	defb 091h,092h,008h,008h,096h,097h,098h,099h,008h,008h,093h,094h,095h,093h,008h,008h	; 79b4  ................
	defb 08fh,090h,091h,092h,008h,0bdh,0bdh,0bdh,0bdh,0bdh,0bdh,008h,008h,080h,080h,080h	; 79c4  ................
	defb 080h,080h,080h,080h,087h,080h,087h,0a0h,0bbh,0bch,0a0h,080h,087h,080h,087h,0a0h	; 79d4  ................
	defb 0b3h,0b4h,0a0h,080h,087h,0a0h,0a0h,0a0h,0b1h,0b2h,0a0h,080h,087h,0a0h,0a0h,08ch	; 79e4  ................
	defb 08bh,08bh,08ah,080h,087h,0a0h,0a0h,09dh,09eh,09fh,089h,080h,087h,080h,087h,09ah	; 79f4  ................
	defb 09bh,09ch,088h,080h,087h,080h,080h,080h,080h,080h,080h,080h,087h,008h,003h,08dh	; 7a04  ................
	defb 08eh,0a0h,0a0h,08dh,08eh,0a0h,0a0h,0a0h,08dh,08eh,0a0h,0a0h,08dh,08eh,0a0h,08dh	; 7a14  ................
	defb 08eh,08dh,08eh,0a0h,0a0h,08dh,08eh,008h,006h,0a0h,0a0h,0a0h,0a0h,0aah,0abh,0ach	; 7a24  ................
	defb 0adh,0aeh,0afh,0b0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0aah,0abh,0a0h	; 7a34  ................
	defb 0a0h,0a0h,0a0h,0aah,0abh,08dh,08eh,0b7h,0b8h,0bah,0a0h,0a0h,0a0h,0b5h,0b6h,0b9h	; 7a44  ................
	defb 0a0h,08dh,08eh,0a0h,0a0h,0a0h,0a0h,08dh,08eh,006h,006h,080h,080h,080h,080h,080h	; 7a54  ................
	defb 087h,080h,08ch,08bh,08ah,080h,087h,0a7h,0a8h,0a9h,089h,080h,087h,0a4h,0a5h,0a6h	; 7a64  ................
	defb 088h,080h,087h,080h,087h,0a0h,0a0h,080h,087h,080h,080h,080h,080h,080h,087h,007h	; 7a74  ................
	defb 004h,0a0h,0aah,0abh,0a0h,0a0h,0a0h,0aah,0abh,0a1h,0a2h,0a0h,0a0h,0a0h,0a0h,0aah	; 7a84  ................
	defb 0abh,0a0h,0a1h,0a2h,0a0h,0a0h,0a0h,0aah,0abh,0a0h,0aah,0abh,0a0h,003h,001h,007h	; 7a94  ................
	defb 000h,009h,001h,00ah,001h,000h,010h,049h,013h,018h,020h,049h,022h,019h,020h,031h	; 7aa4  .......I.. I". 1
	defb 021h,029h,020h,039h,022h,029h,020h,051h,024h,018h,010h,079h,013h,018h,020h,0a5h	; 7ab4  !) 9") Q$..y.. .
	defb 020h,065h,021h,019h,024h,018h,010h,019h,0feh,0dbh,07ah,0fdh,07ah,022h,07bh,040h	; 7ac4   e!.$.....z.z"{@
	defb 07bh,072h,07bh,09ch,07bh,000h,000h,008h,004h,084h,085h,086h,0c5h,082h,083h,0c5h	; 7ad4  {r{.{...........
	defb 0c5h,0c5h,084h,085h,086h,0c5h,082h,083h,0c5h,0c5h,084h,085h,086h,0c5h,082h,083h	; 7ae4  ................
	defb 0c5h,084h,085h,086h,0c5h,082h,083h,0c5h,0c5h,007h,005h,0aeh,0aeh,0aeh,0aeh,0c5h	; 7af4  ................
	defb 0c5h,0a0h,09fh,09eh,0b0h,0c5h,0a9h,0aah,09dh,0b0h,0abh,0a8h,0a7h,09dh,0b0h,0abh	; 7b04  ................
	defb 0a6h,0a7h,09dh,0b0h,0c5h,0a4h,0a5h,09ch,0b0h,0aeh,0aeh,0aeh,0aeh,0c5h,007h,004h	; 7b14  ................
	defb 0c5h,0c5h,0ach,0adh,0c5h,0c5h,0ach,0adh,0a0h,09fh,09fh,09eh,007h,0a1h,0a3h,09dh	; 7b24  ................
	defb 007h,0a1h,0a2h,09dh,007h,0a1h,0a3h,09dh,007h,0a1h,0a2h,09ch,008h,006h,084h,085h	; 7b34  ................
	defb 086h,084h,085h,086h,082h,083h,0c5h,082h,083h,0c5h,084h,085h,086h,084h,085h,086h	; 7b44  ................
	defb 082h,083h,0c5h,082h,083h,0c5h,0c5h,084h,085h,086h,0c5h,0c5h,0c5h,082h,083h,0c5h	; 7b54  ................
	defb 0c5h,0c5h,084h,085h,086h,0c5h,0c5h,0c5h,082h,083h,0c5h,0c5h,0c5h,0c5h,008h,005h	; 7b64  ................
	defb 0c5h,0c5h,08ah,08ch,08eh,0c5h,0c5h,089h,08bh,08dh,087h,088h,0c5h,0c5h,0c5h,0c5h	; 7b74  ................
	defb 0c5h,0c5h,0c5h,0c5h,0c5h,0c5h,094h,095h,08eh,0c5h,0c5h,092h,093h,08dh,094h,095h	; 7b84  ................
	defb 08eh,0c5h,0c5h,092h,093h,08dh,0c5h,0c5h,004h,003h,08fh,090h,091h,0c5h,0c5h,0c5h	; 7b94  ................
	defb 0c5h,080h,081h,080h,081h,0c5h,090h,090h,090h,025h,083h,083h,020h,090h,083h,090h	; 7ba4  .........%.. ...
	defb 090h,025h,020h,0ffh,025h,025h,020h,0ffh,0ffh,020h,020h,0ffh,025h,020h,025h,034h	; 7bb4  .% .%% ..  .% %4
	defb 0ffh,032h,035h,023h,030h,030h,0ffh,0ffh,0ffh,094h,092h,090h,0ffh,094h,094h,090h	; 7bc4  .25#00..........
	defb 092h,0ffh,0ffh,025h,030h,021h,0ffh,024h,024h,030h,023h,0ffh,030h,023h,075h,0ffh	; 7bd4  ...%0!.$$0#.0#u.
	defb 030h,030h,034h,0ffh,034h,023h,030h,023h,0ffh,024h,030h,030h,0ffh,030h,0ffh,035h	; 7be4  004.4#0#.$00.0.5
	defb 034h,0ffh,030h,0ffh,023h,030h,0ffh,0ffh,035h,035h,0ffh,034h,030h,032h,0ffh,030h	; 7bf4  4.0.#0..55.402.0
	defb 032h,0ffh,034h,030h,0ffh,030h,0ffh,032h,030h,0ffh,030h,034h,0ffh,030h,030h,030h	; 7c04  2.40.0.20.04.000
	defb 0ffh,023h,0ffh,030h,034h,030h,0ffh,0ffh,025h,025h,090h,083h,083h,0ffh,0ffh	; 7c14  .#.040..%%.....

; ----------------------------------------------------------------------
; DATOS paisaje_a: 48 bytes y su 0xFF; el recorrido de 0x5587 retrocede 0x30
;   al topar con el, asi que el ciclo son exactamente estos 48. Lo carga
;   0x559d con BC=0x0601
;   0x7c23..0x7c54  (49 bytes)
DATA_paisaje_a:
	defb 094h,095h,096h,097h,098h,0a9h,096h,0aah,090h,091h,092h,093h,099h,0a6h,0a7h,0a8h	; 7c23  ................
	defb 08eh,08bh,0abh,08fh,098h,0a4h,0a2h,0a5h,08ah,08bh,08ch,08dh,099h,0a1h,0a2h,0a3h	; 7c33  ................
	defb 086h,087h,088h,089h,098h,09eh,09fh,0a0h,082h,083h,084h,085h,099h,09ch,084h,09dh	; 7c43  ................
	defb 0ffh	; 7c53

; ----------------------------------------------------------------------
; DATOS paisaje_b: los otros 48 y su 0xFF; lo carga 0x55a6 con C=0x10, y
;   0x5594 alterna entre este y el anterior con el bit 0 de (0xE07C)
;   0x7c54..0x7c85  (49 bytes)
DATA_paisaje_b:
	defb 004h,004h,004h,080h,098h,09ah,09bh,004h,004h,09bh,004h,081h,099h,001h,004h,004h	; 7c54  ................
	defb 004h,004h,004h,080h,098h,09ah,004h,004h,004h,09bh,004h,081h,099h,001h,09bh,004h	; 7c64  ................
	defb 09bh,004h,004h,080h,098h,09ah,004h,09bh,004h,004h,09bh,081h,099h,001h,004h,004h	; 7c74  ................
	defb 0ffh	; 7c84

; ----------------------------------------------------------------------
; DATOS lineas_de_la_calzada: seis filas de doce bits: #..#..#..#.. /
;   .#..#..#..#. / vacia / ..#..#..#..# / vacia / vacia. La carga 0x557a, con
;   el puntero en 0xE090
;   0x7c85..0x7c92  (13 bytes)
DATA_lineas_de_la_calzada:
	defb 092h,040h	; 7c85
	defb 049h,020h	; 7c87
	defb 000h,000h	; 7c89
	defb 024h,090h	; 7c8b
	defb 000h,000h	; 7c8d
	defb 000h,000h	; 7c8f
	defb 0ffh	; 7c91

; ----------------------------------------------------------------------
; DATOS paisajes_7c92: 307 bytes de tiles de paisaje; el unico arranque que se
;   carga con una constante es 0x7d8a, desde 0x5125, y al resto se llega
;   avanzando el puntero de (0xE06F), que sube de tres en tres segun (0xE07A)
;   (0x5790-0x5797)
;   0x7c92..0x7dc5  (307 bytes)
DATA_paisajes_7c92:
	defb 002h,0a2h,0a3h,0a4h,0a5h,0a6h,009h,009h,0a1h,0a3h,0a4h,0a5h,0a7h,009h,009h,002h	; 7c92  ................
	defb 0abh,0ach,0adh,0aeh,0afh,009h,009h,0a9h,0a3h,0a4h,0a5h,0aah,009h,009h,01dh,084h	; 7ca2  ................
	defb 085h,080h,082h,081h,08ah,08bh,082h,083h,084h,085h,081h,089h,08bh,085h,080h,082h	; 7cb2  ................
	defb 083h,081h,08ch,086h,083h,082h,084h,085h,081h,08ch,08ah,080h,083h,082h,083h,081h	; 7cc2  ................
	defb 08ch,089h,084h,085h,080h,084h,085h,081h,088h,082h,083h,082h,082h,083h,081h,087h	; 7cd2  ................
	defb 084h,085h,084h,085h,081h,088h,08bh,082h,083h,082h,083h,081h,087h,08bh,080h,084h	; 7ce2  ................
	defb 085h,081h,088h,08bh,08bh,085h,082h,083h,081h,087h,08bh,08bh,083h,080h,081h,08ch	; 7cf2  ................
	defb 08ah,08bh,08bh,083h,084h,085h,081h,089h,08bh,08bh,085h,082h,083h,085h,081h,08ah	; 7d02  ................
	defb 08bh,083h,083h,084h,085h,081h,089h,08bh,084h,085h,082h,083h,081h,088h,08bh,082h	; 7d12  ................
	defb 083h,085h,085h,081h,087h,08bh,085h,083h,084h,085h,081h,08ah,08bh,083h,085h,082h	; 7d22  ................
	defb 083h,081h,089h,08bh,083h,084h,085h,084h,085h,081h,08ah,085h,082h,083h,082h,083h	; 7d32  ................
	defb 081h,089h,084h,085h,080h,081h,08ch,08ch,088h,082h,083h,080h,084h,085h,081h,087h	; 7d42  ................
	defb 085h,080h,082h,082h,083h,081h,08ah,083h,080h,084h,085h,081h,08ch,089h,084h,085h	; 7d52  ................
	defb 082h,083h,081h,08ch,088h,082h,083h,083h,080h,081h,08ch,087h,085h,080h,084h,085h	; 7d62  ................
	defb 081h,088h,08bh,082h,080h,082h,083h,081h,087h,08bh,002h,09ah,0a3h,0a4h,0a5h,0a0h	; 7d72  ................
	defb 009h,009h,09bh,09ch,09dh,09eh,09fh,009h,009h,03eh,005h,058h,007h,016h,005h,04ch	; 7d82  .........>.X...L
	defb 007h,02ah,0c5h,0c5h,0c5h,0c5h,0c5h,0c5h,0c5h,0c5h,0b5h,0c5h,0c5h,0c5h,0b4h,0c5h	; 7d92  .*..............
	defb 0c5h,0c5h,0b3h,0c5h,0c5h,0c5h,0c7h,0b5h,0c5h,0c5h,0bdh,0b4h,0c5h,0c5h,0bbh,0c7h	; 7da2  ................
	defb 0b5h,0c5h,0c6h,0bch,0b4h,0c5h,0c2h,0bbh,0b3h,0c5h,0c6h,0c6h,0bch,0b5h,0c6h,0c4h	; 7db2  ................
	defb 0bah,0b4h,0ffh	; 7dc2

; ----------------------------------------------------------------------
; DATOS columnas_del_arcen: veinticuatro registros de CUATRO bytes que 0x5555
;   copia a 0xE058, la fila nueva que 0x5732 mete en el anillo. Puntero en
;   0xE08A
;   0x7dc5..0x7e26  (97 bytes)
DATA_columnas_del_arcen:
	defb 0c6h,0c6h,0b9h,0b1h	; 7dc5
	defb 0c6h,0c6h,0bfh,0b6h	; 7dc9
	defb 0c6h,0bbh,0b2h,0c5h	; 7dcd
	defb 0c2h,0bfh,0b6h,0c5h	; 7dd1
	defb 0c6h,0bdh,0b5h,0c5h	; 7dd5
	defb 0c4h,0bbh,0b4h,0c5h	; 7dd9
	defb 0c6h,0c6h,0bch,0c5h	; 7ddd
	defb 0c6h,0c2h,0bah,0b5h	; 7de1
	defb 0c2h,0c6h,0bbh,0b4h	; 7de5
	defb 0c6h,0c3h,0b8h,0b3h	; 7de9
	defb 0c6h,0c4h,0b7h,0b2h	; 7ded
	defb 0c6h,0c6h,0b9h,0b1h	; 7df1
	defb 0c6h,0c1h,0bfh,0b6h	; 7df5
	defb 0c6h,0bfh,0b2h,0c5h	; 7df9
	defb 0c1h,0c7h,0b1h,0c5h	; 7dfd
	defb 0c6h,0bch,0b4h,0c5h	; 7e01
	defb 0c4h,0b9h,0b3h,0c5h	; 7e05
	defb 0c1h,0bfh,0b2h,0c5h	; 7e09
	defb 0c6h,0beh,0b1h,0c5h	; 7e0d
	defb 0c6h,0bdh,0b4h,0c5h	; 7e11
	defb 0c6h,0c2h,0bch,0c5h	; 7e15
	defb 0c6h,0c6h,0b9h,0b5h	; 7e19
	defb 0c6h,0c3h,0b8h,0b4h	; 7e1d
	defb 0c6h,0c1h,0b9h,0b3h	; 7e21
	defb 0ffh	; 7e25

; ----------------------------------------------------------------------
; DATOS datos_7e26: entre las columnas del arcen y los guiones de paisaje del
;   final
;   0x7e26..0x7e60  (58 bytes)
DATA_datos_7e26:
	defb 0c6h,0c6h,0b7h,0b2h,0c6h,0c3h,0bfh,0b1h,0c1h,0bfh,0c7h,0b6h,0c6h,0bdh,0b2h,0c5h	; 7e26  ................
	defb 0c6h,0bfh,0b1h,0c5h,0bfh,0c7h,0b6h,0c5h,0c7h,0b2h,0c5h,0c5h,0c7h,0b1h,0c5h,0c5h	; 7e36  ................
	defb 0c7h,0b6h,0c5h,0c5h,0b2h,0c5h,0c5h,0c5h,0bfh,0c5h,0c5h,0c5h,0b6h,0c5h,0c5h,0c5h	; 7e46  ................
	defb 0ffh,039h,006h,033h,004h,011h,006h,02bh,004h,025h	; 7e56  .9.3...+.%

; ----------------------------------------------------------------------
; DATOS guiones_de_paisaje_b: los otros pares [modo][cuenta]: 0x7e60 (etapa
;   5), 0x7e83 (etapa 4) y 0x7ea8, 0x7f6b y 0x7ed1 (etapa 6)
;   0x7e60..0x7fe4  (388 bytes)
DATA_guiones_de_paisaje_b:
	defb 010h,031h,013h,018h,020h,0adh,020h,065h,022h,021h,020h,059h,021h,021h,020h,081h	; 7e60  .1.. . e"! Y!! .
	defb 022h,019h,020h,041h,021h,019h,020h,069h,024h,018h,010h,061h,0feh,0feh,0feh,0feh	; 7e70  ". A!. i$..a....
	defb 0feh,0feh,0feh,010h,029h,011h,009h,013h,018h,020h,031h,024h,018h,010h,019h,013h	; 7e80  ....).... 1$....
	defb 018h,020h,0fbh,020h,06fh,024h,018h,010h,019h,012h,011h,010h,049h,011h,009h,013h	; 7e90  . . o$......I...
	defb 018h,020h,0c1h,024h,018h,010h,019h,0feh,010h,031h,013h,018h,020h,061h,021h,029h	; 7ea0  . .$.....1.. a!)
	defb 024h,018h,010h,021h,013h,018h,020h,019h,022h,029h,020h,051h,024h,018h,010h,061h	; 7eb0  $..!.. .") Q$..a
	defb 013h,018h,020h,091h,024h,018h,010h,031h,013h,018h,020h,061h,024h,018h,010h,019h	; 7ec0  .. .$..1.. a$...
	defb 0feh,0d9h,07eh,003h,07fh,023h,07fh,041h,07fh,008h,005h,00fh,083h,084h,00fh,00fh	; 7ed0  ..~..#.A........
	defb 00fh,081h,082h,00fh,00fh,00fh,00fh,00fh,083h,084h,083h,084h,00fh,081h,082h,081h	; 7ee0  ................
	defb 082h,00fh,00fh,00fh,00fh,00fh,00fh,083h,084h,00fh,083h,084h,081h,082h,00fh,081h	; 7ef0  ................
	defb 082h,00fh,00fh,005h,006h,00fh,00fh,087h,088h,089h,00fh,00fh,00fh,085h,086h,00fh	; 7f00  ................
	defb 00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,02bh,02fh,02eh	; 7f10  .............+/.
	defb 021h,02dh,029h,007h,004h,098h,097h,097h,096h,091h,092h,093h,095h,08dh,08eh,090h	; 7f20  !-).............
	defb 095h,08dh,08eh,08fh,095h,08ah,08bh,08ch,094h,00fh,087h,088h,089h,00fh,085h,086h	; 7f30  ................
	defb 00fh,008h,005h,00fh,087h,088h,089h,00fh,00fh,085h,086h,00fh,00fh,087h,088h,087h	; 7f40  ................
	defb 088h,089h,085h,086h,085h,086h,00fh,00fh,087h,088h,089h,00fh,00fh,085h,086h,00fh	; 7f50  ................
	defb 00fh,087h,088h,087h,088h,089h,085h,086h,085h,086h,00fh,093h,011h,093h,003h,003h	; 7f60  ................
	defb 013h,0ffh,012h,012h,002h,003h,002h,013h,003h,003h,0ffh,013h,013h,013h,003h,003h	; 7f70  ................
	defb 012h,0ffh,093h,083h,0ffh,092h,092h,0ffh,082h,082h,081h,073h,072h,082h,092h,083h	; 7f80  ...........sr...
	defb 083h,083h,090h,093h,093h,0ffh,000h,010h,003h,000h,003h,0ffh,001h,013h,0ffh,012h	; 7f90  ................
	defb 012h,002h,0ffh,002h,092h,092h,003h,003h,083h,093h,003h,001h,0ffh,083h,090h,013h	; 7fa0  ................
	defb 093h,002h,001h,010h,000h,003h,003h,013h,003h,022h,012h,0ffh,013h,003h,001h,013h	; 7fb0  ........."......
	defb 010h,0ffh,003h,013h,010h,000h,093h,003h,0ffh,012h,012h,093h,083h,003h,003h,001h	; 7fc0  ................
	defb 010h,013h,022h,022h,010h,003h,003h,013h,013h,0ffh,012h,003h,003h,013h,013h,010h	; 7fd0  ..""............
	defb 001h,092h,092h,0ffh	; 7fe0

; ----------------------------------------------------------------------
; DATOS lineas_de_la_calzada_b: las otras seis filas, mas separadas:
;   ..#...#...#. y #...#...#... entre cuatro vacias. La cargan 0x50d5 y 0x56c3
;   0x7fe4..0x7ff1  (13 bytes)
DATA_lineas_de_la_calzada_b:
	defb 000h,000h	; 7fe4
	defb 000h,000h	; 7fe6
	defb 022h,020h	; 7fe8
	defb 000h,000h	; 7fea
	defb 000h,000h	; 7fec
	defb 088h,080h	; 7fee
	defb 0ffh	; 7ff0

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: RC-730 y el titulo en katakana; no lo lee
;   nadie, es la firma de la casa
;   0x7ff1..0x8000  (15 bytes)
DATA_marca_oculta_de_konami:
	defb 0ffh,0ffh,0bah,08fh,081h,0b6h,09bh,000h,0b7h,093h,0bah,0aah,00ah,030h,0aah	; 7ff1  .............0.
