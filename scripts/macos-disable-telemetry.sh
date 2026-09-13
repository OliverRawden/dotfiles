#!/usr/bin/env bash
# Re-apply launchd disables for Siri, Apple Intelligence, telemetry, knowledge,
# Screen Time, and Photos analysis. Maps, Weather, Music, Find My, iCloud auth,
# updates, Murus, ZFS, Docker, and XQuartz are left alone.
#
# System-domain jobs need root. `install` loads a LaunchDaemon that runs this
# at boot and every 5 minutes (macOS 26/27 clears many overrides after reboot).
#
# Usage:
#   sudo ~/.config/scripts/macos-disable-telemetry.sh run
#   sudo ~/.config/scripts/macos-disable-telemetry.sh install
#   ~/.config/scripts/macos-disable-telemetry.sh status

set -uo pipefail

resolve_path() {
  local source="$1"
  local dir
  while [[ -L "$source" ]]; do
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="${dir}/${source}"
  done
  dir="$(cd -P "$(dirname "$source")" && pwd)"
  printf '%s\n' "${dir}/$(basename "$source")"
}

SCRIPT_PATH="$(resolve_path "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
LABEL="com.rawden.disable-telemetry"
PLIST_SRC="${SCRIPT_DIR}/macos-disable-telemetry/${LABEL}.plist"
PLIST_DST="/Library/LaunchDaemons/${LABEL}.plist"
OWNER_NAME="$(stat -f %Su "$SCRIPT_PATH")"
OWNER_UID="$(stat -f %u "$SCRIPT_PATH")"
OWNER_HOME="$(eval echo "~${OWNER_NAME}")"
LOG="${OWNER_HOME}/Library/Logs/macos-disable-telemetry.log"
LOCK_DIR="/tmp/${LABEL}.lock"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Tried in both system/ and gui/$uid. Missing labels are skipped.
LABELS=(
  # --- already disabled on this Mac (system domain) ---
  com.apple.CSCSupportd
  com.apple.CrashReporterSupportHelper
  com.apple.InstallerDiagnostics.installerdiagd
  com.apple.InstallerDiagnostics.installerdiagwatcher
  com.apple.SubmitDiagInfo
  com.apple.analyticsd
  com.apple.audioanalyticsd
  com.apple.biomed
  com.apple.bootpd
  com.apple.contextstored
  com.apple.coreduetd
  com.apple.corespeechd_system
  com.apple.diagnosticd
  com.apple.diagnosticservicesd
  com.apple.ecosystemanalyticsd
  com.apple.ftpd
  com.apple.inboxupdaterd
  com.apple.mdmclient.daemon.runatboot
  com.apple.metadata.mds.spindump
  com.apple.modelcatalogd
  com.apple.modelmanagerd
  com.apple.osanalytics.osanalyticshelper
  com.apple.perfpowermetricd
  com.apple.powerlogHelperd
  com.apple.rtcreportingd
  com.apple.signpost.signpost_reporter
  com.apple.spindump
  com.apple.symptomsd-diag
  com.apple.systemstats.analysis
  com.apple.systemstats.daily
  com.apple.systemstats.microstackshot_periodic
  com.apple.threadradiod
  com.apple.usbctelemetryd

  # --- remaining telemetry / seed / ads ---
  com.apple.DiagnosticsReporter
  com.apple.ReportCrash
  com.apple.analyticsagent
  com.apple.ap.adprivacyd
  com.apple.ap.promotedcontentd
  com.apple.appleseed.fbahelperd
  com.apple.appleseed.seedusaged
  com.apple.appleseed.seedusaged.postinstall
  com.apple.betaenrollmentagent
  com.apple.betaenrollmentd
  com.apple.diagnosticextensionsd
  com.apple.diagnosticspushd
  com.apple.diagnostics_agent
  com.apple.dprivacyd
  com.apple.enhancedloggingd
  com.apple.feedbackd
  com.apple.geoanalyticsd
  com.apple.inputanalyticsd
  com.apple.loginwindow.LWWeeklyMessageTracer
  com.apple.metrickitd
  com.apple.securityuploadd
  com.apple.spindump_agent
  com.apple.symptomsd.distributed-agent
  com.apple.tipsd
  com.apple.wifianalyticsd

  # --- Siri / Apple Intelligence / knowledge (not Siri.agent) ---
  com.apple.DictationIM
  com.apple.ModelCatalogAgent
  com.apple.assistant_cdmd
  com.apple.assistantd
  com.apple.callintelligenced
  com.apple.contacts.donation-agent
  com.apple.corespeechd
  com.apple.generativeexperiencesd
  com.apple.intelligencecontextd
  com.apple.intelligenceflowd
  com.apple.intelligenceplatformd
  com.apple.intelligencetasksd
  com.apple.knowledge-agent
  com.apple.knowledgeconstructiond
  com.apple.languageassetd
  com.apple.mlhostd
  com.apple.mlruntimed
  com.apple.naturallanguaged
  com.apple.parsecd
  com.apple.parsec-fbf
  com.apple.privatecloudcomputed
  com.apple.proactived
  com.apple.proactiveeventtrackerd
  com.apple.reversetemplated
  com.apple.siriactionsd
  com.apple.siriinferenced
  com.apple.siriknowledged
  com.apple.sirittsd
  com.apple.SiriTTSTrainingAgent
  com.apple.speech.speechdatainstallerd
  com.apple.spotlightknowledged
  com.apple.spotlightknowledged.importer
  com.apple.spotlightknowledged.updater
  com.apple.suggestd
  com.apple.textunderstandingd
  com.apple.triald
  com.apple.triald.system

  # --- tracking / analysis / RAM hogs ---
  com.apple.BiomeAgent
  com.apple.ContextStoreAgent
  com.apple.FamilyControlsAgent
  com.apple.ManagedSettingsAgent
  com.apple.ScreenTimeAgent
  com.apple.UsageTrackingAgent
  com.apple.biomesyncd
  com.apple.duetexpertd
  com.apple.familycircled
  com.apple.helpd
  com.apple.mediaanalysisd
  com.apple.ospredictiond
  com.apple.peopled
  com.apple.photoanalysisd
  com.apple.routined
  com.apple.studentd
)

