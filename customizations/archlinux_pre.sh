#!/bin/env bash

info "Some fixes for Archlinux befor chrooting…"

# # Fix for no internet in the chroot
# cp             "/etc/resolv.conf" \
#   "${root_mount}/etc/resolv.conf"

# Fix for ca-certificates not updating
cp             "/etc/ca-certificates/extracted/tls-ca-bundle.pem" \
  "${root_mount}/etc/ca-certificates/extracted/tls-ca-bundle.pem"
