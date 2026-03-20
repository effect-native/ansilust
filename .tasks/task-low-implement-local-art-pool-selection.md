---
id: task-low-implement-local-art-pool-selection
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Local Art Pool Selection

Implement a Stage 1 local artwork provider for `16c random` that enumerates playable ANSI files from `random/` and `local/` before any remote fallback path is considered.

Targets: `src/download/commands/random.zig`, new source/provider helpers if needed
Validation: `zig build test`

## Evidence

- Added Stage 1 local-pool-first selection in `src/download/commands/random.zig` to scan `random/` and `local/`, filter playable `.ans` and `.asc` files, and display a local pick before remote fallback.
- Validation passed with `zig test src/download/commands/random_test.zig` and `zig build test`.
