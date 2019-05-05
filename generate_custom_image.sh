#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions.sh"

test_sudo

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║  Welcome! This program will automate the installation of  ║'
echo '║          ArchLinuxARM on your microSD card.               ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

# Custom config to disable prompts
rpi_version=3
SDCARD=/dev/loop0

prompt_device
prompt_confirmation
prompt_raspberry_pi_image

step_download_image
step_umount_device
step_partition_device_and_mount
step_extract_to_disk

downloadQemu
