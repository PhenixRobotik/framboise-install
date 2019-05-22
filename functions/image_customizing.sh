#!/bin/env bash

custom_image_path() {
  user_home="$(as_user bash -c 'echo $HOME')"
  echo "${user_home}/.cache/custom_archlinuxarm.tar.bz2"
}


download_qemu() {
  info "Installing dependencies for chroot…"
  hash "apt-get"  && apt-get install qemu-arm-static
  ArchPackages=( arch-install-scripts qemu-arm-static )
  hash "yaourt"   && sudo -u "${SUDO_USER}" yaourt -S --noconfirm --needed "${ArchPackages[@]}"
  hash "trizen"   && sudo -u "${SUDO_USER}" trizen -S --noconfirm --needed "${ArchPackages[@]}"
  hash "yay"      && sudo -u "${SUDO_USER}" yay    -S --noconfirm --needed "${ArchPackages[@]}"
  # systemctl restart systemd-binfmt
  # update-binfmts --importdir /usr/lib/binfmt.d/ --enable arm

  info "Done."
}

prepare_install() {
  # Install qemu into the chroot
  cp "$(command -v qemu-arm-static)" "${root_mount}/usr/bin"

  # Allow access from chroot to our repository
  cp -Tr "${ScriptDir}" "root/repository"
  trap 'cleanupInstall' EXIT

  # Fix for ca-certificates not updating
  cp             "/etc/ca-certificates/extracted/tls-ca-bundle.pem" \
    "${root_mount}/etc/ca-certificates/extracted/tls-ca-bundle.pem"

  arch-chroot "${root_mount}" \
    /usr/bin/qemu-arm-static\
    /usr/bin/bash "/repository/archlinux_prepare_intochroot.sh"
}


compress_image() {
  tar_image="$(custom_image_path)"

  info "Compressing to ${tar_image}…"
  tar -C "${root_mount}"\
    --exclude='/tmp/*' \
    --exclude='/var/cache/pacman/pkg/' \
    --xattrs \
    -cjpvf \
    "${tar_image}" \
    "."
  info "Done."
}

setup_custom_image() {
  img_path="$(custom_image_path)"
}
