#!/usr/bin/env bash
# Master test runner for all wrap behavior experiments
# Run this to execute all tests in sequence

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Handle unknown TERM values gracefully
ORIGINAL_TERM="$TERM"
if ! infocmp "$TERM" &>/dev/null; then
  case "$TERM" in
    xterm-ghostty) export TERM=xterm-256color ;;
    *) export TERM=xterm-256color ;;
  esac
fi

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Terminal Wrap Behavior Test Suite                        ║"
echo "║     ansilust UTF8ANSI Renderer Experiment                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This suite will test how your terminal handles wrap control."
echo ""
echo "Terminal Information:"
echo "  TERM: $ORIGINAL_TERM"
# Try stty first, fallback to tput
if command -v stty &>/dev/null && TERM_SIZE=$(stty size 2>/dev/null); then
  TERM_LINES=$(echo "$TERM_SIZE" | cut -d' ' -f1)
  TERM_COLS=$(echo "$TERM_SIZE" | cut -d' ' -f2)
  echo "  Size: ${TERM_COLS}x${TERM_LINES} (cols x lines)"
elif command -v tput &>/dev/null; then
  echo "  Size: $(tput cols 2>/dev/null || echo '?')x$(tput lines 2>/dev/null || echo '?') (cols x lines)"
else
  echo "  Size: unknown"
fi
echo "  Shell: $SHELL"
echo ""
echo "Tests to run:"
echo "  1. Baseline (natural wrapping)"
echo "  2. No-Wrap Mode (CSI ?7l/h)"
echo "  3. Advanced Strategies"
echo ""
echo "Press ENTER to begin testing..."
read

# Test 1: Baseline
echo ""
echo "═══════════════════════════════════════════════════════════════"
"$SCRIPT_DIR/baseline-test.sh"

# Test 2: No-Wrap
echo ""
echo "═══════════════════════════════════════════════════════════════"
"$SCRIPT_DIR/nowrap-test.sh"

# Test 3: Advanced
echo ""
echo "═══════════════════════════════════════════════════════════════"
"$SCRIPT_DIR/advanced-test.sh"

# Complete
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     All Tests Complete!                                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Please record your findings in findings.md"
echo ""
echo "Key observations to document:"
echo "  • Terminal name and version"
echo "  • Which tests succeeded/failed"
echo "  • Whether wrap mode was properly restored"
echo "  • Any visual artifacts or unexpected behavior"
echo "  • Recommended approach for the renderer"
echo ""
