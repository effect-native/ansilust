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

## Green Phase Update

- Green phase complete.
- Implemented the smallest Ghostty bridge behavior required by the pinned tests in `src/ir/ghostty.zig`.
- The bridge now emits a replayable VT surface for visible rows, preserves `Color.none` via `SGR 39/49`, and replays OSC 8 hyperlink open/close metadata.
- Avoided unrelated OpenTUI bridge changes.

## Passing Evidence

- Command: `zig test src/ir/ghostty.zig`
- Result: all 52 tests passed, including both pinned Ghostty bridge tests.
- Command: `zig build test`
- Result: Ghostty bridge coverage remained green, but the full suite still has unrelated pre-existing failures in `src/download/protocols/http_test.zig`.

## Refactor Phase Update

- Refactor phase complete.
- Extracted Ghostty row emission state into a small `RowState` helper and split hyperlink transitions into dedicated open/close helpers.
- Hoisted repeated control-sequence and default-color literals into named constants to improve locality without changing emitted VT behavior.

## Refactor Evidence

- Command: `zig test src/ir/ghostty.zig`
- Result: all 52 tests passed after the refactor, including the pinned Ghostty VT surface and metadata preservation checks.
