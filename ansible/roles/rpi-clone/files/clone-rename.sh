#!/bin/bash
# clone-rename: Change hostname on a cloned SD card
# Usage: sudo clone-rename <device> <new-hostname>
#   e.g. sudo clone-rename sda raspi-02

set -e

DEVICE="$1"
NEW_HOSTNAME="$2"

if [ -z "$DEVICE" ] || [ -z "$NEW_HOSTNAME" ]; then
    echo "Usage: sudo clone-rename <device> <new-hostname>"
    echo "  e.g. sudo clone-rename sda raspi-02"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

# Resolve device path
if [[ "$DEVICE" != /dev/* ]]; then
    DEVICE="/dev/$DEVICE"
fi

# Find root partition (partition 2)
if [[ "$DEVICE" == *"mmcblk"* ]] || [[ "$DEVICE" == *"nvme"* ]]; then
    ROOT_PART="${DEVICE}p2"
    BOOT_PART="${DEVICE}p1"
else
    ROOT_PART="${DEVICE}2"
    BOOT_PART="${DEVICE}1"
fi

if [ ! -b "$ROOT_PART" ]; then
    echo "Error: $ROOT_PART not found"
    exit 1
fi

MOUNT_ROOT=$(mktemp -d)
MOUNT_BOOT=$(mktemp -d)

cleanup() {
    umount "$MOUNT_ROOT" 2>/dev/null || true
    umount "$MOUNT_BOOT" 2>/dev/null || true
    rmdir "$MOUNT_ROOT" 2>/dev/null || true
    rmdir "$MOUNT_BOOT" 2>/dev/null || true
}
trap cleanup EXIT

# Mount partitions
mount "$ROOT_PART" "$MOUNT_ROOT"
mount "$BOOT_PART" "$MOUNT_BOOT"

# Get current hostname
OLD_HOSTNAME=$(cat "$MOUNT_ROOT/etc/hostname" | tr -d '[:space:]')
echo "Renaming: $OLD_HOSTNAME -> $NEW_HOSTNAME"

# /etc/hostname
echo "$NEW_HOSTNAME" > "$MOUNT_ROOT/etc/hostname"

# /etc/hosts
sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" "$MOUNT_ROOT/etc/hosts"

# /boot/firmware/user-data (cloud-init)
if [ -f "$MOUNT_BOOT/user-data" ]; then
    sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" "$MOUNT_BOOT/user-data"
    echo "Updated: /boot/firmware/user-data"
fi

echo "Done: $NEW_HOSTNAME"
