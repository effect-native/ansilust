---
id: task-low-demote-placeholder-publishing-guides
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Demote Placeholder Publishing Guides

Rework or retire docs that still instruct publishing placeholder packages as if they were live ansilust distribution channels.

## Done When

- `packages/PUBLISH.md` no longer reads like an active publication runbook for placeholder packages.
- `16c` and `16colors` remain clearly described as namespace reservations or future surfaces, not current ansilust deployment guarantees.

## Evidence

- `packages/PUBLISH.md:1` now frames the file as publishing notes, explicitly says `16c` and `16colors` are not active deployment channels, and removes publish/verify runbook steps.
- `packages/16c/package.json:4` now describes `16c` as a reserved package name for possible future tooling, not a current ansilust release.
- `packages/16colors/package.json:4` now describes `16colors` as a reserved package name for possible future archive utilities, not a current ansilust release.