VERBOSE=0
DRY_RUN=0

usage() {
  cat <<EOF
Re-apply Siri / telemetry / knowledge launchd disables.

Usage: $(basename "$SCRIPT_PATH") [command] [-v] [--dry-run]

  run         Disable + bootout every listed label (default)
  status      Show override vs actually running
  install     Install LaunchDaemon (root, RunAtLoad + every 5 min)
  uninstall   Remove LaunchDaemon
  help        This text

Needs sudo for system-domain jobs and for install.
Does not touch Maps, Weather, Music, Find My, iCloud, Murus, ZFS, Docker, XQuartz.
EOF
}

log() {
  local line
  line="$(date '+%Y-%m-%d %H:%M:%S') $*"
  mkdir -p "$(dirname "$LOG")"
  printf '%s\n' "$line" | tee -a "$LOG"
}

say() {
  (( VERBOSE )) && printf '%s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

is_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]]
}

need_root() {
  is_root && return 0
  exec sudo -- "$SCRIPT_PATH" "$@"
}

gui_uids() {
  local -a uids
  uids=("$OWNER_UID")
  local console cu
  console="$(stat -f %Su /dev/console 2>/dev/null || true)"
  if [[ -n "$console" && "$console" != root && "$console" != _windowserver ]]; then
    cu="$(id -u "$console" 2>/dev/null || true)"
    [[ -n "$cu" && "$cu" != 0 ]] && uids+=("$cu")
  fi
  printf '%s\n' "${uids[@]}" | awk 'NF && !seen[$0]++'
}

domains_to_try() {
  if is_root; then
    printf '%s\n' system
    local uid
    while IFS= read -r uid; do
      [[ -n "$uid" ]] && printf '%s\n' "gui/${uid}"
    done < <(gui_uids)
  else
    printf '%s\n' "gui/$(id -u)"
  fi
}

job_pid() {
  local spec="$1"
  launchctl print "$spec" 2>/dev/null \
    | awk '/[[:space:]]pid = / { print $3; exit }'
}

is_pid() {
  [[ "${1:-}" =~ ^[0-9]+$ ]] && [[ "$1" -gt 1 ]]
}

disable_one() {
  local domain="$1" name="$2"
  local spec="${domain}/${name}"

  if (( DRY_RUN )); then
    say "dry-run  disable ${spec}"
    return 0
  fi

  local disable_err boot_err disable_rc boot_rc pid
  disable_err="$(launchctl disable "$spec" 2>&1)" && true
  disable_rc=$?
  boot_err="$(launchctl bootout "$spec" 2>&1)" && true
  boot_rc=$?

  if (( disable_rc != 0 )); then
    case "$disable_err" in
      *'Could not find service'*|*'No such process'*|*'Input/output error'*)
        say "skip     ${spec} (not on this build / domain)"
        return 2
        ;;
    esac
    say "disable  ${spec}  rc=${disable_rc}  ${disable_err}"
  else
    say "disable  ${spec}"
  fi

  if (( boot_rc != 0 )); then
    case "$boot_err" in
      *'No such process'*|*'Could not find service'*|*'Operation not permitted'*)
        ;;
      *)
        say "bootout  ${spec}  rc=${boot_rc}  ${boot_err}"
        ;;
    esac
  fi

  pid="$(job_pid "$spec")"
  if is_pid "$pid" && is_root; then
    kill -TERM "$pid" 2>/dev/null || true
    sleep 0.05
    pid="$(job_pid "$spec")"
    if is_pid "$pid"; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
  return 0
}

