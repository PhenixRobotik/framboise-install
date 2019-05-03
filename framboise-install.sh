#!/bin/bash -e

# Taken from https://github.com/danifr/miscellaneous
# Daniel Fernandez Rodriguez <gmail.com daferoes>

info()    { printf '\e[0;32m[INFO] %s\e[0m\n' "$@"; }
warning() { printf '\e[0;35m[WARNING] %s\e[0m\n' "$@"; }
error()   { printf '\e[0;31m[ERROR] %s\e[0m\n' "$@"; }

if [[ "${UID}" -ne 0 ]]; then
 warning 'You need to run this program as root or via sudo… Elevating now.'
 exec sudo "$0" "$@"
fi

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║  Welcome! This program will automate the installation of  ║'
echo '║          ArchLinuxARM on your microSD card.               ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'


read -r -p "Please enter your sdcard device name [sdb]: " SDCARD
SDCARD="${SDCARD:-/dev/sdb}"
if [[ "${SDCARD}" != /dev/* ]]; then
  SDCARD="/dev/$SDCARD"
fi
if [[ ! -b "${SDCARD}" ]]; then
 error "${SDCARD} not found as valid block device :( Exiting..."
 exit 1
fi


read -r -p "This program will FORMAT and INSTALL ArchLinuxARM on ${SDCARD}. \
Are you sure you want to continue? (y/n): " CONTINUE

if [[ "${CONTINUE^^}" != "Y" ]]; then
  info "Exiting. Have a good day!"
  exit 0
fi


read -r -p "Please enter your RaspberryPi version number [2/default=3]: " rpi_version

case "${rpi_version}" in
  "2"     ) img_name='ArchLinuxARM-rpi-2-latest.tar.gz' ;;
  "3"|""  ) img_name='ArchLinuxARM-rpi-3-latest.tar.gz' ;;
  *) echo "Unknown version ${rpi_version}. Exiting." ; exit 1 ;;
esac

echo ""

###############################################################################
# Actually do some work.

###############################################################################
# Downloading the image

download_path="${HOME}/.cache"
img_path="${download_path}/${img_name}"
md5_path="${download_path}/${img_name}.md5"

img_url="http://os.archlinuxarm.org/os/${img_name}"
md5_url="http://os.archlinuxarm.org/os/${img_name}.md5"

download() {
   wget --continue --show-progress --progress=bar:force "$1" -O "$2"
}

info "Downloading MD5 sum file of ArchLinuxARM from ${md5_url}"
download "${md5_url}" "${md5_path}"
info "Done."

info "Downloading latest version of ArchLinuxARM from ${img_url}"
echo "Tip : restarting the script will continue the download where it started."
download "${img_url}" "${img_path}"
info "Done."

md5check() {
  pushd "${download_path}" >/dev/null
  if md5sum --status -c "${md5_path}"; then err=0; else err=1; fi
  popd >/dev/null
  return $err
}

info "Checking the md5 sum…"
if ! md5check; then
  rm -rf "${img_path}" "${md5_path}"
  error "Downloading failed : MD5 sum does not match."
  echo "Please check your connection and restart the script or run:"
  echo "    wget ${img_url} -O ${img_path}"

  exit 1
fi
info "Done."
echo ""

###############################################################################
# Umount sdcard if mounted

info 'Unmounting SD card if needed…'

blocks="$(lsblk -ln -o PATH,MOUNTPOINT)"
mountpoints="$(echo "${blocks}" | awk '$1~v {print $2}' v="${SDCARD}.*")"
mounteddevs="$(echo "${blocks}" | awk '$1~v && $2 {print $1}' v="${SDCARD}.*")"

if echo "${mountpoints}" | grep -qw "^/" \
|| echo "${mountpoints}" | grep -qw "^/boot" \
|| echo "${mountpoints}" | grep -qw "^/home"
then
  echo "${SDCARD} contains the system mounts ! Aborting."
  exit 1
fi

if [[ -n "${mounteddevs}" ]]; then
  umount ${mounteddevs}
  if [[ ${?} -ne 0 ]]; then
    error 'Impossible to umount SD card... Exiting'
    exit 1
  fi
fi

info "Done."
echo ""

###############################################################################
# Create partitions

info "Creating partitions on ${SDCARD}…"

sfdisk_input="
label: dos
name=boot, size= 100MiB, type=c
name=root,               type=83
"

echo "${sfdisk_input}" | \
sfdisk "${SDCARD}"

sync
info "Done."

# Getting new partition paths
blocks="$(lsblk -ln -o PATH,MOUNTPOINT)"
boot_block="${SDCARD}1"
root_block="${SDCARD}2"

info "Formating partitions…"
mkfs.vfat "${boot_block}"
mkfs.ext4 -F "${root_block}"
sync
info "Done."


boot_mount='/tmp/raspberrypi/boot'
root_mount='/tmp/raspberrypi/root'

info "Creating temporary mount directories…"
mkdir -p "${boot_mount}" "${root_mount}"

info 'Mounting…'
mount "${boot_block}" "${boot_mount}"
mount "${root_block}" "${root_mount}"

sync

###############################################################################
# Write the files to the disk

info "Extracting files into ${root_mount}..."
bsdtar -xpf $ALARM_PATH -C "${root_mount}"
info ' Syncing... (this might take a while)'
sync

info "Copying boot into $boot_mount"
mv "${root_mount}/boot/"* "${boot_mount}"
sync

info "Unmounting..."
umount "${boot_mount}" "${root_mount}"
rm -rf "${boot_mount}"
rm -rf "${root_mount}"
sync

info "Everything looks good! Insert the sdcard in you RaspberryPi and have fun!"
