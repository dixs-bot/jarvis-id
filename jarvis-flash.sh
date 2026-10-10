#!/data/data/com.termux/files/usr/bin/bash
# JARVIS.ID Android Flash Tool
# Safety-first Termux ADB/Fastboot toolkit.
set -u
umask 077

APP_NAME="JARVIS.ID Android Flash Tool"
VERSION="2.0.0"
ROOT="${JARVIS_HOME:-$HOME/jarvis-flash}"
CONFIG_DIR="$ROOT/config"
IMAGE_DIR="$ROOT/images"
BACKUP_DIR="$ROOT/backups"
LOG_DIR="$ROOT/logs"
mkdir -p "$CONFIG_DIR" "$IMAGE_DIR" "$BACKUP_DIR" "$LOG_DIR" || exit 1
IMAGE_CATALOG="$CONFIG_DIR/image-catalog.tsv"
LOG_FILE="$LOG_DIR/session-$(date +%Y%m%d).log"
CONFIG_FILE="$CONFIG_DIR/config.conf"

ADB_BIN_ENV_SET="${ADB_BIN+x}"
FASTBOOT_BIN_ENV_SET="${FASTBOOT_BIN+x}"
DRY_RUN_ENV_SET="${JARVIS_DRY_RUN+x}"
ANIMATION_ENV_SET="${JARVIS_ANIMATION+x}"
ADB_BIN="${ADB_BIN:-termux-adb}"
FASTBOOT_BIN="${FASTBOOT_BIN:-termux-fastboot}"
DRY_RUN="${JARVIS_DRY_RUN:-1}"
ANIMATION_MODE="${JARVIS_ANIMATION:-on}"

# Colors (disabled when output is redirected or NO_COLOR is set)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  BLUE=$'\033[94m'; CYAN=$'\033[96m'; WHITE=$'\033[97m'
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
  BLUE=""; CYAN=""; WHITE=""; GREEN=""; RED=""; YELLOW=""; RESET=""
fi

log() {
  local level="$1"; shift
  local message="$*"
  message="${message//$'\n'/ }"
  message="${message//$'\r'/ }"
  printf '[%s] [v%s] [%s] %s\n' "$(date '+%F %T')" "$VERSION" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
}
show_status() {
  local state="$1"; shift
  case "$state" in
    ok) printf '%s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*" ;;
    warning) printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*" ;;
    error) printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$*" ;;
    *) printf '%s[ ... ]%s %s\n' "$CYAN" "$RESET" "$*" ;;
  esac
}
show_warning() { show_status warning "$@"; log WARN "$*"; }
show_error() { show_status error "$@"; log ERROR "$*"; }
show_success() { show_status ok "$@"; log OK "$*"; }
show_progress() { printf '%s[ ... ]%s %s\n' "$CYAN" "$RESET" "$*"; }
info() { printf '%s[INFO]%s %s\n' "$CYAN" "$RESET" "$*"; log INFO "$*"; }
ok() { show_success "$@"; }
warn() { show_warning "$@"; }
err() { show_error "$@"; }
pause() { printf '\nPress Enter to return...'; read -r _ || true; }
header() {
  if [[ -t 1 && -z "${JARVIS_KEEP_SCREEN:-}" ]] && have clear; then clear 2>/dev/null || true; fi
  printf '%s\n' "${CYAN}     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗${RESET}"
  printf '%s\n' "${CYAN}     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝${RESET}"
  printf '%s\n' "${CYAN}     ██║███████║██████╔╝██║   ██║██║███████╗${RESET}"
  printf '%s\n' "${CYAN}██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║${RESET}"
  printf '%s\n' "${CYAN}╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║${RESET}"
  printf '%s\n' "${CYAN} ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝${RESET}"
  printf '\n%s%s%s\n' "$WHITE" "$APP_NAME" "$RESET"
  printf '%s\n' "ANDROID REPAIR • BOOTLOADER • TWRP • CUSTOM ROM"
  printf 'Version: %s\n\n' "$VERSION"
}
show_banner() { header; }
show_confirmation() {
  local prompt="${1:-Continue?}" answer=""
  printf '%s [ketik YES untuk mengonfirmasi]: ' "$prompt"
  read -r answer || return 1
  [[ "$answer" == "YES" ]]
}
confirm() { show_confirmation "$@"; }
show_main_menu() {
  cat <<'MENU'
[01] Device Manager
[02] ADB Toolbox
[03] Fastboot Toolbox
[04] Bootloader / UBL Assistant
[05] TWRP & Recovery Manager
[06] Firmware Flash Assistant
[07] Custom ROM Manager
[08] Backup & Restore
[09] Rescue & Diagnostics
[10] File & Checksum Manager
[11] Service Report
[12] Settings & Dependencies
[13] Update Manager
[00] Exit
MENU
}
show_startup_animation() {
  local delay="0.04" can_animate=0 line
  [[ "$ANIMATION_MODE" == "fast" ]] && delay="0.01"
  [[ "$ANIMATION_MODE" == "off" ]] && delay="0"
  if [[ -t 0 && -t 1 && "${TERM:-dumb}" != "dumb" && "$ANIMATION_MODE" != "off" ]]; then
    can_animate=1
    have clear && clear 2>/dev/null || true
  fi

  show_progress "Initializing JARVIS Core..."
  ((can_animate)) && sleep "$delay"
  if have "$ADB_BIN"; then show_status ok "ADB interface available: $ADB_BIN"; else show_status warning "ADB not found: $ADB_BIN"; fi
  ((can_animate)) && sleep "$delay"
  if have "$FASTBOOT_BIN"; then show_status ok "Fastboot interface available: $FASTBOOT_BIN"; else show_status warning "Fastboot not found: $FASTBOOT_BIN"; fi
  ((can_animate)) && sleep "$delay"
  show_status ok "Safety protocols initialized (dry-run: $DRY_RUN)"
  printf '\n'

  if ((can_animate)); then
    while IFS= read -r line; do printf '%s\n' "${CYAN}${line}${RESET}"; sleep "$delay"; done <<'LOGO'
     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗
     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝
     ██║███████║██████╔╝██║   ██║██║███████║
██   ██║██╔══██╗██╔══██╗╚██╗ ██╔╝██║╚════██║
╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║
 ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝
LOGO
  else
    show_banner
  fi
  show_status ok "JARVIS Core Initialized"
  if have "$ADB_BIN"; then show_status ok "ADB environment ready"; else show_status warning "ADB environment not found"; fi
  if have "$FASTBOOT_BIN"; then show_status ok "Fastboot environment ready"; else show_status warning "Fastboot environment not found"; fi
  show_status ok "Recovery, firmware, and safety modules loaded"
  printf '\n'
}

