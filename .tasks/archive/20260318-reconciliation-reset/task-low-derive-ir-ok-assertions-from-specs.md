---
id: task-low-derive-ir-ok-assertions-from-specs
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Derive IR OK Assertions

Extract the binary, evergreen assertions from `.specs/ir/` that should govern current IR reality.

## Evidence

- Tightened `.ok/ir.ok.md` with spec-derived binary assertions for the IR document root, SoA cell-grid fields, raw-byte and encoding preservation, grapheme pool, color union semantics, palette governance, 32-bit attributes, SAUCE and font preservation, animation framing, hyperlink and event-log scope, narrow API scope, and versioned binary serialization.
- Added stronger negative assertions to prevent treating future-phase topics or uncited vendor encodings as current constitutional truth.
- Added governance rules clarifying that `.specs/ir/requirements.md` informs the constitution, but only `.ok/ir.ok.md` defines current constitutional IR obligations.
