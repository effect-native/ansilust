#!/usr/bin/env bash
# Advanced Test: Test additional wrap control strategies
# Tests cursor save/restore, alternate sequences, and edge cases

set -euo pipefail

echo "=== Terminal Wrap Behavior - Advanced Tests ==="
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

# Test 1: No-wrap with cursor position save/restore
echo "TEST 1: No-wrap + Cursor Save/Restore"
echo "---------------------------------------"
echo "Using: CSI 7 (save), CSI ?7l, content, CSI 8 (restore), CSI ?7h"
echo "Press ENTER..."
read

printf '\033[7'     # Save cursor position
printf '\033[?7l'   # Disable auto-wrap
cat "$(dirname "$0")/test-wide.ans"
printf '\033[8'     # Restore cursor position  
printf '\033[?7h'   # Re-enable auto-wrap

echo ""
echo "Result: Did cursor position affect wrap behavior?"
echo ""
sleep 1

# Test 2: Toggle wrap mid-render
echo "TEST 2: Toggle Wrap Mid-Render"
echo "-------------------------------"
echo "Rendering with wrap toggling between each line"
echo "Press ENTER..."
read

# Read file line by line
while IFS= read -r line; do
    printf '\033[?7l'  # Disable before each line
    printf '%s\n' "$line"
    printf '\033[?7h'  # Re-enable after each line
done < "$(dirname "$0")/test-wide.ans"

echo ""
echo "Result: Did per-line toggling work?"
echo ""
sleep 1

# Test 3: Clear screen before no-wrap render
echo "TEST 3: Clear Screen + No-Wrap"
echo "-------------------------------"
echo "Testing whether screen clear affects wrap mode"
echo "Press ENTER..."
read

printf '\033[2J'    # Clear screen
printf '\033[H'     # Move cursor to home
printf '\033[?7l'   # Disable auto-wrap
cat "$(dirname "$0")/test-wide.ans"
printf '\033[?7h'   # Re-enable auto-wrap

echo ""
echo ""
echo "Result: Did screen clear reset wrap mode?"
echo ""
sleep 1

# Test 4: Alternate screen buffer with no-wrap
echo "TEST 4: Alternate Screen Buffer + No-Wrap"
echo "------------------------------------------"
echo "Testing wrap control in alternate screen buffer"
echo "Press ENTER... (will return to normal screen after)"
read

printf '\033[?1049h'  # Enter alternate screen buffer
printf '\033[2J'      # Clear alternate screen
printf '\033[H'       # Home cursor
printf '\033[?7l'     # Disable auto-wrap
cat "$(dirname "$0")/test-wide.ans"
echo ""
echo ""
echo "Press ENTER to return to normal screen..."
read
printf '\033[?7h'     # Re-enable auto-wrap
printf '\033[?1049l'  # Exit alternate screen buffer

echo ""
echo "Result: Did alternate screen preserve wrap mode changes?"
echo ""

echo ""
echo "=== Advanced Tests Complete ==="
echo ""
echo "Summary Questions:"
echo "1. Which strategy worked best for preventing unwanted wrapping?"
echo "2. Were there any terminals that ignored all wrap control sequences?"
echo "3. Did any approach have side effects on the terminal state?"
echo "4. Should we always pair CSI ?7l with CSI ?7h in the renderer?"
echo ""
