---
id: task-low-implement-stage1-config-loading
level: low
status: pending
blocked_by: ["task-med-add-stage1-config-loading", "task-low-add-red-tests-for-stage1-config-defaults"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Stage1 Config Loading

Load the minimal Stage 1 config defaults into the shared playback runtime without expanding into post-MVP filtering or layout-policy settings.

Targets: new config helper module plus playback runtime integration
Validation: `zig build test`
