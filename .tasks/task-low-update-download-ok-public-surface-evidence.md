---
id: task-low-update-download-ok-public-surface-evidence
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Update Download OK Public Surface Evidence

Correct `.ok/download.ok.md` so its public-surface evidence includes the current `ScreensaverPlaybackLoop` export and any other remaining Stage 1 runtime truth drift.

## Evidence

- `src/download/lib.zig` exports `ScreensaverPlaybackLoop` alongside `RandomPlaybackLoop`.
- `src/download/commands/random.zig` implements the Stage 1 screensaver session loop, alternate-screen/cursor handling, stdin-exit polling, and SIGINT/SIGTERM cleanup hooks.
- `src/download/commands/random_test.zig` pins those screensaver runtime behaviors with source-based tests.
