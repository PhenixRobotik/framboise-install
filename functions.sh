#!/bin/bash

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
  if [[ -z "${SDCARD}" ]]; then
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
  echo       "This program will FORMAT and INSTALL ArchLinuxARM on ${SDCARD}."
  read -r -p "Are you sure you want to continue? (y/n): " CONTINUE

  if [[ "${CONTINUE^^}" != "Y" ]]; then
    info "Exiting. Have a good day!"
    exit 0
  fi
}

prompt_raspberry_pi_image() {
  if [[ -z "${rpi_version}" ]]; then
    read -r -p "Please enter your RaspberryPi version number [2/default=3]: " rpi_version
  fi


  case "${rpi_version}" in
    "2"     ) img_name='ArchLinuxARM-rpi-2-latest.tar.gz' ;;
    "3"|""  ) img_name='ArchLinuxARM-rpi-3-latest.tar.gz' ;;
    *) error "Unknown version ${rpi_version}. Exiting." ; exit 1 ;;
  esac

  echo ""
}

###############################################################################
# Downloading the image

dodownload() {
   # as_user wget --continue --show-progress --progress=bar:force "$1" -O "$2"
   :
}

md5check() {
  pushd "${download_path}" >/dev/null || return 1
  if md5sum --status -c "${md5_path}"; then err=0; else err=1; fi
  popd >/dev/null || return 1
  return $err
}

step_download_image() {
  img_url="http://os.archlinuxarm.org/os/${img_name}"
  md5_url="http://os.archlinuxarm.org/os/${img_name}.md5"

  # shellcheck disable=SC2016
  user_home="$(as_user bash -c 'echo $HOME')"
  download_path="${user_home}/.cache"
  img_path="${download_path}/${img_name}"
  md5_path="${download_path}/${img_name}.md5"

  info "Downloading MD5 sum file of ArchLinuxARM from ${md5_url}"
  dodownload "${md5_url}" "${md5_path}"
  info "Done."

  info "Downloading latest version of ArchLinuxARM from ${img_url}"
  info "Tip : restarting the script will continue the download where it stopped."
  dodownload "${img_url}" "${img_path}"
  info "Done."


  info "Checking the md5 sum…"
  if ! md5check; then
    rm -rf "${img_path}" "${md5_path}"
    error "Downloading failed : MD5 sum does not match."
    error "Please check your connection and restart the script or run:"
    error "    wget ${img_url} -O ${img_path}"

    exit 1
  fi
  info "Done."
  echo ""
}

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

  sfdisk_input="
  label: dos
  name=boot, size= 100MiB, type=c
  name=root,               type=83
  "

  echo "${sfdisk_input}" | \
  sfdisk "${SDCARD}" -W always
  sync
  info "Done."

  # Getting new partition paths
  blocks="$(lsblk "${SDCARD}" -ln -o PATH,MOUNTPOINT | awk '{print $1}')"
  boot_block="$(echo "${blocks}" | grep "^${SDCARD}.*1$")"
  root_block="$(echo "${blocks}" | grep "^${SDCARD}.*2$")"

  info "Formating partitions…"
  mkfs.vfat "${boot_block}"
  mkfs.ext4 -F "${root_block}"
  sync
  info "Done."
}

step_mount_device() {
  root_mount="/tmp/raspberrypi/root"
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

step_flash_finish() {
  sync
  info "Everything looks good! Insert the sdcard in you RaspberryPi and have fun!"
}

###############################################################################
# Generate custom image

create_and_mount_fake_device() {
  info "Creating file for fake device…"
  user_home="$(as_user bash -c 'echo $HOME')"
  DeviceFile="${user_home}/.cache/lodevice.img"
  # 2GB file should be enough
  fallocate "${DeviceFile}" -l 2G
  # dd if="/dev/zero" of="${DeviceFile}" bs=100M count=20
  info "Done."

  info "Mounting fake device…"
  SDCARD="$(losetup -f)"
  losetup "${SDCARD}" "${DeviceFile}"
  info "Done."
}

download_qemu() {
  info "Installing dependencies for chroot…"
  hash "apt-get"  && apt-get install qemu-arm-static
  ArchPackages=( binfmt-qemu-static qemu-arm-static arch-install-scripts )
  hash "yaourt"   && sudo -u "${SUDO_USER}" yaourt -S --noconfirm --needed "${ArchPackages[@]}"
  hash "trizen"   && sudo -u "${SUDO_USER}" trizen -S --noconfirm --needed "${ArchPackages[@]}"
  hash "yay"      && sudo -u "${SUDO_USER}" yay    -S --noconfirm --needed "${ArchPackages[@]}"
  update-binfmts --importdir /usr/lib/binfmt.d/ --enable arm

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
  user_home="$(as_user bash -c 'echo $HOME')"
  tar_image="${user_home}/.cache/custom_archlinuxarm.tar.bz2"

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
