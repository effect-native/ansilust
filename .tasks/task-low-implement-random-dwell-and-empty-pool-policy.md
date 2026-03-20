---
id: task-low-implement-random-dwell-and-empty-pool-policy
level: low
status: pending
blocked_by: ["task-low-add-red-tests-for-random-dwell-and-empty-pool"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Random Dwell And Empty Pool Policy

Implement the fixed Stage 1 dwell default, replay policy for a one-file local pool, and the helpful empty-pool error path without regressing `random-1`.

Targets: `src/download/commands/random.zig`, `src/cli/sixteenc.zig` if CLI/default plumbing is needed
Validation: `zig build test`
