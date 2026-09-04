# omsx_etapa5.tcl - Fuerza la ETAPA 5 y anota que tramos de carretera salen.
#
# Para que sirve: las dos compilaciones del cartucho difieren en UN byte,
# 0x53CB, que es el decimoquinto tramo de la fila de la etapa 5 en el plan de
# 0x537D. En la compilacion con 0x05 la lista ciclica tiene QUINCE tramos y en
# la del 0xFF tiene CATORCE. Para decir cual se juega mas dificil no vale
# leerlo: hay que verlo.
#
# Como se fuerza, sin puntos de ruptura -que ahogan al emulador-: se escribe
# (0xE043)=5 por reloj emulado, muchas veces por segundo. El plan se recalcula
# solo, porque 0x702B lo vuelve a sacar de (0xE043) cada vez que la lista da
# la vuelta.
#
# Lo que se anota en cada muestra:
#   - (0xE0BD), el puntero del plan: su distancia a 0x537D+16*4 dice por que
#     tramo de la lista va
#   - el byte al que apunta, o sea el tramo en curso
#   - (0xE0E5+16i)+0 y +1 de los tres objetos de carretera: tipo y si esta en
#     juego
#
# Variables de entorno:
#   RF_SALIDA  fichero de salida

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion RF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/ROADFIGHTER_DISAM/work/etapa5.txt}]
set ::f [open $::SALIDA w]
set ::vistos {}

proc fuerza {} {
    # (0xE043) es la etapa. Se machaca sin parar para que no la suban.
    debug write memory 0xE043 5
    after time 0.05 fuerza
}

# Machacar la etapa NO basta: 0x50AB solo coloca el puntero del plan al empezar
# la etapa, y 0x702B solo lo recalcula cuando la lista da la vuelta. Asi que
# hay que ponerlo a mano en la fila de la etapa 5, y ademas al FINAL de ella,
# justo antes del byte que separa las dos compilaciones (0x53CB): asi la
# diferencia sale en los primeros segundos y no despues de un ciclo entero.
proc coloca {} {
    debug write memory 0xE0BD 0xC8
    debug write memory 0xE0BE 0x53
}

proc anota {} {
    set lo [debug read memory 0xE0BD]
    set hi [debug read memory 0xE0BE]
    set p [expr {$lo + 256 * $hi}]
    set tramo [debug read memory $p]
    set fila5 [expr {0x537D + 16 * 4}]
    set pos [expr {$p - $fila5}]
    set objs {}
    for {set i 0} {$i < 3} {incr i} {
        set b [expr {0xE0E5 + 16 * $i}]
        lappend objs [format {%d/%d} [debug read memory $b] \
                                     [debug read memory [expr {$b + 1}]]]
    }
    # solo se apunta cuando el tramo CAMBIA, que es lo que interesa
    set clave [format {%d:%d} $pos $tramo]
    if {$clave ne $::vistos} {
        set ::vistos $clave
        puts $::f [format {t=%7.2f  plan+%-3d  tramo=0x%02X  objetos %s} \
                   [machine_info time] $pos $tramo [join $objs { }]]
        flush $::f
    }
    after time 0.05 anota
}

# --- la barra de espacio ---------------------------------------------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

# El acelerador es la barra de espacio, y hay que tenerla PULSADA: sin ella el
# coche no avanza, el recorrido no sube y el plan de la etapa no pasa nunca del
# primer tramo. La primera vez fue eso lo que dejo el emulador dando vueltas
# sin anotar nada.
after time 12.0 { pulsa }
after time 14.0 { pulsa }
after time 16.0 { keymatrixdown 8 0x01 }
after time 16.5 { fuerza }
after time 16.8 { coloca }
after time 17.0 { anota }
after time 140.0 { close $::f ; exit }

after realtime 300 {
    puts {PERRO GUARDIAN a los 300 s reales}
    catch { close $::f }
    exit
}
