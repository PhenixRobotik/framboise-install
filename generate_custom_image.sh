#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions.sh"

test_sudo "$@"

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║   Welcome! This program will automate the generation of   ║'
echo '║                a custom ArchLinuxARM image.               ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

create_and_mount_fake_device

rpi_version=3
prompt_device
prompt_confirmation
prompt_raspberry_pi_image

step_download_image

step_umount_device
step_partition_device
step_extract_to_disk

download_qemu
step_mount_device
prepare_install
compress_image

disable_fake_device
