#!/bin/env bash

download_qemu() {
  info "Installing dependencies for chroot…"
  hash "apt-get" && apt-get install qemu-arm-static
  ArchPackages=( arch-install-scripts qemu-arm-static )
  sudo -u "${SUDO_USER}" yay -S --noconfirm --needed "${ArchPackages[@]}"
  info "Done."
}

compress_image() {
  tar_image="${CacheDir}/custom_raspberrypi.tar.bz2"

  info "Compressing to ${tar_image}…"
  tar -C "${root_mount}"\
    --exclude='/tmp/*' \
    --exclude='/var/cache/pacman/pkg/' \
    --xattrs \
    -cjpvf \
    "${tar_image}" \
    "${root_mount}"
  info "Done."
}

prepare_install() {
  # Install qemu into the chroot
  cp "$(command -v qemu-arm-static)" "${root_mount}/usr/bin"

  pre_chroot_file="${CustomizationsDir}/pre_chroot_${distro}.sh"
  in_chroot_file="${CustomizationsDir}/in_chroot_${distro}.sh"

  if [[ -f "${pre_chroot_file}" ]]; then
    source "${pre_chroot_file}"
  fi

  if [[ -f "${in_chroot_file}" ]]; then
    cp "${in_chroot_file}" "${root_mount}/in_chroot.sh"
    chmod +x "${root_mount}/in_chroot.sh"
    arch-chroot "${root_mount}" /bin/bash "/in_chroot.sh" || true
  else
    arch-chroot "${root_mount}" /bin/bash || true
  fi
}
