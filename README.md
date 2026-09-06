# Dotfiles

These are my personal configs. Mac-first (Apple Silicon + Homebrew). Nothing clever — just a git repo and an install script that symlinks stuff into `$HOME`.

## Install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
```

If the repo is private, curl needs a token. Easier if you already use `gh`:

```bash
gh repo clone OliverRawden/dotfiles ~/.local/share/dotfiles
~/.local/share/dotfiles/install.sh
```

Clone lands in `~/.local/share/dotfiles`. Running the script again is fine — it won't smash existing regular files unless you pass `--force` (which backs them up first).

## What's in here

Configs live at the root of the repo, same paths as on disk:

- `.zshenv` / `.zshrc` — `.zshenv` points `ZDOTDIR` at `.config/zsh`
- `.config/` — zsh, nvim, git, tmux, fish, starship, scripts, Ghostty-adjacent stuff, etc.
- `Library/Application Support/com.mitchellh.ghostty/config.ghostty` — Ghostty lives under Library on macOS, annoying but whatever
- `install.sh` — the bootstrap

## Day to day

```bash
cd ~/.local/share/dotfiles
# edit files here...
git add -A && git commit -m "whatever" && git push
./install.sh   # if you added new paths
```

## Don't commit this

- `rclone.conf`
- `gh/hosts.yml`
- anything in `~/.ssh`
- tokens, API keys, history, `node_modules`, caches

If it's a secret or machine-specific junk, it stays off this repo.
