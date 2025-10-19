#!/bin/bash
# push_flash_blip.sh
# Package the Love2D game and push it to an Android device via ADB.

set -e

# Resolve absolute path to the project root, even if run from tools/ or anywhere else
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "${SCRIPT_DIR}/..")"
GAME_DIR="${ROOT_DIR}/game"
OUTPUT="${ROOT_DIR}/game.love"
DEVICE_PATH="/sdcard/game.love"

echo "==> Packaging ${OUTPUT}..."
# Create the .love file (ZIP with .love extension), excluding scripts and git data
(cd "${GAME_DIR}" && zip -9 -r "${OUTPUT}" . -x "*.git*" "*.sh" > /dev/null)

echo "==> Removing old version on device (if exists)..."
# Ignore error if file does not exist
adb shell "rm -f ${DEVICE_PATH}" 2>/dev/null || true

echo "==> Copying ${OUTPUT} to device..."
if adb push "${OUTPUT}" "${DEVICE_PATH}"; then
  echo "==> Copy successful. Cleaning up local file..."
  rm -f "${OUTPUT}"
  echo "==> Done."
else
  echo "!! Copy failed. Keeping ${OUTPUT}."
  exit 1
fi
