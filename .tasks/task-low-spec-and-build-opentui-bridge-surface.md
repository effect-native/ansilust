---
id: task-low-spec-and-build-opentui-bridge-surface
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Spec And Build OpenTUI Bridge Surface

Turn `src/ir/opentui.zig` from its current minimal placeholder into a tested bridge or explicitly demote the surface from near-term scope.

## Completion evidence

- `src/ir/opentui.zig` now exposes a concrete owned `OptimizedBuffer` with OpenTUI-style parallel slices instead of a width/height-only placeholder.
- `toOptimizedBuffer` now maps IR cells into codepoint/grapheme, normalized color, attribute, wide-flag, hyperlink, and dirty slices with deterministic palette fallback behavior.
- Added bridge tests in `src/ir/opentui.zig` covering scalar projection, default-color signaling, projected attribute bits, grapheme reuse, and custom palette override resolution.
- Validation: `zig test src/ir/opentui.zig`.
