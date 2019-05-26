#!/usr/bin/env bash

info()    { printf '\e[0;32m[INFO] %s\e[0m\n' "$@"; }
warning() { printf '\e[0;35m[WARNING] %s\e[0m\n' "$@"; }
error()   { printf '\e[0;31m[ERROR] %s\e[0m\n' "$@"; }

as_user() { sudo -u phenix -s -- $@; }


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
