# Dotfiles

This repo is just a backup of `~/.config`.

## Setup on a new machine

```bash
# If ~/.config already exists, move it aside first
git clone git@github.com:OliverRawden/config.git ~/.config
# or: git clone https://github.com/OliverRawden/config.git ~/.config
```

Point zsh at this directory from `~/.zshenv`:

```bash
. "$HOME/.cargo/env"
export ZDOTDIR="$HOME/.config/zsh"
```

Ghostty lives outside XDG (`~/Library/Application Support/com.mitchellh.ghostty/`) and is not in this repo yet.

