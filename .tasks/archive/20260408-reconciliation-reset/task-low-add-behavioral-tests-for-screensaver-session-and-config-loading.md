---
id: task-low-add-behavioral-tests-for-screensaver-session-and-config-loading
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Add Behavioral Tests For Screensaver Session And Config Loading

Cover screensaver session cleanup and Stage 1 config loading with behavior-level tests instead of `@embedFile` string checks.

## Evidence

- Added behavior-level tests for screensaver terminal enter/cleanup sequences in `src/download/commands/random_test.zig`.
- Added behavior-level tests for missing and present `config.toml` loading in `src/download/commands/random_test.zig`.
- Ran `zig build test`.
