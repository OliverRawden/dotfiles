# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick start (new machine)

```bash
chezmoi init OliverRawden/dotfiles
chezmoi apply
```

## Daily workflow

```bash
# After editing a tracked dotfile
chezmoi add ~/.zshrc          # update source state
chezmoi git commit -m "Update zshrc"
chezmoi git push

# Or use chezmoi diff/apply to sync changes
chezmoi diff                   # see what would change
chezmoi apply                  # apply source to home directory
```

## What's included

- Shell: zsh, fish completions, starship
- Terminal: Ghostty
- Editor: Neovim (LazyVim)
- Tools: tmux, git, gh, fastfetch, btop, cava, opencode, vicinae
- Scripts: `~/.config/scripts`

## What's excluded

SSH keys, GPG, shell history, caches, and `node_modules`.