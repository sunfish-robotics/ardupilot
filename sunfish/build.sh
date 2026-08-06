#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BOARD="${1:-CUAV-7-Nano}"
ARTIFACT_DIR="${2:-${SCRIPT_DIR}/artifacts/${BOARD}}"
HWDEF_DIR="${REPO_ROOT}/libraries/AP_HAL_ChibiOS/hwdef/${BOARD}"
BOOTLOADER_BIN="${REPO_ROOT}/build/${BOARD}/bin/AP_Bootloader.bin"
BOOTLOADER_HEX="${REPO_ROOT}/build/${BOARD}/bin/AP_Bootloader.hex"
CHECKED_IN_BOOTLOADER="${REPO_ROOT}/Tools/bootloaders/${BOARD}_bl.bin"
TEMP_DIR=""
HAD_CHECKED_IN_BOOTLOADER=false

usage() {
    cat <<EOF
Usage: $0 [board] [artifact-directory]

Build the bootloader and ArduSub firmware for a ChibiOS board.

Defaults:
  board:               CUAV-7-Nano
  artifact-directory:  ${SCRIPT_DIR}/artifacts/<board>
EOF
}

cleanup() {
    if [[ -z "${TEMP_DIR}" ]]; then
        return
    fi

    if [[ "${HAD_CHECKED_IN_BOOTLOADER}" == true ]]; then
        cp -p -- "${TEMP_DIR}/checked-in-bootloader.bin" "${CHECKED_IN_BOOTLOADER}"
    else
        rm -f -- "${CHECKED_IN_BOOTLOADER}"
    fi

    rm -f -- "${TEMP_DIR}/checked-in-bootloader.bin"
    rmdir -- "${TEMP_DIR}"
}

if [[ "${BOARD}" == "-h" || "${BOARD}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ ! -f "${HWDEF_DIR}/hwdef.dat" ]]; then
    echo "Unknown board '${BOARD}': ${HWDEF_DIR}/hwdef.dat does not exist" >&2
    exit 1
fi

if [[ ! -f "${HWDEF_DIR}/hwdef-bl.dat" ]]; then
    echo "Board '${BOARD}' does not have a bootloader hwdef" >&2
    exit 1
fi

if ! python3 -c 'import intelhex' >/dev/null 2>&1; then
    echo "The Python intelhex package is required to create HEX artifacts." >&2
    echo "Install it with: python3 -m pip install --user intelhex" >&2
    exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sunfish-build.XXXXXX")"
trap cleanup EXIT

if [[ -f "${CHECKED_IN_BOOTLOADER}" ]]; then
    cp -p -- "${CHECKED_IN_BOOTLOADER}" "${TEMP_DIR}/checked-in-bootloader.bin"
    HAD_CHECKED_IN_BOOTLOADER=true
fi

cd -- "${REPO_ROOT}"

echo "Building ${BOARD} bootloader"
./waf configure --board "${BOARD}" --bootloader --no-submodule-update --Werror
./waf clean
./waf bootloader

test -f "${BOOTLOADER_BIN}"
test -f "${BOOTLOADER_HEX}"

mkdir -p -- "${ARTIFACT_DIR}"
cp -- "${BOOTLOADER_BIN}" "${ARTIFACT_DIR}/${BOARD}-bootloader.bin"
cp -- "${BOOTLOADER_HEX}" "${ARTIFACT_DIR}/${BOARD}-bootloader.hex"

# ArduPilot reads this path when producing the combined firmware image. Restore
# the repository copy on exit so a local build does not dirty the worktree.
cp -- "${BOOTLOADER_BIN}" "${CHECKED_IN_BOOTLOADER}"
cmp -- "${BOOTLOADER_BIN}" "${CHECKED_IN_BOOTLOADER}"

echo "Building ${BOARD} ArduSub firmware"
./waf configure --board "${BOARD}" --no-submodule-update
./waf sub

FIRMWARE_DIR="${REPO_ROOT}/build/${BOARD}/bin"
cp -- "${FIRMWARE_DIR}/ardusub.apj" "${ARTIFACT_DIR}/${BOARD}-ardusub.apj"
cp -- "${FIRMWARE_DIR}/ardusub.bin" "${ARTIFACT_DIR}/${BOARD}-ardusub.bin"
cp -- "${FIRMWARE_DIR}/ardusub_with_bl.hex" \
    "${ARTIFACT_DIR}/${BOARD}-ardusub-with-bootloader.hex"

echo "Artifacts written to ${ARTIFACT_DIR}"
