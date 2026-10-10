#!/data/data/com.termux/files/usr/bin/bash
set -eu
D="$(cd "$(dirname "$0")/.." && pwd)"
bash -n "$D/jarvis-flash.sh"
bash -n "$D/install.sh"
grep -q 'VERSI="3.0.0"' "$D/jarvis-flash.sh"
grep -q 'Informasi Perangkat' "$D/jarvis-flash.sh"
grep -q 'JARVIS_DRY_RUN:-1' "$D/jarvis-flash.sh"
echo "[LULUS] Sintaks, versi, menu Bahasa Indonesia, dan mode simulasi."
echo "[CATATAN] Pengujian ini tidak menguji USB OTG atau perangkat fisik."
