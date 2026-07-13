#!/usr/bin/env bash
# Remove system-level leftovers that require admin password.
# Run: sudo bash ~/.config/scripts/cleanup-system-leftovers.sh

set -euo pipefail

TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

echo "Removing Google Chrome updater (system)..."
rm -rf /Library/Google
rm -rf "/Library/Application Support/Google"
echo "  Done."

echo ""
echo "Attempting Privacy database cleanup via tccutil..."
ORPHANS=(
  "Accessibility:com.stonerl.Thaw"
  "ScreenCapture:com.stonerl.Thaw"
  "SystemPolicyAllFiles:com.openai.codex"
  "Accessibility:com.hegenberg.BetterTouchTool"
  "ListenEvent:com.sikarugir.configure"
  "ListenEvent:com.sikarugir.Kegworks180081351"
)
for entry in "${ORPHANS[@]}"; do
  svc="${entry%%:*}"
  bid="${entry##*:}"
  if tccutil reset "$svc" "$bid" 2>/dev/null; then
    echo "  Reset $svc for $bid"
  else
    echo "  Skipped $bid ($svc) — app not registered; remove manually in Settings"
  fi
done

echo ""
echo "Note: macOS blocks direct TCC database edits (SIP). Orphaned entries"
echo "must be removed in System Settings → Privacy & Security:"
echo "  • Codex          → Full Disk Access"
echo "  • Thaw           → Accessibility, Screen Recording"
echo "  • BetterTouchTool→ Accessibility"
echo "  • Sikarugir*     → Input Monitoring"
echo "  • Steam Windows  → Input Monitoring (broken path)"
echo ""
echo "Noir is intentionally kept."
echo ""
echo "Restart after manual cleanup if entries still appear."