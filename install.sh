#!/data/data/com.termux/files/usr/bin/bash
set -eu
APP_NAME="JARVIS.ID Android Flash Tool"
VERSION="2.0.0"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${JARVIS_HOME:-$HOME/jarvis-flash}"

printf '%s\n' "== $APP_NAME installer =="
printf 'Version: %s\n' "$VERSION"

if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then
  echo "[ERROR] Termux environment not detected (PREFIX is unavailable)." >&2
  echo "Run this installer from Termux, not a desktop terminal." >&2
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64|armv7l|i686|x86_64) ;;
  *) echo "[WARNING] Architecture $ARCH has not been tested." ;;
esac

for f in jarvis-flash.sh; do
  if [[ ! -f "$SOURCE_DIR/$f" ]]; then
    echo "[ERROR] Required file not found: $SOURCE_DIR/$f" >&2
    exit 1
  fi
done

if ! bash -n "$SOURCE_DIR/jarvis-flash.sh"; then
  echo "[ERROR] Bash syntax check failed; existing installation was not changed." >&2
  exit 1
fi

mkdir -p "$TARGET"/{config,images,backups,logs,lib,docs}
if [[ -f "$TARGET/jarvis-flash.sh" ]]; then
  BACKUP="$TARGET/backups/pre-install-$(date +%Y%m%d-%H%M%S).sh"
  if [[ -e "$BACKUP" ]]; then
    echo "[ERROR] Backup path already exists: $BACKUP" >&2
    exit 1
  fi
  cp -p -- "$TARGET/jarvis-flash.sh" "$BACKUP"
  printf '[INFO] Previous script backed up to: %s\n' "$BACKUP"
fi
install -m 700 "$SOURCE_DIR/jarvis-flash.sh" "$TARGET/jarvis-flash.sh"
for doc in README.md CHANGELOG.md; do
  if [[ -f "$SOURCE_DIR/$doc" ]]; then
    install -m 600 "$SOURCE_DIR/$doc" "$TARGET/docs/$doc"
  fi
done

if [[ ! -f "$TARGET/config/config.conf" ]]; then
cat > "$TARGET/config/config.conf" <<'CONF'
# JARVIS.ID Android Flash Tool settings
ADB_BIN=termux-adb
FASTBOOT_BIN=termux-fastboot
DRY_RUN=1
ANIMATION=on
CONF
fi

chmod 700 "$TARGET/jarvis-flash.sh"
printf '\n[OK] Installed to: %s\n' "$TARGET"
printf '\nDependency check:\n'
for cmd in termux-adb termux-fastboot sha256sum sha256 unzip git; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  [OK] %s -> %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '  [WARNING] %s not found in PATH.\n' "$cmd"
  fi
done
if command -v sha256sum >/dev/null 2>&1 || command -v sha256 >/dev/null 2>&1; then
  echo "  [OK] utilitas SHA-256 tersedia"
else
  echo "  [WARNING] SHA-256 utility unavailable; install coreutils."
fi

cat <<EOF

Installation complete.
Run:
  bash "$TARGET/jarvis-flash.sh"

Notes:
- The installer does not open SSH/tunnels or download remote code.
- Bootloader unlocking is never executed automatically.
- Recovery flashing still requires model and partition verification.
EOF
