---
id: GAP-IR-001
title: Wide/CJK/combining grapheme handling with spacer cells
area: ir
status: pending
priority: high
spec_ref:
  - .specs/ir/design.md#wide-characters
  - .specs/ir/requirements.md#modern-terminals
code_refs:
  - src/ir/cell_grid.zig
  - src/ir/document.zig
  - reference/ghostty/src/terminal/Screen.zig
acceptance:
  - Tests for double-width characters (CJK, emoji) with spacer_head/spacer_tail behavior
  - Tests for combining grapheme sequences (base + combining marks)
  - GraphemePool correctly stores multi-codepoint sequences
  - Cell iteration skips spacer cells correctly
  - Renderer produces correct alignment for mixed-width content
blocked_by: []
labels:
  - unicode
  - graphemes
  - CJK
  - Ghostty
created: 2025-11-03
---

## Context

Ghostty IR uses explicit spacer cells for wide characters:
- Wide char occupies 2+ cells
- First cell: `spacer_head` with content
- Subsequent cells: `spacer_tail` markers

Current ansilust IR has:
- GraphemePool for multi-codepoint storage
- Cell.Contents enum with `scalar` and `grapheme_id`
- No explicit width tracking or spacer mechanism

## Gap

No tests verify:
1. Double-width character handling (emoji, CJK)
2. Spacer cell semantics
3. Combining sequences (e.g., `e` + combining acute = `é`)
4. Iteration skipping spacer cells
5. Renderer alignment with mixed widths

## Implementation Notes

From Ghostty study (`.specs/ir/prior-art-notes.md#ghostty`):
- Wide chars need explicit width tracking
- Spacer cells prevent overwrites
- Grapheme clusters stored separately with reference-counting

Possible approach:
1. Add `width: u8` field to Cell or CellContents
2. Add `spacer: bool` flag or variant
3. Update setCell() to handle wide chars by setting width and marking spacer cells
4. Add tests covering emoji, CJK, and combining sequences

## Test Cases

1. Set emoji at (0,0) → cell (0,0) has content, cell (1,0) is spacer
2. Set combining sequence `e + ́` → stored in grapheme pool, rendered as single glyph
3. Iterate grid → spacer cells skipped or marked
4. Renderer emits correct column count for wide chars

## Reference

- `reference/ghostty/src/terminal/Screen.zig` lines showing spacer_head/tail
- `.specs/ir/PABLODRAW_COMPARISON.md` for width handling notes
