#!/usr/bin/env bash
# Generate .SRCINFO from PKGBUILD using makepkg
# Usage: ./scripts/generate-srcinfo.sh [path-to-aur-directory]

set -euo pipefail

AUR_DIR="${1:-.}/aur"

if [ ! -f "$AUR_DIR/PKGBUILD" ]; then
  echo "❌ Error: PKGBUILD not found at $AUR_DIR/PKGBUILD"
  exit 1
fi

# Check if makepkg is available
if ! command -v makepkg &> /dev/null; then
  echo "❌ Error: makepkg not found. Install base-devel on Arch Linux:"
  echo "   sudo pacman -S base-devel"
  exit 1
fi

# Generate .SRCINFO
cd "$AUR_DIR"
makepkg --printsrcinfo > .SRCINFO

echo "✅ Generated .SRCINFO from PKGBUILD"
