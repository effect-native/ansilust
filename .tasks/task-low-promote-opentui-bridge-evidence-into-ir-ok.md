---
id: task-low-promote-opentui-bridge-evidence-into-ir-ok
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Promote OpenTUI Bridge Evidence Into IR OK

Update `.ok/ir.ok.md` so it cites the now-landed `src/ir/opentui.zig` bridge surface and removes the stale claim that ansilust lacks a shipped OpenTUI conversion bridge.

## Evidence

- Promoted `src/ir/opentui.zig` from implementation-gap language into checked-in bridge evidence within `.ok/ir.ok.md`.
- Added a TRUE constitutional claim for shipped `toOptimizedBuffer` / `OptimizedBuffer` coverage while preserving the existing serializer and Ghostty evidence unchanged.
- Removed stale FALSE claims that the IR lacks a shipped OpenTUI conversion bridge.
