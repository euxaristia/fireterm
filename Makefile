PREFIX ?= $(HOME)/.local

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	install -d $(PREFIX)/bin
	install -m 755 .build/release/fireterm $(PREFIX)/bin/fireterm

uninstall:
	rm -f $(PREFIX)/bin/fireterm

clean:
	swift package clean
