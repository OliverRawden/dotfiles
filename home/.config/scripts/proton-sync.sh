#!/usr/bin/env bash
# Encrypted restic backup of primary home data to Proton Drive via rclone.
# Usage: ~/.config/scripts/proton-sync.sh [backup|snapshots|check|...]
set -euo pipefail

CONF="${HOME}/.config/scripts/proton-sync"
LOG="${HOME}/Library/Logs/proton-sync.log"
CACHE_DIR="${HOME}/Library/Caches/restic"
LOCK_DIR="${HOME}/Library/Caches/proton-sync"
LAUNCH_AGENT_SRC="${CONF}/com.rawden.proton-sync.plist"
LAUNCH_AGENT_DST="${HOME}/Library/LaunchAgents/com.rawden.proton-sync.plist"
INCLUDES_FILE="${CONF}/includes.txt"
EXCLUDES_FILE="${CONF}/excludes.txt"
KEYCHAIN_SERVICE="restic-proton-macos"
RCLONE_REMOTE="proton"
RESTIC_REPOSITORY="rclone:proton:restic-macos"
RCLONE_BIN="${RCLONE_BIN:-/opt/homebrew/bin/rclone}"
RESTIC_BIN="${RESTIC_BIN:-/opt/homebrew/bin/restic}"
HOSTNAME_TAG="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
LABEL="com.rawden.proton-sync"

umask 077
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export RESTIC_REPOSITORY
export RESTIC_PASSWORD_COMMAND="/usr/bin/security find-generic-password -a ${USER} -s ${KEYCHAIN_SERVICE} -w"
export RESTIC_CACHE_DIR="$CACHE_DIR"
export RESTIC_COMPRESSION="${RESTIC_COMPRESSION:-auto}"
export RESTIC_PROGRESS_FPS="${RESTIC_PROGRESS_FPS:-0.2}"

RCLONE_ARGS="serve restic --stdio --protondrive-replace-existing-draft --tpslimit 4 --retries 10 --low-level-retries 20 --retries-sleep 10s"

usage() {
  cat <<EOF
Encrypted restic backup to Proton Drive (rclone remote: ${RCLONE_REMOTE})

Usage: $(basename "$0") [command]

  backup [--prune]   Run a backup now (default). Add --prune to prune after.
  2fa [secret]       Refresh Proton Drive 2FA (code, or 'secret' for TOTP key)
  snapshots          List snapshots
  check              Verify repository metadata
  stats              Show repo stats
  forget             Apply retention (7 daily, 4 weekly, 12 monthly, 3 yearly)
  prune              Remove unreferenced data (slow on Proton Drive)
  doctor             Check rclone, restic, keychain, and repo access
  schedule on|off    Daily launchd job at 03:30 (prune on Sundays)
  unlock             Remove a stale restic lock
  restore [args...]  Pass-through to restic restore
  restic [args...]   Pass-through to restic with repo/password wired up
  help               Show this help

Restic password is in the macOS Keychain (service ${KEYCHAIN_SERVICE}).
Losing it means the backups cannot be decrypted.

Scheduled backups need Full Disk Access for ${RESTIC_BIN}
EOF
}

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_bins() {
  [[ -x "$RESTIC_BIN" ]] || die "restic not found at $RESTIC_BIN"
  [[ -x "$RCLONE_BIN" ]] || die "rclone not found at $RCLONE_BIN"
  [[ -f "$INCLUDES_FILE" ]] || die "missing $INCLUDES_FILE"
  [[ -f "$EXCLUDES_FILE" ]] || die "missing $EXCLUDES_FILE"
}

restic_cmd() {
  "$RESTIC_BIN" \
    -o "rclone.program=${RCLONE_BIN}" \
    -o "rclone.args=${RCLONE_ARGS}" \
    -o "rclone.timeout=5m" \
    "$@"
}

acquire_lock() {
  mkdir -p "$LOCK_DIR"
  local pidfile="${LOCK_DIR}/backup.pid"
  if [[ -f "$pidfile" ]]; then
    local oldpid
    oldpid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "${oldpid}" ]] && kill -0 "$oldpid" 2>/dev/null; then
      die "backup already running (pid $oldpid)"
    fi
  fi
  printf '%s\n' "$$" >"$pidfile"
  trap 'rm -f "$pidfile"' EXIT
}

keychain_has_password() {
  /usr/bin/security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w >/dev/null 2>&1
}

