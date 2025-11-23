#!/bin/bash
set -e  # Exit immediately on any error

# VARIABLES
PVS=("/dev/vdc" "/dev/vdd")       # Initial disks for LVM
NEW_DISK="/dev/vde"               # Disk used for extending VG
VG_NAME="vgdata"                  # Volume Group name
LV_NAME="lvdata"                  # Logical Volume name
LV_SIZE="1.5G"                     # Initial size of LV
MOUNT_POINT="/mnt/lvmdata"        # Mount location

create_lvm() {
  echo "Creating LVM setup..."

  echo "Step 1: Creating Physical Volumes..."
  for PV in "${PVS[@]}"; do
    sudo pvcreate "$PV"           # Mark disk for LVM usage
  done
  sudo pvs

  echo "Step 2: Creating Volume Group $VG_NAME..."
  sudo vgcreate "$VG_NAME" "${PVS[@]}"   # Combine disks into VG
  sudo vgs

  echo "Step 3: Creating Logical Volume $LV_NAME..."
  sudo lvcreate -L "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"   # Create LV inside VG
  sudo lvs

  echo "Step 4: Formatting and Mounting..."
  LV_PATH="/dev/${VG_NAME}/${LV_NAME}"
  sudo mkfs.xfs -f "$LV_PATH"     # Format LV with XFS
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount "$LV_PATH" "$MOUNT_POINT"

  echo "Mount successful at $MOUNT_POINT"
  df -h | grep "$LV_NAME"

  UUID=$(sudo blkid -s UUID -o value "$LV_PATH")
  echo "# UUID=<UUID>  <mount>  <fstype>  <options>  <dump>  <fsck>"
  echo "UUID=${UUID}  $MOUNT_POINT  xfs  defaults  0 2" | sudo tee -a /etc/fstab
  echo "Persistent mount entry added."
}

extend_lvm() {
  echo "Extending LVM with new disk $NEW_DISK..."

  echo "Step 1: Adding new disk as Physical Volume..."
  sudo pvcreate "$NEW_DISK"
  sudo vgextend "$VG_NAME" "$NEW_DISK"
  sudo vgs

  echo "Step 2: Extending Logical Volume by 20M..."
  LV_PATH="/dev/${VG_NAME}/${LV_NAME}"
  sudo lvextend -L +0.8G "$LV_PATH"
  sudo xfs_growfs "$MOUNT_POINT"

  echo "Extension complete."
  sudo lvs
  df -h | grep "$LV_NAME"
}

verify_lvm() {
  echo "Verifying current LVM setup..."
  sudo pvs
  sudo vgs
  sudo lvs
  echo
  df -h | grep "$LV_NAME"
}

cleanup_lvm() {
  echo "Cleaning up LVM setup..."

  LV_PATH="/dev/${VG_NAME}/${LV_NAME}"

  echo "Unmounting LV..."
  sudo umount "$MOUNT_POINT" || true

  echo "Removing fstab entry..."
  sudo sed -i "\|$MOUNT_POINT|d" /etc/fstab

  echo "Removing LV, VG, and PVs..."
  sudo lvremove -y "$LV_PATH" || true
  sudo vgremove -y "$VG_NAME" || true

  for PV in "${PVS[@]}" "$NEW_DISK"; do
    sudo pvremove -y "$PV" || true
  done

  echo "Deleting mount directory..."
  sudo rm -rf "$MOUNT_POINT"

  echo "Cleanup complete."
}

show_help() {
  echo "Usage: $0 [create|extend|verify|cleanup]"
  echo
  echo "  create   - Create full LVM stack (PV → VG → LV → FS → Mount)"
  echo "  extend   - Extend existing LV using new disk ($NEW_DISK)"
  echo "  verify   - Display LVM and mount status"
  echo "  cleanup  - Remove everything created by this script"
  echo
  echo "Example:"
  echo "  sudo $0 create"
  echo "  sudo $0 extend"
  echo "  sudo $0 verify"
  echo "  sudo $0 cleanup"
}

case "$1" in
  create)
    create_lvm
    ;;
  extend)
    extend_lvm
    ;;
  verify)
    verify_lvm
    ;;
  cleanup)
    cleanup_lvm
    ;;
  *)
    show_help
    ;;
esac