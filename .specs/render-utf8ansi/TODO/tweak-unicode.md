✅ COMPLETED (2025-11-01)

## Original Task

Improve character baseline alignment for H4-2017.ANS rendering in modern terminal fonts.

## Issues Identified

1. Line 5: Superscript 2 rendering as ▓ instead of ²
2. Line 16: Rectangle character ▬ too high above baseline
3. Multiple lines: Bullet operator ∙ too bold/heavy
4. Multiple lines: Tilde ~ too low, breaking visual continuity

## Solutions Implemented

### 1. Fixed Superscript 2 (CP437 0xFD)
**Root Cause:** Double-conversion bug - renderer treated Unicode scalars as CP437 bytes.
**Fix:** Removed CP437→Unicode lookup in renderer (parser already converts).
**Result:** `j$$$Q²"\`'²7$$$L` renders correctly.

### 2. Adjusted Rectangle Character (CP437 0x16)
**Mapping:** U+25AC ▬ → U+2583 ▃ (LOWER THREE EIGHTHS BLOCK)
**Rationale:** Baseline alignment, maintains gaps between characters.
**Result:** `_,▃▃,_` sits near baseline like underscores.

### 3. Lightened Bullet Character (CP437 0xF9)
**Mapping:** U+2219 ∙ → U+2027 ‧ (HYPHENATION POINT)
**Rationale:** Lighter weight, not already mapped elsewhere.
**Result:** `‧‧‧‧‧‧‧‧‧` has appropriate visual weight.

### 4. Global Tilde Adjustment (ASCII 0x7E)
**Mapping:** U+007E ~ → U+02DC ˜ (SMALL TILDE) - renderer-level substitution
**Rationale:** Better baseline alignment in decorative patterns.
**Result:** `j$$│˜ .·:·. ˜│$$` forms smooth line.

## Test Coverage

Added 2 new tests (127 total passing):
- Contextual tilde rendering ("`˜ sequence)
- Global tilde behavior verification

## Files Modified

- `src/parsers/ansi.zig` - CP437_CONTROL table, CP437_EXTENDED tweaks
- `src/renderers/utf8ansi.zig` - Contextual glyph rendering (tilde)
- `src/renderers/utf8ansi_test.zig` - Updated Unicode expectations
- `src/parsers/ansi_test.zig` - Updated NUL byte expectations

## Validation

H4-2017.ANS now renders with proper character baseline alignment throughout.
