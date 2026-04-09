---
id: task-low-author-launch-integration-artifact-ownership
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Author Launch Integration Artifact Ownership

Decide which owned docs, service files, or packaging artifacts must exist before screensaver launch integration is promoted from FUTURE.

## Completion evidence

- Confirmed this task was unblocked before editing (`blocked_by: []`).
- Authored the Stage 4 launch integration ownership contract in `.specs/screensaver/requirements.md` as a doc-only change.
- Defined the minimum owned launch slice as one repo-owned launch document plus one repo-owned machine-readable launch artifact for the same path.
- Required any claimed idle-triggered path to also ship the repo-owned activation artifact, such as a systemd user unit, service template, or idle-manager config fragment.
- Required any claimed packaged launch path to also ship the repo-owned packaging/install artifact that places launch assets and ensures offline artwork availability for first use.
- Clarified that examples, wiki snippets, screenshots, and distro-local recipes maintained elsewhere do not satisfy the ownership gate.
- Updated `.specs/screensaver/plan.md` to record the owned Stage 4 baseline and mark `WP-GROW-001` complete now that all linked source/config and launch-ownership tasks are done.
- Avoided runtime code changes and limited scope to the task file plus the screensaver spec files needed to record the contract.
