---
id: GAP-REND-002
title: iCE colors in renderer (blink → bright background)
area: renderers
status: pending
priority: medium
spec_ref:
  - .specs/ir/design.md#ice-colors
  - .specs/render-utf8ansi/requirements.md
code_refs:
  - src/renderers/utf8ansi.zig
  - src/renderers/utf8ansi_test.zig
acceptance:
  - When document.ice_colors == true, renderer maps blink attribute to bright background
  - Tests verify blink → palette 8-15 background colors
  - Tests verify standard mode (ice_colors == false) emits SGR 5 for blink
  - Round-trip test: ANSI with iCE flag → parse → render → correct output
blocked_by: []
labels:
  - renderer
  - ice-colors
  - blink
created: 2025-11-03
---

## Context

iCE colors mode repurposes the blink attribute for high-intensity backgrounds:
- Standard mode: blink attribute → SGR 5 (blinking text)
- iCE mode: blink attribute → bright background colors (palette 8-15)

From IR design:
- `Document.ice_colors: bool` flag (set from SAUCE or format defaults)
- `Attributes.blink: bool` field

Current renderer (`src/renderers/utf8ansi.zig`) does not check `ice_colors` flag.

## Gap

No tests or implementation for:
1. Reading `document.ice_colors` flag in renderer
2. Mapping blink → bright background when flag is true
3. Emitting standard SGR 5 when flag is false

## Implementation Notes

Renderer logic (pseudo):
```zig
if (cell.attributes.blink) {
    if (document.ice_colors) {
        // Map background color to bright variant (add 8 to palette index)
        bg_bright = cell.bg_color.palette + 8;
        // Emit SGR for bright background
    } else {
        // Emit SGR 5 for blink
    }
}
```

## Test Cases

1. Document with ice_colors=false, blink=true → output contains `\x1b[5m`
2. Document with ice_colors=true, blink=true, bg=palette 0 → output emits bright black background (palette 8)
3. Round-trip: Parse ANSI with SAUCE iCE flag → render → verify bright backgrounds

## Reference

- `.specs/ir/prior-art-notes.md#libansilove` for iCE colors behavior
- `reference/libansilove/libansilove/src/loaders/binary.c` for attribute parsing with iCE mode
