# Dotfiles

This directory is `~/.config`. It is a normal git repo. Each app has its own folder.

## Setup on a new machine

```bash
git clone https://github.com/OliverRawden/dotfiles.git ~/.config
```

`~/.zshenv` has to live in `$HOME`, because zsh reads it before `ZDOTDIR` is set. It is a symlink to `~/.config/zsh/.zshenv`, which points zsh at `~/.config/zsh`.

## Layout

One directory per app: `fish/`, `zsh/`, `nvim/`, `ghostty/`, `git/`, `tmux/`, and the rest. Shell colours live next to the shell that uses them:

- `fish/conf.d/ayu-mirage.fish`
- `zsh/ayu-mirage.zsh`

Secrets and machine state stay untracked. See `.gitignore`.

Old home-manager copies are in `~/.local/share/dotfile-archive/`, not in this repo.

## Day to day

```bash
cd ~/.config
git add -A && git commit -m "Update configs" && git push
```
