#!/usr/bin/env bash
# Update flake.nix with evidence-backed release metadata.
# Usage: ./scripts/update-nix-flake.sh <version> <sha256sums-file>

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s <version> [sha256sums-file]\n' "$0" >&2
  exit 1
fi

VERSION="$1"
CHECKSUMS_FILE="${2:-.checksums}"

if [ ! -f "$CHECKSUMS_FILE" ]; then
  echo "❌ Error: Checksums file not found: $CHECKSUMS_FILE"
  exit 1
fi

FLAKE="./flake.nix"

if [ ! -f "$FLAKE" ]; then
  echo "❌ Error: flake.nix not found at $FLAKE"
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
    if [[ $filename =~ linux-x64-gnu ]]; then
      CHECKSUMS["x86_64-linux"]="$hash"
    elif [[ $filename =~ linux-arm64-gnu ]]; then
      CHECKSUMS["aarch64-linux"]="$hash"
    elif [[ $filename =~ darwin-x64 ]]; then
      CHECKSUMS["x86_64-darwin"]="$hash"
    elif [[ $filename =~ darwin-arm64 ]]; then
      CHECKSUMS["aarch64-darwin"]="$hash"
    fi
  fi
done < "$CHECKSUMS_FILE"

# Create a temporary file for the updated flake.nix
FLAKE_TEMP=$(mktemp)
trap "rm -f $FLAKE_TEMP" EXIT

# Update version
sed -E "s/version = (null|\"[^\"]*\")/version = \"$VERSION\"/" "$FLAKE" > "$FLAKE_TEMP"

# Update checksums
for system in "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"; do
  if [ -v CHECKSUMS["$system"] ]; then
    hash="${CHECKSUMS[$system]}"
    sed -i -E "s|\"$system\" = (null|\"[^\"]*\")|\"$system\" = \"$hash\"|" "$FLAKE_TEMP"
  fi
done

# Move temp file to actual flake
mv "$FLAKE_TEMP" "$FLAKE"

echo "✅ Updated flake.nix version=$VERSION"
echo "✅ Updated checksums:"
for system in "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"; do
  echo "   $system: ${CHECKSUMS[$system]:-MISSING}"
done
