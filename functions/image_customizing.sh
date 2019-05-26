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

  pre_chroot_file="${CustomizationsDir}/${distro}_pre.sh"
  in_chroot_files="${CustomizationsDir}/${distro}_files"

  if [[ -f "${pre_chroot_file}" ]]; then
    source "${pre_chroot_file}"
  fi

  cp -R "${in_chroot_files}" "${root_mount}/tmp/customize"
  chmod +x "${root_mount}/tmp/customize/customize.sh"
  arch-chroot "${root_mount}" /bin/bash "/tmp/customize/customize.sh" || true
}
