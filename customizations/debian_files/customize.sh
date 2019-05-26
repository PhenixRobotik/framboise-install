#!/bin/bash -xe
ScriptDir="$(dirname $(readlink -f $0))"
cd "${ScriptDir}"

info()    { printf '\e[0;32m[INFO] %s\e[0m\n' "$@"; }
warning() { printf '\e[0;35m[WARNING] %s\e[0m\n' "$@"; }
error()   { printf '\e[0;31m[ERROR] %s\e[0m\n' "$@"; }

update_system() {
  info "Updating the system…"

  apt update
  apt upgrade -y
}

# Create non-root user
create_user() {
  info "Creating phenix user…"
  useradd --create-home phenix
  echo "phenix:bornagain" | chpasswd
}
as_user() { sudo -u phenix -s -- $@; }

install_code() {
  info "Configuring autologin to graphical session… FIXME not tested"
  "${ScriptDir}/autologin.sh"

  info "Configuring testing repo…"
  "${ScriptDir}/add_testing_repo.sh"

  info "Installing our software…"
  "${ScriptDir}/install_software.sh"
}

install_cleanup() {
  info "Cleaning the installation…"
  # rm /var/cache/pacman/pkg/*.xz
  info "Done."
}

# Some bug fixes ?
export PATH=$PATH:/sbin:/usr/sbin
export LC_ALL=C

warning "Inside the chroot !"

update_system
create_user

install_code

install_cleanup

# For debugging the install
bash
true
