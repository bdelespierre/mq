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
	@cp lib/mq/transform.bash $(LIBDIR)/mq/transform.bash
	@chmod +x $(BINDIR)/mq
	@echo "Installed mq to $(BINDIR)"
	@echo "Installed transform.bash to $(LIBDIR)/mq"
	@if mkdir -p /usr/share/grc && cp share/grc/mq /usr/share/grc/mq 2>/dev/null; then \
		echo "Installed grc config to /usr/share/grc/mq"; \
	elif mkdir -p ~/.grc && cp share/grc/mq ~/.grc/mq 2>/dev/null; then \
		echo "Installed grc config to ~/.grc/mq"; \
	else \
		echo "Skipped grc config (could not write to /usr/share/grc or ~/.grc)"; \
	fi

uninstall:
	@rm -f $(BINDIR)/mq
	@rm -rf $(LIBDIR)/mq
	@-rm -f /usr/share/grc/mq 2>/dev/null
	@-rm -f ~/.grc/mq 2>/dev/null
	@echo "Removed mq from $(BINDIR)"
	@echo "Removed $(LIBDIR)/mq"
