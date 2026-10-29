# rlsp is raz modules a program builds with its own raz, reaching them
# with -I rlsp/src, or from ~/.raz/lib after make install. They need
# rjson's Json: ../rjson/src here, or RJSON=... Each module's main is
# its test; the session test plays a small peer, or the installed
# TypeScript server. Tests build with the raz on PATH, which must be
# the version the modules are written for, RAZVERSION: make warns of
# any other.
#
#   make check      each module's test, then the session with a test peer
#   make check-lsp  the session with the installed typescript-language-server;
#                   TSSERVER selects tsserver.js
#   make fmt        the sources are as raz's formatter lays them out
#   make loc        lines, by rloc; a measure, not a limit
#   make install    the modules in RAZLIB (~/.raz/lib)

RAZ ?= raz
RAZVERSION = 0.25.0
# Build and test from this checkout only, never the copy `make install` put on RAZ_PATH.
export RAZ_PATH :=
RJSON ?= ../rjson/src
# raz's tools, the formatter among them, lie beside its real path
RAZTOOLS = $(dir $(realpath $(shell command -v $(RAZ))))tools

ifneq "$(word 2,$(shell $(RAZ) --version 2>/dev/null))" "$(RAZVERSION),"
$(warning rlsp is written for raz $(RAZVERSION); $(RAZ) is $(or $(shell $(RAZ) --version 2>/dev/null),not found))
endif
INC = -I src -I $(RJSON)
MODS = LspWire LspText
TSSERVER ?=

build:
	mkdir -p build

# each module's main is its test; then LspServer against the test peer
check: | build
	@for m in $(MODS); do \
	    $(RAZ) -Werror $(INC) -o build/$$m src/$$m.raz && build/$$m || { echo "FAIL $$m"; exit 1; }; \
	done
	$(RAZ) -Werror $(INC) -o build/LspServer src/LspServer.raz
	$(RAZ) -Werror $(INC) -o build/LspPeer test/LspPeer.raz
	$(RAZ) -Werror $(INC) -o build/LspSession test/LspSession.raz
	build/LspSession

# optional: the installed TypeScript server, no downloads
check-lsp: | build
	$(RAZ) -Werror $(INC) -o build/LspSession test/LspSession.raz
	build/LspSession --typescript $(if $(TSSERVER),--tsserver "$(TSSERVER)")

# the sources are as raz's formatter lays them out
fmt: | build
	$(RAZ) -o build/Pretty $(RAZTOOLS)/Pretty.raz
	@fail=0; for f in src/*.raz test/*.raz; do \
	    build/Pretty $$f | cmp -s - $$f || { echo "not formatted: $$f"; fail=1; }; \
	done; test $$fail = 0

loc:
	@rloc src test/*.raz

# Where `make install` puts the modules, for programs to import with no -I: raz(1), RAZ_PATH.
RAZLIB ?= $(HOME)/.raz/lib
MODULES = $(wildcard src/*.raz)

install:
	mkdir -p $(RAZLIB)
	install -m644 $(MODULES) $(RAZLIB)
	echo 0.25 > $(RAZLIB)/RAZ-VERSION

uninstall:
	rm -f $(addprefix $(RAZLIB)/,$(notdir $(MODULES)))

clean:
	rm -rf build

.PHONY: check check-lsp fmt loc install uninstall clean
