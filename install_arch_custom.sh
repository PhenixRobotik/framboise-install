#!/bin/bash
set -euf -o pipefail

# shellcheck source=functions.sh
source "functions/_.sh"

echo '╔═══════════════════════════════════════════════════════════╗'
echo '║                                                           ║'
echo '║  Welcome! This program will automate the installation of  ║'
echo '║          ArchLinuxARM on your microSD card.               ║'
echo '║                                                           ║'
echo '╚═══════════════════════════════════════════════════════════╝'

# Custom config to disable prompts
rpi_version=3
create_and_mount_fake_device

prompt_device
prompt_confirmation
prompt_raspberry_pi_image

setup_custom_image

step_umount_device
step_partition_device
step_extract_to_disk

step_flash_finish
