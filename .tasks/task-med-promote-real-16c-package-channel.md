---
id: task-med-promote-real-16c-package-channel
level: medium
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Promote Real 16c Package Channel

Replace the placeholder `packages/16c` surface with a real launcher/release path backed by the native binary payloads.

Keep this slice focused on package naming, launcher behavior, and release assembly rather than first-use artwork provisioning.

## Note

- Parent high-level gate was reconciled on 2026-04-09 via `task-high-enable-fresh-start-16c-screensaver`.
- This medium now owns the next executable package-channel work: package naming drift, real launcher behavior, and release/publish assembly for `16c` only.

## Evidence

- Replaced the `packages/16c` placeholder with a real npm launcher surface in `packages/16c/package.json`, `packages/16c/index.js`, `packages/16c/bin/launcher.js`, and `packages/16c/README.md`.
- Extended `scripts/assemble-npm-packages.js`, `scripts/release.sh`, and `.github/workflows/release.yml` so release assembly now produces/publishes aligned `ansilust-*` and `16c-*` native package families and ships `16c-<platform>` GitHub release archives.
- Added `scripts/package-channel.test.mjs` and passed `node --test ./scripts/package-channel.test.mjs` plus `zig build` on 2026-04-09.
