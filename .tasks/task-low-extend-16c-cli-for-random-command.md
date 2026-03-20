---
id: task-low-extend-16c-cli-for-random-command
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Extend 16c CLI For Random Command

Add the CLI parse/help/version surface for `16c random` while preserving the existing `random-1` command contract.

## Evidence

- Updated `src/cli/sixteenc.zig` so `16c random` is exposed in usage/help and dispatches through the reusable `download.RandomPlaybackLoop`, while `random-1` remains a supported command.
- `zig build` succeeds after the CLI change.
- `./zig-out/bin/16c --help 2>&1` shows the `random` command surface and `./zig-out/bin/16c --version 2>&1` still prints the existing version string.
- `zig build test` still has one unrelated existing failure in `src/download/database/interface_test.zig` (`ArchiveDatabase.getRandomFile returns different files`); no CLI-specific regression from this change was surfaced.
