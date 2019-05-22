#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions/_.sh"

test_sudo "$@"

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║  Welcome! This program will automate the installation of  ║'
echo '║                  a custom Raspbian image.                 ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

# Custom config to disable prompts
rpi_version=3
# create_and_mount_fake_device

prompt_device
prompt_confirmation
prompt_raspberry_pi_image

# step_download_image

step_umount_device
img_path="$(find "${FunctionsDir}/../cache" -maxdepth 1 -name "*.img")"
step_write_dd_image_to_disk

step_flash_finish
