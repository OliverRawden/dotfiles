# Dotfiles

This repo **is** `~/.config`. No chezmoi — just git.

## Setup on a new machine

```bash
# If ~/.config already exists, move it aside first
git clone https://github.com/OliverRawden/dotfiles.git ~/.config
```

Point zsh at this directory from `~/.zshenv`:

```bash
. "$HOME/.cargo/env"
export ZDOTDIR="$HOME/.config/zsh"
```

Ghostty lives outside XDG (`~/Library/Application Support/com.mitchellh.ghostty/`) and is not in this repo.

## Day to day

```bash
cd ~/.config
git add -A && git commit -m "Update configs" && git push
```

## Not tracked

Secrets and machine state stay local: `rclone.conf`, `gh/hosts.yml`, Wireshark keys, `node_modules`, Raycast extensions, shell history dumps.
