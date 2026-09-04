# omsx_etapa.tcl - Como omsx_carretera.tcl, pero forzando QUE ETAPA se juega.
#
# La demostracion sortea la etapa con el registro R (0x52B8), y en un arranque
# limpio de openMSX el sorteo sale siempre igual: la 2. Para poder comprobar
# tools/pista.py contra las SEIS ramas de calzada hace falta forzarla.
#
# Se fuerza en el sitio bueno: un punto de ruptura en 0x504C, la primera
# instruccion de `prepara_la_etapa`, que escribe (0xE043) ANTES de que la
# rutina monte nada. Asi el decorado, los guiones y las listas se eligen todos
# para la etapa forzada y el estado queda coherente -al reves de lo que pasa
# forzando (0xE043) a mitad de partida, que deja la pantalla con basura-.
#
#   RF_ETAPA   la etapa, de 1 a 6 (por defecto 1)
#   RF_SALIDA  carpeta de salida
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart roadfighter.rom -script tools/omsx_etapa.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::ETAPA  [opcion RF_ETAPA 1]
set ::SALIDA [opcion RF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/ROADFIGHTER_DISAM/work/carretera}]
file mkdir $::SALIDA
set ::n 0

# 0x504C: la primera instruccion de prepara_la_etapa
debug set_bp 0x504C {} {
    debug write memory 0xE043 $::ETAPA
}

proc vuelca {} {
    if {[debug read memory 0xE043] != $::ETAPA} { after frame vuelca ; return }
    set i [format %03d $::n]
    set f [open $::SALIDA/vars_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE040 128]
    close $f
    set f [open $::SALIDA/anillo_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE186 528]
    close $f
    incr ::n
    if {$::n >= 60} { exit }
    after frame vuelca
}

after time 30 vuelca
