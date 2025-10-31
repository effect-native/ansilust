#!/usr/bin/env bash
# Detect terminal information for test documentation

# Handle unknown TERM values gracefully
ORIGINAL_TERM="${TERM:-unknown}"
if [ "$ORIGINAL_TERM" != "unknown" ] && ! infocmp "$TERM" &>/dev/null; then
  case "$TERM" in
    xterm-ghostty) export TERM=xterm-256color ;;
    *) export TERM=xterm-256color ;;
  esac
fi

echo "=== Terminal Detection ==="
echo ""

# Terminal type
echo "TERM: $ORIGINAL_TERM"
if [ "$ORIGINAL_TERM" != "$TERM" ]; then
  echo "  (using $TERM for compatibility)"
fi
echo "COLORTERM: ${COLORTERM:-unknown}"
echo ""

# Terminal program
if command -v ps &> /dev/null; then
    PARENT_PID=$(ps -o ppid= -p $$)
    TERMINAL_NAME=$(ps -o comm= -p $PARENT_PID 2>/dev/null || echo "unknown")
    echo "Parent process: $TERMINAL_NAME"
fi
echo ""

# Size detection methods
echo "Terminal size detection:"
echo ""

# Method 1: tput
if command -v tput &> /dev/null; then
    COLS=$(tput cols 2>/dev/null || echo "error")
    LINES=$(tput lines 2>/dev/null || echo "error")
    echo "  tput: ${COLS}x${LINES} (cols x lines)"
else
    echo "  tput: not available"
fi

# Method 2: stty
if command -v stty &> /dev/null; then
    SIZE=$(stty size 2>/dev/null || echo "error error")
    STTY_LINES=$(echo $SIZE | cut -d' ' -f1)
    STTY_COLS=$(echo $SIZE | cut -d' ' -f2)
    echo "  stty: ${STTY_COLS}x${STTY_LINES} (cols x lines)"
else
    echo "  stty: not available"
fi

# Method 3: Environment variables
echo "  COLUMNS env: ${COLUMNS:-not set}"
echo "  LINES env: ${LINES:-not set}"

echo ""

# Color support
echo "Color support:"
if command -v tput &> /dev/null; then
    COLORS=$(tput colors 2>/dev/null || echo "unknown")
    echo "  tput colors: $COLORS"
else
    echo "  tput colors: unavailable"
fi

# Test true color support
echo ""
echo "True color test (24-bit RGB):"
echo "  If you see a smooth gradient below, true color is supported:"
printf "  "
for i in {0..255}; do
    printf "\e[38;2;${i};$((255-i));128m█\e[0m"
done
printf "\n"

echo ""
echo "256 color test:"
echo "  If you see multiple colors below, 256-color is supported:"
printf "  "
for i in {0..15}; do
    printf "\e[48;5;${i}m  \e[0m"
done
printf "\n"

echo ""
echo "=== Detection Complete ==="
echo ""
echo "Copy this information to findings.md for your test terminal."
