#!/bin/env bash

###############################################################################
# Umount sdcard if mounted

step_umount_device() {
  info 'Unmounting SD card…'

  blocks="$(lsblk "${SDCARD}" -ln -o PATH,MOUNTPOINT)"
  blocksmounted="$(echo "${blocks}" | awk '$2 {print $1,$2}')"
  blocksmpoints="$(echo "${blocksmounted}" | awk '{print $2}')"

  if echo "${blocksmpoints}" | grep -qw "^/" \
  || echo "${blocksmpoints}" | grep -qw "^/boot" \
  || echo "${blocksmpoints}" | grep -qw "^/home"
  then
    echo "${SDCARD} contains the system mounts ! Aborting."
    exit 1
  fi
  set -x
  echo "${blocksmounted}"
  while read -r blockmounted; do
    [[ -z "${blockmounted}" ]] && continue

    block="$(echo "${blockmounted}" | awk '{print $1}')"
    mountpoint="$(echo "${blockmounted}" | awk '{print $2}')"

    if [[ "${mountpoint}" == '[SWAP]' ]]; then
      swapoff "${block}"
    else
      umount "${mountpoint}"
    fi
    # shellcheck disable=SC2181
    if [[ ${?} -ne 0 ]]; then
      error "Impossible to umount ${mountpoint}... Exiting"
      exit 1
    fi
  done <<< "${blocksmounted}"

  info "Done."
  echo ""
}

###############################################################################
# Create partitions

step_partition_device() {
  info "Creating partitions on ${SDCARD}…"

  parted --script "${SDCARD}" mklabel msdos
  parted --script "${SDCARD}" mkpart primary fat32 0% 100M
  parted --script "${SDCARD}" mkpart primary ext4 100M 100%
  sync
  info "Done."

  detect_partitions

  info "Formating partitions…"
  mkfs.vfat "${boot_block}"
  mkfs.ext4 -F "${root_block}"
  sync
  info "Done."
}

detect_partitions() {
  # Getting new partition paths
  blocks="$(lsblk "${SDCARD}" -ln -o PATH,MOUNTPOINT | awk '{print $1}')"
  boot_block="$(echo "${blocks}" | grep "^${SDCARD}.*1$")"
  root_block="$(echo "${blocks}" | grep "^${SDCARD}.*2$")"
}
