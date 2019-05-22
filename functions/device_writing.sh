#!/bin/env bash

###############################################################################
# Write the files to the disk

step_extract_to_disk() {
  SEPARATED_TREE=true step_mount_device

  info "Extracting files into ${root_mount}..."
  bsdtar -xpf "${img_path}" -C "${root_mount}"
  info "Syncing... (this might take a while)"
  sync

  info "Copying boot into ${boot_mount}"
  rsync -a --remove-source-files "${root_mount}/boot/" "${boot_mount}/"
  find "${root_mount}/boot/" -depth -type d -empty -delete
  sync "${boot_mount}" "${root_mount}"

  # step_umount_device
}
