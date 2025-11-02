#!/usr/bin/env bash
# Update AUR PKGBUILD with latest checksums and version
# Usage: ./scripts/update-aur-pkgbuild.sh <version> <sha256sums-file>

set -euo pipefail

VERSION="${1:-0.0.1}"
CHECKSUMS_FILE="${2:-.checksums}"

if [ ! -f "$CHECKSUMS_FILE" ]; then
  echo "❌ Error: Checksums file not found: $CHECKSUMS_FILE"
  exit 1
fi

AUR_DIR="./aur"
PKGBUILD="$AUR_DIR/PKGBUILD"

if [ ! -f "$PKGBUILD" ]; then
  echo "❌ Error: PKGBUILD not found at $PKGBUILD"
  exit 1
fi

# Extract checksums from SHA256SUMS file
# Expected format: <hash> <filename>
declare -A CHECKSUMS

while IFS= read -r line; do
  if [[ $line =~ ^([a-f0-9]{64})[[:space:]]+(.*) ]]; then
    hash="${BASH_REMATCH[1]}"
    filename="${BASH_REMATCH[2]}"
    
    # Extract architecture from filename
    # Filenames like: ansilust-linux-x64-gnu.tar.gz
    if [[ $filename =~ linux-x64-gnu ]]; then
      CHECKSUMS["x86_64"]="$hash"
    elif [[ $filename =~ linux-arm64-gnu ]]; then
      CHECKSUMS["aarch64"]="$hash"
    elif [[ $filename =~ linux-armv7-gnu ]]; then
      CHECKSUMS["armv7h"]="$hash"
    fi
  fi
done < "$CHECKSUMS_FILE"

# Update PKGBUILD with new version
sed -i "s/^pkgver=.*/pkgver=$VERSION/" "$PKGBUILD"

# Update checksums
if [ -v CHECKSUMS["x86_64"] ]; then
  sed -i "s/sha256sums_x86_64=.*/sha256sums_x86_64=('${CHECKSUMS["x86_64"]}')/" "$PKGBUILD"
fi

if [ -v CHECKSUMS["aarch64"] ]; then
  sed -i "s/sha256sums_aarch64=.*/sha256sums_aarch64=('${CHECKSUMS["aarch64"]}')/" "$PKGBUILD"
fi

if [ -v CHECKSUMS["armv7h"] ]; then
  sed -i "s/sha256sums_armv7h=.*/sha256sums_armv7h=('${CHECKSUMS["armv7h"]}')/" "$PKGBUILD"
fi

echo "✅ Updated PKGBUILD version=$VERSION"
echo "✅ Updated checksums:"
echo "   x86_64: ${CHECKSUMS[x86_64]:-MISSING}"
echo "   aarch64: ${CHECKSUMS[aarch64]:-MISSING}"
echo "   armv7h: ${CHECKSUMS[armv7h]:-MISSING}"
