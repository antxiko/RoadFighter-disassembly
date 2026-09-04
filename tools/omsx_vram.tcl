# omsx_vram.tcl - Vuelca la VRAM de verdad del cartucho, para comprobar los PNG.
#
# Para que sirve: tools/graficos.py monta las imagenes ejecutando en Python los
# pasos del cartucho (el descompresor L_4611, el espejo L_4652, el interprete
# de rotulos L_45F0 y el pegador de retales L_783F). Mirar el dibujo no basta:
# hay que comparar sus bytes con los que el VDP tiene de verdad. Esto deja
# correr el juego y en varios instantes vuelca los 16 KB de VRAM, los ocho
# registros del VDP y las variables que dicen QUE se estaba dibujando.
#
# No pone NINGUN punto de ruptura: los volcados van por reloj emulado, que es
# lo unico que no ahoga al emulador.
#
# Variables de entorno:
#   RF_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart roadfighter.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion RF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/ROADFIGHTER_DISAM/work/omsx}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {etiqueta} {
    set i [format %02d $::n]
    incr ::n
    # los 16 KB de VRAM tal cual los ve el VDP
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    # los ocho registros, que dicen donde esta cada tabla
    set r {}
    for {set k 0} {$k < 8} {incr k} {
        lappend r [format %02X [debug read {VDP regs} $k]]
    }
    set f [open $::SALIDA/info_$i.txt w]
    puts $f [format {etiqueta %s} $etiqueta]
    puts $f [format {tiempo %s} [machine_info time]]
    puts $f [format {regs %s} [join $r { }]]
    # Las variables de trabajo empiezan en 0xE000. Estos nombres son los que el
    # listado de Road Fighter tiene confirmados, no los de ninguna plantilla:
    # 0xE000 es el indice del reparto de escenas de 0x4096, 0xE043 la etapa
    # (0x4394 la sube y la corta en 7), 0xE04C el contador que decide el final
    # de etapa contra la tabla de 0x74B6, y 0xE0BD el puntero de la lista
    # ciclica de tramos de la etapa (0x703A).
    foreach {nombre dir} {escena 0xE000 orden 0xE001 fotogramas 0xE003
                          contador_escena 0xE004 nivel 0xE03B
                          vuelta 0xE042 etapa 0xE043 cuenta_atras 0xE04C
                          subestado 0xE0C2} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    # el puntero de tramos, que es una palabra
    set lo [debug read memory 0xE0BD]
    set hi [debug read memory 0xE0BE]
    puts $f [format {puntero_de_tramos %d} [expr {$lo + 256 * $hi}]]
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
}

# --- la barra de espacio, que es con lo que se juega y se elige -------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

# --- calendario -------------------------------------------------------------
# El titulo tarda en montarse; antes de los 8 s la VRAM esta a medio pintar y
# no es comparable con nada. Se pulsa espacio para arrancar la partida y a
# partir de ahi los volcados cogen la pantalla de carretera ya montada.
after time  8.0 { vuelca logotipo_konami }
after time 11.0 { vuelca menu }
after time 12.0 { vuelca menu }
after time 13.0 { vuelca menu }
after time 14.0 { vuelca menu }
after time 16.0 { vuelca menu }
after time 18.0 { pulsa }
after time 19.0 { pulsa }
after time 22.0 { vuelca carretera }
after time 28.0 { vuelca carretera }
after time 30.0 { exit }

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 240 {
    puts {PERRO GUARDIAN a los 240 s reales}
    exit
}
