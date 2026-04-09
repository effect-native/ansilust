---
id: task-low-add-fresh-machine-16c-screensaver-smoke-coverage
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Add Fresh-Machine 16c Screensaver Smoke Coverage

Add end-to-end validation for the exact target contract: a clean machine or temp-home environment can start `16c screensaver` from the package channel and reach immediate looping playback without manual seeding.

## Evidence

- Cleared stale blockers after verifying `task-low-replace-placeholder-16c-package-with-real-launcher-surface` and `task-low-wire-release-assembly-and-publish-surface-for-16c` are both already `done`.
- Added package-channel smoke coverage in `scripts/package-channel.test.mjs` that builds `zig-out/bin/16c`, injects a temp installed `16c-<platform>` payload package through `NODE_PATH`, runs `packages/16c/bin/launcher.js screensaver --instant` against a clean temp home/XDG root, and asserts starter-art seeding plus repeated playback output.
- Validation: `npm run test:package-channels`
