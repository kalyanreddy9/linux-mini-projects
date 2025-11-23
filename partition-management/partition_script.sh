#!/bin/bash
set -e  # Exit on any error

# VARIABLES
DISK="/dev/vdb"           # Target disk (update to your unused disk)
MOUNT1="/mnt/data1"
MOUNT2="/mnt/data2"

# Partition layout
# 0–1MiB   → Reserved for GPT/bootloader alignment
# 1–11MiB  → Partition 1 (10 MiB)
# 11–31MiB → Partition 2 (20 MiB)
SIZE1_START="1MiB"
SIZE1_END="11MiB"
SIZE2_END="31MiB"

# -------------------------------------------------------------------
# FUNCTIONS
# -------------------------------------------------------------------

create_partitions() {
  if [ ! -b "$DISK" ]; then
    echo "Error: Disk $DISK not found."
    exit 1
  fi

  echo "Disk detected: $DISK"
  lsblk "$DISK"
  sleep 1

  echo "Creating GPT partition table..."
  sudo parted -s "$DISK" mklabel gpt

  echo "Creating partitions..."
  sudo parted -s "$DISK" mkpart primary ext4 "$SIZE1_START" "$SIZE1_END"
  sudo parted -s "$DISK" mkpart primary xfs  "$SIZE1_END" "$SIZE2_END"
  sudo parted -s "$DISK" print
  sleep 1

  echo "Formatting partitions..."
  sudo mkfs.ext4 "${DISK}1"
  sudo mkfs.xfs  "${DISK}2"
  sudo blkid "${DISK}1"
  sudo blkid "${DISK}2"
  sleep 1

  echo "Creating mount directories..."
  sudo mkdir -p "$MOUNT1" "$MOUNT2"

  echo "Mounting partitions..."
  sudo mount "${DISK}1" "$MOUNT1"
  sudo mount "${DISK}2" "$MOUNT2"
  df -h | grep "$(basename "$DISK")"
  sleep 1

  echo "Updating /etc/fstab with UUIDs..."
  UUID1=$(sudo blkid -s UUID -o value "${DISK}1")
  UUID2=$(sudo blkid -s UUID -o value "${DISK}2")
  echo "UUID=${UUID1}  $MOUNT1  ext4  defaults  0 2" | sudo tee -a /etc/fstab
  echo "UUID=${UUID2}  $MOUNT2  xfs   defaults  0 2" | sudo tee -a /etc/fstab
  tail -n 5 /etc/fstab

  echo "Validating mount consistency..."
  sudo umount "$MOUNT1" "$MOUNT2"
  sudo mount -a
  df -h | grep "$(basename "$DISK")"

  echo "Disk partitioning and persistence verified successfully."
  sudo parted -s "$DISK" print
}

cleanup_partitions() {
  echo "Running cleanup for $DISK"
  read -rp "Are you sure you want to cleanup (this will wipe $DISK)? [y/N]: " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Cleanup aborted."
    exit 0
  fi

  for MNT in "$MOUNT1" "$MOUNT2"; do
    if mount | grep -q "on $MNT "; then
      echo "Unmounting $MNT..."
      sudo umount "$MNT"
    fi
  done

  echo "Removing /etc/fstab entries..."
  sudo sed -i "\|$MOUNT1|d" /etc/fstab
  sudo sed -i "\|$MOUNT2|d" /etc/fstab

  echo "Deleting partitions from $DISK..."
  sudo parted -s "$DISK" mklabel gpt  # resets partition table

  echo "Removing mount directories..."
  sudo rm -rf "$MOUNT1" "$MOUNT2"

  echo "Cleanup completed. $DISK is reset to a blank GPT state."
}

show_help() {
  echo "Usage: $0 [create|cleanup]"
  echo
  echo "  create   - Create partitions, format, mount, and persist them"
  echo "  cleanup  - Unmount, remove /etc/fstab entries, and wipe disk"
  echo
  echo "Example:"
  echo "  sudo $0 create"
  echo "  sudo $0 cleanup"
}

# -------------------------------------------------------------------
# MAIN EXECUTION
# -------------------------------------------------------------------
case "$1" in
  create)
    create_partitions
    ;;
  cleanup)
    cleanup_partitions
    ;;
  *)
    show_help
    ;;
esac
