---
id: task-low-add-red-tests-for-local-art-pool-selection
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Local Art Pool Selection

Add failing tests that define the Stage 1 local artwork pool contract for `random/` plus `local/`, supported-file filtering, and local-first selection.

Targets: `src/download/commands/random_test.zig`, new adjacent test helpers if needed
Validation: targeted failing test run

## Evidence

- Failing command: `zig test src/download/commands/random_test.zig`
- Failure reason: the new Stage 1 red tests fail because `src/download/commands/random.zig` still does not scan `local/`, does not declare supported `.ans`/`.asc` local-pool filtering, and still reaches the remote `db.getRandomFile()` path before any local-pool selection logic exists.
