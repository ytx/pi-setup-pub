#!/bin/bash
# clone-dd: Clone boot SD card to another disk using dd
# Copies only up to the end of the last partition (not the full card)
# Usage: sudo clone-dd <destination-device> [new-hostname]
#   e.g. sudo clone-dd sdb
#   e.g. sudo clone-dd sdb raspi-02

set -e

DEST="$1"
NEW_HOSTNAME="$2"

if [ -z "$DEST" ]; then
    echo "Usage: sudo clone-dd <destination-device> [new-hostname]"
    echo "  e.g. sudo clone-dd sdb"
    echo "  e.g. sudo clone-dd sdb raspi-02"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

# Resolve device path
if [[ "$DEST" != /dev/* ]]; then
    DEST="/dev/$DEST"
fi

if [ ! -b "$DEST" ]; then
    echo "Error: $DEST is not a block device"
    exit 1
fi

# Source is always the boot device
SRC="/dev/mmcblk0"
if [ ! -b "$SRC" ]; then
    echo "Error: boot device $SRC not found"
    exit 1
fi

# Prevent cloning to the boot device
if [ "$DEST" = "$SRC" ]; then
    echo "Error: destination is the same as the boot device"
    exit 1
fi

# Get end sector of the last partition
END_SECTOR=$(fdisk -l "$SRC" | awk '/^\/dev\// { end=$3 } END { print end }')

if [ -z "$END_SECTOR" ] || [ "$END_SECTOR" -le 0 ] 2>/dev/null; then
    echo "Error: could not determine last partition end sector"
    exit 1
fi

# Add 1 to include the last sector
TOTAL_SECTORS=$((END_SECTOR + 1))
TOTAL_BYTES=$((TOTAL_SECTORS * 512))
TOTAL_MB=$((TOTAL_BYTES / 1024 / 1024))

# Check destination size
DEST_BYTES=$(blockdev --getsize64 "$DEST")
DEST_MB=$((DEST_BYTES / 1024 / 1024))

if [ "$DEST_BYTES" -lt "$TOTAL_BYTES" ]; then
    echo "Error: destination too small (${DEST_MB}MB < ${TOTAL_MB}MB needed)"
    exit 1
fi

echo "Source:      $SRC"
echo "Destination: $DEST"
echo "Copy size:   ${TOTAL_MB}MB (${TOTAL_SECTORS} sectors)"
echo ""
echo "WARNING: All data on $DEST will be destroyed!"
read -p "Continue? (y/N) " -r
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
dd if="$SRC" of="$DEST" bs=4M iflag=count_bytes count="$TOTAL_BYTES" status=progress

# Flush
sync

echo ""
echo "Done: cloned ${TOTAL_MB}MB to $DEST"

# Rename hostname if specified
if [ -n "$NEW_HOSTNAME" ]; then
    echo ""
    clone-rename "$DEST" "$NEW_HOSTNAME"
fi
