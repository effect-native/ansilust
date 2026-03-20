---
id: task-low-decide-and-record-stage1-signal-coverage-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Decide And Record Stage1 Signal Coverage Contract

Resolve whether Stage 1 should implement `SIGHUP` and `SIGQUIT` cleanup or narrow the screensaver spec to the currently shipped signal set.

## Evidence

- Updated `.specs/screensaver/requirements.md` so Stage 1 signal cleanup explicitly covers only `SIGINT` and `SIGTERM`.
- Recorded broader signal coverage as future additive hardening rather than current Stage 1 scope.
