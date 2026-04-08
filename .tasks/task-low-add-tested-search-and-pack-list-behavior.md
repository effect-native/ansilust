---
id: task-low-add-tested-search-and-pack-list-behavior
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Add Tested Search And Pack List Behavior

Implement evidence-backed `searchFiles` and `listPacksByYear` behavior for the current archive database surface.

## Red Phase Update

- Red phase complete.
- Added executable failing tests in `src/download/database/interface_test.zig` that define the minimum current archive contract around the single checked-in curated entry.
- `searchFiles("CXC-STICK")` is now pinned to return the curated `mist1025/CXC-STICK.ASC` file metadata.
- `listPacksByYear(2025)` is now pinned to return the curated `mist1025` pack metadata and ZIP URL shape.
- Production implementation intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `zig build test`
- Observed failure: `ArchiveDatabase.searchFiles returns curated file matches` failed with `expected 1, found 0` at `src/download/database/interface_test.zig:63`.
- Observed failure: `ArchiveDatabase.listPacksByYear returns curated pack metadata` failed with `expected 1, found 0` at `src/download/database/interface_test.zig:86`.
- Cause pinned by RED evidence: `src/download/database/hardcoded.zig` still returns empty arrays for both methods.
