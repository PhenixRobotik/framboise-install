#!/bin/env bash

step_mount_device() {
  root_mount="/mnt/raspberrypi/root"
  # Bsdtar does not like to extract to fat32, so we'll need to mount separately
  if [[ -n "${SEPARATED_TREE:-}" ]]; then
    boot_mount="/tmp/raspberrypi/boot"
  else
    boot_mount="${root_mount}/boot"
  fi

  info 'Mounting…'
  mkdir -p "${root_mount}"
  mount "${root_block}" "${root_mount}"
  mkdir -p "${boot_mount}"
  mount "${boot_block}" "${boot_mount}"

  sync
}

step_mount_device_cleanup() {
  umount --recursive "${boot_mount}" || true
  umount --recursive "${root_mount}" || true
}
