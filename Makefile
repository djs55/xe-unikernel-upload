.PHONY: all clean install build
all: build doc

BINDIR?=/tmp
MANDIR?=/tmp

setup.bin: setup.ml
	@ocamlopt.opt -o $@ $< || ocamlopt -o $@ $< || ocamlc -o $@ $<
	@rm -f setup.cmx setup.cmi setup.o setup.cmo

version.ml: VERSION
	echo "let version = \"$(shell cat VERSION)\"" > version.ml

setup.data: setup.bin
	@./setup.bin -configure

build: setup.data setup.bin version.ml
	@./setup.bin -build
	mv main.native xe-unikernel-upload
	./xe-unikernel-upload --help=groff > xe-unikernel-upload.1

doc: setup.data setup.bin
	@./setup.bin -doc

install: setup.bin
	@./setup.bin -install
	mkdir -p $(BINDIR)
	install -m 0755 xe-unikernel-upload $(BINDIR)/xe-unikernel-upload
	install -m 0644 xe-unikernel-upload.1 $(MANDIR)/xe-unikernel-upload.1

test: setup.bin build
	@./setup.bin -test

reinstall: install

uninstall:
	rm -f $(BINDIR)/xe-unikernel-upload
	rm -f $(MANDIR)/xe-unikernel-upload.1

clean:
	@ocamlbuild -clean
	@rm -f setup.data setup.log setup.bin xe-unikernel-upload.1 xe-unikernel-upload
