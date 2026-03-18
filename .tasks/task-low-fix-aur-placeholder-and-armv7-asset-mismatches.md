---
id: task-low-fix-aur-placeholder-and-armv7-asset-mismatches
level: low
status: pending
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Fix AUR Placeholder And ARMv7 Asset Mismatches

Reconcile AUR packaging files with the current artifact naming and supported-channel truth.

## Done When

- `aur/PKGBUILD` and `scripts/update-aur-pkgbuild.sh` no longer point at nonexistent `linux-armv7-*` assets.
- AUR files either reflect real release evidence or stay clearly marked as aspirational placeholders.
