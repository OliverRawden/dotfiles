#!/usr/bin/env bash
# Shared helpers for vault weekly review automation.

set -euo pipefail

VAULT_ROOT="${VAULT_ROOT:-${HOME}/Documents/Obsidian/Main}"
REVIEW_DIR="${HOME}/.config/scripts/obsidian-weekly-review"
STATE_FILE="${REVIEW_DIR}/state.json"
LOG_DIR="${REVIEW_DIR}/logs"
PROMPT_FILE="${REVIEW_DIR}/prompt.txt"
GROK_BIN="${GROK_BIN:-${HOME}/.grok/bin/grok}"
GROK_MODEL="${GROK_MODEL:-grok-4.5}"

mkdir -p "$LOG_DIR"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "${LOG_DIR}/weekly-review.log"
}

notify() {
  local title="$1"
  local message="$2"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${message}\" with title \"${title}\"" >/dev/null 2>&1 || true
  fi
}

init_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    cat >"$STATE_FILE" <<EOF
{
  "last_run_at": null,
  "last_status": null
}
EOF
  fi
}

state_set() {
  local key="$1"
  local value="$2"
  init_state
  python3 - "$STATE_FILE" "$key" "$value" <<'PY'
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
if value == "null":
    data[key] = None
else:
    data[key] = value
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

state_get() {
  local key="$1"
  init_state
  python3 - "$STATE_FILE" "$key" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
val = data.get(sys.argv[2], "")
print("" if val is None else val)
PY
}

ensure_grok() {
  if [[ ! -x "$GROK_BIN" ]]; then
    log "ERROR: Grok CLI not found at $GROK_BIN"
    return 1
  fi
}

run_weekly_review() {
  ensure_grok || return 1

  local run_log="${LOG_DIR}/grok-run-$(date +%Y%m%d-%H%M%S).log"
  state_set "last_run_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  state_set "last_status" "running"

  log "Starting weekly review (Grok Build)"
  notify "Vault Weekly Review" "Grok Build session started — processing inbox."

  if "$GROK_BIN" \
    --prompt-file "$PROMPT_FILE" \
    --cwd "$VAULT_ROOT" \
    --model "$GROK_MODEL" \
    --yolo \
    --rules "Read GROK.md first. Follow all vault standards in GROK.md." \
    --output-format plain \
    >>"$run_log" 2>&1; then
    state_set "last_status" "completed"
    log "Weekly review completed — see $run_log"
    notify "Vault Weekly Review" "Completed — inbox processed and vault updated."
    return 0
  fi

  state_set "last_status" "failed"
  log "ERROR: Weekly review failed — see $run_log"
  notify "Vault Weekly Review" "Failed — check logs in ~/.config/scripts/obsidian-weekly-review/logs/"
  return 1
}

print_status() {
  init_state
  echo "Vault weekly review status"
  echo "  Vault:     $VAULT_ROOT"
  echo "  Last run:  $(state_get last_run_at)"
  echo "  Status:    $(state_get last_status)"
  echo "  Logs:      $LOG_DIR"
}
