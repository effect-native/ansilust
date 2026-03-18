---
id: task-low-prune-unsupported-npm-target-promises
level: low
status: pending
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Prune Unsupported NPM Target Promises

Make the npm meta package promise only the platform packages that are actually supported by the current release contract.

## Done When

- `packages/ansilust/package.json` no longer promises unsupported or mismatched platform packages.
- The npm-supported target set matches the intended release workflow target set exactly.
