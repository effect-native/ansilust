# Prior Art Notes

This memo captures the concrete references that justify each settled IR decision. Use it alongside the [decision log](decisions.md) whenever you’re auditing or extending the spec.

---

## Ghostty (reference/ghostty/ghostty)

### D1 & D2 — Cell Grid SoA and Grapheme Pool  
- `Page` stores rows, cells, arenas, style sets, hyperlink maps, and dirty flags as parallel offsets inside one mmap’d buffer, matching our SoA plan.  
  [↗ source](../../reference/ghostty/ghostty/src/terminal/page.zig#L93-L172)  
- Grapheme data is held in a dedicated bitmap allocator plus an offset hash map; multi-codepoint sequences never live in the primary cell array.  
  [↗ source](../../reference/ghostty/ghostty/src/terminal/page.zig#L108-L125)

### D4 & D5 — Raw Bytes + Normalized Unicode  
- Each `Cell` is a packed 64-bit struct with a `content_tag` discriminating between codepoint, grapheme, or background-only payloads. This mirrors our “raw bytes arena + normalized scalar” duality.  
  [↗ source](../../reference/ghostty/ghostty/src/terminal/page.zig#L1994-L2070)

### D6 — Palette Model  
- Ghostty defines a 256-entry palette, reserves indices 0–15 for named ANSI colors, and documents cube/gray ramp filling. This underpins our shared palette object.  
  [↗ source](../../reference/ghostty/ghostty/src/terminal/color.zig#L5-L129)

### D7 — Attribute Bitflags  
- `style.Style.Flags` compresses classic + modern attributes into a packed `u16`, leaving spare bits. Scaling that to a 32-bit field in our IR keeps parity while adding headroom.  
  [↗ source](../../reference/ghostty/ghostty/src/terminal/style.zig#L19-L41)

---

## Bun (reference/bun)

### D3 — Source Encoding Enum Strategy  
- Bun’s text encoding registry normalizes names via the IANA charset tables (ICU/WebKit lineage). Reusing MIBenum discriminants keeps us aligned with a shipping Zig codebase.  
  [↗ source](../../reference/bun/src/bun.js/bindings/TextEncodingRegistry.cpp#L365-L383)

### Allocator & Error Idioms (supports D13/D17)  
- Global allocator configuration and exit paths demonstrate the “IR owns allocations” pattern we adopted.  
  [↗ source](../../reference/bun/src/Global.zig#L1-L160)  
- Error handling throughout Bun favors explicit error unions (`error{…}`) over optional returns, reinforcing our dedicated error set in [D17](decisions.md#d17-error-model).

---

## ansilove (reference/ansilove)

### D11 — SAUCE Preservation  
- Documentation stresses that SAUCE is a mandatory 128-byte record providing fonts, column counts, flags, and must be retained verbatim.  
  [↗ source](../../reference/ansilove/AGENTS.md#sauce-metadata-critical)  
- The CLI (`ansilove/src/ansilove.c`) only renders correctly when SAUCE hints override defaults, underscoring dual storage (raw bytes + parsed view).  
  [↗ source](../../reference/ansilove/src/ansilove.c#L185-L343)

### Classic Format Fidelity  
- ANSI loader keeps raw character bytes, columns, and attributes in struct arrays, backing our decision to archive raw bytes per cell.  
  [↗ source](../../reference/libansilove/libansilove/src/loaders/ansi.c#L70-L214)

---

## Open Questions (Tom/Bramwell to finalize)

These areas still require explicit sign-off because no reference project gives us a complete answer yet:

- [D8 & D9](decisions.md#d8-ansimation-frame-representation) — ansimation frame storage and delta mechanics (Ghostty doesn’t expose an IR-level animation pipeline).  
- [D12](decisions.md#d12-serialization-format) — binary layout/versioning.  
- [D14](decisions.md#d14-api-surface-scope) — public API breadth (Ghostty/Bun keep comparable APIs internal).  
- Vendor-band encoding additions beyond the documented set in [D3](decisions.md#d3-source-encoding-tag) — every new charset must cite an archival spec before we assign IDs.

Keep this document updated as we learn more or when those open issues get resolved.