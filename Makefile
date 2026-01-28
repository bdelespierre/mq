.PHONY: test install install-local install-system uninstall uninstall-local uninstall-system

test:
	@bats tests/

# Local installation (~/.local and ~/.grc)
install-local:
	@mkdir -p ~/.local/bin
	@mkdir -p ~/.local/lib/mq
	@mkdir -p ~/.grc
	@cp bin/mq ~/.local/bin/mq
	@cp lib/mq/transform.bash ~/.local/lib/mq/transform.bash
	@cp share/grc/conf.mq ~/.grc/conf.mq
	@chmod +x ~/.local/bin/mq
	@echo "Installed mq to ~/.local/bin"
	@echo "Installed transform.bash to ~/.local/lib/mq"
	@echo "Installed grc config to ~/.grc/conf.mq"

# System installation (/usr/local and /usr/share/grc)
install-system:
	@mkdir -p /usr/local/bin
	@mkdir -p /usr/local/lib/mq
	@mkdir -p /usr/share/grc
	@cp bin/mq /usr/local/bin/mq
	@cp lib/mq/transform.bash /usr/local/lib/mq/transform.bash
	@cp share/grc/conf.mq /usr/share/grc/conf.mq
	@chmod +x /usr/local/bin/mq
	@echo "Installed mq to /usr/local/bin"
	@echo "Installed transform.bash to /usr/local/lib/mq"
	@echo "Installed grc config to /usr/share/grc/conf.mq"

# Default install (local)
install: install-local

# Local uninstall
uninstall-local:
	@rm -f ~/.local/bin/mq
	@rm -rf ~/.local/lib/mq
	@rm -f ~/.grc/conf.mq
	@echo "Removed mq from ~/.local/bin"
	@echo "Removed ~/.local/lib/mq"
	@echo "Removed ~/.grc/conf.mq"

# System uninstall
uninstall-system:
	@rm -f /usr/local/bin/mq
	@rm -rf /usr/local/lib/mq
	@rm -f /usr/share/grc/conf.mq
	@echo "Removed mq from /usr/local/bin"
	@echo "Removed /usr/local/lib/mq"
	@echo "Removed /usr/share/grc/conf.mq"

# Default uninstall (local)
uninstall: uninstall-local
