---
id: task-low-define-instant-and-streaming-speed-flags
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Instant And Streaming Speed Flags

Decide how the MVP exposes instant playback and streaming-speed controls without overcommitting to later presentation modes.

## Evidence

- Added Stage 1 playback requirements in `.specs/screensaver/requirements.md` for `--instant`, `--streaming-speed <preset>`, mutual exclusivity, and Stage 1 scope boundaries.
- Added data requirements that keep these controls as per-invocation CLI overrides and defer persisted playback-mode configuration to Stage 3.