prompt_text() {
  local title="$1" message="$2" hidden="${3:-false}"
  local hidden_flag=""
  [[ "$hidden" == "true" ]] && hidden_flag="with hidden answer"
  /usr/bin/osascript <<APPLESCRIPT
tell application "System Events"
  activate
  set theResult to display dialog "${message}" default answer "" ${hidden_flag} with title "${title}" buttons {"Cancel", "Continue"} default button "Continue"
  return text returned of theResult
end tell
APPLESCRIPT
}

notify() {
  /usr/bin/osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true
}

proton_ls() {
  if [[ -n "${1:-}" ]]; then
    "$RCLONE_BIN" lsd "${RCLONE_REMOTE}:" --retries 1 --timeout 90s --protondrive-2fa "$1"
  else
    "$RCLONE_BIN" lsd "${RCLONE_REMOTE}:" --retries 1 --timeout 90s
  fi
}

cmd_2fa() {
  local mode="${1:-code}"
  case "$mode" in
    secret|otp|totp)
      local secret obscured
      secret="$(prompt_text "Proton Drive TOTP" "Paste the Proton TOTP secret (the Base32 key from Proton Pass / 2FA setup), not a 6-digit code." true)"
      [[ -n "$secret" ]] || die "no TOTP secret entered"
      obscured="$("$RCLONE_BIN" obscure "$secret")"
      "$RCLONE_BIN" config update "$RCLONE_REMOTE" otp_secret_key "$obscured" --non-interactive >/dev/null
      "$RCLONE_BIN" config update "$RCLONE_REMOTE" 2fa "" --non-interactive >/dev/null || true
      log "stored TOTP secret on rclone remote ${RCLONE_REMOTE}"
      proton_ls >/dev/null
      log "Proton Drive login succeeded"
      ;;
    *)
      local code
      code="$(prompt_text "Proton Drive 2FA" "Enter the current 6-digit Proton 2FA code from Proton Pass / your authenticator.")"
      [[ "$code" =~ ^[0-9]{6}$ ]] || die "expected a 6-digit code"
      log "testing Proton Drive with one-shot 2FA code"
      proton_ls "$code" >/dev/null
      "$RCLONE_BIN" config update "$RCLONE_REMOTE" 2fa "" --non-interactive >/dev/null || true
      log "Proton Drive login succeeded. For unattended backups, run: $0 2fa secret"
      ;;
  esac
}

existing_includes() {
  local path
  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    [[ -e "$path" ]] && printf '%s\n' "$path"
  done <"$INCLUDES_FILE"
}

dotfiles_list() {
  /usr/bin/find "$HOME" -maxdepth 1 \( -type f -o -type l \) -name '.*' \
    ! -name '.DS_Store' \
    ! -name '.CFUserTextEncoding' \
    ! -name '.emulator_console_auth_token' \
    -print
}

cmd_forget() {
  restic_cmd forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --keep-yearly 3 \
    --retry-lock 30m
}

cmd_backup() {
  need_bins
  keychain_has_password || die "no restic password in Keychain (service ${KEYCHAIN_SERVICE})"
  acquire_lock
  mkdir -p "$CACHE_DIR" "$LOCK_DIR" "$(dirname "$LOG")"

  local prune=0 scheduled=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prune) prune=1 ;;
      --scheduled) scheduled=1 ;;
      *) die "unknown backup option: $1" ;;
    esac
    shift
  done

  if [[ "$scheduled" -eq 1 ]]; then
    exec >>"$LOG" 2>&1
    local today
    today="$(date +%u)"
    [[ "$today" == "7" ]] && prune=1
  fi

  local tmp_includes tmp_dots
  tmp_includes="$(mktemp "${LOCK_DIR}/includes.XXXXXX")"
  tmp_dots="$(mktemp "${LOCK_DIR}/dotfiles.XXXXXX")"
  existing_includes >"$tmp_includes"
  dotfiles_list >"$tmp_dots"

  log "starting backup to ${RESTIC_REPOSITORY}"
  log "paths:" && sed 's/^/  /' "$tmp_includes" "$tmp_dots" | tee -a "$LOG"

  local rc=0
  /usr/bin/caffeinate -i "$RESTIC_BIN" \
    -o "rclone.program=${RCLONE_BIN}" \
    -o "rclone.args=${RCLONE_ARGS}" \
    -o "rclone.timeout=5m" \
    backup \
    --files-from-verbatim "$tmp_includes" \
    --files-from-verbatim "$tmp_dots" \
    --exclude-file "$EXCLUDES_FILE" \
    --exclude-caches \
    --skip-if-unchanged \
    --tag macos \
    --tag "host:${HOSTNAME_TAG}" \
    --retry-lock 30m \
    --verbose || rc=$?

  rm -f "$tmp_includes" "$tmp_dots"

  if [[ "$rc" -ne 0 && "$rc" -ne 3 ]]; then
    notify "proton-sync" "Backup failed (exit ${rc})"
    die "backup failed with exit ${rc}"
  fi
  [[ "$rc" -eq 3 ]] && log "warning: some files could not be read (exit 3); snapshot still created"

  cmd_forget
  if [[ "$prune" -eq 1 ]]; then
    log "pruning unreferenced data (slow on Proton Drive)"
    restic_cmd prune --retry-lock 30m
  fi

  if [[ "$rc" -eq 3 ]]; then
    notify "proton-sync" "Backup finished with unreadable files"
  else
    notify "proton-sync" "Backup finished"
  fi
  log "backup complete"
}

