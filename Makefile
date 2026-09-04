# Road Fighter (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# Hay DOS compilaciones del cartucho, la facil y la dificil, y difieren en UN
# SOLO BYTE (0x53CB). El listado se hace sobre la facil; la dificil se coteja
# con `make coteja`, que comprueba que la diferencia sigue siendo esa y solo esa.
#
# Ninguna de las dos se distribuye. Hacen falta en la raiz como roadfighter.rom
# y roadfighter_dificil.rom, y `make comprueba` verifica los dos sha256.

ROM      = roadfighter.rom
ROMD     = roadfighter_dificil.rom
SHA      = 6d36c9e9b6a6b93f642722dcd314834d01e519ab3a98d7e4ca257468bcaf29e1
SHAD     = 070fc231f979a04bb4652f7c5e585f6445758af32ffcbf60757deb1f7b5856e7
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = ROAD FIGHTER - Konami - MSX1 - cartucho RC-730 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Road Fighter (Konami, RC-730) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -
	@test -f $(ROMD) && echo "$(SHAD)  $(ROMD)" | shasum -a 256 -c - || \
	 echo "  (falta $(ROMD); solo hace falta para 'make coteja')"

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/roadfighter.trace.json: $(ROM) $(SRC)/roadfighter.entries $(SRC)/roadfighter.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/roadfighter.entries \
	        $(WORK)/roadfighter $(SRC)/roadfighter.nocode

trace: $(WORK)/roadfighter.trace.json

listado: $(WORK)/roadfighter.trace.json $(SRC)/roadfighter.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/roadfighter.trace.json \
	        $(SRC)/roadfighter.notes work/msx.sym $(SRC)/roadfighter.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/roadfighter.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/roadfighter.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/roadfighter.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/roadfighter.trace.json $(SRC)/roadfighter.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/roadfighter.entries $(SRC)/roadfighter.notes \
	        $(SRC)/roadfighter.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/roadfighter.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/dibuja.py $(ROM) $(ORG) $(SRC)/roadfighter.notes work/gfx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/roadfighter.trace.json $(WORK)/roadfighter.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes web clean
