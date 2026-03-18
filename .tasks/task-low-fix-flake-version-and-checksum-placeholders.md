---
id: task-low-fix-flake-version-and-checksum-placeholders
level: low
status: pending
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Fix Flake Version And Checksum Placeholders

Bring `flake.nix` into alignment with current release evidence or explicitly demote it as an aspirational secondary channel.

## Done When

- `flake.nix` no longer advertises stale `0.0.1` placeholder release metadata as if it were current.
- Nix packaging state matches the deployment constitution's evidence-backed channel policy.
