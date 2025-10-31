#!/usr/bin/env bash
# No-Wrap Test: Test DECAWM (DEC Private Mode 7) to disable auto-wrap
# Tests whether CSI ?7l/h can control terminal wrapping behavior

set -euo pipefail

echo "=== Terminal Wrap Behavior - No-Wrap Mode Test ==="
echo ""
echo "Terminal: $TERM"
# Try stty first, fallback to tput
if command -v stty &>/dev/null && TERM_SIZE=$(stty size 2>/dev/null); then
  TERM_LINES=$(echo "$TERM_SIZE" | cut -d' ' -f1)
  TERM_COLS=$(echo "$TERM_SIZE" | cut -d' ' -f2)
  echo "Terminal size: ${TERM_COLS}x${TERM_LINES} (cols x lines)"
elif command -v tput &>/dev/null; then
  echo "Terminal size: $(tput cols 2>/dev/null || echo '?')x$(tput lines 2>/dev/null || echo '?') (cols x lines)"
else
  echo "Terminal size: unknown"
fi
echo ""
echo "This test uses DECAWM (CSI ?7l) to disable auto-wrap before rendering."
echo "The sequence CSI ?7h will re-enable auto-wrap afterward."
echo ""
echo "Expected behavior:"
echo "  - Content wider than terminal should NOT wrap"
echo "  - Overflow should be clipped/hidden at the right edge"
echo "  - Auto-wrap should restore after test completes"
echo ""
echo "Press ENTER to start..."
read

echo ""
echo "--- Emitting: CSI ?7l (disable auto-wrap) ---"

# Disable auto-wrap
printf '\033[?7l'

# Small delay to ensure mode change takes effect
sleep 0.1

# Display the wide ANSI art
cat "$(dirname "$0")/test-wide.ans"

echo ""
echo ""

# Re-enable auto-wrap
printf '\033[?7h'

echo "--- Emitted: CSI ?7h (re-enable auto-wrap) ---"
echo ""
echo "=== No-Wrap Test Complete ==="
echo ""
echo "Questions to answer:"
echo "1. Did the colored bars stay on single lines (no wrapping)?"
echo "2. Was the right-side content clipped at the terminal edge?"
echo "3. Does auto-wrap work correctly now? (Try: echo '123456789012345...' with a long string)"
echo ""
echo "Test auto-wrap restoration:"
printf "This is a very long line that should wrap at your terminal width if auto-wrap was properly restored: "
for i in {1..200}; do printf "%d" $((i % 10)); done
printf "\n"
echo ""
