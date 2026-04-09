---
id: task-low-fix-platform-package-name-drift-for-cli-launchers
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Fix Platform Package Name Drift For CLI Launchers

Reconcile the existing npm payload naming drift between `scripts/assemble-npm-packages.js` and `packages/ansilust/package.json` so the repo has one trustworthy platform-package convention before reusing that plumbing for `16c`.

## Evidence

- Normalized release assembly target naming to `linux-arm64-*` in `scripts/assemble-npm-packages.js`, matching `packages/ansilust/package.json` and the launcher convention.
- Covered the arm64 naming contract with `scripts/package-channel.test.mjs`.
