---
id: task-low-reconcile-launcher-installer-and-artifact-platform-ids
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Reconcile Launcher Installer And Artifact Platform IDs

Unify platform naming and detection across the launcher, shell installer, PowerShell installer, and release artifact names.

## Done When

- Runtime and installer platform IDs resolve only to artifact names that the release workflow actually produces.
- ARM and Windows naming mismatches are removed or clearly demoted.

## Evidence

- `packages/ansilust/bin/launcher.js` now resolves Linux ARM64 as `linux-arm64-*`, rejects unsupported Windows/i386 targets, and lists only the release-workflow platform IDs.
- `scripts/install.sh` now emits only `darwin-{x64,arm64}` and `linux-{x64,arm64,arm}-{gnu,musl}`, while failing early for Windows and 32-bit Linux.
- `scripts/install.ps1` now explicitly demotes Windows installation because `.github/workflows/release.yml` does not currently publish any `win32-*` artifacts.
