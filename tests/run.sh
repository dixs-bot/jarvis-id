#!/usr/bin/env bash
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
MOCK_DIR="$TMP_DIR/mock-bin"
mkdir -p "$MOCK_DIR" "$TMP_DIR/home/images"
export JARVIS_HOME="$TMP_DIR/home"
export MOCK_CALL_LOG="$TMP_DIR/fastboot-calls.log"
export ADB_BIN="$MOCK_DIR/termux-adb"
export FASTBOOT_BIN="$MOCK_DIR/termux-fastboot"
export JARVIS_DRY_RUN=1
: > "$MOCK_CALL_LOG"

cat > "$ADB_BIN" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == "devices" ]]; then
  printf 'List of devices attached\nMOCKADB-1\tdevice product:testdevice\nMOCKADB-2\tunauthorized transport_id:2\n'
  exit 0
fi
if [[ "${1:-}" == "-s" && "${3:-}" == "shell" && "${4:-}" == "getprop" ]]; then
  case "${5:-}" in
    ro.product.model) printf 'Mock Phone\n' ;;
    ro.product.manufacturer) printf 'Mock Vendor\n' ;;
    ro.product.device|ro.product.name) printf 'testdevice\n' ;;
    ro.build.version.release) printf '15\n' ;;
    ro.boot.flash.locked) printf '1\n' ;;
    *) printf '\n' ;;
  esac
  exit 0
fi
printf 'mock ADB received: %s\n' "$*" >&2
exit 0
MOCK

cat > "$FASTBOOT_BIN" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_CALL_LOG"
if [[ "${1:-}" == "devices" ]]; then
  printf 'MOCKFB-1\tfastboot\n'
  exit 0
fi
if [[ "${1:-}" == "-s" && "${3:-}" == "getvar" && "${4:-}" == "product" ]]; then
  printf '(bootloader) product: testdevice\n'
  exit 0
fi
if [[ "${1:-}" == "-s" && "${3:-}" == "flash" ]]; then
  printf 'mock flash accepted\n'
  exit 0
fi
if [[ "${1:-}" == "-s" && "${3:-}" == "boot" ]]; then
  printf 'mock boot accepted\n'
  exit 0
fi
exit 0
MOCK
chmod +x "$ADB_BIN" "$FASTBOOT_BIN"

# Source the application without entering the interactive menu.
source "$TOOL_DIR/jarvis-flash.sh"

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s (expected <%s>, got <%s>)\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
}
assert_contains() {
  local text="$1" expected="$2" label="$3"
  if ! grep -Fq -- "$expected" <<< "$text"; then
    printf 'FAIL: %s (missing <%s>)\n' "$label" "$expected" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
}

serial="$(get_adb_serial 2>/dev/null)"
assert_eq "MOCKADB-1" "$serial" "ADB selects only authorized device"
image="$TMP_DIR/home/images/test recovery.img"
printf 'mock recovery image\n' > "$image"
sha256sum="$(sha256_value "$image")"
assert_eq 64 "${#sha256sum}" "SHA-256 helper returns a 64-character digest"

get_fastboot_serial() { printf 'MOCKFB-1\n'; }
choose_file() { printf '%s\n' "$image"; }

out="$(printf '%s\n%s\n%s\n\n' "$sha256sum" "testdevice" "recovery" | flash_recovery 2>&1)"
assert_contains "$out" "Dry-run is enabled" "recovery flash defaults to dry-run"
if grep -Eq '(^|[[:space:]])flash[[:space:]]' "$MOCK_CALL_LOG"; then
  printf 'FAIL: dry-run did not issue a flash command\n' >&2
  exit 1
fi
printf 'PASS: dry-run does not call Fastboot flash\n'

out="$(printf '%s\n\n' "0000000000000000000000000000000000000000000000000000000000000000" | flash_recovery 2>&1)"
assert_contains "$out" "checksum is invalid or does not match" "checksum mismatch blocks recovery flash"

out="$(printf '%s\n%s\n\n' "$sha256sum" "another-device" | flash_recovery 2>&1)"
assert_contains "$out" "does not exactly match" "product/codename mismatch blocks recovery flash"

out="$(printf '%s\n%s\n%s\n\n' "$sha256sum" "testdevice" "boot" | flash_recovery 2>&1)"
assert_contains "$out" "Unsupported or unverified partition" "unapproved partition blocks recovery flash"
if grep -Eq '(^|[[:space:]])flash[[:space:]]' "$MOCK_CALL_LOG"; then
  printf 'FAIL: blocked operation called Fastboot flash\n' >&2
  exit 1
fi
printf 'PASS: blocked validation paths do not call Fastboot flash\n'

DRY_RUN=0
out="$(printf '%s\n%s\n%s\nYES\n\n' "$sha256sum" "testdevice" "recovery" | flash_recovery 2>&1)"
assert_contains "$out" "Fastboot reported success" "confirmed flash routes to mock Fastboot and reports exit code"
if ! grep -Fq -- '-s MOCKFB-1 flash recovery' "$MOCK_CALL_LOG"; then
  printf 'FAIL: confirmed operation did not route the expected command to the mock\n' >&2
  exit 1
fi
printf 'PASS: confirmed flash command reaches mock only\n'

menu="$(show_main_menu)"
assert_contains "$menu" "[13] Update Manager" "13 requested menu areas are present"
assert_contains "$menu" "[00] Exit" "zero exit navigation is present"

(
  config_home="$TMP_DIR/config-home"
  marker="$TMP_DIR/config-was-executed"
  mkdir -p "$config_home/config"
  printf 'ADB_BIN=%s\nFASTBOOT_BIN=%s\nDRY_RUN=0\nANIMATION=fast\nUNKNOWN=$(touch %q)\n' \
    "$MOCK_DIR/termux-adb" "$MOCK_DIR/termux-fastboot" "$marker" > "$config_home/config/config.conf"
  export JARVIS_HOME="$config_home"
  unset ADB_BIN FASTBOOT_BIN JARVIS_DRY_RUN JARVIS_ANIMATION
  source "$TOOL_DIR/jarvis-flash.sh"
  assert_eq "$MOCK_DIR/termux-adb" "$ADB_BIN" "plain-text config loads the ADB executable"
  assert_eq "0" "$DRY_RUN" "plain-text config loads dry-run preference"
  assert_eq "fast" "$ANIMATION_MODE" "plain-text config loads animation preference"
  [[ ! -e "$marker" ]]
  printf 'PASS: config values are parsed without executing unknown lines\n'
)

printf '\nAll mock tests passed. No physical device was accessed.\n'
