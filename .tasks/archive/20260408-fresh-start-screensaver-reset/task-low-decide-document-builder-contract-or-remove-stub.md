---
id: task-low-decide-document-builder-contract-or-remove-stub
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Decide Document Builder Contract Or Remove Stub

Either promote `src/ir/document_builder.zig` into a tested supported surface or demote/remove the stub so the IR module surface stays binary.

## Unblocked Evidence

- Direct parent medium task `task-med-implement-ir-serialization-surface` was resolved as governance.
- This low task now carries the remaining atomic contract decision work.

## Decision

- `src/ir/document_builder.zig` is demoted from the supported IR contract for now.
- The existing file remains a placeholder stub only and must not be treated as a supported public surface.
- Promotion now requires a separate follow-up that specifies parser-construction invariants and adds tests for the builder lifecycle.

## Completion Evidence

- Updated `.specs/ir/design.md` to remove `DocumentBuilder` from the active supported contract and mark it as deferred.
- Updated `STATUS.md` so project status no longer claims the builder stub as complete supported surface.
- Updated `.specs/ir/PHASE1_COMPLETE.md` to record the placeholder-only status for historical clarity.
