#!/bin/env bash

# Some basic utilitary functions


info()    { printf '\e[0;32m[INFO] %s\e[0m\n' "$@"; }
warning() { printf '\e[0;35m[WARNING] %s\e[0m\n' "$@"; }
error()   { printf '\e[0;31m[ERROR] %s\e[0m\n' "$@"; }


test_sudo() {
  if [[ "${UID}" -ne 0 ]]; then
   warning 'You need to run this program as root or via sudo… Elevating now.'
   exec sudo "$0" "$@"
  fi
}

as_user() {
  sudo -u "${SUDO_USER}" "$@";
}



prompt_device() {
  if [[ -z "${SDCARD:-}" ]]; then
    read -r -p "Please enter your sdcard device name [sdb]: " SDCARD
  fi

  SDCARD="${SDCARD:-/dev/sdb}"
  if [[ "${SDCARD}" != /dev/* ]]; then
    SDCARD="/dev/$SDCARD"
  fi

  if [[ ! -b "${SDCARD}" ]]; then
    error "${SDCARD} not found as valid block device :( Exiting..."
    exit 1
  fi
}

prompt_confirmation() {
  warning    "This program will FORMAT ${SDCARD}."
  read -r -p "Are you sure you want to continue? (y/n): " CONTINUE

  if [[ "${CONTINUE^^}" != "Y" ]]; then
    info "Exiting. Have a good day!"
    exit 0
  fi
}

step_flash_finish() {
  sync
  info "Everything looks good! Insert the sdcard in you RaspberryPi and have fun!"
}
