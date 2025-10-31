#!/usr/bin/env bash
# Test horizontal scrolling with less pager

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Horizontal Scrolling Test with 'less' Pager ==="
echo ""
echo "This test demonstrates horizontal scrolling by piping to 'less -S -R'"
echo ""
echo "  -S : Chop long lines (enable horizontal scrolling)"
echo "  -R : Raw control characters (preserve ANSI colors)"
echo ""
echo "Controls:"
echo "  Arrow Left/Right : Scroll horizontally"
echo "  Arrow Up/Down    : Scroll vertically"
echo "  q                : Quit"
echo ""
echo "Press ENTER to launch pager..."
read

# Pipe the wide ANSI art through less with horizontal scrolling
cat "$SCRIPT_DIR/test-wide.ans" | less -S -R

echo ""
echo "=== Pager Test Complete ==="
echo ""
echo "Did you see horizontal scrolling? (Arrow keys should have worked)"
echo ""
