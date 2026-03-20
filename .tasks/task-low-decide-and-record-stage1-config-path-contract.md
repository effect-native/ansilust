---
id: task-low-decide-and-record-stage1-config-path-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Decide And Record Stage1 Config Path Contract

Resolve whether Stage 1 config lives under the `16colors` data root or `~/.config/16c/`, then make the specs and code contract explicit.

## Evidence

- Updated `.specs/screensaver/requirements.md` to make the Stage 1 config-path contract explicit: shipped runtime config loads from `config.toml` under the resolved `16colors` root, not `~/.config/16c/config.toml`.
- Kept broader persisted config work future-facing in Stage 3 language by framing it as an extension or replacement of the shipped Stage 1 contract rather than current behavior.
- Re-read the edited requirements for consistency after the contract change.
