#!/bin/bash -xe
ScriptDir="$(dirname $(readlink -f $0))"

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

install_dependencies() {
  :
}

install_code() {
  :
  # # Install dependencies
  # pacman -S --noconfirm --needed python-yaml python-evdev
  #
  # # Copy code to the correct location
  # cp -Tr "${ScriptDir}/StrangerFamily" /home/mike/StrangerFamily
  #
  # # Setup boot service
  # cp "${ScriptDir}/stranger-family.service" \
  #           /usr/lib/systemd/system/stranger-family.service
  # chmod 644 /usr/lib/systemd/system/stranger-family.service
  # # Useless inside chroot:
  # # systemctl daemon-reload
  # systemctl enable stranger-family
  # # Useless inside chroot:
  # # systemctl status stranger-family # Should be enabled, stopped
}

install_cleanup() {
  rm /var/cache/pacman/pkg/*.xz
}

# Some bug fixes ?
export PATH=$PATH:/sbin:/usr/sbin
export LC_ALL=C

warning "Inside the chroot !"

update_ystem
create_user

install_dependencies
install_code

install_cleanup

# For debugging the install
bash
true
