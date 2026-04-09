---
id: task-low-promote-serialize-and-ghostty-evidence-into-ir-ok
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Promote Serialize And Ghostty Evidence Into IR OK

Update `.ok/ir.ok.md` so it reflects the now-landed serializer and Ghostty bridge instead of treating both surfaces as purely negative evidence.

## Evidence

- Updated `.ok/ir.ok.md` to promote checked-in serializer evidence from `src/ir/serialize.zig`, including the roundtrip tests `serialize: roundtrip preserves default document contract` and `serialize: roundtrip preserves populated cells and resources`.
- Updated `.ok/ir.ok.md` to promote checked-in Ghostty bridge evidence from `src/ir/ghostty.zig`, including the tests `toGhosttyStream emits minimum visible Ghostty VT surface` and `toGhosttyStream preserves Ghostty-critical color none and hyperlink metadata`.
- Kept OpenTUI out of this scoped reconciliation update to avoid crossing the parallel queue boundary named in the task handoff.
