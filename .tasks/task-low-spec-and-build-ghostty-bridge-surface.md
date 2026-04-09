---
id: task-low-spec-and-build-ghostty-bridge-surface
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Spec And Build Ghostty Bridge Surface

Turn `src/ir/ghostty.zig` from a stub into a tested bridge or explicitly demote the surface from near-term scope.

## Red Phase Update

- Red phase complete.
- Added executable failing tests in `src/ir/ghostty.zig` that pin the minimum supported Ghostty bridge contract.
- The new coverage requires `toGhosttyStream` to emit a replayable VT stream for visible document rows and to preserve Ghostty-critical `Color.none` plus OSC 8 hyperlink metadata.
- Production bridge implementation intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `zig test src/ir/ghostty.zig`
- Observed failure: `toGhosttyStream emits minimum visible Ghostty VT surface` fails because `src/ir/ghostty.zig:17` still returns the explicit stub error `error.InvalidState` instead of writing any Ghostty-compatible VT output.
- Observed failure: `toGhosttyStream preserves Ghostty-critical color none and hyperlink metadata` fails for the same reason before it can emit `SGR 39/49` or OSC 8 sequences.
