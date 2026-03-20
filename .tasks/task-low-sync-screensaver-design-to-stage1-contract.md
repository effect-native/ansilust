---
id: task-low-sync-screensaver-design-to-stage1-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Sync Screensaver Design To Stage1 Contract

Propagate the resolved Stage 1 signal/config contract into `.specs/screensaver/design.md` without overstating post-MVP behavior.

## Evidence

- Updated `.specs/screensaver/design.md` to point Stage 1 config loading at `config.toml` under the resolved `16colors` root instead of `~/.config/16c/config.toml`.
- Narrowed Stage 1 session/signal language to keyboard exit plus best-effort cleanup on `SIGINT` and `SIGTERM`, with broader signal coverage kept future-facing.
