#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions/_.sh"

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║   Welcome! This program will automate the generation of   ║'
echo '║                  a custom Raspbian image.                 ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

# Custom config to disable prompts
rpi_version=3
create_and_mount_fake_device

prompt_device
prompt_confirmation
prompt_raspberry_pi_image

step_download_image

step_umount_device
# step_partition_device
# step_extract_to_disk
step_extract_dd_image_to_file
step_mount_device

download_qemu
prepare_install
compress_image

step_flash_finish