cmd_run() {
  if (( ! DRY_RUN )); then
    mkdir "$LOCK_DIR" 2>/dev/null || {
      printf '%s\n' "already running"
      exit 0
    }
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
  fi

  local -a domains
  domains=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && domains+=("$line")
  done < <(domains_to_try)

  if ! is_root; then
    log "warning: not root; only touching ${domains[*]} (system jobs unchanged)"
  fi

  local name domain rc hit pid s
  local disabled=0 skipped=0
  local -a survivors
  survivors=()

  for name in "${LABELS[@]}"; do
    hit=0
    for domain in "${domains[@]}"; do
      disable_one "$domain" "$name"
      rc=$?
      (( rc != 2 )) && hit=1
    done
    if (( hit )); then
      disabled=$((disabled + 1))
    else
      skipped=$((skipped + 1))
    fi
  done

  sleep 0.3
  for name in "${LABELS[@]}"; do
    for domain in "${domains[@]}"; do
      pid="$(job_pid "${domain}/${name}")"
      if is_pid "$pid"; then
        survivors+=("${domain}/${name} pid=${pid}")
      fi
    done
  done

  log "run domains=${domains[*]} labels=${#LABELS[@]} touched=${disabled} absent=${skipped} still_running=${#survivors[@]}"
  if [[ ${#survivors[@]} -gt 0 ]]; then
    for s in "${survivors[@]}"; do
      log "  still running: $s"
    done
  fi
}

override_state() {
  local domain="$1" name="$2"
  launchctl print-disabled "$domain" 2>/dev/null \
    | awk -v n="$name" '
        $0 ~ "\"" n "\"" {
          if ($0 ~ /disabled/) { print "disabled"; exit }
          if ($0 ~ /enabled/)  { print "enabled";  exit }
        }
      '
}

cmd_status() {
  local -a domains
  domains=()
  if is_root; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && domains+=("$line")
    done < <(domains_to_try)
  else
    domains=(system "gui/$(id -u)")
  fi

  printf '%s\n' "script owner: ${OWNER_NAME} (${OWNER_UID})"
  printf '%s\n' "log: ${LOG}"
  printf '%s\n' "daemon: ${PLIST_DST}"
  if [[ -f "$PLIST_DST" ]]; then
    printf '%s\n' "daemon plist: installed"
  else
    printf '%s\n' "daemon plist: not installed (run: sudo $SCRIPT_PATH install)"
  fi
  printf '%s\n' ""
  printf '%-44s %-10s %s\n' "LABEL" "OVERRIDE" "PID"
  printf '%s\n' "--------------------------------------------------------------------------------"

  local name domain state pid shown
  for name in "${LABELS[@]}"; do
    shown=0
    for domain in "${domains[@]}"; do
      state="$(override_state "$domain" "$name")"
      pid="$(job_pid "${domain}/${name}")"
      [[ -z "$state" && -z "$pid" ]] && continue
      printf '%-44s %-10s %s\n' "${domain}/${name}" "${state:-none}" "${pid:-}"
      shown=1
    done
    if (( !shown && VERBOSE )); then
      printf '%-44s %-10s\n' "$name" "absent"
    fi
  done
}

cmd_install() {
  [[ -f "$PLIST_SRC" ]] || die "missing $PLIST_SRC"
  cp "$PLIST_SRC" "$PLIST_DST"
  chmod 644 "$PLIST_DST"
  chown root:wheel "$PLIST_DST"
  launchctl bootout system "$PLIST_DST" 2>/dev/null || true
  launchctl bootstrap system "$PLIST_DST" || die "bootstrap failed"
  launchctl enable "system/${LABEL}"
  log "installed ${PLIST_DST}"
  "$SCRIPT_PATH" run
}

cmd_uninstall() {
  launchctl bootout system "$PLIST_DST" 2>/dev/null || true
  launchctl disable "system/${LABEL}" 2>/dev/null || true
  rm -f "$PLIST_DST"
  log "removed ${PLIST_DST}"
}

cmd="${1:-run}"
if [[ $# -gt 0 ]]; then
  shift
fi
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

case "$cmd" in
  run)
    [[ -t 1 ]] && VERBOSE=1
    verbose_flag=""
    dry_flag=""
    (( VERBOSE )) && verbose_flag="-v"
    (( DRY_RUN )) && dry_flag="--dry-run"
    need_root run $verbose_flag $dry_flag
    cmd_run
    ;;
  status) cmd_status ;;
  install)
    need_root install
    cmd_install
    ;;
  uninstall)
    need_root uninstall
    cmd_uninstall
    ;;
  help|-h|--help) usage ;;
  *) die "unknown command: $cmd (try: help)" ;;
esac
