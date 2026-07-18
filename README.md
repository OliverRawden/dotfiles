# Dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

Private repo: source of truth lives in `~/.local/share/chezmoi` and is applied to `$HOME`.

## Bootstrap (new machine)

```bash
# Install chezmoi (Homebrew)
brew install chezmoi

# Clone this repo and apply
chezmoi init --apply OliverRawden/dotfiles
```

If you prefer a two-step flow:

```bash
chezmoi init OliverRawden/dotfiles
chezmoi diff    # review
chezmoi apply
```

## Daily workflow

```bash
# Edit a live file, then pull it into the source state
chezmoi add ~/.zshrc
# or refresh everything already managed:
chezmoi re-add

# Commit & push from the source repo
chezmoi git add -A
chezmoi git commit -m "Update configs"
chezmoi git push

# Preview / apply source → home
chezmoi status
chezmoi diff
chezmoi apply
```

Useful:

```bash
chezmoi managed     # list tracked paths
chezmoi cd          # open a shell in the source repo
chezmoi edit ~/.zshrc
```

## What's included

| Area | Paths |
|------|--------|
| **Shell** | `~/.zshrc`, `~/.zprofile`, `~/.config/starship.toml` |
| **Git / GitHub** | `~/.gitconfig`, `~/.config/gh/` |
| **Terminal** | Ghostty (`~/Library/Application Support/com.mitchellh.ghostty/`), `~/.tmux.conf` |
| **Editors** | Neovim (LazyVim) `~/.config/nvim/`, Zed `~/.config/zed/settings.json` |
| **CLI tools** | fastfetch, cava, opencode |
| **Scripts** | `~/.config/scripts/` (see below) |

### Custom scripts (`~/.config/scripts`)

| Script | Purpose |
|--------|---------|
| `cleanup-system-leftovers.sh` | Remove leftover system files (Chrome updater, orphaned TCC entries). Run with `sudo`. |
| `proton-sync.sh` | Sync selected folders to Proton Drive. |
| `obsidian-weekly-review.sh` | Spawn a Grok Build session for the Obsidian weekly review. Helpers live in `obsidian-weekly-review/`. |

## What's excluded

Tracked intentionally **not** applied or committed:

- SSH keys, GPG, shell history
- Caches, `node_modules`, logs, `.DS_Store`
- Zed prompt library DB / themes cache
- Obsidian weekly-review `state.json` and `logs/`
- Fish config (installer-managed)

See [`.chezmoiignore`](.chezmoiignore) for the full list.

## Notes

- **Private files** (mode `600` / sensitive paths) are stored with chezmoi's `private_` prefix (e.g. `gh` hosts, Zed settings).
- Do not commit secrets. Prefer environment variables or a password manager for tokens.
- After cloning on a new Mac, install apps/fonts you rely on (Ghostty, Nerd Fonts, Neovim, Zed, etc.) separately; chezmoi only manages config files.
