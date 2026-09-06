#!/usr/bin/env bash
# Bootstrap OliverRawden/dotfiles with chezmoi.
#
# One-liner (new machine):
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/OliverRawden/dotfiles/main/install.sh)"
#
# Idempotent: safe to re-run. Does not print secrets.

set -euo pipefail

REPO="OliverRawden/dotfiles"
CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

is_macos() { [ "$(uname -s)" = "Darwin" ]; }

ensure_brew_in_path() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  if [ -x /opt/homebrew/bin/brew ]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    # Intel Mac
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
  is_macos || die "Homebrew is required on non-macOS only if brew is how you install tools; install chezmoi another way"
  log "Installing Homebrew (NONINTERACTIVE)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew_in_path
  command -v brew >/dev/null 2>&1 || die "Homebrew installed but brew not found on PATH"
}

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    return 0
  fi
  ensure_brew_in_path
  if command -v brew >/dev/null 2>&1; then
    log "Installing chezmoi via Homebrew..."
    brew install chezmoi
  else
    log "Installing chezmoi via binary installer..."
    mkdir -p "$HOME/.local/bin"
    sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  command -v chezmoi >/dev/null 2>&1 || die "chezmoi not found after install"
}

source_is_this_repo() {
  local dir="$1"
  [ -d "$dir/.git" ] || return 1
  local url
  url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  case "$url" in
    *OliverRawden/dotfiles*) return 0 ;;
    *) return 1 ;;
  esac
}

apply_dotfiles() {
  if source_is_this_repo "$CHEZMOI_SOURCE"; then
    log "Chezmoi source already set to $REPO — chezmoi update --apply"
    chezmoi update --apply
  else
    log "Initializing chezmoi from $REPO — chezmoi init --apply"
    chezmoi init --apply "$REPO"
  fi
}

main() {
  if is_macos; then
    install_homebrew
    ensure_brew_in_path
  else
    ensure_brew_in_path
  fi
  install_chezmoi
  apply_dotfiles
  log "Done. Dotfiles applied via chezmoi ($REPO)."
}

main "$@"
