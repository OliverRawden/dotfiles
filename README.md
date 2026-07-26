# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup on a new machine

```bash
# Install chezmoi (macOS)
brew install chezmoi

# Init and apply (replace USER with your GitHub username)
chezmoi init --apply OliverRawden
# or explicitly:
# chezmoi init --apply https://github.com/OliverRawden/dotfiles.git
```

## Common commands

```bash
chezmoi status          # see drift between source and home
chezmoi diff            # preview changes
chezmoi apply           # apply source → home
chezmoi add ~/.zshrc    # track a new file
chezmoi update          # pull + apply
```

## Notes

- Secrets are **not** tracked (e.g. `~/.config/gh/hosts.yml`, SSH keys, API tokens).
- Re-authenticate tools after clone (`gh auth login`, etc.).
