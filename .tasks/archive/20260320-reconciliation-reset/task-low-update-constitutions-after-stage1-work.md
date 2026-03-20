---
id: task-low-update-constitutions-after-stage1-work
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Update Constitutions After Stage1 Work

After the remaining implementation lands, promote the new evidenced runtime truth in `.ok/download.ok.md` and `.ok/screensaver.ok.md` without overstating any post-MVP behavior.

Targets: `.ok/download.ok.md`, `.ok/screensaver.ok.md`
Validation: `zig build`, `zig build test`

## Evidence

- Updated `.ok/download.ok.md` to match current Stage 1 download/runtime evidence from `src/cli/sixteenc.zig`, `src/download/commands/random.zig`, `src/download/commands/stage1_config.zig`, `src/download/storage/files.zig`, and `src/download/commands/random_test.zig`: `random`, `screensaver`, and `random-1` are shipped; looping modes are local-pool-first over `random/` and `local/`; playback flags are `--instant` and `--streaming-speed <preset>`; config loading is limited to `config.toml` defaults plus `playback.dwell_seconds` and `source.mode = "auto"`; remote fallback remains limited to `random-1`; `cleanupRandom` is still a TODO.
- Updated `.ok/screensaver.ok.md` to match current Stage 1 screensaver evidence from `src/cli/sixteenc.zig`, `src/download/commands/random.zig`, `src/download/commands/stage1_config.zig`, `src/download/storage/files.zig`, and `src/download/commands/random_test.zig`: looping `random` and dedicated `screensaver` are shipped; looping playback is local-pool-first; standard dwell defaults to 20 seconds with flag/config behavior as implemented; screensaver session cleanup covers alternate screen, cursor restore, input exit, and best-effort SIGINT/SIGTERM handling; broader Stage 2+ claims remain future-facing.
- Validation: `zig build` passed after the Stage 1 config build repair.
- Validation: `zig build test` passed after the Stage 1 config build repair.
