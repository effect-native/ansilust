#!/bin/bash
# Test script for Bramwell to verify combining characters in Ghostty

echo "Testing combining characters in Ghostty"
echo "========================================"
echo ""

echo "1. Superscript a with combining underline (what we want for ª):"
printf "   ᵃ̲ (U+1D43 MODIFIER LETTER SMALL A + U+0332 COMBINING LOW LINE)\n"
echo ""

echo "2. In context (the actual pattern from H4-2017.ANS):"
printf "   ╚ᵃ̲\"\`˜\n"
echo ""

echo "3. Current rendering (without combining underline):"
printf "   ╚ª\"\`˜\n"
echo ""

echo "4. Multiple in sequence:"
printf "   ᵃ̲ ᵃ̲ ᵃ̲ ᵃ̲ ᵃ̲\n"
echo ""

echo "QUESTION FOR BRAMWELL:"
echo "Does the superscript 'a' show with an underline in items 1, 2, and 4?"
echo "Compare items 2 (with underline) vs 3 (current, no underline)."
echo ""
echo "If YES: We can implement combining character support for ª"
echo "If NO:  We need a different solution"
