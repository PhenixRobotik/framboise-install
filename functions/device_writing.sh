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

step_extract_dd_image_to_file() {
  info "Extracting ${img_path}..."

  mkdir -p "${FunctionsDir}/../cache"
  unzip -o "${img_path}" -d "${FunctionsDir}/../cache"

  DeviceFile="$(find "${FunctionsDir}/../cache" -name "*.img")"

  mount_fake_device
  detect_partitions
}

step_write_dd_image_to_disk() {
  info "Writing dd image ${img_path} to ${SDCARD}..."

  dd if="${img_path}" of="${SDCARD}" \
    bs=4M conv=fsync \
    status=progress

  info "Syncing... (this might take a while)"
  sync

  info "Done!"
}
