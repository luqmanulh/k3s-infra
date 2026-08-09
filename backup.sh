#!/bin/bash
# Script Backup Sederhana untuk K3s (Single Node)
# Harus dijalankan dengan akses root (sudo)

set -e

BACKUP_DIR="/root/k3s-backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
CURRENT_BACKUP="$BACKUP_DIR/$DATE"

echo "Memulai proses backup ke $CURRENT_BACKUP..."
mkdir -p "$CURRENT_BACKUP"

# 1. Backup state Kubernetes (Jika menggunakan SQLite default k3s)
if [ -d "/var/lib/rancher/k3s/server/db/" ]; then
    echo "Backup K3s State (Database)..."
    # Menyalin database utama k3s
    cp -r /var/lib/rancher/k3s/server/db "$CURRENT_BACKUP/k3s-db-state"
fi

# 2. Backup Persistent Volumes (Data Aplikasi: Forgejo, Traefik, dsb)
if [ -d "/var/lib/rancher/k3s/storage/" ]; then
    echo "Backup Application Data (Persistent Volumes)..."
    # Mengarsipkan seluruh data aplikasi ke dalam tar.gz
    tar -czf "$CURRENT_BACKUP/app-data.tar.gz" -C /var/lib/rancher/k3s/ storage/
fi

# 3. Backup file konfigurasi (opsional namun penting)
echo "Backup Kustomize & Environment lokal..."
mkdir -p "$CURRENT_BACKUP/config"
cp -r /home/lnh/dev/k3s-infra/* "$CURRENT_BACKUP/config/" || true
cp /home/lnh/dev/k3s-infra/.env* "$CURRENT_BACKUP/config/" 2>/dev/null || true

# 4. Kompresi akhir
echo "Mengompresi semua hasil backup..."
cd $BACKUP_DIR
tar -czf "k3s-full-backup-$DATE.tar.gz" "$DATE"
rm -rf "$DATE"

echo "=== Backup Selesai! ==="
echo "File backup Anda tersimpan di: $BACKUP_DIR/k3s-full-backup-$DATE.tar.gz"
