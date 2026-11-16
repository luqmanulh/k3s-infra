#!/bin/bash
# Script Restore untuk K3s (Single Node)
# Harus dijalankan dengan akses root (sudo)
# PENGGUNAAN: sudo ./restore.sh /path/ke/k3s-full-backup-TANGGAL.tar.gz

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Gagal: Jalankan script ini dengan sudo / root."
    exit 1
fi

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Gagal: Anda harus menyertakan file backup!"
    echo "Contoh: sudo ./restore.sh /root/k3s-backups/k3s-full-backup-2026-07-07_12-00-00.tar.gz"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Gagal: File $BACKUP_FILE tidak ditemukan!"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "1. Mengekstrak file utama ke folder sementara ($TEMP_DIR)..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
EXTRACTED_DIR=$(ls -1 "$TEMP_DIR" | head -n 1)
BACKUP_ROOT="$TEMP_DIR/$EXTRACTED_DIR"

echo "2. Mematikan service K3s (mencegah data korup saat restore)..."
systemctl stop k3s

echo "3. Me-restore Kubernetes State Database..."
if [ -d "$BACKUP_ROOT/k3s-db-state" ]; then
    mkdir -p /var/lib/rancher/k3s/server/db
    rm -rf /var/lib/rancher/k3s/server/db/*
    cp -a "$BACKUP_ROOT/k3s-db-state/"* /var/lib/rancher/k3s/server/db/
else
    echo "Peringatan: K3s DB State tidak ditemukan di file backup."
fi

echo "4. Me-restore K3s server TLS, cred, dan token (jika tersedia)..."
if [ -d "$BACKUP_ROOT/k3s-server-creds" ]; then
    for item in tls cred token; do
        if [ -e "$BACKUP_ROOT/k3s-server-creds/$item" ]; then
            rm -rf "/var/lib/rancher/k3s/server/$item"
            cp -a "$BACKUP_ROOT/k3s-server-creds/$item" /var/lib/rancher/k3s/server/
        fi
    done
fi

echo "5. Me-restore Application Data (Persistent Volumes)..."
if [ -f "$BACKUP_ROOT/app-data.tar" ]; then
    rm -rf /var/lib/rancher/k3s/storage/*
    tar -xf "$BACKUP_ROOT/app-data.tar" -C /var/lib/rancher/k3s/
elif [ -f "$BACKUP_ROOT/app-data.tar.gz" ]; then
    # Kompatibel dengan format backup lama
    rm -rf /var/lib/rancher/k3s/storage/*
    tar -xzf "$BACKUP_ROOT/app-data.tar.gz" -C /var/lib/rancher/k3s/
else
    echo "Peringatan: app-data.tar(.gz) tidak ditemukan di file backup."
fi

if [ -d "$BACKUP_ROOT/pv-sqlite" ]; then
    echo "6. Menimpa database SQLite PV dengan snapshot konsisten..."
    while IFS= read -r -d '' snap_db; do
        rel_path="${snap_db#$BACKUP_ROOT/pv-sqlite/}"
        target_db="/var/lib/rancher/k3s/storage/$rel_path"
        if [ -f "$target_db" ]; then
            uid_gid=$(stat -c "%u:%g" "$target_db")
            cp -f "$snap_db" "$target_db"
            chown "$uid_gid" "$target_db"
        else
            mkdir -p "$(dirname "$target_db")"
            cp -f "$snap_db" "$target_db"
        fi
        # Hapus file WAL/SHM lama agar SQLite memakai snapshot bersih
        rm -f "${target_db}-wal" "${target_db}-shm"
    done < <(find "$BACKUP_ROOT/pv-sqlite" -type f -name "*.db" -print0)
fi

echo "7. Menyalakan kembali service K3s..."
systemctl start k3s

echo "=== Restore Selesai! ==="
echo "Mohon tunggu beberapa menit hingga Kubernetes selesai booting dan mengaktifkan kembali semua Pod."
