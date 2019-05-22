#!/bin/env bash

###############################################################################
# Downloading the image


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

dodownload() {
   as_user wget --continue --show-progress --progress=bar:force "$1" -O "$2"
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
