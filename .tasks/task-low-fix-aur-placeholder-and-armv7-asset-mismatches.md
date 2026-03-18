---
id: task-low-fix-aur-placeholder-and-armv7-asset-mismatches
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Fix AUR Placeholder And ARMv7 Asset Mismatches

Reconcile AUR packaging files with the current artifact naming and supported-channel truth.

## Done When

- `aur/PKGBUILD` and `scripts/update-aur-pkgbuild.sh` no longer point at nonexistent `linux-armv7-*` assets.
- AUR files either reflect real release evidence or stay clearly marked as aspirational placeholders.

## Evidence

- Removed `armv7h` from `aur/PKGBUILD` and `aur/.SRCINFO`, leaving only the `x86_64` and `aarch64` release assets that match current artifact naming.
- Updated `scripts/update-aur-pkgbuild.sh` to stop parsing or reporting `linux-armv7-*` checksums.
- Re-read the edited AUR files and verified no `linux-armv7-*` or `armv7h` references remain.
