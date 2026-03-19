---
id: task-low-demote-ansilust-com-install-promises
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Demote Ansilust Dot Com Install Promises

Remove or clearly demote claims that the install scripts are already hosted at `ansilust.com`.

## Done When

- `README.md`, `scripts/install.sh`, and `scripts/install.ps1` stop presenting `ansilust.com` install endpoints as current shipped reality unless matching website evidence is added.
- Install instructions stay within repository-evidenced distribution surfaces.

## Evidence

- `README.md` now points installer examples at repository-hosted raw GitHub script URLs and explicitly says the shell installer is not currently shipped from `ansilust.com`.
- `README.md` now states the PowerShell script is in-repo for future Windows work and does not represent a current shipped Windows install path.
- `scripts/install.sh` and `scripts/install.ps1` now describe themselves as repository scripts instead of `ansilust.com`-served endpoints.
- Validation grep for `ansilust\.com/install(\.ps1)?` across the scoped files returned no matches.
