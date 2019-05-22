#!/bin/bash -xe
ScriptDir="$(dirname $(readlink -f $0))"

info()    { printf '\e[0;32m[INFO] %s\e[0m\n' "$@"; }
warning() { printf '\e[0;35m[WARNING] %s\e[0m\n' "$@"; }
error()   { printf '\e[0;31m[ERROR] %s\e[0m\n' "$@"; }


updateSystem() {
  info "Updating the system…"

  pacman -Syy
  pacman-key --init
  pacman-key --populate archlinuxarm
  pacman -Syuu --noconfirm
  pacman -S    --noconfirm --needed sudo git base-devel
}

# Create non-root user
createUser() {
  info "Creating phenix user…"
  useradd --create-home phenix
  echo "bornagain" | passwd mike
}
asUser() { sudo -u mike -s -- $@; }

# Install AUR helper
installYay() {
  if pacman -Qi yay &>/dev/null; then return; fi

  asUser git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
  # Install missing dependencies as root
  (source PKGBUILD && pacman -S --noconfirm --needed --asdeps "${makedepends[@]}" "${depends[@]}")
  # makepkg cannot be run as root
  asUser makepkg
  pacman -U --noconfirm ./yay-*.pkg.tar.*
  popd
}


installRpiWs281x() {
  pacman -S --noconfirm --needed python python-setuptools scons swig

  asUser git clone https://github.com/jgarff/rpi_ws281x /tmp/rpi_ws281x
  pushd /tmp/rpi_ws281x
  asUser scons
  pushd python
  python setup.py install
  popd
  popd
}

installI2c() {
  pacman -S --noconfirm --needed i2c-tools lm_sensors

  # Reboot-persistent
  echo "i2c-bcm2708"  >> /etc/modules-load.d/raspberrypi.conf
  echo "i2c-dev"      >> /etc/modules-load.d/raspberrypi.conf
  # For now: (useless inside chroot)
  # modprobe "i2c-bcm2708"
  # modprobe "i2c-dev"
}


installCode() {
  # Install dependencies
  pacman -S --noconfirm --needed python-yaml python-evdev

  # Copy code to the correct location
  cp -Tr "${ScriptDir}/StrangerFamily" /home/mike/StrangerFamily

  # Setup boot service
  cp "${ScriptDir}/stranger-family.service" \
            /usr/lib/systemd/system/stranger-family.service
  chmod 644 /usr/lib/systemd/system/stranger-family.service
  # Useless inside chroot:
  # systemctl daemon-reload
  systemctl enable stranger-family
  # Useless inside chroot:
  # systemctl status stranger-family # Should be enabled, stopped
}

installCleanup() {
  rm /var/cache/pacman/pkg/*.xz
}

warning "Inside the chroot !"

updateSystem
createUser

installYay
# installRpiWs281x
# installI2c
#
# installCode

installCleanup

# For debugging the install
bash
true
