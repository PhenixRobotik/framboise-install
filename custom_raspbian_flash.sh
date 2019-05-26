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

rpi_version=3

prompt_device
prompt_confirmation

step_dd_image_continue
step_write_dd_image_to_disk
step_flash_finish
