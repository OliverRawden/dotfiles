#!/bin/bash
# Sync selected folders to Proton Drive

set -euo pipefail

PROTON_PATH="$HOME/Library/CloudStorage/ProtonDrive-o.rawden@proton.me-folder"
BACKUP_ROOT="$PROTON_PATH/MacBookPro"
LOG="$HOME/Library/Logs/proton-sync.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"
}

sync_dir() {
  local src="$1"
  local dest="$2"

  if [[ ! -d "$src" ]]; then
    log "SKIP: source not found: $src"
    return 0
  fi

  mkdir -p "$dest"
  log "SYNC: $src -> $dest"
  rsync -av --delete \
    --exclude '.DS_Store' \
    "$src/" "$dest/" >> "$LOG" 2>&1
}

if [[ ! -d "$PROTON_PATH" ]]; then
  log "ERROR: Proton Drive not mounted at $PROTON_PATH"
  exit 1
fi

log "Sync started"
sync_dir "$HOME/Developer"  "$BACKUP_ROOT/Developer"
sync_dir "$HOME/Documents"  "$BACKUP_ROOT/Documents"
sync_dir "$HOME/Desktop"    "$BACKUP_ROOT/Desktop"
sync_dir "$HOME/Games"      "$BACKUP_ROOT/Games"
sync_dir "$HOME/Movies"     "$BACKUP_ROOT/Movies"
sync_dir "$HOME/Music"      "$BACKUP_ROOT/Music"
sync_dir "$HOME/Pictures"   "$BACKUP_ROOT/Pictures"
sync_dir "$HOME/.config"    "$BACKUP_ROOT/.config"
log "Sync finished"
