.PHONY: test install uninstall

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib

test:
	@bats tests/

install:
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)/mysql-query
	@cp bin/mysql-query $(BINDIR)/mysql-query
	@cp lib/mysql-query/transform.sh $(LIBDIR)/mysql-query/transform.sh
	@chmod +x $(BINDIR)/mysql-query
	@echo "Installed mysql-query to $(BINDIR)"
	@echo "Installed transform.sh to $(LIBDIR)/mysql-query"

uninstall:
	@rm -f $(BINDIR)/mysql-query
	@rm -rf $(LIBDIR)/mysql-query
	@echo "Removed mysql-query from $(BINDIR)"
	@echo "Removed $(LIBDIR)/mysql-query"
