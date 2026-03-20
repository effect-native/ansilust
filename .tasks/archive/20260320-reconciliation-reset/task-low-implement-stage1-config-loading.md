---
id: task-low-implement-stage1-config-loading
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Stage1 Config Loading

Load the minimal Stage 1 config defaults into the shared playback runtime without expanding into post-MVP filtering or layout-policy settings.

Targets: new config helper module plus playback runtime integration
Validation: `zig build test`

## Evidence

- Added `src/download/commands/stage1_config.zig` to load built-in Stage 1 defaults from `config.toml`, with support for `playback.dwell_seconds` and `source.mode = "auto"`.
- Integrated config loading into the shared playback runtime in `src/download/commands/random.zig` so standard dwell timing uses config defaults while existing random, screensaver, and random-1 behavior stays otherwise unchanged.
- Validation: `zig build test`
