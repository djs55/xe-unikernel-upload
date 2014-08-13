.PHONY: all clean install build
all: build doc

BINDIR?=/tmp

setup.bin: setup.ml
	@ocamlopt.opt -o $@ $< || ocamlopt -o $@ $< || ocamlc -o $@ $<
	@rm -f setup.cmx setup.cmi setup.o setup.cmo

version.ml: VERSION
	echo "let version = \"$(shell cat VERSION)\"" > version.ml

setup.data: setup.bin
	@./setup.bin -configure

build: setup.data setup.bin version.ml
	@./setup.bin -build

doc: setup.data setup.bin
	@./setup.bin -doc

install: setup.bin
	@./setup.bin -install
	mkdir -p $(BINDIR)
	install -m 0755 _build/main.native $(BINDIR)/xe-unikernel-upload

test: setup.bin build
	@./setup.bin -test

reinstall: install

uninstall:
	rm -f $(BINDIR)/xe-unikernel-upload

clean:
	@ocamlbuild -clean
	@rm -f setup.data setup.log setup.bin
