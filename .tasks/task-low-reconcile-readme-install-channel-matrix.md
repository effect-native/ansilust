---
id: task-low-reconcile-readme-install-channel-matrix
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Reconcile README Install Channel Matrix

Align the README installation section with the channels and target matrix that the current release evidence can actually support.

## Done When

- README install instructions no longer promise unsupported Windows, AUR, Nix, or domain-hosted flows as current facts without matching evidence.
- Reader-facing install guidance matches `.ok/deployments.ok.md` and `.ok/website.ok.md`.

## Evidence

- Re-read `README.md` after editing and confirmed the install matrix now limits GitHub Releases, npm, and the shell installer to the currently supported Unix and macOS target set.
- Confirmed `README.md` now treats Windows/PowerShell, AUR, Nix, and website-hosted installer flows as not currently shipped.
- Verified the README text keeps the earlier installer-hosting demotion by stating the shell installer is served from raw GitHub repository paths, not `ansilust.com`.