cmd_doctor() {
  need_bins
  log "restic: $("$RESTIC_BIN" version | head -1)"
  log "rclone: $("$RCLONE_BIN" version | head -1)"
  log "repository: ${RESTIC_REPOSITORY}"
  log "keychain service: ${KEYCHAIN_SERVICE}"
  if keychain_has_password; then
    log "keychain: restic password found"
  else
    log "keychain: MISSING restic password"
  fi
  log "testing Proton Drive"
  if proton_ls; then
    log "Proton Drive: ok"
  else
    log "Proton Drive: FAILED (run: $0 2fa)"
  fi
  if restic_cmd cat config >/dev/null 2>&1; then
    log "restic repo: reachable"
    restic_cmd snapshots --compact || true
  else
    log "restic repo: not initialized or unreachable"
  fi
  if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
    log "schedule: loaded"
  else
    log "schedule: not loaded"
  fi
  log "Grant Full Disk Access to ${RESTIC_BIN} so Documents/Desktop/Pictures/iPhone backups can be read."
}

cmd_schedule() {
  local action="${1:-}"
  local uid
  uid="$(id -u)"
  case "$action" in
    on)
      [[ -f "$LAUNCH_AGENT_SRC" ]] || die "missing $LAUNCH_AGENT_SRC"
      mkdir -p "$(dirname "$LAUNCH_AGENT_DST")"
      cp "$LAUNCH_AGENT_SRC" "$LAUNCH_AGENT_DST"
      launchctl bootout "gui/${uid}/${LABEL}" >/dev/null 2>&1 || true
      launchctl bootstrap "gui/${uid}" "$LAUNCH_AGENT_DST"
      launchctl enable "gui/${uid}/${LABEL}"
      log "scheduled daily backup at 03:30 (forget daily; prune on Sundays)"
      log "grant Full Disk Access to ${RESTIC_BIN} or the job will skip TCC-protected folders"
      ;;
    off)
      launchctl bootout "gui/${uid}/${LABEL}" >/dev/null 2>&1 || true
      rm -f "$LAUNCH_AGENT_DST"
      log "schedule disabled"
      ;;
    *)
      die "usage: $0 schedule on|off"
      ;;
  esac
}

main() {
  mkdir -p "$(dirname "$LOG")"
  local cmd="${1:-backup}"
  if [[ $# -gt 0 ]]; then
    shift
  fi
  case "$cmd" in
    backup|"") cmd_backup "$@" ;;
    2fa) cmd_2fa "$@" ;;
    forget) need_bins; cmd_forget ;;
    prune) need_bins; restic_cmd prune --retry-lock 30m "$@" ;;
    check) need_bins; restic_cmd check "$@" ;;
    snapshots) need_bins; restic_cmd snapshots "$@" ;;
    stats) need_bins; restic_cmd stats "$@" ;;
    doctor) cmd_doctor ;;
    schedule) cmd_schedule "$@" ;;
    unlock) need_bins; restic_cmd unlock "$@" ;;
    restore) need_bins; restic_cmd restore "$@" ;;
    restic) need_bins; restic_cmd "$@" ;;
    help|-h|--help) usage ;;
    *) usage; die "unknown command: $cmd" ;;
  esac
}

main "$@"
