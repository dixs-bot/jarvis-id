#!/data/data/com.termux/files/usr/bin/bash
set -eu
SUMBER="$(cd "$(dirname "$0")" && pwd)"
TARGET="${JARVIS_HOME:-$HOME/jarvis-flash}"
echo "Pemasang JARVIS.ID Android Flash Tool v3.0.0"
if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then echo "[GAGAL] Jalankan dari aplikasi Termux." >&2; exit 1; fi
[[ -f "$SUMBER/jarvis-flash.sh" ]] || { echo "[GAGAL] jarvis-flash.sh tidak ditemukan." >&2; exit 1; }
mkdir -p "$TARGET"/{config,images,backups,logs,tests}
if [[ -f "$TARGET/jarvis-flash.sh" ]]; then cp "$TARGET/jarvis-flash.sh" "$TARGET/jarvis-flash.sh.backup-$(date +%Y%m%d-%H%M%S)"; fi
install -m 700 "$SUMBER/jarvis-flash.sh" "$TARGET/jarvis-flash.sh"
[[ ! -f "$SUMBER/README.md" ]] || install -m 600 "$SUMBER/README.md" "$TARGET/README.md"
printf '3.0.0\n' > "$TARGET/VERSION"
echo "Pemeriksaan dependensi:"
for c in termux-adb termux-fastboot; do command -v "$c" >/dev/null 2>&1 && echo "[ADA] $c" || echo "[PERINGATAN] $c tidak ditemukan"; done
echo "[SELESAI] Terpasang di $TARGET"
echo "Jalankan: bash \"$TARGET/jarvis-flash.sh\""
echo "Mode simulasi flashing aktif secara bawaan."
