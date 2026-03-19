---
id: task-low-prune-unsupported-npm-target-promises
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Prune Unsupported NPM Target Promises

Make the npm meta package promise only the platform packages that are actually supported by the current release contract.

## Done When

- `packages/ansilust/package.json` no longer promises unsupported or mismatched platform packages.
- The npm-supported target set matches the intended release workflow target set exactly.

## Evidence

- Updated `packages/ansilust/package.json` optional dependencies to match the current deployment constitution target matrix exactly: `darwin-arm64`, `darwin-x64`, `linux-arm64-gnu`, `linux-arm64-musl`, `linux-arm-gnu`, `linux-arm-musl`, `linux-x64-gnu`, and `linux-x64-musl`.
- Removed unsupported promises for `ansilust-linux-i386-musl` and `ansilust-win32-x64`.
- Corrected mismatched `aarch64` npm package promises to `arm64` so the meta package aligns with the release workflow target names.
