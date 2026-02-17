# My Dotfiles
This directory stores the real shell config files and keeps `~/.zshrc` as a tiny bootstrap loader.

## Concept
- Keep `~/.zshrc` minimal and stable.
- Put the actual zsh configuration in `~/.mydotfiles/zshrc`.
- Let `~/.zshrc` source that file at shell startup.
- Version-control files under `~/.mydotfiles` with git.

Current bootstrap line in `~/.zshrc`:

```sh
[ -f "$HOME/.mydotfiles/zshrc" ] && source "$HOME/.mydotfiles/zshrc"