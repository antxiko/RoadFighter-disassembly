# omsx_coche.tcl - Mide COMO se mueve el coche por la pantalla.
#
# Lo que hay que resolver: 0xE04B/0xE04C es la Y del sprite del coche en punto
# fijo 8.8, y 0x6CA1 le suma 0x48 por fotograma con el acelerador pulsado y
# 0x6C67 le resta otros tantos sin el. Leyendo el codigo no se puede decidir
# hacia donde se mueve el coche EN PANTALLA sin equivocarse, asi que se mide:
# se deja correr la demostracion y se apunta, fotograma a fotograma, la Y del
# coche junto al acelerador -el bit 4 de (0xE009)- y la velocidad de (0xE04F).
#
# No pone puntos de ruptura: va por reloj emulado, como omsx_vram.tcl.
#
#   RF_SALIDA  fichero de salida (por defecto work/coche.txt)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart roadfighter.rom -script tools/omsx_coche.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion RF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/ROADFIGHTER_DISAM/work/coche.txt}]
set ::f [open $::SALIDA w]
puts $::f "# t  escena  estado  Yalta  Ybaja  acelerador  velocidad  Ysprite"
set ::n 0

proc apunta {} {
    set escena   [debug read memory 0xE000]
    set estado   [debug read memory 0xE049]
    set ybaja    [debug read memory 0xE04B]
    set yalta    [debug read memory 0xE04C]
    set mando    [debug read memory 0xE009]
    set veloc    [debug read memory 0xE04F]
    # la Y que el VDP tiene de verdad: sprite 1, la tabla esta en 0x3B00
    set ysprite  [debug read VRAM 0x3B04]
    puts $::f [format "%4d  %2d  %2d  0x%02X  0x%02X  %d  0x%02X  0x%02X" \
        $::n $escena $estado $yalta $ybaja [expr {($mando & 0x10) ? 1 : 0}] \
        $veloc $ysprite]
    incr ::n
    if {$::n >= 900} {
        close $::f
        exit
    }
    after time 0.06 apunta
}

# 25 segundos de margen para que arranque, pase la portada y entre la
# demostracion, que es la que pilota sola
after time 25 apunta
