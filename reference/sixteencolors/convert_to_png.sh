#!/bin/bash

# Convert all ANSI/ASCII art files in sixteencolors directory and subdirectories to PNG
# Using ansilove with default output location

set -e

BASE_DIR="/home/tom/Hack/ansilust/reference/sixteencolors"

echo "Starting conversion of ANSI/ASCII art files to PNG..."
echo "Base directory: $BASE_DIR"
echo ""

TOTAL=0
SUCCESS=0
FAILED=0

# Find all files recursively (no extension filtering, excluding .png and .exe)
cd "$BASE_DIR"
find . -type f ! -name ".*" ! -name "*.sh" ! -name "*.md" ! -name "*.zip" ! -name "*.png" ! -name "*.exe" | while read -r file; do
    TOTAL=$((TOTAL + 1))
    
    # Remove leading ./
    display_file="${file#./}"
    
    printf "[%d] Converting: %s\n" "$TOTAL" "$display_file"
    
    if ansilove "$file" 2>/dev/null; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        printf "  ⚠ Failed to convert: %s\n" "$display_file"
    fi
done

echo ""
echo "========================================="
echo "Conversion complete!"
echo "========================================="
