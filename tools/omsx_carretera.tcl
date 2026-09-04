# omsx_carretera.tcl - Vuelca el estado del generador de carretera en
# fotogramas CONSECUTIVOS, para comprobar tools/pista.py contra la maquina.
#
# La comparacion contra un volcado de VRAM suelto no vale: la carretera es
# procedural y depende de todo lo que se lleva recorrido, asi que no hay forma
# de saber en que punto del guion estaba. Lo que si vale es esto: se apunta el
# estado ENTERO del generador -las variables de 0xE040 a 0xE0C0, el anillo de
# 0xE186 a 0xE395 y la fila nueva de 0xE058- en fotogramas seguidos. Despues,
# en Python, se carga el estado del fotograma N, se ejecuta UN paso y se
# compara con el estado del N+1. Si el motor rehecho es fiel, tiene que salir
# byte a byte.
#
#   RF_SALIDA  carpeta de salida (por defecto work/carretera)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart roadfighter.rom -script tools/omsx_carretera.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion RF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/ROADFIGHTER_DISAM/work/carretera}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {} {
    # solo interesa cuando se esta jugando de verdad: el reparto de escenas
    # de (0xE000) tiene que estar en una escena de partida y la etapa puesta
    set etapa [debug read memory 0xE043]
    if {$etapa < 1 || $etapa > 6} { after frame vuelca ; return }

    set i [format %03d $::n]
    # 0xE040..0xE0C0: las variables del generador
    set f [open $::SALIDA/vars_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE040 128]
    close $f
    # 0xE186..0xE395: el anillo entero
    set f [open $::SALIDA/anillo_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE186 528]
    close $f

    incr ::n
    if {$::n >= 60} { exit }
    after frame vuelca
}

# 30 segundos: arranque, portada y la demostracion ya rodando
after time 30 vuelca
