---
id: task-med-align-supported-platform-matrix
level: medium
status: done
blocked_by: ["task-high-distribution-surface-alignment"]
expires_at: 2026-03-23T22:49:25Z
---

# Align Supported Platform Matrix

Make the supported target set consistent across release automation, npm packaging, launcher behavior, installer detection, and packaging helpers.

## Evidence

- `.github/workflows/release.yml:34-47`
- `packages/ansilust/package.json:28-38`
- `packages/ansilust/bin/launcher.js:83-93`
- `scripts/install.sh:63-100`
- `scripts/install.ps1:59-62`
