---
id: task-low-wire-release-assembly-and-publish-surface-for-16c
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Wire Release Assembly And Publish Surface For 16c

Extend the current release assembly and publish flow so `16c` can become an evidence-backed deployment channel rather than a reserved namespace.

## Evidence

- Updated `.github/workflows/release.yml` to carry `16c` binaries through build artifacts, npm package assembly, npm publish, and GitHub release archive creation.
- Updated `scripts/release.sh` so the version bump flow now advances both launcher manifests (`ansilust` and `16c`).
