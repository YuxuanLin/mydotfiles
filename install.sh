#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m==> %s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
err()   { printf "\033[1;31m==> %s\033[0m\n" "$1"; }

backup_to_local() {
    local src="$1" dst="$2"
    if [ -f "$src" ] && [ ! -L "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        ok "Backed up $src → $dst"
    fi
}

# ---------------------------------------------------------------------------
# OS detection & prerequisites
# ---------------------------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      err "Unsupported OS: $OS"; exit 1 ;;
esac
info "Detected OS: $OS"

if [ "$OS" = "linux" ]; then
    info "Installing Linux prerequisites…"
    sudo apt-get update -qq
    sudo apt-get install -y -qq build-essential curl git zsh
fi

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------
if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
else
    info "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ "$OS" = "macos" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# ---------------------------------------------------------------------------
# Git — config
# ---------------------------------------------------------------------------
backup_to_local "$HOME/.gitconfig"   "$HOME/.gitconfig.local"
ln -sfn "$DOTFILES_DIR/configuration/git/gitconfig" "$HOME/.gitconfig"
ok "Linked gitconfig → ~/.gitconfig"

# ---------------------------------------------------------------------------
# Zsh — install, plugins, config
# ---------------------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh…"
    RUNZSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    ok "zsh-autosuggestions already installed"
else
    info "Installing zsh-autosuggestions…"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    ok "zsh-syntax-highlighting already installed"
else
    info "Installing zsh-syntax-highlighting…"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

backup_to_local "$HOME/.zshrc"       "$HOME/.zshrc.local"
ln -sfn "$DOTFILES_DIR/configuration/zsh/zshrc" "$HOME/.zshrc"
ok "Linked zshrc → ~/.zshrc"

# ---------------------------------------------------------------------------
# nvm
# ---------------------------------------------------------------------------
if [ -d "$HOME/.nvm" ]; then
    ok "nvm already installed"
else
    info "Installing nvm…"
    PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)"
fi

# ---------------------------------------------------------------------------
# Neovim — install, dependencies, config
# ---------------------------------------------------------------------------
if command -v nvim &>/dev/null; then
    ok "Neovim already installed"
else
    info "Installing Neovim…"
    brew install neovim
fi

if command -v fd &>/dev/null; then
    ok "fd already installed"
else
    info "Installing fd…"
    brew install fd
fi

if command -v rg &>/dev/null; then
    ok "ripgrep already installed"
else
    info "Installing ripgrep…"
    brew install ripgrep
fi

NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$HOME/.config"
if [ -d "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
    warn "Backing up existing nvim config to $NVIM_DIR.bak"
    mv "$NVIM_DIR" "$NVIM_DIR.bak"
fi
if [ ! -L "$NVIM_DIR" ]; then
    info "Linking LazyVim config…"
    ln -sfn "$DOTFILES_DIR/configuration/nvim" "$NVIM_DIR"
    ok "Linked nvim config → ~/.config/nvim"
else
    ok "LazyVim config already linked"
fi

# ---------------------------------------------------------------------------
# tmux — install, TPM, plugins, config
# ---------------------------------------------------------------------------
if command -v tmux &>/dev/null; then
    ok "tmux already installed"
else
    info "Installing tmux…"
    brew install tmux
fi

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    ok "TPM already installed"
else
    info "Installing TPM (Tmux Plugin Manager)…"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

backup_to_local "$HOME/.tmux.conf"   "$HOME/.tmux.conf.local"
ln -sfn "$DOTFILES_DIR/configuration/tmux/tmux.conf" "$HOME/.tmux.conf"
ok "Linked tmux.conf → ~/.tmux.conf"

# Install tmux plugins via TPM
info "Installing tmux plugins…"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

# ---------------------------------------------------------------------------
# lazygit
# ---------------------------------------------------------------------------
if command -v lazygit &>/dev/null; then
    ok "lazygit already installed"
else
    info "Installing lazygit…"
    brew install lazygit
fi

# ---------------------------------------------------------------------------
echo ""
ok "All done! Open a new terminal or run: source ~/.zshrc"
