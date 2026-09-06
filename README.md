# Dotfiles

Plain git. No chezmoi.

Clone lives at `~/.local/share/dotfiles`. Tracked files sit under `home/`
mirroring `$HOME`, and `install.sh` symlinks them into place.

## Install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
```

The repo is **private**, so that curl needs a token (or use `gh`):

```bash
# already authed with gh:
gh repo clone OliverRawden/dotfiles ~/.local/share/dotfiles
~/.local/share/dotfiles/install.sh
```

Safe to re-run. By default it won't clobber existing regular files; pass
`--force` to back them up (`*.bak.<timestamp>`) and replace with symlinks.

Default clone path: `~/.local/share/dotfiles`.

## Layout

```
install.sh          # bootstrap (also at ~/.config/scripts/install-dotfiles.sh)
home/
  .zshenv
  .zshrc            # tiny PATH stub; real zsh lives under .config/zsh (ZDOTDIR)
  .config/
    zsh/            # .zshrc, .zprofile
    fish/
    git/
    tmux/
    nvim/
    opencode/
    zed/
    gh/config.yml   # not hosts.yml
    scripts/
    cava/, fastfetch/, cliamp/, starship.toml, ...
  Library/Application Support/com.mitchellh.ghostty/config.ghostty
```

## Day to day

```bash
cd ~/.local/share/dotfiles
# edit files under home/ ...
git add -A && git commit -m "Update configs" && git push
# re-link if you added new paths:
./install.sh
```

## Stays out of the repo

Secrets and machine state — do not commit these:

- `rclone.conf`
- `gh/hosts.yml`
- SSH keys (`~/.ssh`)
- tokens, API keys, anything that isn't plain config
- `node_modules`, lockfile junk, shell history, app caches

## macOS notes

Written for Apple Silicon + Homebrew. Ghostty config is under
`~/Library/Application Support/...` (not XDG). `~/.zshenv` sets
`ZDOTDIR=$HOME/.config/zsh`.
