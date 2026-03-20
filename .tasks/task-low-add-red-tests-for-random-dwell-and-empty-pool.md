---
id: task-low-add-red-tests-for-random-dwell-and-empty-pool
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Random Dwell And Empty Pool

Add failing tests that pin the 20-second default dwell policy, single-file replay behavior, and helpful empty-pool failure contract for `16c random`.

Targets: `src/download/commands/random_test.zig`
Validation: targeted failing test run

## Evidence

- Failing command: `zig test src/download/commands/random_test.zig`
- Failure reason: the new red tests fail because `src/download/commands/random.zig` still defaults `RandomPlaybackLoop.delay_ns` to `0`, does not declare an explicit `candidates.items.len == 1` replay path, and still lacks a helpful empty-pool error/message that names `random/` and `local/` instead of failing closed before remote fallback.
