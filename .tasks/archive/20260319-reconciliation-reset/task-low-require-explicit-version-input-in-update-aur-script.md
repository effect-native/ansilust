---
id: task-low-require-explicit-version-input-in-update-aur-script
level: low
status: done
blocked_by: []
expires_at: 2026-03-26T23:35:25Z
---

# Require Explicit Version Input In Update AUR Script

Remove the `0.0.1` fallback from `scripts/update-aur-pkgbuild.sh` so AUR metadata updates require explicit release evidence.

## Evidence

- Removed the implicit `0.0.1` fallback from `scripts/update-aur-pkgbuild.sh`.
- Added an explicit missing-version error with usage output before the script proceeds.
