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
  "./autologin.sh"

  info "Configuring testing repo…"
  "./add_testing_repo.sh"


  info "Installing software dependencies…"
  apt install -t testing meson
  apt install libgtkmm-3.0-dev


  info "Cloning, building and installing our software…"
  cd /tmp
  as_user git clone 'https://github.com/phenixrobotik/framboise-software.git'
  cd "framboise-software"
  as_user meson "_build"
  cd "_build"
  as_user ninja
  ninja install

  info "Enabling userland SystemD unit…"
  as_user systemctl --enable "framboise-brain"
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
