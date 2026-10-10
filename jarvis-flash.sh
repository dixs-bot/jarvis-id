#!/data/data/com.termux/files/usr/bin/bash
# JARVIS.ID Android Flash Tool v3.0.0 — Antarmuka Bahasa Indonesia
set -u
umask 077
VERSI="3.0.0"
NAMA="JARVIS.ID Android Flash Tool"
RUMAH="${JARVIS_HOME:-$HOME/jarvis-flash}"
ADB="${ADB_BIN:-termux-adb}"
FASTBOOT="${FASTBOOT_BIN:-termux-fastboot}"
mkdir -p "$RUMAH"/{config,images,backups,logs} || exit 1
LOG="$RUMAH/logs/sesi-$(date +%Y%m%d).log"
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
 BIRU=$'\033[34m'; SIAN=$'\033[36m'; PUTIH=$'\033[97m'; HIJAU=$'\033[32m'; MERAH=$'\033[31m'; KUNING=$'\033[33m'; RESET=$'\033[0m'
else BIRU=""; SIAN=""; PUTIH=""; HIJAU=""; MERAH=""; KUNING=""; RESET=""; fi
catat(){ printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >> "$LOG"; }
info(){ printf '%s[INFO]%s %s\n' "$SIAN" "$RESET" "$*"; catat INFO "$*"; }
sukses(){ printf '%s[BERHASIL]%s %s\n' "$HIJAU" "$RESET" "$*"; catat BERHASIL "$*"; }
peringatan(){ printf '%s[PERINGATAN]%s %s\n' "$KUNING" "$RESET" "$*"; catat PERINGATAN "$*"; }
gagal(){ printf '%s[GAGAL]%s %s\n' "$MERAH" "$RESET" "$*"; catat GAGAL "$*"; }
jeda(){ printf '\nTekan Enter untuk kembali...'; read -r _ || true; }
ada(){ command -v "$1" >/dev/null 2>&1; }
konfirmasi(){ local a; printf '%s [ketik YA untuk melanjutkan]: ' "$1"; read -r a || return 1; [[ "$a" == YA ]]; }
judul(){
 clear 2>/dev/null || true
 printf '%s\n' "${SIAN}     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗${RESET}" "${SIAN}     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝${RESET}" "${SIAN}     ██║███████║██████╔╝██║   ██║██║███████╗${RESET}" "${SIAN}██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║${RESET}" "${SIAN}╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║${RESET}" "${SIAN} ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝${RESET}"
 printf '%s\n' "${PUTIH}             JARVIS.ID ANDROID FLASH TOOL v$VERSI${RESET}" "       PERBAIKAN ANDROID • BOOTLOADER • TWRP • CUSTOM ROM"
}
animasi(){
 if [[ ! -t 1 || "${JARVIS_ANIMATION:-normal}" == off ]]; then judul; return; fi
 local delay=0.025 line
 [[ "${JARVIS_ANIMATION:-normal}" == fast ]] && delay=0.005
 clear 2>/dev/null || true
 while IFS= read -r line; do printf '%s%s%s\n' "$SIAN" "$line" "$RESET"; sleep "$delay"; done <<'LOGO'
     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗
     ██║██╔══██╗██╔══██╗██║   ██║██║╔══════╝
     ██║███████║██████╔╝██║   ██║██║███████╗
██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║
╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║
 ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝
LOGO
 printf '\n%sJ A R V I S . I D%s\n' "$PUTIH" "$RESET"
 for line in "Memulai mesin JARVIS" "Memeriksa alat ADB" "Memeriksa alat Fastboot" "Memuat protokol keselamatan"; do
   printf '%s[MEMERIKSA]%s %s\n' "$SIAN" "$RESET" "$line"; sleep "$delay"
 done
}
pilih_adb(){
 ada "$ADB" || { gagal "Perintah $ADB tidak ditemukan."; return 1; }
 local -a list=(); local line serial state n
 while IFS= read -r line; do
  [[ "$line" == *$'\t'* ]] || continue
  serial="${line%%$'\t'*}"; state="${line#*$'\t'}"; state="${state%%[[:space:]]*}"
  [[ "$state" == device ]] && list+=("$serial")
 done < <("$ADB" devices 2>/dev/null)
 ((${#list[@]})) || { gagal "Tidak ada perangkat ADB siap. Periksa kabel, USB debugging, dan izin."; return 1; }
 ((${#list[@]}==1)) && { printf '%s\n' "${list[0]}"; return; }
 printf 'Perangkat ADB:\n' >&2; local i
 for i in "${!list[@]}"; do printf ' %d) %s\n' "$((i+1))" "${list[$i]}" >&2; done
 printf 'Pilih nomor: ' >&2; read -r n || return 1
 [[ "$n" =~ ^[0-9]+$ ]] && ((n>0 && n<=${#list[@]})) || return 1
 printf '%s\n' "${list[$((n-1))]}"
}
pilih_fb(){
 ada "$FASTBOOT" || { gagal "Perintah $FASTBOOT tidak ditemukan."; return 1; }
 local -a list=(); local line serial n
 while IFS= read -r line; do serial="$(awk '{print $1}' <<< "$line")"; [[ -n "$serial" && "$serial" != List ]] && list+=("$serial"); done < <("$FASTBOOT" devices 2>/dev/null)
 ((${#list[@]})) || { gagal "Perangkat Fastboot tidak terdeteksi."; return 1; }
 ((${#list[@]}==1)) && { printf '%s\n' "${list[0]}"; return; }
 printf 'Perangkat Fastboot:\n' >&2; local i
 for i in "${!list[@]}"; do printf ' %d) %s\n' "$((i+1))" "${list[$i]}" >&2; done
 printf 'Pilih nomor: ' >&2; read -r n || return 1
 [[ "$n" =~ ^[0-9]+$ ]] && ((n>0 && n<=${#list[@]})) || return 1
 printf '%s\n' "${list[$((n-1))]}"
}
prop(){ "$ADB" -s "$1" shell getprop "$2" 2>/dev/null | tr -d '\r' | head -n1; }
sha(){ if ada sha256sum; then sha256sum "$1"; elif ada sha256; then sha256 -q "$1"; else gagal "Pasang coreutils untuk SHA-256."; return 1; fi; }
file_img(){
 local -a a=(); local f n
 shopt -s nullglob; for f in "$RUMAH/images"/*.img; do [[ -f "$f" ]] && a+=("$f"); done; shopt -u nullglob
 if ((${#a[@]}==0)); then peringatan "Tidak ada .img di folder images."; printf 'Masukkan lokasi file lengkap (kosong untuk batal): '; read -r f || return 1; [[ -f "$f" ]] || return 1; printf '%s\n' "$f"; return; fi
 for n in "${!a[@]}"; do printf ' %d) %s\n' "$((n+1))" "${a[$n]}" >&2; done
 printf 'Pilih nomor (0 batal): ' >&2; read -r n || return 1
 [[ "$n" =~ ^[0-9]+$ ]] && ((n>0 && n<=${#a[@]})) || return 1; printf '%s\n' "${a[$((n-1))]}"
}
info_perangkat(){
 judul; local s; s="$(pilih_adb)" || { jeda; return; }
 printf '\nNomor: %s\nMerek: %s\nModel: %s\nCodename: %s\nProduk: %s\nAndroid: %s\nSDK: %s\nArsitektur: %s\nFingerprint: %s\nSlot aktif: %s\n' "$s" "$(prop "$s" ro.product.manufacturer)" "$(prop "$s" ro.product.model)" "$(prop "$s" ro.product.device)" "$(prop "$s" ro.product.name)" "$(prop "$s" ro.build.version.release)" "$(prop "$s" ro.build.version.sdk)" "$(prop "$s" ro.product.cpu.abi)" "$(prop "$s" ro.build.fingerprint)" "$(prop "$s" ro.boot.slot_suffix)"
 "$ADB" -s "$s" shell df -h /data 2>/dev/null | tail -n1; jeda
}
adb_menu(){
 while true; do judul; cat <<'M'
ALAT ADB
1. Daftar perangkat
2. Buka shell Android
3. Mulai ulang perangkat
4. Mulai ulang ke pemulihan
5. Mulai ulang ke bootloader
6. Simpan logcat
7. Kirim file ke perangkat
8. Ambil file dari perangkat
0. Kembali
M
 read -r -p "Pilih: " c || return
 case "$c" in
  1) "$ADB" devices -l; jeda;;
  2) local s; s="$(pilih_adb)" && "$ADB" -s "$s" shell; jeda;;
  3|4|5) local s target=""; s="$(pilih_adb)" || { jeda; continue; }; [[ "$c" == 4 ]] && target=recovery; [[ "$c" == 5 ]] && target=bootloader
    if konfirmasi "Mulai ulang perangkat?"; then if [[ -n "$target" ]]; then "$ADB" -s "$s" reboot "$target"; else "$ADB" -s "$s" reboot; fi; catat ADB "reboot kode=$?"; fi; jeda;;
  6) local s out; s="$(pilih_adb)" || { jeda; continue; }; out="$RUMAH/logs/logcat-$(date +%Y%m%d-%H%M%S).txt"; "$ADB" -s "$s" logcat -d > "$out" 2>&1; sukses "Log disimpan: $out"; jeda;;
  7) local s src dst; s="$(pilih_adb)" || { jeda; continue; }; printf 'Lokasi file Termux: '; read -r src; [[ -f "$src" ]] || { gagal "File tidak ditemukan."; jeda; continue; }; printf 'Lokasi tujuan perangkat: '; read -r dst; if konfirmasi "Kirim file?"; then "$ADB" -s "$s" push "$src" "$dst"; catat ADB "push kode=$?"; fi; jeda;;
  8) local s src dst; s="$(pilih_adb)" || { jeda; continue; }; printf 'Lokasi file perangkat: '; read -r src; printf 'Lokasi tujuan Termux: '; read -r dst; if konfirmasi "Ambil file?"; then "$ADB" -s "$s" pull "$src" "$dst"; catat ADB "pull kode=$?"; fi; jeda;;
  0) return;; *) peringatan "Pilihan tidak tersedia."; jeda;;
 esac
 done
}
fastboot_menu(){
 while true; do judul; cat <<'M'
ALAT FASTBOOT
1. Daftar perangkat
2. Periksa nama produk
3. Periksa variabel umum
4. Mulai ulang perangkat
5. Coba mulai ulang ke pemulihan
6. Boot image sementara (jika didukung)
0. Kembali
M
 read -r -p "Pilih: " c || return
 case "$c" in
  1) "$FASTBOOT" devices; jeda;;
  2) local s; s="$(pilih_fb)" && "$FASTBOOT" -s "$s" getvar product 2>&1; jeda;;
  3) local s v; s="$(pilih_fb)" || { jeda; continue; }; for v in product current-slot unlocked is-userspace secure; do echo "--- $v ---"; "$FASTBOOT" -s "$s" getvar "$v" 2>&1 || true; done; jeda;;
  4|5) local s; s="$(pilih_fb)" || { jeda; continue; }; if konfirmasi "Mulai ulang perangkat?"; then if [[ "$c" == 5 ]]; then "$FASTBOOT" -s "$s" reboot recovery; else "$FASTBOOT" -s "$s" reboot; fi; catat FASTBOOT "reboot kode=$?"; fi; jeda;;
  6) local s img; s="$(pilih_fb)" || { jeda; continue; }; img="$(file_img)" || { jeda; continue; }; printf 'Pratinjau: %s -s %q boot %q\n' "$FASTBOOT" "$s" "$img"; if konfirmasi "Jalankan boot sementara?"; then "$FASTBOOT" -s "$s" boot "$img"; catat FASTBOOT "boot sementara kode=$?"; fi; jeda;;
  0) return;; *) peringatan "Pilihan tidak tersedia."; jeda;;
 esac
 done
}
ubl(){
 judul; peringatan "Membuka bootloader biasanya menghapus data dan dapat memengaruhi garansi."
 echo "Menu ini hanya memberi panduan; tidak menjalankan perintah unlock otomatis."
 echo "1. Cadangkan data"; echo "2. Periksa panduan resmi untuk model tepat"; echo "3. Pastikan OEM unlocking tersedia dan syarat vendor terpenuhi"
 echo "Jangan gunakan perintah unlock generik. Tool tidak melewati FRP atau otorisasi vendor."
 jeda
}
flash_recovery(){
 judul; peringatan "Mode simulasi aktif secara bawaan. Kecocokan file wajib diverifikasi manual."
 local s product img target
 s="$(pilih_fb)" || { jeda; return; }
 product="$("$FASTBOOT" -s "$s" getvar product 2>&1 | sed -n 's/.*product:[[:space:]]*//p' | head -n1 | tr -d '\r')"
 printf 'Produk Fastboot: %s\n' "${product:-tidak diketahui}"
 img="$(file_img)" || { jeda; return; }
 printf 'File: %s\nUkuran: ' "$img"; du -h "$img" | awk '{print $1}'; sha "$img" || { jeda; return; }
 peringatan "Checksum harus dibandingkan dengan checksum resmi; nama file bukan bukti kompatibilitas."
 printf 'Ketik product/codename yang sudah diverifikasi: '; read -r target
 if [[ -z "$product" || "$product" != "$target" ]]; then gagal "Identitas tidak cocok. Flash dibatalkan."; jeda; return; fi
 echo "Perintah yang dipertimbangkan: $FASTBOOT -s $s flash recovery $img"
 peringatan "Hanya gunakan partisi recovery jika dokumentasi resmi model memastikan partisi itu ada."
 if [[ "${JARVIS_DRY_RUN:-1}" != 0 ]]; then info "SIMULASI: tidak ada partisi yang ditulis."; jeda; return; fi
 if konfirmasi "Saya sudah memverifikasi image dan partisi recovery. Lanjutkan?"; then "$FASTBOOT" -s "$s" flash recovery "$img"; local rc=$?; catat FLASH "serial=$s product=$product file=$img kode=$rc"; ((rc==0)) && sukses "Perintah selesai; recovery belum tentu dapat boot." || gagal "Flash gagal kode $rc"; fi
 jeda
}
rom_menu(){
 judul; echo "DAFTAR PERIKSA CUSTOM ROM"; echo "1. Cocokkan codename dengan panduan maintainer"; echo "2. Periksa firmware dasar dan recovery yang diwajibkan"; echo "3. Cadangkan data"; echo "4. Verifikasi SHA-256 dari sumber tepercaya"; echo "5. Jangan anggap semua ZIP dapat dipasang dengan cara sama"
 if konfirmasi "Hitung SHA-256 file .img di folder kerja?"; then local f; f="$(file_img)" && sha "$f"; fi; jeda
}
backup_menu(){
 judul; echo "Cadangan di versi ini terbatas pada metadata dan log, bukan partisi penuh."
 if konfirmasi "Simpan log sesi ke folder cadangan?"; then cp "$LOG" "$RUMAH/backups/log-$(date +%Y%m%d-%H%M%S).txt" && sukses "Log disalin."; fi; jeda
}
file_menu(){
 judul; ls -lh "$RUMAH/images" 2>/dev/null || true; echo "File kerja: $RUMAH/images"
 echo "1. Salin file ke folder images"; echo "2. Hitung SHA-256 file image"; echo "0. Kembali"; read -r -p "Pilih: " c || return
 case "$c" in
  1) local src; printf 'Lokasi file sumber: '; read -r src; if [[ -f "$src" ]] && konfirmasi "Salin tanpa menimpa file yang ada?"; then cp -n -- "$src" "$RUMAH/images/" && sukses "File disalin."; else gagal "File tidak ditemukan atau dibatalkan."; fi; jeda;;
  2) local f; f="$(file_img)" && sha "$f"; jeda;;
 esac
}
diagnostik(){
 judul; echo "Arsitektur host: $(uname -m)"; echo "Log: $LOG"; echo "Dependensi:"
 for c in "$ADB" "$FASTBOOT" sha256sum sha256 git; do if ada "$c"; then echo " [ADA] $c"; else echo " [TIDAK ADA] $c"; fi; done
 echo "Perangkat ADB:"; "$ADB" devices -l 2>&1 || true; echo "Perangkat Fastboot:"; "$FASTBOOT" devices 2>&1 || true; jeda
}
laporan(){
 judul; local f="$RUMAH/logs/laporan-servis-$(date +%Y%m%d-%H%M%S).txt"
 { echo "JARVIS.ID v$VERSI"; date; uname -m; echo "ADB:"; "$ADB" devices -l 2>&1 || true; echo "Fastboot:"; "$FASTBOOT" devices 2>&1 || true; } > "$f"
 sukses "Laporan disimpan: $f"; cat "$f"; jeda
}
pengaturan(){
 judul; echo "Versi: $VERSI"; echo "Folder kerja: $RUMAH"; echo "Mode simulasi flashing: ${JARVIS_DRY_RUN:-1}"; echo "Animasi: ${JARVIS_ANIMATION:-normal}"
 echo "Matikan animasi: JARVIS_ANIMATION=off"; echo "Percepat animasi: JARVIS_ANIMATION=fast"; echo "Mode simulasi aktif secara bawaan."
 jeda
}
menu(){
 while true; do judul; cat <<'M'
 1. Informasi Perangkat
 2. Peralatan ADB
 3. Peralatan Fastboot
 4. Asisten Buka Kunci Bootloader (UBL)
 5. Pasang TWRP / Pemulihan
 6. Persiapan Custom ROM
 7. Cadangan & Pemulihan Informasi
 8. Pengelola Berkas & SHA-256
 9. Diagnostik & Catatan
10. Laporan Servis
11. Pengaturan & Dependensi
12. Keluar
M
 printf '\nADB: '; ada "$ADB" && printf 'TERSEDIA' || printf 'TIDAK ADA'
 printf ' | Fastboot: '; ada "$FASTBOOT" && printf 'TERSEDIA\n' || printf 'TIDAK ADA\n'
 read -r -p "Pilih menu: " c || break
 case "$c" in
  1) info_perangkat;; 2) adb_menu;; 3) fastboot_menu;; 4) ubl;; 5) flash_recovery;; 6) rom_menu;; 7) backup_menu;; 8) file_menu;; 9) diagnostik;; 10) laporan;; 11) pengaturan;; 12|0) info "JARVIS.ID ditutup."; exit 0;; *) peringatan "Pilihan tidak tersedia."; jeda;;
 esac
 done
}
trap 'printf "\nDihentikan. Catatan: %s\n" "$LOG"; catat SISTEM "dihentikan oleh Ctrl+C"; exit 130' INT
catat MULAI "versi=$VERSI"
animasi
menu
