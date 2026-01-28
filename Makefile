.PHONY: test install install-local install-system uninstall uninstall-local uninstall-system

test:
	@bats tests/

# Local installation (~/.local and ~/.grc)
install-local:
	@mkdir -p ~/.local/bin
	@mkdir -p ~/.local/lib/mq
	@mkdir -p ~/.local/share/bash-completion/completions
	@mkdir -p ~/.grc
	@cp bin/mq ~/.local/bin/mq
	@cp lib/mq/transform.bash ~/.local/lib/mq/transform.bash
	@cp share/bash-completion/completions/mq ~/.local/share/bash-completion/completions/mq
	@cp share/grc/conf.mq ~/.grc/conf.mq
	@chmod +x ~/.local/bin/mq
	@echo "Installed mq to ~/.local/bin"
	@echo "Installed transform.bash to ~/.local/lib/mq"
	@echo "Installed bash completion to ~/.local/share/bash-completion/completions"
	@echo "Installed grc config to ~/.grc/conf.mq"

# System installation (/usr/local)
install-system:
	@mkdir -p /usr/local/bin
	@mkdir -p /usr/local/lib/mq
	@mkdir -p /usr/local/share/bash-completion/completions
	@mkdir -p /usr/local/share/grc
	@cp bin/mq /usr/local/bin/mq
	@cp lib/mq/transform.bash /usr/local/lib/mq/transform.bash
	@cp share/bash-completion/completions/mq /usr/local/share/bash-completion/completions/mq
	@cp share/grc/conf.mq /usr/local/share/grc/conf.mq
	@chmod +x /usr/local/bin/mq
	@echo "Installed mq to /usr/local/bin"
	@echo "Installed transform.bash to /usr/local/lib/mq"
	@echo "Installed bash completion to /usr/local/share/bash-completion/completions"
	@echo "Installed grc config to /usr/local/share/grc/conf.mq"

# Default install (local)
install: install-local

# Local uninstall
uninstall-local:
	@rm -f ~/.local/bin/mq
	@rm -rf ~/.local/lib/mq
	@rm -f ~/.local/share/bash-completion/completions/mq
	@rm -f ~/.grc/conf.mq
	@echo "Removed mq from ~/.local/bin"
	@echo "Removed ~/.local/lib/mq"
	@echo "Removed bash completion from ~/.local/share/bash-completion/completions"
	@echo "Removed ~/.grc/conf.mq"

# System uninstall
uninstall-system:
	@rm -f /usr/local/bin/mq
	@rm -rf /usr/local/lib/mq
	@rm -f /usr/local/share/bash-completion/completions/mq
	@rm -f /usr/local/share/grc/conf.mq
	@echo "Removed mq from /usr/local/bin"
	@echo "Removed /usr/local/lib/mq"
	@echo "Removed bash completion from /usr/local/share/bash-completion/completions"
	@echo "Removed /usr/local/share/grc/conf.mq"

# Default uninstall (local)
uninstall: uninstall-local
