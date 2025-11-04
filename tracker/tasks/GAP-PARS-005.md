---
id: GAP-PARS-005
title: ANSI SGR completeness (italic, faint, underline styles, etc.)
area: parsers
status: pending
priority: high
spec_ref:
  - .specs/ir/TEST_CASE_MAPPING.md#sgr-tests
  - .specs/ir/design.md#attributes
code_refs:
  - src/parsers/ansi.zig
  - src/parsers/ansi_test.zig
  - src/ir/attributes.zig
acceptance:
  - Tests added for SGR 2 (faint)
  - Tests added for SGR 3 (italic)
  - Tests added for SGR 4:X underline styles (none, single, double, curly, dotted, dashed)
  - Tests added for SGR 7 (inverse/reverse)
  - Tests added for SGR 9 (strikethrough)
  - Tests added for SGR 53 (overline)
  - Tests added for SGR 58/59 (underline color set/default)
  - All new tests pass
blocked_by: []
labels:
  - SGR
  - attributes
  - modern-terminals
created: 2025-11-03
---

## Context

Current ANSI parser only handles basic SGR codes (colors, bold, blink, underline as boolean).

Modern terminals and Ghostty support richer attributes:
- Multiple underline styles (SGR 4:0 through 4:5)
- Separate underline color (SGR 58;2;r;g;b or 58;5;n)
- Faint, italic, inverse, strikethrough, overline

## Missing SGR Coverage

From gap analysis:
- No handling/tests for italic (SGR 3)
- No handling/tests for faint (SGR 2)
- No handling/tests for underline styles beyond boolean
- No handling/tests for strikethrough (SGR 9)
- No handling/tests for overline (SGR 53)
- No handling/tests for inverse/reverse (SGR 7)
- No handling/tests for underline color (SGR 58/59)

## Implementation Notes

1. Extend `src/parsers/ansi.zig` StyleState.applySGR() to handle new codes
2. Add tests to `src/parsers/ansi_test.zig` following existing pattern
3. Verify `src/ir/attributes.zig` already supports these (it does: UnderlineStyle, underline_color, etc.)
4. Ensure renderer emits these correctly (may need GAP-REND-003 for underline color output)

## Reference

- `.specs/ir/TEST_CASE_MAPPING.md` Section 1.2 has complete SGR test templates
- `reference/ghostty/src/terminal/Parser.zig` for modern SGR handling patterns
