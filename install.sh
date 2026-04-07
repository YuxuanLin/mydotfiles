#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m==> %s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
err()   { printf "\033[1;31m==> %s\033[0m\n" "$1"; }

# Back up a file to its .local variant before symlinking.
# Skips if the file doesn't exist, is already a symlink (previous install),
# or the .local file already exists (don't overwrite a prior backup).
backup_to_local() {
    local src="$1" dst="$2"
    if [ -f "$src" ] && [ ! -L "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        ok "Backed up $src → $dst"
    fi
}

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      err "Unsupported OS: $OS"; exit 1 ;;
esac
info "Detected OS: $OS"

# ---------------------------------------------------------------------------
# Ubuntu prerequisites
# ---------------------------------------------------------------------------
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
# Oh My Zsh
# ---------------------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh…"
    RUNZSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# ---------------------------------------------------------------------------
# Zsh plugins
# ---------------------------------------------------------------------------
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
# Fonts — JetBrainsMono Nerd Font
# ---------------------------------------------------------------------------
if [ "$OS" = "macos" ]; then
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        ok "JetBrainsMono Nerd Font already installed"
    else
        info "Installing JetBrainsMono Nerd Font…"
        brew install --cask font-jetbrains-mono-nerd-font
    fi
else
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if [ -d "$FONT_DIR" ] && [ "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
        ok "JetBrainsMono Nerd Font already installed"
    else
        info "Installing JetBrainsMono Nerd Font…"
        FONT_VERSION="3.3.0"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/JetBrainsMono.tar.xz"
        mkdir -p "$FONT_DIR"
        curl -fsSL "$FONT_URL" | tar -xJ -C "$FONT_DIR"
        fc-cache -f "$FONT_DIR"
        ok "Installed JetBrainsMono Nerd Font to $FONT_DIR"
    fi
fi

# ---------------------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------------------
if command -v nvim &>/dev/null; then
    ok "Neovim already installed"
else
    info "Installing Neovim…"
    brew install neovim
fi

# ---------------------------------------------------------------------------
# LazyVim
# ---------------------------------------------------------------------------
if [ -d "$HOME/.config/nvim" ]; then
    ok "LazyVim already installed"
else
    info "Installing LazyVim…"
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
fi

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
# Symlinks — back up existing configs to .local variants before overwriting.
# Each managed config file sources/includes its .local counterpart, so any
# prior user customizations are preserved automatically.
# ---------------------------------------------------------------------------
info "Creating symlinks…"

backup_to_local "$HOME/.zshrc"       "$HOME/.zshrc.local"
ln -sfn "$DOTFILES_DIR/configuration/zsh/zshrc" "$HOME/.zshrc"
ok "Linked zshrc → ~/.zshrc"

backup_to_local "$HOME/.gitconfig"   "$HOME/.gitconfig.local"
ln -sfn "$DOTFILES_DIR/configuration/git/gitconfig" "$HOME/.gitconfig"
ok "Linked gitconfig → ~/.gitconfig"

# ---------------------------------------------------------------------------
echo ""
ok "All done! Open a new terminal or run: source ~/.zshrc"
