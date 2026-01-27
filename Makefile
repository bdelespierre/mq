.PHONY: test install uninstall

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib
GRCDIR := /usr/share/grc

test:
	@bats tests/

install:
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)/mq
	@mkdir -p $(GRCDIR)
	@cp bin/mq $(BINDIR)/mq
	@cp lib/mq/transform.sh $(LIBDIR)/mq/transform.sh
	@cp share/grc/mq $(GRCDIR)/mq
	@chmod +x $(BINDIR)/mq
	@echo "Installed mq to $(BINDIR)"
	@echo "Installed transform.sh to $(LIBDIR)/mq"
	@echo "Installed grc config to $(GRCDIR)/mq"

uninstall:
	@rm -f $(BINDIR)/mq
	@rm -rf $(LIBDIR)/mq
	@rm -f $(GRCDIR)/mq
	@echo "Removed mq from $(BINDIR)"
	@echo "Removed $(LIBDIR)/mq"
	@echo "Removed $(GRCDIR)/mq"
