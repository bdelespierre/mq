#!/usr/bin/env bash
#
# mq installer - curl -fsSL https://raw.githubusercontent.com/bdelespierre/mq/master/install.sh | bash
#

set -euo pipefail

REPO="https://github.com/bdelespierre/mq.git"
INSTALL_DIR="${MQ_INSTALL_DIR:-$HOME/.local}"
TMP_DIR=""

info() { echo -e "\033[1;34m==>\033[0m $*"; }
error() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

cleanup() {
    [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Check dependencies
command -v git >/dev/null 2>&1 || error "git is required but not installed"
command -v make >/dev/null 2>&1 || error "make is required but not installed"

# Create temp directory
TMP_DIR=$(mktemp -d)
info "Cloning mq repository..."
git clone --quiet --depth 1 "$REPO" "$TMP_DIR"

# Install
info "Installing to $INSTALL_DIR..."
make -C "$TMP_DIR" install PREFIX="$INSTALL_DIR" >/dev/null

# Verify installation
if [[ -x "$INSTALL_DIR/bin/mq" ]]; then
    info "Successfully installed mq to $INSTALL_DIR/bin/mq"
else
    error "Installation failed"
fi

# Check if bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR/bin:"* ]]; then
    echo ""
    echo "Add this to your shell profile (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "    export PATH=\"\$PATH:$INSTALL_DIR/bin\""
    echo ""
fi

info "Done! Run 'mq --help' to get started."
