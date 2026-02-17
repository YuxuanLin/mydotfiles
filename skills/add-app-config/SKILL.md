---
name: add-app-config
description: >-
  Add a new application's configuration files to the mydotfiles repository,
  update install.sh with the appropriate symlink or setup command, and update
  README.md. Use when the user wants to track, persist, or manage a new app's
  config in their dotfiles.
---

# Add App Configuration

Add a new application's configuration to this dotfiles repo so it is version-controlled and automatically restored on a fresh machine.

## Repo layout

```
mydotfiles/
├── install.sh
├── README.md
└── configuration/
    ├── git/gitconfig          # symlinked → ~/.gitconfig
    ├── iterm2/…               # loaded via macOS defaults
    ├── vscode/…
    └── zsh/zshrc              # symlinked → ~/.zshrc
```

## Steps

### 1. Identify the config to track

Determine:
- **App name** (lowercase, used as directory name under `configuration/`)
- **Source path(s)** — where the app stores its config (e.g. `~/.config/app/config.toml`, `~/Library/Preferences/…`)
- **Install method** — how the config is consumed by the app:
  - **symlink** (most common) — `ln -sfn` from the default location to the repo copy
  - **defaults write** — for macOS plist-based apps (like iTerm2)
  - **copy** — if the app doesn't support symlinks and rewrites the file
  - **XDG / env var** — if the app reads a path from an environment variable

### 2. Copy the config into the repo

```bash
mkdir -p configuration/<app-name>
cp <source-path> configuration/<app-name>/
```

Remove any secrets, tokens, or machine-specific absolute paths. If the config contains secrets, split it: track the non-secret parts and document the secrets the user must fill in manually.

### 3. Update install.sh

Add a new section following the existing pattern. Place it in the **Symlinks** block if it's a symlink, or create a dedicated block (like the iTerm2 block) for more complex setups.

**Symlink example:**

```bash
ln -sfn "$DOTFILES_DIR/configuration/<app-name>/<filename>" "$HOME/.<filename>"
ok "Linked <filename> → ~/.<filename>"
```

**defaults write example (macOS plist apps):**

```bash
if [ -d "/Applications/<App>.app" ]; then
    info "Configuring <App>…"
    defaults write <bundle-id> <key> -<type> <value>
    ok "<App> configured"
else
    warn "<App> not found — skipping"
fi
```

Guidelines:
- Keep the script idempotent — `ln -sfn` already handles overwriting
- Guard optional apps with an existence check (`if [ -d … ]` or `command -v`)
- Use the existing `info`, `ok`, `warn` helpers for output

### 4. Update README.md

Add a row to the **Managed Configs** table:

```markdown
| `configuration/<app-name>/<filename>` | Brief description |
```

If a symlink was added, add it to the **Symlinks** list under **What the Installer Does** as well.

### 5. Verify

- Run `install.sh` and confirm the new config is linked / loaded correctly
- Confirm the app picks up the managed config
- Check `git diff` to review what will be committed
