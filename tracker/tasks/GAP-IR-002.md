---
id: GAP-IR-002
title: OpenTUI bridge tests (to_optimized_buffer)
area: ir
status: pending
priority: medium
spec_ref:
  - .specs/ir/design.md#opentui-compatibility
  - reference/opentui/AGENTS.md
code_refs:
  - src/ir/opentui.zig
acceptance:
  - Tests verify conversion from Document to OptimizedBuffer structure
  - Color mapping (palette → RGBA, RGB → RGBA)
  - Attribute flags mapping (bold, italic, underline, etc.)
  - Grapheme pool integration verified
  - Round-trip Document → OptimizedBuffer → render matches expectations
blocked_by: []
labels:
  - opentui
  - integration
  - IR
created: 2025-11-03
---

## Context

`src/ir/opentui.zig` exists but has no tests. OpenTUI is a primary integration target.

From `.specs/ir/design.md`:
- IR should convert cleanly to OpenTUI's OptimizedBuffer
- OptimizedBuffer uses structure-of-arrays: separate char[], fg[], bg[], attrs[]
- Colors are RGBA floats (0.0-1.0)
- Attributes are u8 bitflags

## Test Coverage Needed

1. **Basic conversion**: Simple document → OptimizedBuffer
2. **Color mapping**:
   - Palette indices → RGBA via DOS palette lookup
   - RGB → RGBA (add alpha=1.0)
   - Color.none → default terminal color
3. **Attribute mapping**:
   - Bold, italic, underline, blink → bitflags
   - Verify bitflag values match OpenTUI conventions
4. **Grapheme pool**: Multi-codepoint chars stored/retrieved correctly
5. **Dimensions**: Width/height match
6. **Round-trip**: Document → OptimizedBuffer → render → matches expectations

## Implementation Notes

- May need to read OpenTUI source to verify exact RGBA conversions
- DOS palette RGB values must match standard (see `src/ir/color.zig`)
- Bitflag order/values critical for compatibility

## Reference

- `reference/opentui/AGENTS.md` for OptimizedBuffer structure
- `.specs/ir/prior-art-notes.md#opentui` for integration notes
