---
id: task-low-fix-flake-version-and-checksum-placeholders
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Fix Flake Version And Checksum Placeholders

Bring `flake.nix` into alignment with current release evidence or explicitly demote it as an aspirational secondary channel.

## Done When

- `flake.nix` no longer advertises stale `0.0.1` placeholder release metadata as if it were current.
- Nix packaging state matches the deployment constitution's evidence-backed channel policy.

## Evidence

- Replaced stale hard-coded `0.0.1` and placeholder checksum strings in `flake.nix` with explicitly unset release metadata and an aspirational-package message.
- Updated `scripts/update-nix-flake.sh` to require an explicit release version and to populate the new `release.checksums` structure from SHA256 evidence.
- Re-read `flake.nix` and `scripts/update-nix-flake.sh` to confirm they now describe release metadata as unset until backed by published artifacts.
