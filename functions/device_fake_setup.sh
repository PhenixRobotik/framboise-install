#!/bin/env bash

create_fake_device() {
  info "Creating file for fake device…"
  user_home="$(as_user bash -c 'echo $HOME')"
  DeviceFile="${user_home}/.cache/lodevice.img"
  # 2GB file should be enough
  fallocate "${DeviceFile}" -l 4G
  # dd if="/dev/zero" of="${DeviceFile}" bs=100M count=20
  info "Done."
}

mount_fake_device() {
  info "Mounting fake device…"
  SDCARD="$(losetup -f)"
  losetup -P "${SDCARD}" "${DeviceFile}"
  info "Done."
}

create_and_mount_fake_device() {
  create_fake_device
  mount_fake_device
}

create_and_mount_fake_device_cleanup() {
  losetup -d "${SDCARD}" || true
}
