.PHONY: test install install-local install-system uninstall uninstall-local uninstall-system

# Default prefix for local installation
PREFIX ?= $(HOME)/.local

test:
	@bats tests/

# Install to $(PREFIX)
install:
	@mkdir -p $(PREFIX)/bin
	@mkdir -p $(PREFIX)/lib/mq
	@mkdir -p $(PREFIX)/share/bash-completion/completions
	@mkdir -p $(PREFIX)/share/grc
	@cp bin/mq $(PREFIX)/bin/mq
	@cp lib/mq/transform.bash $(PREFIX)/lib/mq/transform.bash
	@cp share/bash-completion/completions/mq $(PREFIX)/share/bash-completion/completions/mq
	@cp share/grc/conf.mq $(PREFIX)/share/grc/conf.mq
	@chmod +x $(PREFIX)/bin/mq
	@echo "Installed mq to $(PREFIX)/bin"
	@echo "Installed transform.bash to $(PREFIX)/lib/mq"
	@echo "Installed bash completion to $(PREFIX)/share/bash-completion/completions"
	@echo "Installed grc config to $(PREFIX)/share/grc/conf.mq"

# Uninstall from $(PREFIX)
uninstall:
	@rm -f $(PREFIX)/bin/mq
	@rm -rf $(PREFIX)/lib/mq
	@rm -f $(PREFIX)/share/bash-completion/completions/mq
	@rm -f $(PREFIX)/share/grc/conf.mq
	@echo "Removed mq from $(PREFIX)/bin"
	@echo "Removed $(PREFIX)/lib/mq"
	@echo "Removed bash completion from $(PREFIX)/share/bash-completion/completions"
	@echo "Removed grc config from $(PREFIX)/share/grc/conf.mq"
