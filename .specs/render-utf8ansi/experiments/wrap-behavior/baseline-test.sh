#!/usr/bin/env bash
# Baseline Test: Observe natural terminal wrapping behavior
# Tests how terminals wrap wide ANSI content without any wrap control sequences

set -euo pipefail

echo "=== Terminal Wrap Behavior - Baseline Test ==="
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
echo "This test displays 160-column colored bars."
echo "Observe how your terminal wraps the content at its current width."
echo ""
echo "Press ENTER to start..."
read

# Display the wide ANSI art
cat "$(dirname "$0")/test-wide.ans"

echo ""
echo ""
echo "=== Baseline Test Complete ==="
echo ""
echo "Questions to answer:"
echo "1. Did the colored bars wrap at your terminal width?"
echo "2. Were there visible artifacts where wrapping occurred?"
echo "3. Did the colors remain correct after wrapping?"
echo ""
