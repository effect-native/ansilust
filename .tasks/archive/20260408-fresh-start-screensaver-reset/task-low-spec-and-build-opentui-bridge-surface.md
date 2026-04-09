---
id: task-low-spec-and-build-opentui-bridge-surface
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Spec And Build OpenTUI Bridge Surface

Turn `src/ir/opentui.zig` from a stub into a tested bridge or explicitly demote the surface from near-term scope.

## Red phase update

- Added failing executable coverage in `src/ir/opentui.zig` for the minimum bridge surface contract:
  - the module should expose a concrete `OptimizedBuffer` bridge type if this surface remains in near-term scope;
  - `toOptimizedBuffer` should return a buffer payload instead of `Error!void`.
- Intentionally avoided `src/ir/ghostty.zig` and production bridge implementation.

## Failure evidence

- Command: `zig test src/ir/opentui.zig`
- Result: expected RED failure captured (`50 passed; 2 failed`)
- Assertion failures:
  - `OpenTUI bridge exports a concrete buffer surface` failed because `src/ir/opentui.zig` does not declare `OptimizedBuffer`.
  - `toOptimizedBuffer returns a buffer payload instead of void` failed because the exported bridge function still returns `errors.Error!void`.

## Phase status

- RED phase complete: failing coverage added and verified against current implementation.
