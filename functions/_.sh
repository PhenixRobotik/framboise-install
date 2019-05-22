#!/bin/env bash

FunctionsDir="$(dirname "$(realpath "${BASH_SOURCE}")")"
CacheDir="${FunctionsDir}/../cache"
CustomizationsDir="${FunctionsDir}/../customizations"

# shellcheck source=base.sh
source "${FunctionsDir}/base.sh"
# shellcheck source=image_downloading.sh
source "${FunctionsDir}/image_downloading.sh"
# shellcheck source=device_partitionning.sh
source "${FunctionsDir}/device_partitionning.sh"
# shellcheck source=device_mounting.sh
source "${FunctionsDir}/device_mounting.sh"
# shellcheck source=device_writing.sh
source "${FunctionsDir}/device_writing.sh"

# shellcheck source=device_fake_setup.sh
source "${FunctionsDir}/device_fake_setup.sh"
# shellcheck source=image_customizing.sh
source "${FunctionsDir}/image_customizing.sh"


cleanup() {
  step_mount_device_cleanup
  create_and_mount_fake_device_cleanup
}
trap 'cleanup' EXIT