have() { command -v "$1" >/dev/null 2>&1; }
load_config() {
  [[ -r "$CONFIG_FILE" ]] || return 0
  local key value
  while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    value="${value%$'\r'}"
    case "$key" in
      ADB_BIN) [[ -z "$ADB_BIN_ENV_SET" && -n "$value" ]] && ADB_BIN="$value" ;;
      FASTBOOT_BIN) [[ -z "$FASTBOOT_BIN_ENV_SET" && -n "$value" ]] && FASTBOOT_BIN="$value" ;;
      DRY_RUN) [[ -z "$DRY_RUN_ENV_SET" && ( "$value" == "0" || "$value" == "1" ) ]] && DRY_RUN="$value" ;;
      ANIMATION) [[ -z "$ANIMATION_ENV_SET" && ( "$value" == "off" || "$value" == "fast" || "$value" == "on" ) ]] && ANIMATION_MODE="$value" ;;
    esac
  done < "$CONFIG_FILE"
}
load_config
require_cmd() {
  if ! have "$1"; then
    err "Command '$1' not found. Check the installation and dependencies."
    return 1
  fi
}
confirm() {
  local prompt="${1:-Lanjutkan?}"
  local answer=""
  printf '%s [ketik YES untuk mengonfirmasi]: ' "$prompt"
  read -r answer || return 1
  [[ "$answer" == "YES" ]]
}
choose_file() {
  local dir="${1:-$IMAGE_DIR}" pattern="${2:-*}"
  local -a files=()
  local f
  shopt -s nullglob
  for f in "$dir"/$pattern; do [[ -f "$f" ]] && files+=("$f"); done
  shopt -u nullglob
  if ((${#files[@]} == 0)); then
    warn "No matching files in: $dir" >&2
    printf 'Enter a full file path (blank to cancel): '
    read -r f || return 1
    [[ -n "$f" && -f "$f" ]] || return 1
    printf '%s\n' "$f"
    return 0
  fi
  local i
  printf 'Select a file:\n' >&2
  for i in "${!files[@]}"; do printf '  %d) %s (%s)\n' "$((i+1))" "${files[$i]}" "$(du -h "${files[$i]}" | awk '{print $1}')" >&2; done
  printf 'Number (0 cancels): ' >&2
  read -r i || return 1
  [[ "$i" =~ ^[0-9]+$ ]] || return 1
  (( i > 0 && i <= ${#files[@]} )) || return 1
  printf '%s\n' "${files[$((i-1))]}"
}
adb_devices() {
  require_cmd "$ADB_BIN" || return 1
  local output rc
  output="$("$ADB_BIN" devices -l 2>&1)"; rc=$?
  printf '%s\n' "$output"
  if ((rc != 0)); then err "ADB devices gagal (exit $rc)."; log ADB "devices exit=$rc"; return "$rc"; fi
  if ! grep -q $'\tdevice\\([[:space:]]\\|$\\)' <<< "$output"; then
    warn "No authorized ADB device. unauthorized/offline states are not ready for operations."
  fi
  log ADB "devices exit=0"
}
get_adb_serial() {
  require_cmd "$ADB_BIN" || return 1
  local -a serials=()
  local output line serial state
  output="$("$ADB_BIN" devices 2>&1)" || { err "Could not read the ADB device list."; return 1; }
  while IFS= read -r line; do
    [[ "$line" == *$'\t'* ]] || continue
    serial="${line%%$'\t'*}"
    state="${line#*$'\t'}"; state="${state%%[[:space:]]*}"
    if [[ "$state" == "device" ]]; then
      serials+=("$serial")
    elif [[ "$state" == "unauthorized" || "$state" == "offline" ]]; then
      warn "ADB device $serial: $state (operation blocked)" >&2
    fi
  done <<< "$output"
  if ((${#serials[@]} == 0)); then
    err "No ADB device is in the 'device' state. Check USB debugging and authorization." >&2
    return 1
  elif ((${#serials[@]} == 1)); then
    printf '%s\n' "${serials[0]}"
    return 0
  fi
  printf 'ADB devices:\n' >&2
  local i
  for i in "${!serials[@]}"; do printf '  %d) %s\n' "$((i+1))" "${serials[$i]}" >&2; done
  printf 'Select a number: ' >&2
  read -r i || return 1
  [[ "$i" =~ ^[0-9]+$ ]] && (( i > 0 && i <= ${#serials[@]} )) || return 1
  printf '%s\n' "${serials[$((i-1))]}"
}
adb_shell_prop() {
  local serial="$1" prop="$2"
  "$ADB_BIN" -s "$serial" shell getprop "$prop" 2>/dev/null | tr -d '\r' | head -n 1 || true
}
get_fastboot_serial() {
  require_cmd "$FASTBOOT_BIN" || return 1
  local -a serials=()
  local output line serial
  output="$("$FASTBOOT_BIN" devices 2>&1)" || { err "Could not read the Fastboot device list."; return 1; }
  while IFS= read -r line; do
    serial="$(awk '{print $1}' <<< "$line")"
    [[ -n "$serial" && "$serial" != "List" && "$serial" != "no" ]] && serials+=("$serial")
  done <<< "$output"
  if ((${#serials[@]} == 0)); then
    err "No Fastboot device detected." >&2
    return 1
  elif ((${#serials[@]} == 1)); then printf '%s\n' "${serials[0]}"; return 0; fi
  printf 'Fastboot devices:\n' >&2
  local i
  for i in "${!serials[@]}"; do printf '  %d) %s\n' "$((i+1))" "${serials[$i]}" >&2; done
  printf 'Select a number: ' >&2; read -r i || return 1
  [[ "$i" =~ ^[0-9]+$ ]] && (( i > 0 && i <= ${#serials[@]} )) || return 1
  printf '%s\n' "${serials[$((i-1))]}"
}
sha256_file() {
  local file="$1"
  if have sha256sum; then sha256sum -- "$file"
  elif have sha256; then sha256 -q "$file"
  else err "sha256sum/sha256 utility unavailable."; return 1; fi
}
sha256_value() {
  local result
  result="$(sha256_file "$1")" || return 1
  printf '%s\n' "${result%% *}" | tr '[:upper:]' '[:lower:]'
}
list_inventory() {
  local dir="${1:-$IMAGE_DIR}" f
  shopt -s nullglob
  local files=("$dir"/*)
  shopt -u nullglob
  if ((${#files[@]} == 0)); then
    printf '  (empty)\n'
    return
  fi
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    printf '  %-48s %10s bytes\n' "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')"
  done
}
refresh_catalog() {
  local tmp="$IMAGE_CATALOG.tmp.$$" f name size digest
  shopt -s nullglob
  local files=("$IMAGE_DIR"/*)
  shopt -u nullglob
  : > "$tmp" || return 1
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f" | tr '\t\n\r' '   ')"
    size="$(wc -c < "$f" | tr -d ' ')"
    digest="$(sha256_value "$f" 2>/dev/null || printf 'unavailable')"
    printf '%s\t%s\t%s\n' "$name" "$size" "$digest" >> "$tmp"
  done
  mv -f -- "$tmp" "$IMAGE_CATALOG"
}
device_info() {
  header
  printf 'ADB connection state:\n'
  if ! have "$ADB_BIN"; then
    warn "ADB command not found: $ADB_BIN"
  else
    adb_devices || true
  fi
  printf '\nFastboot connection state:\n'
  if have "$FASTBOOT_BIN"; then "$FASTBOOT_BIN" devices -l 2>&1 || warn "Fastboot enumeration gagal."
  else warn "Fastboot command not found: $FASTBOOT_BIN"; fi
  if ! have "$ADB_BIN"; then pause; return; fi
  local serial
  serial="$(get_adb_serial)" || { pause; return; }
  local model manu product device android sdk arch fingerprint locked slot value
  model="$(adb_shell_prop "$serial" ro.product.model)"
  manu="$(adb_shell_prop "$serial" ro.product.manufacturer)"
  device="$(adb_shell_prop "$serial" ro.product.device)"
  product="$(adb_shell_prop "$serial" ro.product.name)"
  android="$(adb_shell_prop "$serial" ro.build.version.release)"
  sdk="$(adb_shell_prop "$serial" ro.build.version.sdk)"
  arch="$(adb_shell_prop "$serial" ro.product.cpu.abi)"
  fingerprint="$(adb_shell_prop "$serial" ro.build.fingerprint)"
  locked="$(adb_shell_prop "$serial" ro.boot.flash.locked)"
  slot="$(adb_shell_prop "$serial" ro.boot.slot_suffix)"
  [[ -n "$model" ]] || model="not reported"
  [[ -n "$manu" ]] || manu="not reported"
  [[ -n "$device" ]] || device="not reported"
  [[ -n "$product" ]] || product="not reported"
  [[ -n "$android" ]] || android="not reported"
  [[ -n "$sdk" ]] || sdk="not reported"
  [[ -n "$arch" ]] || arch="not reported"
  [[ -n "$fingerprint" ]] || fingerprint="not reported"
  case "$locked" in 0) locked="unlocked (reported by Android)" ;; 1) locked="locked (reported by Android)" ;; *) locked="unknown / not reported" ;; esac
  [[ -n "$slot" ]] || slot="not reported"
  printf '\nADB device: %s\n' "$serial"
  printf 'Model:           %s\n' "$model"
  printf 'Manufacturer:    %s\n' "$manu"
  printf 'Device/codename: %s\n' "$device"
  printf 'Product:         %s\n' "$product"
  printf 'Android:         %s\n' "$android"
  printf 'SDK:             %s\n' "$sdk"
  printf 'Architecture:    %s\n' "$arch"
  printf 'Fingerprint:     %s\n' "$fingerprint"
  printf 'Bootloader:      %s\n' "$locked"
  printf 'Slot aktif:      %s\n' "$slot"
  printf '/data storage:   '
  value="$("$ADB_BIN" -s "$serial" shell df -h /data 2>/dev/null | tail -n 1 | awk '{print $4 " available of " $2}' || true)"
  printf '%s\n' "${value:-not available}"
  log DEVICE "info serial=$serial product=$product device=$device"
  pause
}
adb_menu() {
  while true; do
    header
    cat <<'MENU'
ADB TOOLS
1. List devices
2. Interactive shell
3. Reboot system
4. Reboot recovery
5. Reboot bootloader/Fastboot
6. Capture logcat to file
7. Push local file to device
8. Pull file from device
9. View Android properties
0. Back
MENU
    read -r -p "Choice: " c || return
    case "$c" in
      1) adb_devices; pause ;;
      2)
        local s rc
        s="$(get_adb_serial)" || { pause; continue; }
        "$ADB_BIN" -s "$s" shell; rc=$?
        log ADB "command=interactive-shell serial=$s exit=$rc"
        pause ;;
      3|4|5)
        local s target
        s="$(get_adb_serial)" || { pause; continue; }
        target=""; [[ "$c" == 4 ]] && target="recovery"; [[ "$c" == 5 ]] && target="bootloader"
        if confirm "Reboot device $s to ${target:-system}?"; then
          if [[ -n "$target" ]]; then "$ADB_BIN" -s "$s" reboot "$target"; else "$ADB_BIN" -s "$s" reboot; fi
          local rc=$?
          log ADB "reboot serial=$s target=${target:-normal} exit=$rc"
          ((rc == 0)) && ok "ADB reboot command completed." || err "ADB reboot failed (exit $rc)."
        fi; pause ;;
      6)
        local s out
        s="$(get_adb_serial)" || { pause; continue; }
        out="$LOG_DIR/logcat-${s}-$(date +%Y%m%d-%H%M%S).txt"
        info "Capturing logcat. Press Ctrl+C to stop."
        "$ADB_BIN" -s "$s" logcat -d > "$out" 2>&1
        local rc=$?
        if ((rc == 0)); then ok "Log disimpan: $out"; else err "Logcat failed (exit $rc)."; fi
        log ADB "logcat serial=$s file=$(basename "$out") exit=$rc"; pause ;;
      7)
        local s src dst
        s="$(get_adb_serial)" || { pause; continue; }
        printf 'Local file path: '; read -r src
        [[ -f "$src" ]] || { err "File not found."; pause; continue; }
        printf 'Device destination path (for example /sdcard/Download/): '; read -r dst
        if confirm "Push $src ke $dst?"; then
          "$ADB_BIN" -s "$s" push "$src" "$dst"; local rc=$?
          log ADB "push serial=$s exit=$rc"
          ((rc == 0)) && ok "Push completed." || err "Push failed (exit $rc)."
        fi; pause ;;
      8)
        local s src dst
        s="$(get_adb_serial)" || { pause; continue; }
        printf 'Device file path: '; read -r src
        printf 'Local destination path: '; read -r dst
        if [[ -e "$dst" ]] && ! confirm "Local destination exists. Explicitly overwrite $dst?"; then pause; continue; fi
        if confirm "Pull $src ke $dst?"; then
          "$ADB_BIN" -s "$s" pull "$src" "$dst"; local rc=$?
          log ADB "pull serial=$s exit=$rc"
          ((rc == 0)) && ok "Pull completed." || err "Pull failed (exit $rc)."
        fi; pause ;;
      9)
        local s rc
        s="$(get_adb_serial)" || { pause; continue; }
        "$ADB_BIN" -s "$s" shell getprop | less 2>/dev/null || "$ADB_BIN" -s "$s" shell getprop
        rc=$?
        log ADB "command=shell-getprop serial=$s exit=$rc"
        pause ;;
      0) return ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
fastboot_menu() {
  require_cmd "$FASTBOOT_BIN" || { pause; return; }
  while true; do
    header
    cat <<'MENU'
FASTBOOT TOOLS
1. List devices
2. Show product
3. Inspect common variables
4. Reboot system
5. Reboot recovery (if supported)
6. Temporarily boot an image (device support required)
0. Back
MENU
    read -r -p "Choice: " c || return
    case "$c" in
      1) "$FASTBOOT_BIN" devices; local rc=$?; log FASTBOOT "command=devices exit=$rc"; pause ;;
      2)
        local s rc; s="$(get_fastboot_serial)" || { pause; continue; }
        "$FASTBOOT_BIN" -s "$s" getvar product 2>&1
        rc=$?
        log FASTBOOT "command=getvar-product serial=$s exit=$rc"
        pause ;;
      3)
        local s v rc; s="$(get_fastboot_serial)" || { pause; continue; }
        for v in product current-slot unlocked is-userspace secure; do
          printf '\n--- %s ---\n' "$v"
          "$FASTBOOT_BIN" -s "$s" getvar "$v" 2>&1
          rc=$?
          log FASTBOOT "command=getvar-$v serial=$s exit=$rc"
        done
        pause ;;
      4|5)
        local s; s="$(get_fastboot_serial)" || { pause; continue; }
        if [[ "$c" == 5 ]]; then
          warn "Not all devices support Fastboot recovery reboot."
          if confirm "Try rebooting device $s to recovery?"; then "$FASTBOOT_BIN" -s "$s" reboot recovery; fi
        else
          if confirm "Reboot device $s?"; then "$FASTBOOT_BIN" -s "$s" reboot; fi
        fi
        local rc=$?
        log FASTBOOT "reboot choice=$c serial=$s exit=$rc"
        ((rc == 0)) && ok "Fastboot reboot command completed." || err "Fastboot reboot failed (exit $rc)."
        pause ;;
      6)
        local s img
        s="$(get_fastboot_serial)" || { pause; continue; }
        img="$(choose_file "$IMAGE_DIR" '*.img')" || { pause; continue; }
        warn "Fastboot boot hanya didukung pada sebagian perangkat dan image yang cocok."
        printf 'Command preview: %s -s %q boot %q\n' "$FASTBOOT_BIN" "$s" "$img"
        if [[ "$DRY_RUN" != "0" ]]; then
          warn "Dry-run is enabled; no device command was executed."
          log FASTBOOT "boot-preview serial=$s image=$(basename "$img")"
        elif confirm "Boot this image temporarily on device $s?"; then
          "$FASTBOOT_BIN" -s "$s" boot "$img"; local rc=$?
          log FASTBOOT "boot serial=$s image=$(basename "$img") exit=$rc"
          ((rc == 0)) && ok "Fastboot boot command completed." || err "Fastboot boot failed (exit $rc)."
        fi
        pause ;;
      0) return ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
ubl_assistant() {
  header
  warn "Bootloader unlocking erases data on many devices and may affect warranty."
  printf 'This assistant provides information only; it never runs a generic unlock command.\n\n'
  if have "$ADB_BIN"; then
    local s model manu dev
    s="$(get_adb_serial 2>/dev/null || true)"
    if [[ -n "$s" ]]; then
      model="$(adb_shell_prop "$s" ro.product.model)"
      manu="$(adb_shell_prop "$s" ro.product.manufacturer)"
      dev="$(adb_shell_prop "$s" ro.product.device)"
      printf 'Model: %s\nManufacturer: %s\nCodename/device: %s\n' "$model" "$manu" "$dev"
    else
      info "No active ADB device. Connect a device or enter Fastboot mode."
    fi
  fi
  cat <<'TXT'

Safe guidance:
1. Enable Developer options and OEM unlocking only if the option is available.
2. Back up all important data.
3. Check the manufacturer's official instructions for the exact model.
4. Complete any official account authorization and waiting period.
5. Use an unlock command only when model-specific documentation tells you to.
6. Follow the on-device prompts after unlocking.

`fastboot flashing unlock` and `fastboot oem unlock` are NOT universal.
This tool deliberately does not run unlock commands automatically; an incorrect
command can erase data or leave the device unable to boot.
TXT
  pause
}
flash_recovery() {
  header
  warn "Flashing is destructive. Compatibility cannot be proven from a filename or checksum alone."
  local s img raw product target_codename trusted_sha actual_sha partition_choice
  require_cmd "$FASTBOOT_BIN" || { pause; return; }
  s="$(get_fastboot_serial)" || { pause; return; }
  raw="$("$FASTBOOT_BIN" -s "$s" getvar product 2>&1)"
  product="$(sed -nE 's/.*product:[[:space:]]*([^[:space:]]+).*/\1/p' <<< "$raw" | head -n 1 | tr -d '\r')"
  if [[ -z "$product" || "$product" == "unknown" ]]; then
    err "Fastboot did not report a product. Recovery flashing is blocked."
    log FLASH "blocked product-unavailable serial=$s"
    pause; return
  fi
  printf 'Serial: %s\nFastboot product reported by device: %s\n' "$s" "$product"
  img="$(choose_file "$IMAGE_DIR" '*.img')" || { info "Cancelled."; pause; return; }
  [[ "${img,,}" == *.img && -f "$img" && -s "$img" ]] || { err "Select a non-empty .img file."; pause; return; }
  printf '\nImage: %s\nSize: %s bytes\n' "$img" "$(wc -c < "$img" | tr -d ' ')"
  actual_sha="$(sha256_file "$img" 2>/dev/null | awk '{print tolower($1)}')" || actual_sha=""
  if [[ ! "$actual_sha" =~ ^[a-f0-9]{64}$ ]]; then
    err "SHA-256 utility unavailable or could not hash the image. Operation blocked."
    log FLASH "blocked checksum-unavailable serial=$s"
    pause; return
  fi
  printf 'Calculated SHA-256: %s\n' "$actual_sha"
  printf 'Enter the trusted SHA-256 published by the image maintainer: '
  read -r trusted_sha || { info "Cancelled."; pause; return; }
  trusted_sha="${trusted_sha,,}"
  if [[ ! "$trusted_sha" =~ ^[a-f0-9]{64}$ || "$trusted_sha" != "$actual_sha" ]]; then
    err "Trusted checksum is invalid or does not match. Flash blocked."
    log FLASH "blocked checksum-mismatch serial=$s product=$product image=$(basename "$img")"
    pause; return
  fi
  show_success "Checksum matches the trusted value you provided. This does not prove compatibility."
  printf 'Enter the target codename/product from the official maintainer instructions: '
  read -r target_codename || { info "Cancelled."; pause; return; }
  if [[ -z "$target_codename" || "$target_codename" != "$product" ]]; then
    err "Target does not exactly match the Fastboot product ($product). Operation blocked."
    log FLASH "blocked product-mismatch serial=$s detected=$product supplied=$target_codename"
    pause; return
  fi
  printf '\nOnly the dedicated recovery partition is permitted by this assistant.\n'
  warn "Read the official instructions and confirm this model has a dedicated recovery partition."
  printf 'Type the partition name documented for this exact model (only recovery is allowed): '
  read -r partition_choice || { info "Cancelled."; pause; return; }
  if [[ "$partition_choice" != "recovery" ]]; then
    err "Unsupported or unverified partition. Operation blocked."
    log FLASH "blocked partition serial=$s partition=$partition_choice"
    pause; return
  fi
  printf '\nCommand preview:\n%s -s %q flash recovery %q\n' "$FASTBOOT_BIN" "$s" "$img"
  log FLASH "validated serial=$s product=$product partition=recovery image=$(basename "$img") sha256=$actual_sha dry_run=$DRY_RUN"
  if [[ "$DRY_RUN" != "0" ]]; then
    show_warning "Dry-run is enabled. No device command was executed."
    pause; return
  fi
  warn "A successful Fastboot exit code does not guarantee the recovery will boot."
  if ! confirm "I verified the official model-specific partition and image instructions. Flash now?"; then
    info "Cancelled."
    log FLASH "cancelled serial=$s product=$product"
    pause; return
  fi
  local -a command=("$FASTBOOT_BIN" -s "$s" flash recovery "$img")
  "${command[@]}"
  local rc=$?
  log FLASH "serial=$s product=$product partition=recovery image=$(basename "$img") sha256=$actual_sha exit=$rc"
  if ((rc == 0)); then
    ok "Fastboot reported success. This does not guarantee recovery will boot."
  else
    err "Flash failed (exit code $rc). Keep the device connected and follow model-specific recovery steps."
  fi
  pause
}
rom_prep() {
  header
  printf 'Image/ROM directory: %s\n\n' "$IMAGE_DIR"
  list_inventory "$IMAGE_DIR"
  printf '\nCustom ROM readiness checklist:\n'
  printf '1. Match the device codename against the maintainer release page.\n'
  printf '2. Read the ROM and required firmware instructions.\n'
  printf '3. Confirm the required recovery is available.\n'
  printf '4. Back up important files and understand any data wipe.\n'
  printf '5. Verify SHA-256 against the official source.\n'
  printf '6. Do not use a package with unclear instructions or a mismatched target.\n'
  printf '7. ROM installation is not automated; follow the exact device/recovery instructions.\n\n'
  if confirm "Calculate SHA-256 for one file in the images directory?"; then
    local f; f="$(choose_file "$IMAGE_DIR" '*')" && sha256_file "$f"
  fi
  log ROM_PREP "checklist viewed"
  pause
}
backup_menu() {
  while true; do
    header
    cat <<'TXT'
Backups here are limited to accessible files, device metadata, and logs.
This tool does not create or restore full partition backups.
TXT
    printf '\nBackup inventory:\n'
    list_inventory "$BACKUP_DIR"
    cat <<'MENU'

1. Back up device information (ADB)
2. Copy current session log
3. Verify backup file integrity
4. Restore a local backup file
0. Back
MENU
    read -r -p "Choice: " c || return
    case "$c" in
      1)
        local s out p
        s="$(get_adb_serial)" || { pause; continue; }
        out="$BACKUP_DIR/device-info-${s}-$(date +%Y%m%d-%H%M%S).txt"
        if [[ -e "$out" ]]; then err "Backup already exists; refusing to overwrite."; pause; continue; fi
        {
          printf 'JARVIS.ID device information backup\nTimestamp: %s\nSerial: %s\n' "$(date '+%F %T %z')" "$s"
          for p in ro.product.model ro.product.manufacturer ro.product.device ro.product.name ro.build.version.release ro.build.fingerprint ro.boot.slot_suffix; do
            printf '%s=' "$p"; adb_shell_prop "$s" "$p"
          done
          "$ADB_BIN" -s "$s" shell df -h /data 2>/dev/null || true
        } > "$out"
        sha256_value "$out" > "$out.sha256" 2>/dev/null || true
        ok "Device information saved: $out"
        log BACKUP "device-info serial=$s file=$(basename "$out")"
        pause ;;
      2)
        local out
        out="$BACKUP_DIR/session-log-$(date +%Y%m%d-%H%M%S).txt"
        if [[ -e "$out" ]]; then err "Backup already exists; refusing to overwrite."
        elif cp -- "$LOG_FILE" "$out"; then ok "Session log copied: $out"; log BACKUP "session-log file=$(basename "$out")"
        else err "Could not copy session log."; fi
        pause ;;
      3)
        local f sidecar actual expected
        f="$(choose_file "$BACKUP_DIR" '*')" || { pause; continue; }
        sidecar="$f.sha256"
        if [[ -f "$sidecar" ]]; then
          expected="$(awk '{print tolower($1)}' "$sidecar")"
          actual="$(sha256_value "$f")" || { err "SHA-256 unavailable."; pause; continue; }
          if [[ "$expected" == "$actual" ]]; then ok "Backup integrity check passed."
          else err "Backup checksum mismatch."; fi
        else
          printf 'No saved checksum exists. Enter a checksum from a trusted source: '
          read -r expected || { pause; continue; }
          actual="$(sha256_value "$f")" || { err "SHA-256 unavailable."; pause; continue; }
          if [[ "${expected,,}" == "$actual" ]]; then ok "Checksum matches the supplied value."
          else err "Checksum mismatch."; fi
        fi
        log BACKUP "integrity-check file=$(basename "$f")"
        pause ;;
      4)
        local src dst parent
        src="$(choose_file "$BACKUP_DIR" '*')" || { pause; continue; }
        printf 'Absolute restore destination path: '
        read -r dst || { pause; continue; }
        if [[ -z "$dst" || "$dst" != /* || "$dst" == *$'\n'* || "$dst" == *"/../"* || "$dst" == */.. ]]; then
          err "Destination must be an absolute path without parent-directory traversal."
          pause; continue
        fi
        if [[ -d "$dst" ]]; then dst="${dst%/}/$(basename "$src")"; fi
        parent="$(dirname "$dst")"
        if [[ ! -d "$parent" ]]; then err "Destination directory does not exist."; pause; continue; fi
        if [[ -e "$dst" ]] && ! confirm "Destination exists. Explicitly overwrite $dst?"; then
          info "Restore cancelled."; pause; continue
        fi
        if confirm "Restore local file $(basename "$src") to $dst?"; then
          if cp -- "$src" "$dst"; then ok "Local backup file restored."; log RESTORE "file=$(basename "$src") destination=$(basename "$dst")"
          else err "Restore failed."; fi
        fi
        pause ;;
      0) return ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
file_manager() {
  while true; do
    header
    printf 'Working directory: %s\n\n' "$IMAGE_DIR"
    refresh_catalog || warn "Could not refresh the local catalog."
    printf 'Local catalog: %s\n' "$IMAGE_CATALOG"
    list_inventory "$IMAGE_DIR"
    cat <<'MENU'

1. Copy file to images directory
2. Calculate SHA-256
3. Verify a trusted SHA-256
4. Show images directory
0. Back
MENU
    read -r -p "Choice: " c || return
    case "$c" in
      1)
        printf 'Source file path: '; read -r src
        if [[ -f "$src" ]]; then
          if confirm "Copy file to $IMAGE_DIR?"; then
            if cp -n -- "$src" "$IMAGE_DIR/"; then ok "Copied if the destination filename was not already present."
            else err "Copy failed; existing files are not overwritten."; fi
            log FILE "copy source=$(basename "$src")"
          fi
        else err "File not found."; fi
        pause ;;
      2)
        local f
        f="$(choose_file "$IMAGE_DIR" '*')" && sha256_file "$f"
        log CHECKSUM "calculated file=$(basename "${f:-unknown}")"
        pause ;;
      3)
        local f expected actual
        f="$(choose_file "$IMAGE_DIR" '*')" || { pause; continue; }
        actual="$(sha256_value "$f")" || { err "SHA-256 utility unavailable."; pause; continue; }
        printf 'Calculated SHA-256: %s\nTrusted SHA-256 from the official source: ' "$actual"
        read -r expected || { pause; continue; }
        expected="${expected,,}"
        if [[ "$expected" =~ ^[a-f0-9]{64}$ && "$expected" == "$actual" ]]; then
          ok "Checksum matches the trusted value provided."
          log CHECKSUM "verified file=$(basename "$f") sha256=$actual"
        else
          err "Invalid checksum or mismatch. Do not use this file for flashing."
          log CHECKSUM "mismatch file=$(basename "$f")"
        fi
        printf 'A matching checksum proves integrity relative to the value you supplied, not device compatibility.\n'
        pause ;;
      4) printf 'Folder: %s\n' "$IMAGE_DIR"; pause ;;
      0) return ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
diagnostics() {
  header
  printf 'Tanggal: %s\n' "$(date)"
  printf 'Android host: %s\n' "$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  printf 'Arsitektur: %s\n' "$(uname -m)"
  printf '\nDependensi:\n'
  for c in "$ADB_BIN" "$FASTBOOT_BIN" git sha256sum sha256 unzip; do
    if have "$c"; then printf '  [OK] %s: %s\n' "$c" "$(command -v "$c")"; else printf '  [--] %s not found\n' "$c"; fi
  done
  printf '\nADB devices:\n'
  if have "$ADB_BIN"; then "$ADB_BIN" devices -l 2>&1 || warn "ADB enumeration failed."
  else printf 'unavailable\n'; fi
  printf '\nFastboot devices:\n'
  if have "$FASTBOOT_BIN"; then "$FASTBOOT_BIN" devices 2>&1 || warn "Fastboot enumeration failed."
  else printf 'unavailable\n'; fi
  printf '\nLog terbaru: %s\n' "$LOG_FILE"
  pause
}
firmware_assistant() {
  header
  printf 'Firmware inventory: %s\n' "$IMAGE_DIR"
  list_inventory "$IMAGE_DIR"
  cat <<'TXT'

Classification is advisory only. This tool does not execute package scripts,
modify anti-rollback state, downgrade firmware, cross-flash regions, or wipe
partitions. Vendor authorization and proprietary formats are not supported.
TXT
  local package listing type
  package="$(choose_file "$IMAGE_DIR" '*.zip')" || { pause; return; }
  if [[ "${package,,}" != *.zip ]]; then
    warn "Only ZIP contents are inspected here; no vendor flashing format is inferred."
  elif ! have unzip; then
    warn "unzip is unavailable; package contents cannot be inspected."
  else
    listing="$(unzip -Z1 "$package" 2>/dev/null)" || listing=""
    if [[ -z "$listing" ]]; then
      err "The archive could not be listed. It is not treated as flashable firmware."
      log FIRMWARE "inspect failed package=$(basename "$package")"
      pause; return
    fi
    type="unclassified ZIP"
    if grep -Eqi '(^|/)payload\.bin$|(^|/)META-INF/com/android/metadata$' <<< "$listing"; then
      type="recovery OTA candidate"
    elif grep -Eqi 'flash-all(\.sh|\.bat)?$|(^|/)(images/)?(bootloader|radio|super)\.' <<< "$listing"; then
      type="fastboot package candidate"
    fi
    printf '\nAdvisory type: %s\n' "$type"
    printf 'Archive entries (first 30):\n'
    head -n 30 <<< "$listing"
    printf '\n'
    warn "This listing does not confirm the device model, region, build, signature, or compatibility."
    log FIRMWARE "inspected package=$(basename "$package") advisory=$type"
  fi
  if [[ -f "$package" ]]; then
    printf '\nSHA-256: '
    sha256_value "$package" || printf 'unavailable\n'
  fi
  printf '\nNext steps: confirm exact model/codename, region, build prerequisites, vendor instructions, and trusted checksum before using the official method.\n'
  pause
}
rescue_diagnostics() {
  header
  cat <<'MENU'
RESCUE & DIAGNOSTICS
1. ADB unauthorized / offline
2. USB OTG device not detected
3. Fastboot device missing
4. Recovery boot failure
5. Bootloop
6. Insufficient storage
7. Image checksum mismatch
8. Wrong device codename
9. Unsupported Fastboot command
10. USB disconnected during operation
0. Back
MENU
  printf 'Choose an issue: '
  local choice
  read -r choice || return
  case "$choice" in
    1) printf '\nSymptoms: device appears as unauthorized/offline, or no ADB operations work.\nPossible causes: USB debugging disabled, RSA prompt not accepted, stale host authorization, cable/port issue.\nSafe checks: inspect `termux-adb devices -l`; unlock the phone and check its authorization prompt; reconnect USB OTG.\nRecommended steps: accept the prompt only on your own device; if needed revoke debugging authorizations in Android settings and reconnect.\nRisks: revoking authorizations requires approving the host again. Never bypass account or device security.\nIf unresolved: test a known data cable/OTG adapter and consult the device maintainer.\n' ;;
    2) printf '\nSymptoms: Android host does not show a USB device.\nPossible causes: charge-only cable, OTG adapter/power issue, unsupported host/target combination, damaged port.\nSafe checks: use `termux-adb devices -l`; reconnect without a hub; verify Android USB mode and OTG support.\nRecommended steps: try a known data cable and powered OTG adapter, then reconnect.\nRisks: avoid repeated connector movement during an active transfer.\nIf unresolved: check Termux/Android USB support for this exact device; no host-side root is assumed.\n' ;;
    3) printf '\nSymptoms: Fastboot reports no device.\nPossible causes: device is not in bootloader mode, OTG permissions/cable issue, missing Fastboot tool, vendor-specific USB mode.\nSafe checks: run `termux-fastboot devices`; verify the screen says bootloader/fastboot; reconnect the cable.\nRecommended steps: use official key/button instructions to enter bootloader, then check again.\nRisks: do not issue flash/unlock commands until the serial and product are visible.\nIf unresolved: consult the manufacturer or ROM maintainer for host OTG compatibility.\n' ;;
    4) printf '\nSymptoms: recovery does not start or returns to bootloader.\nPossible causes: image/partition mismatch, unsupported recovery layout, verified boot or firmware prerequisite.\nSafe checks: verify the exact image checksum and codename against maintainer documentation; inspect slot and bootloader state if supported.\nRecommended steps: use the maintainer’s documented recovery procedure only; do not guess a partition.\nRisks: flashing boot/vendor_boot/vbmeta or wiping data can make the device unbootable or erase data.\nIf unresolved: stop and use the official device-specific rescue guide.\n' ;;
    5) printf '\nSymptoms: repeated reboot before Android starts.\nPossible causes: failed update, incompatible image/module, storage or filesystem problem.\nSafe checks: note the last successful operation; try only documented recovery/bootloader access; preserve logs and package checksums.\nRecommended steps: consult the device maintainer’s recovery sequence and verify exact build prerequisites.\nRisks: wipes and firmware flashes may permanently remove user data; do not flash as a first response.\nIf unresolved: stop and seek model-specific service guidance.\n' ;;
    6) printf '\nSymptoms: package copy or installation reports insufficient space.\nPossible causes: low /data space, large temporary extraction, reserved system space.\nSafe checks: `termux-adb shell df -h /data` when ADB is authorized; inspect local free space with `df -h`.\nRecommended steps: move only verified files to appropriate storage and remove only files you recognize.\nRisks: do not delete system or unknown application data to free space.\nIf unresolved: follow Android storage support guidance for the exact device.\n' ;;
    7) printf '\nSymptoms: calculated SHA-256 differs from maintainer value.\nPossible causes: incomplete download/copy, wrong file, untrusted or stale checksum.\nSafe checks: compare the full 64-character value with the official maintainer release page; recopy/re-download from the trusted source.\nRecommended steps: do not flash this file; repeat verification after obtaining a fresh copy.\nRisks: a mismatched image may brick the device or compromise data.\nIf unresolved: contact the maintainer; never waive a mismatch.\n' ;;
    8) printf '\nSymptoms: image target codename differs from detected Fastboot product.\nPossible causes: wrong image, regional/model variant, vendor reports an alias.\nSafe checks: compare product/device identifiers with official documentation for the exact model.\nRecommended steps: stop until an authoritative source explains the difference.\nRisks: do not substitute a similar model or force a flash.\nIf unresolved: request model-specific confirmation from the maintainer or vendor.\n' ;;
    9) printf '\nSymptoms: Fastboot rejects `getvar` or another command.\nPossible causes: command unsupported by the bootloader version, vendor implementation difference, device not in expected mode.\nSafe checks: capture exact output and exit code; try only documented read-only variables.\nRecommended steps: use the vendor/maintainer procedure for this model.\nRisks: do not treat an unsupported variable as proof of unlock state or partition support.\nIf unresolved: share a privacy-reviewed service report with the maintainer.\n' ;;
    10) printf '\nSymptoms: USB disconnects during a device operation.\nPossible causes: loose connector, power draw, cable/adapter or port fault.\nSafe checks: keep the device connected if a write is active; observe the device display and tool output.\nRecommended steps: wait for an explicit device state before reconnecting or retrying; check the official rescue instructions.\nRisks: disconnecting during a write may corrupt firmware. Do not blindly repeat the flash.\nIf unresolved: use authorized service guidance for the exact model.\n' ;;
    0) return ;;
    *) warn "Invalid selection." ;;
  esac
  pause
}
service_report() {
  header
  local report rc
  report="$BACKUP_DIR/service-report-$(date +%Y%m%d-%H%M%S).txt"
  if [[ -e "$report" ]]; then err "Report already exists; refusing to overwrite."; pause; return; fi
  {
    printf 'JARVIS.ID Android Flash Tool service report\nVersion: %s\nTimestamp: %s\n' "$VERSION" "$(date '+%F %T %z')"
    printf 'Host architecture: %s\nAndroid host release: %s\nDry-run default: %s\n' "$(uname -m)" "$(getprop ro.build.version.release 2>/dev/null || printf 'unknown')" "$DRY_RUN"
    printf '\nTool availability:\n'
    for c in "$ADB_BIN" "$FASTBOOT_BIN" sha256sum sha256 unzip git; do
      if have "$c"; then printf '%s: %s\n' "$c" "$(command -v "$c")"; else printf '%s: not found\n' "$c"; fi
    done
    printf '\nADB devices:\n'
    if have "$ADB_BIN"; then "$ADB_BIN" devices -l 2>&1 || true; else printf 'unavailable\n'; fi
    printf '\nFastboot devices:\n'
    if have "$FASTBOOT_BIN"; then "$FASTBOOT_BIN" devices -l 2>&1 || true; else printf 'unavailable\n'; fi
    printf '\nRecent local log:\n'
    tail -n 100 "$LOG_FILE" 2>/dev/null || true
    printf '\nReview this report before sharing; device serials and local paths may be identifying.\n'
  } > "$report"
  rc=$?
  if ((rc == 0)); then
    ok "Service report saved: $report"
    sha256_value "$report" > "$report.sha256" 2>/dev/null || true
    log REPORT "export file=$(basename "$report")"
  else
    err "Could not write service report (exit $rc)."
  fi
  pause
}
update_manager() {
  header
  local app_dir repo status branch current
  app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if ! have git || ! repo="$(git -C "$app_dir" rev-parse --show-toplevel 2>/dev/null)"; then
    warn "This installation is not inside a Git repository; no update was attempted."
    printf 'Current application version: %s\n' "$VERSION"
    pause; return
  fi
  status="$(git -C "$repo" status --porcelain 2>&1)" || status="status unavailable"
  branch="$(git -C "$repo" branch --show-current 2>/dev/null || printf 'unknown')"
  current="$(git -C "$repo" log -1 --oneline 2>/dev/null || printf 'unknown')"
  printf 'Repository: %s\nBranch: %s\nCurrent commit: %s\n' "$repo" "$branch" "$current"
  if [[ -n "$status" ]]; then
    warn "Local changes exist. Safe update is blocked; commit or back up your work first."
    printf '%s\n' "$status"
    pause; return
  fi
  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    warn "No origin remote is configured; no update was attempted."
    pause; return
  fi
  printf '\nThe updater uses fetch + fast-forward-only and never resets local files.\n'
  if ! confirm "Fetch and check the configured origin?"; then pause; return; fi
  git -C "$repo" fetch origin
  local rc=$?
  if ((rc != 0)); then err "Fetch failed (exit $rc). Local files were not reset."; pause; return; fi
  if ! git -C "$repo" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    warn "No upstream is configured; fetched refs were not merged."
    pause; return
  fi
  git -C "$repo" log --oneline "HEAD..@{upstream}" 2>/dev/null || true
  if ! confirm "Review the changelog above and fast-forward to the configured upstream?"; then pause; return; fi
  git -C "$repo" pull --ff-only
  rc=$?
  if ((rc == 0)); then
    ok "Fast-forward update completed."
    git -C "$repo" log -1 --oneline
    printf 'If the update causes a problem, use `git revert` for a committed change or restore a saved copy; this tool never runs reset --hard.\n'
    log UPDATE "fast-forward completed repo=$repo"
  else
    err "Fast-forward update failed (exit $rc). No hard reset was run; inspect Git status and resolve manually."
    log UPDATE "fast-forward failed repo=$repo exit=$rc"
  fi
  pause
}
settings_menu() {
  while true; do
    header
    printf 'ADB executable: %s\nFastboot executable: %s\nDry-run: %s\n' "$ADB_BIN" "$FASTBOOT_BIN" "$DRY_RUN"
    printf 'Working directory: %s\n' "$ROOT"
    cat <<'MENU'

1. Check dependencies and connections
2. Toggle dry-run for this session
3. Show working directories
4. Show startup animation settings
0. Back
MENU
    read -r -p "Choice: " c || return
    case "$c" in
      1) diagnostics ;;
      2)
        if [[ "$DRY_RUN" == "0" ]]; then DRY_RUN=1; else DRY_RUN=0; fi
        log SETTINGS "dry_run=$DRY_RUN"
        if [[ "$DRY_RUN" == "0" ]]; then warn "Dry-run disabled for this session. Device operations still require explicit confirmation."
        else ok "Dry-run enabled for this session."; fi
        pause ;;
      3) printf '%s\n' "$ROOT" "$CONFIG_DIR" "$IMAGE_DIR" "$BACKUP_DIR" "$LOG_DIR"; pause ;;
      4)
        printf 'JARVIS_ANIMATION=%s (supported: off, fast; default is normal)\n' "$ANIMATION_MODE"
        printf 'Set NO_COLOR to disable ANSI colors. Animation falls back to a static banner when output is not a terminal.\n'
        pause ;;
      0) return ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
main_menu() {
  local first_screen=1
  while true; do
    if ((first_screen)); then first_screen=0; else header; fi
    show_main_menu
    printf '\nADB: '; if have "$ADB_BIN"; then printf '%sready%s' "$GREEN" "$RESET"; else printf '%smissing%s' "$RED" "$RESET"; fi
    printf ' | Fastboot: '; if have "$FASTBOOT_BIN"; then printf '%sready%s\n' "$GREEN" "$RESET"; else printf '%smissing%s\n' "$RED" "$RESET"; fi
    read -r -p "Select menu: " choice || break
    case "$choice" in
      1|01) device_info ;;
      2|02) adb_menu ;;
      3|03) fastboot_menu ;;
      4|04) ubl_assistant ;;
      5|05) flash_recovery ;;
      6|06) firmware_assistant ;;
      7|07) rom_prep ;;
      8|08) backup_menu ;;
      9|09) rescue_diagnostics ;;
      10) file_manager ;;
      11) service_report ;;
      12) settings_menu ;;
      13) update_manager ;;
      0|00) printf 'Thank you for using %s.\n' "$APP_NAME"; return 0 ;;
      *) warn "Invalid selection."; pause ;;
    esac
  done
}
jarvis_interrupt() {
  printf '\nInterrupted safely. Check the log: %s\n' "$LOG_FILE"
  log EXIT "interrupted"
  exit 130
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap jarvis_interrupt INT
  log START "version=$VERSION root=$ROOT dry_run=$DRY_RUN"
  show_startup_animation
  main_menu
fi
