#!/usr/bin/env bash
#
# mq installer - curl -fsSL https://raw.githubusercontent.com/bdelespierre/mq/master/install.sh | bash
#

set -euo pipefail

REPO="bdelespierre/mq"
INSTALL_DIR="${MQ_INSTALL_DIR:-$HOME/.local}"
TMP_DIR=""

info() { echo -e "\033[1;34m==>\033[0m $*"; }
error() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

cleanup() {
    [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Check dependencies
command -v curl >/dev/null 2>&1 || error "curl is required but not installed"
command -v tar >/dev/null 2>&1 || error "tar is required but not installed"
command -v make >/dev/null 2>&1 || error "make is required but not installed"

# Get latest tag from GitHub API
info "Fetching latest version..."
LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/tags" | grep -m1 '"name":' | cut -d'"' -f4)
[[ -z "$LATEST_TAG" ]] && error "Failed to fetch latest version"
info "Latest version: $LATEST_TAG"

# Create temp directory
TMP_DIR=$(mktemp -d)

# Download and extract tarball
TARBALL_URL="https://github.com/$REPO/archive/refs/tags/$LATEST_TAG.tar.gz"
info "Downloading $TARBALL_URL..."
curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR"

# Find extracted directory (mq-{version} without 'v' prefix)
EXTRACT_DIR="$TMP_DIR/mq-${LATEST_TAG#v}"
[[ -d "$EXTRACT_DIR" ]] || error "Failed to extract archive"

# Install
info "Installing to $INSTALL_DIR..."
make -C "$EXTRACT_DIR" install PREFIX="$INSTALL_DIR" >/dev/null

# Verify installation
if [[ -x "$INSTALL_DIR/bin/mq" ]]; then
    info "Successfully installed mq $LATEST_TAG to $INSTALL_DIR/bin/mq"
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
