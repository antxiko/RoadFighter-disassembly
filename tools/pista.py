#!/usr/bin/env python3
"""Dibuja las SEIS carreteras de Road Fighter ejecutando el motor del cartucho.

Este juego no lleva mapas: la carretera se GENERA, fila a fila, con un puñado
de listas ciclicas y un anillo de RAM de 24 por 22. Por eso aqui no hay nada
que descomprimir; lo que hay es que ejecutar el generador.

Lo que se rehace en Python, rutina por rutina y con la direccion de cada una
al lado, es exactamente lo que corre el Z80 en cada fotograma de juego:

    0x551D  motor_de_la_carretera        el reparto por etapa
    0x592A  llena_la_fila_de_fondo       el lienzo de 22 columnas
    0x5534  la etapa 1                   solo las lineas de la calzada
    0x5545  la etapa 2                   cuatro columnas de una lista
    0x5563  la etapa 3                   la fila entera desde bits, y el puente
    0x55E9  la etapa 4                   siete columnas y su espejo
    0x5642  la etapa 5                   igual con otra tabla y cuatro columnas
    0x56AC  la etapa 6                   como la 3 y ademas rehace las lineas
    0x58AF  pega_un_tramo_de_calzada     un tramo cada ocho filas
    0x56F7  el paisaje de los lados      tres puertas segun el modo
    0x585F  pasa_al_tramo_de_paisaje_siguiente
    0x590E  apunta_el_arcen_de_esta_fila la cola de veinticuatro casillas
    0x5944  pinta_el_rotulo_de_meta      CHECK POINT, o GOAL en la sexta
    0x54AF  arma_el_paisaje              los tramos sueltos del guion
    0x5716  corre_el_anillo              la fila nueva entra en el anillo

La comprobacion de que esta bien hecho no es que la imagen quede bonita: es
que las primeras veinticuatro filas de cada etapa tienen que dar el mismo
anillo que el cartucho de verdad, y eso se compara contra el volcado de VRAM
del emulador con --coteja.

Uso: pista.py <rom> <org> <salida> [filas] [--coteja <vram.bin>]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import (ORG, PALETA, png, vram_limpia, escena_juego,   # noqa: E402
                      NOMBRES, usa_fondo)

ANILLO, ANILLO_FIN, ANCHO = 0xE186, 0xE396, 0x16
FILA = 0xE058                   # la fila nueva, 22 bytes


class Maquina:
    """La RAM de 0xE000 a 0xE400 y las rutinas del motor de la carretera.

    Se trabaja con direcciones de verdad -m[0xE07D] es (0xE07D)- para poder
    cotejar cada linea de Python con su linea de ensamblador sin traducir
    nada por el camino.
    """

    def __init__(self, rom, etapa):
        self.rom = rom
        self.ram = bytearray(0x400)
        self.etapa = etapa
        self.filas = []
        self.prepara_la_etapa()

    # --- acceso ------------------------------------------------------
    def __getitem__(self, a):
        return self.ram[a - 0xE000]

    def __setitem__(self, a, v):
        self.ram[a - 0xE000] = v & 0xFF

    def w(self, a):
        return self[a] | (self[a + 1] << 8)

    def setw(self, a, v):
        self[a] = v & 0xFF
        self[a + 1] = (v >> 8) & 0xFF

    def rb(self, a):
        return self.rom[a - ORG]

    def rw(self, a):
        return self.rb(a) | (self.rb(a + 1) << 8)

    # --- 0x504C prepara_la_etapa -------------------------------------
    def prepara_la_etapa(self):
        self[0xE043] = self.etapa
        for a in range(0xE098, 0xE0B0):          # 0x505C: el arcen, tile 0x20
            self[a] = 0x20
        # 0x5068: el guion de paisaje de 0x54AF, segun la vuelta y la etapa
        self.setw(0xE0B2, 0x50DC if self.etapa == 6 else 0x50BE)
        self.monta_el_paisaje_de_la_etapa()      # 0x507E
        self[0xE07D] = 8                          # 0x5081: el margen del arcen
        # 0x5092: el tile de fondo de esta etapa
        self[0xE089] = self.rb(0x5191 + self.etapa - 1)
        self[0xE086] = 4                          # 0x50B1
        self.setw(0xE046, ANILLO)                 # 0x50B6

    # --- 0x50BF monta_el_paisaje_de_la_etapa -------------------------
    def monta_el_paisaje_de_la_etapa(self):
        self.elige_los_guiones_de_la_etapa()      # 0x50BF
        rama = self.rw(0x50C9 + 2 * (self.etapa - 1))   # tabla de seis
        if rama == 0x50D5:
            self.setw(0xE090, 0x7FE4)             # lineas separadas
        elif rama == 0x50E8:
            self.setw(0xE08A, 0x7DC5)             # las columnas del arcen
        elif rama == 0x50EF:
            self.setw(0xE090, 0x7C85)             # lineas juntas
            self.setw(0xE06F, 0x7C54)             # el paisaje B
            self[0xE07C] = 1
            self[0xE08A] = 1
            self.setw(0xE0B2, 0x7AA1)
        elif rama in (0x510A, 0x5122):
            for i in range(12):                   # 0x510A: doce bytes de golpe
                self[0xE08A + i] = self.rb(0x5116 + i)
            if rama == 0x5122:
                self.setw(0xE08A, 0x7D8A)         # 0x5125: y ademas otro arcen
                self.setw(0xE092, 0x010E)
        # 0x50E7: hay etapas que no cambian nada

    # --- 0x5132 elige_los_guiones_de_la_etapa ------------------------
    def elige_los_guiones_de_la_etapa(self):
        p = 0x5161 + 6 * (self.etapa - 1)
        for i in range(6):                        # 0x5140: los TRES punteros
            self[0xE071 + i] = self.rb(p + i)
        self[0xE07F] = 1                          # 0x5148
        g = self.w(0xE071)                        # 0x514D: el primer par
        self[0xE07A] = self.rb(g)
        self[0xE07B] = self.rb(g + 1)
        self.setw(0xE071, g + 2)
        self.setw(0xE06F, 0x5998)                 # 0x515A: el paisaje de salida

    # --- 0x551D motor_de_la_carretera --------------------------------
    def fotograma(self):
        self.llena_la_fila_de_fondo()             # 0x551D
        rama = self.rw(0x5526 + 2 * self.etapa)   # indexada SIN restar uno
        {0x5534: self.etapa_1, 0x5545: self.etapa_2, 0x5563: self.etapa_3,
         0x55E9: self.etapa_4, 0x5642: self.etapa_5,
         0x56AC: self.etapa_6}[rama]()
        self.corre_el_anillo()                    # 0x5540 -> `call 05716h`
        self.filas.append(bytes(self[FILA + i] for i in range(ANCHO)))

    # --- 0x592A llena_la_fila_de_fondo -------------------------------
    def llena_la_fila_de_fondo(self):
        for i in range(ANCHO):
            self[FILA + i] = self[0xE089]

    # --- las seis calzadas -------------------------------------------
    def etapa_1(self):                            # 0x5534
        self.pega_un_tramo_de_calzada()
        self.remate_5537()

    def etapa_2(self):                            # 0x5545
        self.pega_un_tramo_de_calzada()
        hl = self.w(0xE08A)
        if self.rb(hl) == 0xFF:                   # 0x554D
            hl = 0x7DC5
        for i in range(4):                        # 0x5558: cuatro columnas
            self[FILA + i] = self.rb(hl + i)
        self.setw(0xE08A, hl + 4)
        self.remate_5537()

    def etapa_3(self):                            # 0x5563
        self.doce_bits(FILA)                      # 0x5566
        self.mas_bits(FILA + 12, 10)              # 0x5569
        hl = self.w(0xE090) + 2
        if self.rb(hl) == 0xFF:
            hl = 0x7C85
        self.setw(0xE090, hl)
        self.el_puente()                          # 0x5580

    def el_puente(self):                          # 0x5580
        hl = self.w(0xE06F)
        if self.rb(hl) == 0xFF:
            hl = (hl - 0x30) & 0xFFFF
            self.setw(0xE06F, hl)
            self[0xE08A] = (self[0xE08A] - 1) & 0xFF
            if self[0xE08A]:                      # 0x5592 -> L_55E4
                self[0xE08B] = 6
            else:
                self[0xE07C] ^= 1                 # 0x5594: el vaiven
                # 0x55A3 es `and a / jr z`: con la bandera a CERO va el
                # primer guion, no el segundo
                if not self[0xE07C]:
                    self.setw(0xE06F, 0x7C23)
                    self.setw(0xE08A, 0x0601)
                else:
                    self.setw(0xE06F, 0x7C54)
                    self.setw(0xE08A, 0x0610)
        hl = self.w(0xE06F)                       # 0x55B3
        for i in range(4):                        # cuatro del guion
            self[0xE05C + i] = self.rb(hl + i)
        # 0x55C3: `ld (hl),0d0h` y detras un `ldir` de SEIS que se propaga a
        # si mismo desde 0xE060 a 0xE061. Son SIETE casillas, no seis, y por
        # eso las cuatro del guion que vienen detras arrancan en 0xE067.
        for i in range(7):
            self[0xE060 + i] = 0xD0
        for i in range(4):                        # 0x55CB: y otras cuatro
            self[0xE067 + i] = self.rb(hl + 4 + i)
        self.setw(0xE06F, hl + 8)
        self[0xE08C] = (self[0xE08C] + 1) & 0xFF
        if (self[0xE08C] & 3) < 2:                # 0x55D7
            self[0xE063] = 0xD1                   # la raya del centro
        self.remate_553A()

    def etapa_4(self):                            # 0x55E9
        hl = self.perfil_de_siete()
        for i in range(7):                        # 0x55F5: el espejo
            self[0xE06E - i] = (self.rb(hl + i) + 0x0D) & 0xFF
        self.remate_5537()

    def etapa_5(self):                            # 0x5642
        self.el_paisaje_de_los_lados()            # 0x5642
        self.perfil_de_siete()                    # 0x5645
        hl = self.w(0xE094)
        if self.rb(hl) == 0xFF:                   # 0x564D
            self[0xE092] = (self[0xE092] - 1) & 0xFF
            hl = self.w(0xE090)
            if not self[0xE092]:
                hl += 1
                self.setw(0xE090, hl)
                self[0xE092] = (self.rb(hl) >> 2) & 0x3F
            i = (self.rb(hl) & 3) * 2             # 0x5665
            hl = self.rw(0x56A4 + i)
            self.setw(0xE094, hl)
        hl = self.w(0xE094)                       # 0x5676
        if (self.rb(self.w(0xE090)) & 3) == 3:    # el tipo 3 no escribe nada
            self.setw(0xE094, hl)
            hl += 4
        else:
            for i in range(4):                    # 0x568B: cuatro al otro lado
                self[0xE06E - i] = self.rb(hl + i)
            hl += 4
        self.setw(0xE094, hl)
        self.remate_553A()

    def etapa_6(self):                            # 0x56AC
        self.doce_bits(FILA)
        self.mas_bits(FILA + 12, 10)
        hl = self.w(0xE090) + 2
        if self.rb(hl) == 0xFF:
            hl = 0x7FE4
        self.setw(0xE090, hl)
        self.etapa_1()                            # 0x56C9: vuelve por L_5534

    # --- 0x56CC/0x56CE/0x56D5: la fila desde una palabra de bits ------
    def doce_bits(self, de):
        self.mas_bits(de, 12)

    def mas_bits(self, de, b):
        """L_56CE: RECARGA la palabra desde el puntero, que no se mueve."""
        hl = self.w(0xE090)
        pal = (self.rb(hl) << 8) | self.rb(hl + 1)
        for i in range(b):
            arriba = pal & 0x8000
            pal = (pal << 1) & 0xFFFF
            if self.etapa == 3:                   # 0x56D5: sus propios tiles
                self[de + i] = 0x9B if arriba else 0x04
            else:
                self[de + i] = 0x80 if arriba else 0x0F

    # --- 0x5600: el guion de perfiles de las etapas 4 y 5 -------------
    def perfil_de_siete(self):
        self[0xE08D] = (self[0xE08D] - 1) & 0xFF
        if not self[0xE08D]:
            self[0xE08C] = (self[0xE08C] - 1) & 0xFF
            if not self[0xE08C]:
                hl = self.w(0xE08A) + 1
                self.setw(0xE08A, hl)
                self[0xE08C] = (self.rb(hl) >> 2) & 0x3F
            hl = self.w(0xE08A)                   # 0x561A
            p = self.rw(0x569C + (self.rb(hl) & 3) * 2)
            self[0xE08D] = self.rb(p)             # su cuenta va delante
            self.setw(0xE08E, p + 1)
        hl = self.w(0xE08E)                       # 0x5633
        for i in range(7):
            self[FILA + i] = self.rb(hl + i)
        self.setw(0xE08E, hl + 7)
        return hl

    # --- 0x58AF pega_un_tramo_de_calzada ------------------------------
    def pega_un_tramo_de_calzada(self):
        self[0xE07F] = (self[0xE07F] - 1) & 0xFF
        if not self[0xE07F]:
            self[0xE07F] = 8                      # 0x58BF
            hl = self.w(0xE073) + 1
            self.setw(0xE073, hl)
            if self.rb(hl) == 0xFF:               # 0x58E7
                self[0xE086] = 8
            else:
                p = self.rw(self.w(0xE075) + (self.rb(hl) & 0x0F) * 2)
                # `ld (0e085h),bc` guarda C delante: el PRIMER byte del tramo
                # es B -las veces- y el segundo, C, es lo ancho que es
                self[0xE085] = self.rb(p + 1)     # lo ancho que es
                self[0xE086] = self.rb(p)         # y cuantas veces se repite
                self.setw(0xE087, p + 2)
        elif self[0xE086] == 1:                   # 0x58B9: la ultima no baja
            return
        else:
            self[0xE086] = (self[0xE086] - 1) & 0xFF
        hl = self.w(0xE073)                       # 0x58EC
        if self.rb(hl) == 0xFF:
            return
        col = ((self.rb(hl) >> 4) & 0x0F) * 2
        p = self.w(0xE087)
        for i in range(self[0xE085]):
            self[FILA + col + i] = self.rb(p + i)
        self.setw(0xE087, p + self[0xE085])

    # --- los remates comunes -----------------------------------------
    def remate_5537(self):
        self.el_paisaje_de_los_lados()            # 0x5537
        self.remate_553A()

    def remate_553A(self):
        # 0x553A NO apunta el arcen: eso lo hace 0x5701, dentro del paisaje de
        # los lados. Las etapas 3 y 5 entran aqui de un salto y por eso en
        # ellas la cola del arcen se apunta una sola vez.
        self.pinta_el_rotulo_de_meta()            # 0x553A
        self.arma_el_paisaje()                    # 0x553D

    # --- 0x56F7 el paisaje de los lados -------------------------------
    def el_paisaje_de_los_lados(self):
        if self[0xE07A] == 0xFE:                  # 0x56F7
            self.monta_el_paisaje_de_la_etapa()
        self.apunta_el_arcen_de_esta_fila()       # 0x5701 -> L_590E
        rama = self.rw(0x570C + 2 * (self[0xE07A] & 0x0F))
        if rama == 0x5768:
            self.fila_de_un_tramo()
        elif rama == 0x5810:
            self.fila_estrecha()
        elif rama == 0x57A7:
            self.fila_del_paisaje()

    # --- 0x590E apunta_el_arcen_de_esta_fila --------------------------
    def apunta_el_arcen_de_esta_fila(self):
        for a in range(0xE0AF, 0xE098, -1):       # 0x5917: lddr
            self[a] = self[a - 1]
        self[0xE098] = ((self[0xE07D] << 2) | (self[0xE07A] & 3)) & 0xFF

    # --- 0x57A7 arma_la_fila_del_paisaje ------------------------------
    def fila_del_paisaje(self):
        borde = self.rb(0x5808 + (self[0xE07B] & 7))
        de = FILA + self[0xE07D]
        self[de] = borde                          # 0x57BA
        de += 1
        hl = self.w(0xE06F)
        c = self[0xE081]
        hl = (hl + ((9 - c) & 0xFF)) & 0xFFFF     # 0x57C3: nueve menos
        for i in range(c):
            if 0 <= de - FILA + i < ANCHO:
                self[de + i] = self.rb(hl + i)
        self.setw(0xE06F, hl + c + 2)             # 0x57CE: dos de salto
        self.baja_la_cuenta_del_tramo()

    # --- 0x5810 arma_la_fila_estrecha ---------------------------------
    def fila_estrecha(self):
        self[0xE07B] = (self[0xE07B] - 1) & 0xFF
        if not self[0xE07B]:                      # 0x5814 -> L_5852
            if (self[0xE07A] & 0x0F) != 1:
                self[0xE07D] = (self[0xE07D] + 1) & 0xFF
            return self.pasa_al_tramo_siguiente()
        if not (self[0xE07B] & 7):                # 0x5817: uno de cada ocho
            if (self[0xE07A] & 0x0F) == 2:        # 0x5824: con el 2 se abre
                self[0xE07D] = (self[0xE07D] + 1) & 0xFF
            else:
                self[0xE07D] = (self[0xE07D] - 1) & 0xFF
            p = self.rw(0x593A + (self[0xE07A] & 0x0F) * 2)
            self.setw(0xE06F, p)
        hl = self.w(0xE06F)                       # 0x583E
        de = FILA + self[0xE07D]
        self.pon(de, self.rb(hl))                 # 0x5849: su `ldi` propio
        self.setw(0xE06F, hl + 1)
        self.tramo_ancho(de + 1)                  # 0x584B -> L_5784

    # --- 0x5768 arma_la_fila_de_un_tramo ------------------------------
    def fila_de_un_tramo(self):
        self[0xE07B] = (self[0xE07B] - 1) & 0xFF
        if not self[0xE07B]:                      # 0x576C
            return self.pasa_al_tramo_siguiente()
        hl = self.w(0xE06F)
        if self.rb(hl) == 0xFF:
            hl = 0x5998
            self.setw(0xE06F, hl)
        # 0x5768 NO copia su byte aparte: cae dentro de L_5784 y el `ldi` de
        # 0x5784 es el suyo. Contarlo dos veces deja la fila una columna corta
        # y el puntero uno atrasado, que es justo lo que la maquina no hace.
        self.tramo_ancho(FILA + self[0xE07D])     # 0x5784

    def tramo_ancho(self, de):
        """L_5784: un `ldi` y detras un tramo de tres, seis o nueve."""
        hl = self.w(0xE06F)
        self.pon(de, self.rb(hl))                 # 0x5784: el `ldi`
        hl += 1
        de += 1
        b = (self[0xE07A] >> 4) & 3
        salto = ((2 - b) & 0xFF) * 3              # 0x5790: dos menos, del reves
        hl = (hl + salto) & 0xFFFF
        n = (b + 1) * 3
        for i in range(n):
            self.pon(de + i, self.rb(hl + i))
        self.setw(0xE06F, hl + n)

    def pon(self, a, v):
        """Escribe en la fila nueva, dejando pasar el desborde de 0xE06E.

        El cartucho tampoco comprueba nada: 0xE06E y 0xE06F quedan detras de
        las 22 columnas y algun tramo ancho los roza.
        """
        if FILA <= a <= 0xE070:
            self[a] = v

    def baja_la_cuenta_del_tramo(self):
        """El final de 0x57D3, comun a la puerta ancha."""
        v = (self[0xE07B] - 1) & 0xFF
        self[0xE07B] = v
        if v & 0x80:                              # 0x57DA: `jp m`
            return self.pasa_al_tramo_siguiente()
        if v & 7 or v == 0:
            return
        if (self[0xE07A] & 0x0F) == 3:            # 0x57ED: con el 3 se ensancha
            self[0xE081] = (self[0xE081] + 1) & 0xFF
        else:
            self[0xE081] = (self[0xE081] - 1) & 0xFF
        p = self.rw(0x593A + (self[0xE07A] & 0x0F) * 2)
        self.setw(0xE06F, p)

    # --- 0x585F pasa_al_tramo_de_paisaje_siguiente --------------------
    def pasa_al_tramo_siguiente(self):
        hl = self.w(0xE071)
        self[0xE07A] = self.rb(hl)
        self[0xE07B] = self.rb(hl + 1)
        self.setw(0xE071, hl + 2)
        b = self[0xE07A]
        a = b & 0x0F
        if a == 2:                                # 0x5873: cierra el arcen
            self[0xE07D] = (self[0xE07D] - 1) & 0xFF
        p = self.rw(0x593A + a * 2)               # 0x587B
        self.setw(0xE06F, p)
        a2 = (b & 0x0F) - 3                       # 0x588C: solo el 3 y el 4
        if 0 <= a2 < 2:
            self[0xE081] = self.rb(0x58AB + a2 + ((b >> 4) & 0x0F))
        self.el_paisaje_de_los_lados()            # 0x5890 / 0x58A8

    # --- 0x5944 pinta_el_rotulo_de_meta -------------------------------
    def pinta_el_rotulo_de_meta(self):
        if self.w(0xE078) != 0x0F09:
            return
        de = self.w(0xE046) + 0x1C
        if self.etapa == 6:
            org, n, de = 0x5978, 5, de + 3        # GOAL
        else:
            org, n = 0x596D, 11                   # CHECK POINT
        for i in range(n):
            self.escribe_anillo(de + i, self.rb(org + i))

    # --- 0x54AF arma_el_paisaje ---------------------------------------
    def arma_el_paisaje(self):
        if not self[0xE0B4]:
            hl = self.w(0xE0B2)
            if self[0xE079] != self.rb(hl):
                return
            t = self.rb(hl + 1)
            self.setw(0xE0B2, hl + 2)
            self.setw(0xE0B5, 0x54F9 + t * 4)
            self[0xE0B4] = 2                      # dos filas
            self[0xE0B7] = (((self[0xE098] >> 2) & 0x3F) + 2) & 0xFF
        hl = self.w(0xE0B5)                       # 0x54E0
        de = FILA + self[0xE0B7]
        for i in range(2):
            if 0 <= de - FILA + i < ANCHO:
                self[de + i] = self.rb(hl + i)
        self.setw(0xE0B5, hl + 2)
        self[0xE0B4] -= 1

    # --- 0x5716 corre_el_anillo ---------------------------------------
    def corre_el_anillo(self):
        hl = (self.w(0xE046) - ANCHO) & 0xFFFF
        if hl == ANILLO - ANCHO:                  # 0xE170
            hl = ANILLO_FIN - ANCHO               # 0xE380
        self.setw(0xE046, hl)
        for i in range(ANCHO):
            self.escribe_anillo(hl + i, self[FILA + i])

    def escribe_anillo(self, a, v):
        while a >= ANILLO_FIN:
            a -= (ANILLO_FIN - ANILLO)
        if ANILLO <= a < ANILLO_FIN:
            self[a] = v


def corre(rom, etapa, filas):
    """Devuelve las `filas` filas de calzada que el cartucho genera."""
    m = Maquina(rom, etapa)
    for _ in range(filas):
        m.fotograma()
    return m


def anillo_de(m):
    """Las 24 filas del anillo tal como las volcaria 0x573A."""
    out, de = [], m.w(0xE046)
    for _f in range(24):
        fila = []
        for _c in range(ANCHO):
            fila.append(m[de])
            de += 1
            if de == ANILLO_FIN:
                de = ANILLO
        out.append(bytes(fila))
    return out


def dibuja(rom, etapa, filas, ruta, zoom=2):
    """Pinta las filas generadas como una tira vertical de carretera.

    Los colores salen del decorado de ESA etapa, que monta escena_juego, y
    cada celda se pinta con pinta_celda -la misma de graficos.py- para que el
    reparto en tres tercios de SCREEN 2 salga igual que en la pantalla.

    LA PRIMERA FILA VA ABAJO, y esto no es una preferencia. El generador las
    saca en el orden en que entran en la pantalla, o sea de la salida hacia
    adelante, y en este juego se avanza hacia ARRIBA: las filas nuevas asoman
    por el borde de arriba. Apilando la fila 0 arriba, el mapa sale volcado y
    todo lo que ocupa mas de una fila queda del reves -los tejados debajo de
    su fachada, la piscina encima de su casa y el rotulo de Konami, que esta
    en la linea de salida, en el otro extremo de la tira-.

    Lo destapo theNestruo (issue #1) y se publico mal. El tercio de SCREEN 2
    sigue saliendo del indice de la fila EN EL MAPA, no de donde acabe pintada:
    es lo que decide sus colores y no cambia por darle la vuelta a la tira.
    """
    v = escena_juego(rom, etapa)
    usa_fondo(0)                              # R7 = 0xE0 en marcha: fondo negro
    alto, ancho = len(filas), ANCHO * 8
    pix = [0] * (ancho * alto * 8)
    for f, fila in enumerate(filas):
        for c, tile in enumerate(fila):
            # el tercio es el de la fila de PANTALLA en la que caeria
            pinta_celda_en(v, alto - 1 - f, c, tile, pix, ancho, f % 24)
    png(pix, ancho, alto * 8, ruta, zoom)


def pinta_celda_en(vram, fila, col, tile, pix, ancho, fila_pantalla):
    """pinta_celda, pero eligiendo el tercio con la fila de pantalla."""
    from graficos import PATRONES, COLORES, PALETA, FONDO
    tercio = (fila_pantalla // 8) * 0x800
    for y in range(8):
        forma = vram[PATRONES + tercio + tile * 8 + y]
        color = vram[COLORES + tercio + tile * 8 + y]
        tinta = PALETA[color >> 4] if (color >> 4) else FONDO
        papel = PALETA[color & 15] if (color & 15) else FONDO
        for x in range(8):
            pix[(fila * 8 + y) * ancho + col * 8 + x] =                 tinta if forma & (0x80 >> x) else papel


def main():
    if len(sys.argv) < 4:
        return print(__doc__) or 2
    rom = open(sys.argv[1], "rb").read()
    salida = sys.argv[3]
    filas = int(sys.argv[4]) if len(sys.argv) > 4 else 96
    os.makedirs(salida, exist_ok=True)
    for etapa in range(1, 7):
        m = corre(rom, etapa, filas)
        dibuja(rom, etapa, m.filas, os.path.join(salida, "pista_%d.png" % etapa))
        print("  etapa %d: %d filas" % (etapa, len(m.filas)))
    print("escrito en", salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
