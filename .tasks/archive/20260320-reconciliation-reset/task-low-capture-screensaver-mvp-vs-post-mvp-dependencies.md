---
id: task-low-capture-screensaver-mvp-vs-post-mvp-dependencies
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Capture Screensaver MVP Vs Post-MVP Dependencies

Record which screensaver capabilities require only current repo evidence and which remain blocked on future mirror, database, integration, or packaging work.

## Evidence

- Updated `.ok/screensaver.ok.md` to cite `.specs/screensaver/requirements.md`, `.specs/screensaver/design.md`, and `.specs/screensaver/plan.md` alongside the gap snapshot and neighboring constitutions.
- Split the capability ladder and dependency boundaries so Stage 1 MVP stays limited to local-loop playback plus ansilust-owned rendering, while Stage 2-4 explicitly remain post-MVP because they depend on future download inventory, config, launch, and packaging work evidenced in `.ok/download.ok.md`, `.ok/deployments.ok.md`, and `.specs/screensaver/requirements.md`.
