---
id: task-low-remove-stale-random1-messaging-from-looping-runtime
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Remove Stale Random1 Messaging From Looping Runtime

Fix Stage 1 runtime output so `random` and `screensaver` no longer log `random-1`-specific messaging.

## Evidence

- Narrowed shared loop messaging in `src/download/commands/random.zig` so looped `random`/`screensaver` output uses `16c random`, while `executeRandomOne` keeps the dedicated `16c random-1` wording and seed hint.
- Ran `zig build test` after the refactor; test suite passed.
