---
id: task-med-close-ir-bridge-truth-gaps
level: medium
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Close IR Bridge Truth Gaps

Bring `.ok/ir.ok.md` back into sync with the current repository and resolve the remaining ambiguity around the OpenTUI bridge surface.

## Completion evidence

- Confirmed this medium gate was executable before making changes (`blocked_by: []`).
- Re-read `.ok/ir.ok.md` and verified the remaining stale IR truth was concentrated in the still-negative OpenTUI bridge claim.
- Replaced the minimal placeholder in `src/ir/opentui.zig` with a concrete bridge surface: `OptimizedBuffer` now owns parallel slices for codepoints, grapheme IDs, default-aware normalized foreground/background colors, projected attribute bits, wide flags, hyperlink IDs, and dirty flags, plus `deinit` cleanup.
- Added executable OpenTUI bridge coverage in `src/ir/opentui.zig` proving scalar-cell projection, default-color preservation, attribute-bit projection, grapheme-ID reuse, and document-palette override resolution.
- Validation: `zig test src/ir/opentui.zig`.
- Advanced the next executable work in `.tasks/` by marking `task-low-spec-and-build-opentui-bridge-surface` done and unblocking the remaining IR constitution follow-ups for serializer/Ghostty and OpenTUI evidence promotion.
