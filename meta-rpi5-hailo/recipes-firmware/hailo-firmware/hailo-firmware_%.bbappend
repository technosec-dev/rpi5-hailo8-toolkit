# The recipe sets LICENSE = "LICENSE". That name is looked up in LICENSE_PATH
# before the recipe's own file is considered, and meta-hailo-tappas adds a
# licenses/LICENSE of its own, so the SBOM records the TAPPAS license text for
# the firmware. Without meta-hailo-tappas there is no text at all and
# do_create_spdx stops with "Cannot find any text for license".
#
# A name of its own, pointed at the license Hailo publishes next to the
# firmware blob, records the right text either way.
LICENSE = "Hailo-Firmware"
NO_GENERIC_LICENSE[Hailo-Firmware] = "LICENSE"
