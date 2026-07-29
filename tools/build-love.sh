#!/usr/bin/env bash

# Create love package using act or 7z
if command -v act &>/dev/null; then
  act -j build-love
elif command -v 7z &>/dev/null; then
  source ./game/product.env
  # Check if PRODUCT_NAME was found
  if [ -z "${PRODUCT_NAME}" ]; then
    echo "Error: Could not find PRODUCT_NAME in game/product.env"
    exit 1
  fi
  PRODUCT_FILE="$(echo "${PRODUCT_NAME}" | tr ' ' '-')"

  mkdir -p "./builds/1"
  # Create a temporary copy of the game directory for build
  mkdir -p "./builds/temp"
  cp -r ./game/* "./builds/temp/"

  # Remove debug-related code from main.lua
  python3 -c "import re, sys; f=sys.argv[1]; lines=open(f).readlines(); out=[]; skip=False; depth=0
for l in lines:
    if not skip:
        if 'Settings.IS_DEBUG_ENABLED' in l: skip=True; depth=1
        else: out.append(l)
    else:
        depth += len(re.findall(r'\bif\b', l)) - len(re.findall(r'\bend\b', l))
        if depth <= 0: skip=False
open(f, 'w').writelines(out)" "./builds/temp/main.lua"

  # Remove overlayStats.lua file
  rm -f "./builds/temp/lib/overlayStats.lua"

  7z a -tzip -mx=6 -mpass=15 -mtc=off \
    "./builds/1/${PRODUCT_FILE}.love" \
    ./builds/temp/* \
    -xr!.gitkeep

  # Clean up temporary directory
  rm -rf "./builds/temp"
else
  echo 'ERROR! Command not find `act` or `7z` to build the package.'
  exit 1
fi
