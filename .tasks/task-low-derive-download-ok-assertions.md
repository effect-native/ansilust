---
id: task-low-derive-download-ok-assertions
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Derive Download OK Assertions

Extract the binary, evergreen assertions from `.specs/download/` that should govern the download/archive surface.

## Evidence

- Tightened `.ok/download.ok.md` with additional binary assertions derived from `.specs/download/**` that explicitly separate spec intent around storage standards, dual-CLI behavior, database authority, and archive workflows from current shipped download truth.
- Added matching FALSE assertions so spec examples and acceptance-criteria prose do not get misread as evidence of shipped aliases, background database updates, extraction/indexing, interoperability surfaces, or broader archive-management capabilities.
