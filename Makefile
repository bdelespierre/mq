.PHONY: test install uninstall

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib

test:
	@bats tests/

install:
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)/mq
	@cp bin/mq $(BINDIR)/mq
	@cp lib/mq/transform.sh $(LIBDIR)/mq/transform.sh
	@chmod +x $(BINDIR)/mq
	@echo "Installed mq to $(BINDIR)"
	@echo "Installed transform.sh to $(LIBDIR)/mq"

uninstall:
	@rm -f $(BINDIR)/mq
	@rm -rf $(LIBDIR)/mq
	@echo "Removed mq from $(BINDIR)"
	@echo "Removed $(LIBDIR)/mq"
