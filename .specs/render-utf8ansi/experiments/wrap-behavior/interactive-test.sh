#!/usr/bin/env bash
# Interactive wrap behavior test - asks questions one at a time
# Produces a copy-pasteable report at the end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Handle unknown TERM values gracefully
# Save original TERM for reporting
ORIGINAL_TERM="$TERM"

# If tput/infocmp can't find the terminfo, fall back to a compatible value
if ! infocmp "$TERM" &>/dev/null; then
  # Map known Ghostty terms to xterm-256color
  case "$TERM" in
    xterm-ghostty)
      export TERM=xterm-256color
      ;;
    *)
      # Generic fallback
      export TERM=xterm-256color
      ;;
  esac
fi

# Detect terminal size
get_terminal_size() {
  if command -v stty &>/dev/null && TERM_SIZE=$(stty size 2>/dev/null); then
    TERM_LINES=$(echo "$TERM_SIZE" | cut -d' ' -f1)
    TERM_COLS=$(echo "$TERM_SIZE" | cut -d' ' -f2)
    echo "${TERM_COLS}x${TERM_LINES}"
  elif command -v tput &>/dev/null; then
    echo "$(tput cols 2>/dev/null || echo '?')x$(tput lines 2>/dev/null || echo '?')"
  else
    echo "unknown"
  fi
}

# Storage for responses
declare -A RESPONSES

# Helper to ask a question
ask() {
  local key="$1"
  local question="$2"
  echo ""
  echo "Q: $question"
  echo -n "A: "
  read -r answer
  RESPONSES["$key"]="$answer"
}

# Clear screen and start
clear
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Terminal Wrap Behavior - Interactive Test                ║"
echo "║     ansilust UTF8ANSI Renderer Experiment                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This test will ask you questions one at a time."
echo "Answer each question, then press ENTER to continue."
echo "At the end, you'll get a report to copy & paste."
echo ""
echo "Press ENTER to begin..."
read

# Collect basic info automatically
RESPONSES["term_var"]="$ORIGINAL_TERM"
RESPONSES["term_size"]="$(get_terminal_size)"

# Try to detect terminal name from parent process
if command -v ps &> /dev/null; then
    PARENT_PID=$(ps -o ppid= -p $$ | tr -d ' ')
    TERMINAL_NAME=$(ps -o comm= -p $PARENT_PID 2>/dev/null | tr -d ' ' || echo "unknown")
    RESPONSES["terminal_name"]="$TERMINAL_NAME"
else
    RESPONSES["terminal_name"]="unknown"
fi

# Try to get version if we know the terminal
RESPONSES["terminal_version"]="unknown"
case "${RESPONSES[terminal_name]}" in
    ghostty)
        RESPONSES["terminal_version"]=$(ghostty --version 2>/dev/null || echo "unknown")
        ;;
    alacritty)
        RESPONSES["terminal_version"]=$(alacritty --version 2>/dev/null | head -1 || echo "unknown")
        ;;
    kitty)
        RESPONSES["terminal_version"]=$(kitty --version 2>/dev/null || echo "unknown")
        ;;
    wezterm|wezterm-gui)
        RESPONSES["terminal_version"]=$(wezterm --version 2>/dev/null || echo "unknown")
        ;;
esac

# Test 1: Baseline wrapping
clear
echo "=== TEST 1: Baseline Wrapping ==="
echo ""
echo "I'm going to display 160-column colored bars."
echo "Observe how your terminal handles them."
echo ""
echo "Press ENTER to display..."
read

cat "$SCRIPT_DIR/test-wide.ans"

echo ""
echo ""
ask "baseline_wrapped" "Did the colored bars wrap at your terminal width? (yes/no)"
ask "baseline_artifacts" "Were there visual artifacts where wrapping occurred? (yes/no/none)"
ask "baseline_colors" "Did colors remain correct after wrapping? (yes/no)"

# Test 2: No-wrap mode
clear
echo "=== TEST 2: No-Wrap Mode (DECAWM) ==="
echo ""
echo "I'm going to disable auto-wrap with CSI ?7l, display the bars,"
echo "then re-enable auto-wrap with CSI ?7h."
echo ""
echo "Press ENTER to display..."
read

printf '\033[?7l'
sleep 0.1
cat "$SCRIPT_DIR/test-wide.ans"
echo ""
echo ""
printf '\033[?7h'

