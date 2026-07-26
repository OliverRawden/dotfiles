#!/usr/bin/env bash
# Spawn a Grok Build session to run the Obsidian vault weekly review.
# Usage: obsidian-weekly-review.sh [run]

set -euo pipefail

SCRIPT_DIR="${HOME}/.config/scripts/obsidian-weekly-review"
# shellcheck source=obsidian-weekly-review/lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<EOF
Obsidian vault weekly review

Usage: $(basename "$0") [run]

  run     Spawn Grok Build to process inbox and run weekly review (default)
  status  Show last run time and status

Scheduled via Apple Shortcuts — run weekly:

  $(basename "$0")

EOF
}

main() {
  local cmd="${1:-run}"
  case "$cmd" in
    run|scheduled|"") run_weekly_review ;;
    status)           print_status ;;
    -h|--help|help)   usage ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
