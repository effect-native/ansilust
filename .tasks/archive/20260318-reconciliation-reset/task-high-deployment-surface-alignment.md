---
id: task-high-deployment-surface-alignment
level: high
status: in-progress
blocked_by: []
expires_at: 2026-03-25T12:46:37-04:00
---

# Deployment Surface Alignment

Bring package metadata, installers, and user-facing deployment claims back into alignment with the currently proven release matrix.

## DotOK-Only Run Notes

- Evidence: `.ok/deployments.ok.md` exists and now serves as the deployment constitution for this surface.
- Constraint: this run is limited to DotOK/project-management work, so package manifests, installers, release automation, and user-facing product claims are out of scope.
- Orchestration decision: keep this high task open as the umbrella coordinator until a later authorized product run performs the required repository-facing reconciliation.
- Downstream status: `task-med-demote-unproven-distribution-channels` and `task-med-align-platform-matrix-promises` remain blocked because they require product-surface changes rather than project-management-only edits.
