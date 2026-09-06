#!/usr/bin/env bash
# Bootstrap OliverRawden/dotfiles — plain git, no chezmoi.
#
# One-liner (new machine):
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
#
# Note: the GitHub repo is private. curl needs auth, e.g.:
#   sh -c "$(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
#     https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
# Or clone with gh/git first, then run ./install.sh from the clone.
#
# Idempotent: safe to re-run. Does not print secrets.
#
# Approach: clone/pull into ~/.local/share/dotfiles, then symlink each
# tracked path from home/ into $HOME (symlink farm). Existing regular
# files are left alone unless --force is passed.

set -euo pipefail

REPO_SLUG="OliverRawden/dotfiles"
REPO_URL="https://github.com/${REPO_SLUG}.git"
DOTFILES="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
FORCE=0

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

is_macos() { [ "$(uname -s)" = "Darwin" ]; }

usage() {
  cat <<'EOF'
Usage: install.sh [--force]

  --force   Replace existing non-symlink files at destination paths
            (backups go to path.bak.<timestamp>). Symlinks are always
            updated to point at the repo.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg: $arg" ;;
  esac
done

ensure_brew_in_path() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  ensure_brew_in_path
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  is_macos || return 0
  log "Installing Homebrew (NONINTERACTIVE)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew_in_path
  command -v brew >/dev/null 2>&1 || die "Homebrew installed but brew not found on PATH"
}

repo_is_ours() {
  local dir="$1"
  [ -d "$dir/.git" ] || return 1
  local url
  url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  case "$url" in
    *OliverRawden/dotfiles*) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_clone() {
  if repo_is_ours "$DOTFILES"; then
    log "Updating $DOTFILES ..."
    git -C "$DOTFILES" pull --ff-only || log "warning: git pull failed (offline?); using existing clone"
    return 0
  fi
  if [ -e "$DOTFILES" ]; then
    die "$DOTFILES exists but is not this repo — move it aside and re-run"
  fi
  mkdir -p "$(dirname "$DOTFILES")"
  log "Cloning $REPO_SLUG → $DOTFILES ..."
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "$REPO_SLUG" "$DOTFILES"
  else
    git clone "$REPO_URL" "$DOTFILES"
  fi
  repo_is_ours "$DOTFILES" || die "clone did not look like $REPO_SLUG"
}

# Symlink $DOTFILES/home/<rel> → $HOME/<rel>
link_path() {
  local rel="$1"
  local src="$DOTFILES/home/$rel"
  local dst="$HOME/$rel"

  [ -e "$src" ] || [ -L "$src" ] || die "missing source: $src"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    local cur
    cur="$(readlink "$dst")"
    if [ "$cur" = "$src" ]; then
      return 0
    fi
    log "repoint symlink: ~/$rel"
    rm "$dst"
  elif [ -e "$dst" ]; then
    if [ "$FORCE" -eq 1 ]; then
      local bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
      log "backup existing ~/$rel → $bak"
      mv "$dst" "$bak"
    else
      log "skip (exists, not a symlink): ~/$rel  (pass --force to replace)"
      return 0
    fi
  fi

  ln -s "$src" "$dst"
  log "link ~/$rel"
}

apply_symlinks() {
  local home_root="$DOTFILES/home"
  [ -d "$home_root" ] || die "missing $home_root — is the repo layout wrong?"

  # Every regular file under home/ becomes a symlink in $HOME
  # (directories are created as needed; we link files, not dir roots,
  # so unmanaged siblings in e.g. ~/.config stay put).
  while IFS= read -r -d '' src; do
    local rel="${src#"$home_root"/}"
    link_path "$rel"
  done < <(find "$home_root" -type f -print0)
}

main() {
  if is_macos; then
    install_homebrew
    ensure_brew_in_path
  else
    ensure_brew_in_path
  fi

  ensure_clone
  apply_symlinks

  log "Done. Dotfiles linked from $DOTFILES (plain git, no chezmoi)."
  log "Re-run with --force to replace existing non-symlink files."
}

main "$@"
