#!/bin/bash
# Script Backup untuk K3s (Single Node)
# Harus dijalankan dengan akses root (sudo)

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Gagal: Jalankan script ini dengan sudo / root."
    exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "sqlite3 belum terpasang, menginstall sqlite3..."
        apt-get update -qq && apt-get install -y -qq sqlite3
    else
        echo "Gagal: sqlite3 belum terpasang. Install dulu secara manual."
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
BACKUP_DIR="${BACKUP_DIR:-$TARGET_HOME/k3s-backups}"
RETENTION_COUNT="${RETENTION_COUNT:-5}"
INFRA_DIR="${INFRA_DIR:-$SCRIPT_DIR}"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
CURRENT_BACKUP="$BACKUP_DIR/$DATE"

cleanup() {
    rm -rf "$CURRENT_BACKUP"
}
trap cleanup EXIT

echo "Memulai proses backup ke $CURRENT_BACKUP..."
mkdir -p "$CURRENT_BACKUP"

# 1. Backup state Kubernetes & kredensial cluster K3s
if [ -f "/var/lib/rancher/k3s/server/db/state.db" ]; then
    echo "1. Backup K3s State (Database) menggunakan sqlite3..."
    mkdir -p "$CURRENT_BACKUP/k3s-db-state"
    sqlite3 /var/lib/rancher/k3s/server/db/state.db ".backup '$CURRENT_BACKUP/k3s-db-state/state.db'"
fi

echo "2. Backup K3s server TLS, cred, dan token..."
mkdir -p "$CURRENT_BACKUP/k3s-server-creds"
for item in tls cred token; do
    if [ -e "/var/lib/rancher/k3s/server/$item" ]; then
        cp -a "/var/lib/rancher/k3s/server/$item" "$CURRENT_BACKUP/k3s-server-creds/"
    fi
done

# 2. Backup Persistent Volumes (Data Aplikasi: Forgejo, Traefik, Uptime Kuma, dll.)
if [ -d "/var/lib/rancher/k3s/storage" ]; then
    echo "3. Backup konsisten database SQLite di dalam PV..."
    while IFS= read -r -d '' db_file; do
        # Pastikan file benar-benar SQLite 3 (bukan BoltDB/BerkeleyDB/file kosong)
        if head -c 15 "$db_file" 2>/dev/null | grep -qx "SQLite format 3"; then
            rel_path="${db_file#/var/lib/rancher/k3s/storage/}"
            dest_file="$CURRENT_BACKUP/pv-sqlite/$rel_path"
            mkdir -p "$(dirname "$dest_file")"
            echo "   -> $rel_path"
            sqlite3 "$db_file" ".backup '$dest_file'"
        fi
    done < <(find /var/lib/rancher/k3s/storage -type f -name "*.db" -print0)

    echo "4. Mengarsipkan Application Data (Persistent Volumes)..."
    # Pakai .tar tanpa gzip agar tidak terjadi kompresi ganda pada langkah akhir
    tar -cf "$CURRENT_BACKUP/app-data.tar" -C /var/lib/rancher/k3s/ storage/
fi

# 3. Backup file konfigurasi & environment lokal
if [ -d "$INFRA_DIR" ]; then
    echo "5. Backup Kustomize & Environment lokal..."
    mkdir -p "$CURRENT_BACKUP/config"
    tar -cf - --exclude=".git" -C "$INFRA_DIR" . | tar -xf - -C "$CURRENT_BACKUP/config/"
fi

# 4. Kompresi akhir (satu kali) & rotasi backup lama
echo "6. Mengompresi hasil backup..."
ARCHIVE_PATH="$BACKUP_DIR/k3s-full-backup-$DATE.tar.gz"
tar -czf "$ARCHIVE_PATH" -C "$BACKUP_DIR" "$DATE"
chmod 700 "$BACKUP_DIR"
chmod 600 "$ARCHIVE_PATH"
chown "$TARGET_USER:$TARGET_USER" "$BACKUP_DIR" "$ARCHIVE_PATH"

echo "7. Membersihkan backup lama (menyimpan $RETENTION_COUNT backup terbaru)..."
ls -1t "$BACKUP_DIR"/k3s-full-backup-*.tar.gz 2>/dev/null | tail -n +$((RETENTION_COUNT + 1)) | xargs -r rm -f

echo "=== Backup Selesai! ==="
echo "File backup tersimpan di: $ARCHIVE_PATH"
echo "Catatan: Salin file ini ke luar VPS (scp/rsync/rclone) untuk cadangan off-site."
