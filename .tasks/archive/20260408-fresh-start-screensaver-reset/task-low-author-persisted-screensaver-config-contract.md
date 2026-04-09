---
id: task-low-author-persisted-screensaver-config-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Author Persisted Screensaver Config Contract

Define the smallest persisted config schema that extends beyond dwell seconds while staying separate from later-stage overlays and desktop integration.

## Note

- Unblocked on 2026-04-08 after `task-med-spec-stage2-source-and-config-growth` was completed as task-governance orchestration.

## Completion evidence

- Confirmed this task was unblocked before editing (`blocked_by: []`).
- Authored the minimal persisted screensaver config contract in `.specs/screensaver/requirements.md` as a doc-only change.
- Defined the smallest post-Stage-1 persisted schema as shared `config.toml` tables `[playback]` and `[source]`, with `playback.dwell_seconds` and `source.mode` as the only required documented keys.
- Limited persisted `source.mode` to the documented literals `auto` and `local_archive` for this contract.
- Explicitly kept overlays, archive filters, launch integration, idle integration, monitor policy, and package-time settings out of this first persisted config contract.
- Avoided runtime code changes and limited scope to the task file plus the screensaver requirements needed to record the contract.
