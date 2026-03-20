---
id: task-low-add-red-tests-for-random-dwell-and-empty-pool
level: low
status: pending
blocked_by: ["task-med-add-random-dwell-and-empty-pool-policy"]
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Random Dwell And Empty Pool

Add failing tests that pin the 20-second default dwell policy, single-file replay behavior, and helpful empty-pool failure contract for `16c random`.

Targets: `src/download/commands/random_test.zig`
Validation: targeted failing test run
