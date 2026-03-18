---
id: task-low-link-ir-ok-to-live-evidence
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Link IR OK To Live Evidence

Anchor the future IR constitution to current code, tests, and documentation evidence so it can be reconciled mechanically.

## Evidence

- Rewrote `.ok/ir.ok.md` to cite live checked-in IR evidence from `src/ir/**` and `src/parsers/ansi*.zig` instead of relying on `.specs/ir/**` intent alone.
- Added an explicit live-evidence section to `.ok/ir.ok.md` that points to current code, colocated tests, and parser integration coverage.
- Demoted unsupported implementation claims in `.ok/ir.ok.md` by marking serialization, Ghostty bridge, and OpenTUI bridge support as not-yet-live because `src/ir/serialize.zig`, `src/ir/ghostty.zig`, and `src/ir/opentui.zig` are still stubs.
- Recorded the current evidence gap for exact raw-byte preservation so future IR work must add real checked-in storage before the constitution can claim that capability as TRUE.
