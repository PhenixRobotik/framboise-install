#!/bin/env bash

###############################################################################
# Downloading the image


prompt_raspberry_pi_image_archlinux() {
  distro="archlinux"

  if [[ -z "${rpi_version}" ]]; then
    read -r -p "Please enter your RaspberryPi version number [2/default=3]: " rpi_version
  fi


  case "${rpi_version}" in
    "2"     ) img_name='ArchLinuxARM-rpi-2-latest.tar.gz' ;;
    "3"|""  ) img_name='ArchLinuxARM-rpi-3-latest.tar.gz' ;;
    *) error "Unknown version ${rpi_version}. Exiting." ; exit 1 ;;
  esac

  img_url="http://os.archlinuxarm.org/os/${img_name}"
  hash_name="${img_name}.md5"
  hash_sum="http://os.archlinuxarm.org/os/${hash_name}"

  echo ""
}

prompt_raspberry_pi_image_debian() {
  distro="debian"

  img_name="2019-04-08-raspbian-stretch.zip"
  img_srv="https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09"

  img_url="${img_srv}/${img_name}"
  hash_name="${img_name}.sha256"
  hash_sum="${img_srv}/${hash_name}"

  echo ""
}

prompt_raspberry_pi_image() {
  prompt_raspberry_pi_image_debian
}

dodownload() {
   as_user wget --continue --show-progress --progress=bar:force "$1" -O "$2"
}

hash_check() {
  pushd "${download_path}" >/dev/null || return 1
  if [ ${hash_name: -4} == ".md5" ]; then
    if md5sum    --status -c "${hash_path}"; then err=0; else err=1; fi
  else
    if sha256sum --status -c "${hash_path}"; then err=0; else err=1; fi
  fi
  popd >/dev/null || return 1
  return $err
}

step_download_image() {
  # shellcheck disable=SC2016
  user_home="$(as_user bash -c 'echo $HOME')"
  download_path="${user_home}/.cache"
  img_path="${download_path}/${img_name}"
  hash_path="${download_path}/${hash_name}"

  info "Downloading hash sum file of ${img_name} from ${hash_sum}"
  dodownload "${hash_sum}" "${hash_path}"
  info "Done."

  info "Downloading latest version of ${img_name} from ${img_url}"
  info "Tip : restarting the script will continue the download where it stopped."
  dodownload "${img_url}" "${img_path}"
  info "Done."


  info "Checking the hash sum…"
  if ! hash_check; then
    rm -rf "${img_path}" "${hash_path}"
    error "Downloading failed : hash sum does not match."
    error "Please check your connection and restart the script or run:"
    error "    wget ${img_url} -O ${img_path}"

    exit 1
  fi
  info "Done."
  echo ""
}
