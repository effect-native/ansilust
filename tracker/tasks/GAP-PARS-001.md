---
id: GAP-PARS-001
title: Binary parser (160x25, attr byte)
area: parsers
status: pending
priority: high
spec_ref:
  - .specs/ir/requirements.md#classic-bbs-art
  - .specs/ir/TEST_CASE_MAPPING.md#part-3
code_refs:
  - src/parsers/lib.zig
  - reference/libansilove/libansilove/src/loaders/binary.c
acceptance:
  - All tests in src/parsers/binary_test.zig pass
  - 160-column format parsing verified
  - Attribute byte fg/bg/bold/blink parsed correctly
  - iCE colors mode behavior (blink → bright background) verified
  - Round-trip test through IR to renderer
blocked_by: []
labels:
  - classic
  - BBS
created: 2025-11-03
---

## Context

Binary format is one of the classic BBS art formats supported by libansilove.

**Format Specification**:
- Fixed 160 columns × 25 rows
- Each cell: character byte (1) + attribute byte (1)
- Attribute byte encoding:
  - Bits 0-3: Foreground color (0-15)
  - Bits 4-6: Background color (0-7)
  - Bit 7: Blink (or bright background in iCE colors mode)

**Reference Implementation**: `reference/libansilove/libansilove/src/loaders/binary.c`

## Test Cases

From `.specs/ir/TEST_CASE_MAPPING.md#part-3`:

1. Parse 160-column format
2. Parse attribute byte (foreground, background, bold, blink)
3. iCE colors mode (blink → bright background)

## Notes

- Must handle iCE colors flag from SAUCE or document metadata
- Bold flag is encoded in bit 3 of attribute byte (part of foreground color range 8-15)