ask "nowrap_prevented" "Did the bars stay on single lines (no wrapping)? (yes/no)"
ask "nowrap_clipped" "Was overflow clipped at the terminal edge? (yes/no/unsure)"

# Test wrap restoration
echo ""
echo "Testing if auto-wrap was restored..."
printf "Long line test: "
for i in {1..200}; do printf "%d" $((i % 10)); done
printf "\n"
echo ""

ask "nowrap_restored" "Did the long line above wrap normally? (yes/no)"

# Test 3: Per-line toggle
clear
echo "=== TEST 3: Per-Line Wrap Toggle ==="
echo ""
echo "I'm going to toggle wrap mode ON/OFF for each line."
echo ""
echo "Press ENTER to display..."
read

while IFS= read -r line; do
  printf '\033[?7l'
  printf '%s\n' "$line"
  printf '\033[?7h'
done < "$SCRIPT_DIR/test-wide.ans"

echo ""
echo ""
ask "perline_worked" "Did per-line toggling prevent wrapping? (yes/no)"
ask "perline_issues" "Any visual glitches with this approach? (yes/no/describe)"

# Test 4: Alternate screen buffer
clear
echo "=== TEST 4: Alternate Screen Buffer ==="
echo ""
echo "I'm going to switch to alternate screen, disable wrap,"
echo "display bars, then return to normal screen."
echo ""
echo "Press ENTER to switch to alternate screen..."
read

printf '\033[?1049h'  # Enter alternate screen
printf '\033[2J'      # Clear
printf '\033[H'       # Home
printf '\033[?7l'     # Disable wrap

cat "$SCRIPT_DIR/test-wide.ans"

echo ""
echo ""
echo "Press ENTER to return to normal screen..."
read

printf '\033[?7h'     # Re-enable wrap
printf '\033[?1049l'  # Exit alternate screen

ask "altscreen_worked" "Did wrap control work in alternate screen? (yes/no)"
ask "altscreen_state" "Did wrap mode restore correctly after returning? (yes/no)"

# Final questions
clear
echo "=== Final Assessment ==="
echo ""
ask "overall_decawm" "Overall, does DECAWM (CSI ?7l/h) work reliably in this terminal? (yes/no/partial)"
ask "recommended" "What strategy would you recommend for this terminal? (always-use-decawm/use-with-fallback/dont-use-decawm/detect-width)"
ask "notes" "Any other observations or quirks? (or press ENTER to skip)"

# Generate report
clear
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Test Complete - Copy & Paste Report Below                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "TERMINAL WRAP BEHAVIOR TEST REPORT"
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "Terminal: ${RESPONSES[terminal_name]}"
echo "Version: ${RESPONSES[terminal_version]}"
echo "TERM variable: ${RESPONSES[term_var]}"
echo "Size: ${RESPONSES[term_size]}"
echo ""
echo "=== Baseline Wrapping ==="
echo "Bars wrapped at terminal width: ${RESPONSES[baseline_wrapped]}"
echo "Visual artifacts: ${RESPONSES[baseline_artifacts]}"
echo "Colors correct: ${RESPONSES[baseline_colors]}"
echo ""
echo "=== No-Wrap Mode (CSI ?7l/h) ==="
echo "Prevented wrapping: ${RESPONSES[nowrap_prevented]}"
echo "Overflow clipped correctly: ${RESPONSES[nowrap_clipped]}"
echo "Auto-wrap restored: ${RESPONSES[nowrap_restored]}"
echo ""
echo "=== Per-Line Toggle ==="
echo "Worked: ${RESPONSES[perline_worked]}"
echo "Issues: ${RESPONSES[perline_issues]}"
echo ""
echo "=== Alternate Screen Buffer ==="
echo "Wrap control worked: ${RESPONSES[altscreen_worked]}"
echo "State restored correctly: ${RESPONSES[altscreen_state]}"
echo ""
echo "=== Overall Assessment ==="
echo "DECAWM works reliably: ${RESPONSES[overall_decawm]}"
echo "Recommended strategy: ${RESPONSES[recommended]}"
echo "Additional notes: ${RESPONSES[notes]}"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "Copy everything from 'TERMINAL WRAP BEHAVIOR TEST REPORT' above"
echo "and paste it to continue the conversation."
echo ""
