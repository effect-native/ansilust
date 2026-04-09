---
id: task-high-enable-fresh-start-16c-screensaver
level: high
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Enable Fresh-Start 16c Screensaver

Close the main gap between the current local-only `16c screensaver` runtime and the intended fresh-machine experience where `npx 16c screensaver` immediately starts rotating artwork.

This slice covers only the real `16c` package channel and the first-use artwork path needed for immediate looping playback on a fresh machine.

## Evidence

- Confirmed `blocked_by: []` on 2026-04-09, so this orchestration gate was executable.
- Reconciled this high-level slice strictly against the scoped fresh-start gap captured in `.tasks/artifacts/gaps-snapshot-20260409011855.md`.
- Preserved tunnel vision for this gate: the next work remains limited to two direct implementation slices only:
  - `task-med-promote-real-16c-package-channel`
  - `task-med-provision-first-use-starter-art`
- Advanced the next executable work by clearing the parent blocker on both medium tasks without touching IR, website, download-stage expansion, or auth scopes.
