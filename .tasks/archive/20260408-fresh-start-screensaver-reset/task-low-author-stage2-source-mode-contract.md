---
id: task-low-author-stage2-source-mode-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Author Stage 2 Source Mode Contract

Define the next supported source-mode surface beyond `auto` without prematurely depending on `.index.db` or mirror workflows.

## Note

- Unblocked on 2026-04-08 after `task-med-spec-stage2-source-and-config-growth` was completed as task-governance orchestration.

## Completion evidence

- Confirmed this task was unblocked before editing (`blocked_by: []`).
- Authored the Stage 2 screensaver source-mode contract in `.specs/screensaver/requirements.md` as a doc-only change.
- Defined the first additive post-Stage-1 source mode as `source.mode = "local_archive"`.
- Kept the contract local-only: `packs/` is the primary managed archive surface, while `random/` and `local/` remain eligible fallback roots.
- Explicitly kept `.index.db`, mirror sync, bootstrap, and remote growth out of this contract so the new mode does not imply runtime or catalog authority changes.
- Preserved `source.mode = "auto"` as the shipped default contract to avoid redefining current Stage 1 behavior.
- Avoided runtime code changes and limited scope to the task file plus the screensaver requirements needed to record the contract.
