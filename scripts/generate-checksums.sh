#!/usr/bin/env bash
# Generate SHA256 checksums for all binaries
#
# Usage: bash scripts/generate-checksums.sh [artifact_directory]
# 
# Examples:
#   bash scripts/generate-checksums.sh zig-out/
#   bash scripts/generate-checksums.sh release-artifacts/
#
# This script will:
#   1. Find all binary/archive files in the specified directory
#   2. Compute SHA256 hashes for each file
#   3. Write to SHA256SUMS in the same directory
#   4. Sort alphabetically for consistent output
#

set -e

# Configuration
ARTIFACT_DIR="${1:-.}"
OUTPUT_FILE="${ARTIFACT_DIR}/SHA256SUMS"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

print_success() {
  echo -e "${GREEN}✓${NC} $*"
}

print_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

# Validate input directory
if [ ! -d "$ARTIFACT_DIR" ]; then
  print_error "Directory not found: $ARTIFACT_DIR"
  exit 1
fi

print_info "Generating checksums for files in: $ARTIFACT_DIR"

# Create temporary checksum file
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Find and process files
# Look for: .tar.gz, .zip, binaries (no extension)
file_count=0

# Function to add checksum for a file
add_checksum() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    return
  fi
  
  # Skip the SHA256SUMS file itself
  if [ "$(basename "$file")" = "SHA256SUMS" ]; then
    return
  fi
  
  # Skip temporary files
  if [[ "$(basename "$file")" =~ ^\..*$ ]]; then
    return
  fi
  
  local hash
  hash=$(sha256sum "$file" | awk '{print $1}')
  
  local basename
  basename=$(basename "$file")
  
  echo "$hash  $basename" >> "$TEMP_FILE"
  print_success "Checksummed: $basename"
  file_count=$((file_count + 1))
}

# Process different file types
print_info "Finding files..."

# Find .tar.gz files
while IFS= read -r -d '' file; do
  add_checksum "$file"
done < <(find "$ARTIFACT_DIR" -maxdepth 1 -name "*.tar.gz" -print0 2>/dev/null)

# Find .zip files
while IFS= read -r -d '' file; do
  add_checksum "$file"
done < <(find "$ARTIFACT_DIR" -maxdepth 1 -name "*.zip" -print0 2>/dev/null)

# Find binaries (files with no extension that are executable)
while IFS= read -r -d '' file; do
  # Skip directories and special files
  if [ -f "$file" ] && [ -x "$file" ]; then
    add_checksum "$file"
  fi
done < <(find "$ARTIFACT_DIR" -maxdepth 1 -type f ! -name "*.*" -print0 2>/dev/null)

# Find Windows executables
while IFS= read -r -d '' file; do
  add_checksum "$file"
done < <(find "$ARTIFACT_DIR" -maxdepth 1 -name "*.exe" -print0 2>/dev/null)

# Check if we found any files
if [ $file_count -eq 0 ]; then
  print_error "No files found in $ARTIFACT_DIR"
  exit 1
fi

print_info "Found $file_count files"

# Sort checksums alphabetically and write to output file
print_info "Sorting and writing to $OUTPUT_FILE..."
sort "$TEMP_FILE" > "$OUTPUT_FILE"

# Verify the output
if [ ! -f "$OUTPUT_FILE" ]; then
  print_error "Failed to create $OUTPUT_FILE"
  exit 1
fi

print_success "Checksums generated: $OUTPUT_FILE"
print_info "Total files: $file_count"
print_info ""
print_info "Checksum file contents:"
echo "---"
cat "$OUTPUT_FILE"
echo "---"

print_success "Done!"
