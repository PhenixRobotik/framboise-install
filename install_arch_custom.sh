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
SDCARD=/dev/loop0

prompt_device
prompt_confirmation
setup_custom_image

step_umount_device
step_partition_device
step_extract_to_disk
step_umount_device

step_flash_finish
