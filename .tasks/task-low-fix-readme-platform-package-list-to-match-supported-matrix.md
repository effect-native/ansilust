---
id: task-low-fix-readme-platform-package-list-to-match-supported-matrix
level: low
status: done
blocked_by: []
expires_at: 2026-03-26T23:35:25Z
---

# Fix README Platform Package List To Match Supported Matrix

Update the package inventory block in `README.md` so it reflects only the supported published package names and does not list unsupported Windows or i386 targets.

## Evidence

- Updated `README.md` platform package inventory to list only the eight supported published package names.
- Removed unsupported Windows and i386 entries and corrected Linux ARM package names to `ansilust-linux-arm-gnu` and `ansilust-linux-arm-musl`.
- Matched the inventory to `packages/ansilust/package.json` optional dependencies and the current supported release target matrix.
