---
id: task-low-implement-local-art-pool-selection
level: low
status: pending
blocked_by: ["task-low-add-red-tests-for-local-art-pool-selection"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Local Art Pool Selection

Implement a Stage 1 local artwork provider for `16c random` that enumerates playable ANSI files from `random/` and `local/` before any remote fallback path is considered.

Targets: `src/download/commands/random.zig`, new source/provider helpers if needed
Validation: `zig build test`
