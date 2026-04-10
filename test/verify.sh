#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OS="$(uname -s)"
case "$OS" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
esac

failures=0

check() {
    if eval "$1"; then
        printf "\033[1;32mPASS\033[0m: %s\n" "$2"
    else
        printf "\033[1;31mFAIL\033[0m: %s\n" "$2"
        failures=$((failures + 1))
    fi
}

# ---------------------------------------------------------------------------
# Run install.sh
# ---------------------------------------------------------------------------
printf "\n=== Running install.sh ===\n\n"
export NONINTERACTIVE=1
bash "$DOTFILES_DIR/install.sh"

# Put brew on PATH for verification
if [ "$OS" = "macos" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# Verify installations
# ---------------------------------------------------------------------------
printf "\n=== Verifying installations ===\n\n"

check "command -v brew"                                                    "Homebrew installed"
check "test -d \$HOME/.oh-my-zsh"                                         "Oh My Zsh installed"
check "test -d \$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"      "zsh-autosuggestions installed"
check "test -d \$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"  "zsh-syntax-highlighting installed"
check "test -d \$HOME/.nvm"                                               "nvm installed"
check "command -v nvim"                                                    "Neovim installed"
check "command -v fd"                                                      "fd installed"
check "command -v rg"                                                      "ripgrep installed"
check "test -L \$HOME/.config/nvim"                                       "LazyVim config is a symlink"
check "test -f \$HOME/.config/nvim/init.lua"                              "LazyVim init.lua exists"
check "command -v lazygit"                                                 "lazygit installed"

# Symlinks
check "test -L \$HOME/.zshrc"      "zshrc is a symlink"
check "test -L \$HOME/.gitconfig"  "gitconfig is a symlink"
check "readlink \$HOME/.zshrc     | grep -q 'configuration/zsh/zshrc'"    "zshrc points to correct target"
check "readlink \$HOME/.gitconfig | grep -q 'configuration/git/gitconfig'" "gitconfig points to correct target"

# ---------------------------------------------------------------------------
# Idempotency — run again, should succeed with "already installed" messages
# ---------------------------------------------------------------------------
printf "\n=== Running install.sh again (idempotency check) ===\n\n"
bash "$DOTFILES_DIR/install.sh"
check "true" "install.sh is idempotent (second run succeeded)"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf "\n"
if [ "$failures" -eq 0 ]; then
    printf "\033[1;32mAll checks passed.\033[0m\n"
else
    printf "\033[1;31m%d check(s) failed.\033[0m\n" "$failures"
fi
exit "$failures"
