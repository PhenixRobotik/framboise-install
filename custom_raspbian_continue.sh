#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions/_.sh"

test_sudo "$@"

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║   Welcome! This program will automate the generation of   ║'
echo '║                  a custom Raspbian image.                 ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

#
# download_qemu
# prepare_install
# compress_image
#
# step_flash_finish

step_dd_image_continue
step_mount_device
