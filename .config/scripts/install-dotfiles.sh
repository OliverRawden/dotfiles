#!/usr/bin/env bash
# My dotfiles bootstrap. Plain git, nothing fancy.
#
# New machine:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
#
# If the repo is private, curl needs a token, or just:
#   gh repo clone OliverRawden/dotfiles ~/.local/share/dotfiles
#   ~/.local/share/dotfiles/install.sh
#
# Safe to run more than once. Won't overwrite normal files unless you pass --force.

set -euo pipefail

REPO_SLUG="OliverRawden/dotfiles"
REPO_URL="https://github.com/${REPO_SLUG}.git"
DOTFILES="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
FORCE=0

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

is_macos() { [ "$(uname -s)" = "Darwin" ]; }

usage() {
  cat <<'USAGE'
Usage: install.sh [--force]

  --force   Replace existing non-symlink files (backs them up as *.bak.<timestamp>)
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg: $arg" ;;
  esac
done

ensure_brew_in_path() {
  command -v brew >/dev/null 2>&1 && return 0
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  command -v brew >/dev/null 2>&1 && return 0
  ensure_brew_in_path
  command -v brew >/dev/null 2>&1 && return 0
  is_macos || return 0
  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew_in_path
  command -v brew >/dev/null 2>&1 || die "Homebrew installed but brew isn't on PATH"
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
    git -C "$DOTFILES" pull --ff-only || log "warning: pull failed; using what's already there"
    return 0
  fi
  if [ -e "$DOTFILES" ]; then
    die "$DOTFILES exists but isn't this repo — move it aside and re-run"
  fi
  mkdir -p "$(dirname "$DOTFILES")"
  log "Cloning $REPO_SLUG → $DOTFILES ..."
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "$REPO_SLUG" "$DOTFILES"
  else
    git clone "$REPO_URL" "$DOTFILES"
  fi
  repo_is_ours "$DOTFILES" || die "clone didn't look like $REPO_SLUG"
}

# Files that live in the repo but shouldn't be linked into $HOME
skip_rel() {
  case "$1" in
    README.md|install.sh|.gitignore|.gitattributes) return 0 ;;
    *) return 1 ;;
  esac
}

link_path() {
  local rel="$1"
  local src="$DOTFILES/$rel"
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
      log "backup ~/$rel → $bak"
      mv "$dst" "$bak"
    else
      log "skip (exists): ~/$rel  (use --force to replace)"
      return 0
    fi
  fi

  ln -s "$src" "$dst"
  log "link ~/$rel"
}

apply_symlinks() {
  [ -d "$DOTFILES/.git" ] || die "missing $DOTFILES/.git"
  # Only link files git tracks — skips README/install and anything gitignored.
  while IFS= read -r -d '' rel; do
    [ -n "$rel" ] || continue
    skip_rel "$rel" && continue
    link_path "$rel"
  done < <(git -C "$DOTFILES" ls-files -z)
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

  log "Done. Linked from $DOTFILES"
  log "Re-run with --force if you want existing files replaced."
}

main "$@"
