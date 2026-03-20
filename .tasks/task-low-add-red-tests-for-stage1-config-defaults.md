---
id: task-low-add-red-tests-for-stage1-config-defaults
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Stage1 Config Defaults

Add failing tests for missing-config defaults and the minimal `playback.dwell_seconds` plus `source.mode` config contract.

Targets: new config/runtime tests near `src/download/commands/` or a new config helper module
Validation: targeted failing test run

## Evidence

- Command: `zig test src/download/commands/random_test.zig`
- Result: fails because `src/download/commands/random.zig` does not yet contain Stage 1 config loading for missing-file defaults, `playback.dwell_seconds`, or `source.mode = "auto"`.
