#!/bin/bash
# Script Restore Sederhana untuk K3s (Single Node)
# Harus dijalankan dengan akses root (sudo)
# PENGGUNAAN: sudo ./restore.sh /path/ke/k3s-full-backup-TANGGAL.tar.gz

set -e

BACKUP_FILE=$1

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
echo "1. Mengekstrak file utama ke folder sementara ($TEMP_DIR)..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
EXTRACTED_DIR=$(ls "$TEMP_DIR" | head -n 1)

echo "2. Mematikan service K3s (PENTING untuk mencegah data korup saat di-restore)..."
systemctl stop k3s

echo "3. Me-restore Kubernetes State Database..."
if [ -d "$TEMP_DIR/$EXTRACTED_DIR/k3s-db-state" ]; then
    # Hapus DB lama, timpa dengan backup
    rm -rf /var/lib/rancher/k3s/server/db/*
    cp -r $TEMP_DIR/$EXTRACTED_DIR/k3s-db-state/* /var/lib/rancher/k3s/server/db/
else
    echo "Peringatan: K3s DB State tidak ditemukan di file backup."
fi

echo "4. Me-restore Application Data (Persistent Volumes)..."
if [ -f "$TEMP_DIR/$EXTRACTED_DIR/app-data.tar.gz" ]; then
    # Hapus storage lama (opsional, tapi disarankan agar bersih 100% sama dengan backup)
    # Peringatan: Ini menghapus data yang ada sekarang!
    rm -rf /var/lib/rancher/k3s/storage/*
    
    # Ekstrak data backup ke folder storage
    tar -xzf "$TEMP_DIR/$EXTRACTED_DIR/app-data.tar.gz" -C /var/lib/rancher/k3s/
else
    echo "Peringatan: app-data.tar.gz tidak ditemukan di file backup."
fi

echo "5. Menghapus file sementara..."
rm -rf "$TEMP_DIR"

echo "6. Menyalakan kembali service K3s..."
systemctl start k3s

echo "=== Restore Selesai! ==="
echo "Mohon tunggu beberapa menit hingga Kubernetes selesai booting dan mengaktifkan kembali semua Pod."
