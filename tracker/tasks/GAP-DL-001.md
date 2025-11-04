---
id: GAP-DL-001
title: HTTP client with std.http (range requests, resume, progress)
area: download
status: pending
priority: high
spec_ref:
  - .specs/download/requirements.md#fr11-download-management
  - .specs/download/plan.md#phase-4
code_refs:
  - src/download/protocols/http.zig
acceptance:
  - Replace stub with std.http.Client implementation
  - Support HTTP Range requests for resume
  - Display progress (bytes transferred, percentage, speed, ETA)
  - Handle network errors with descriptive messages
  - Return error.ConnectionFailed, error.TimeoutReached, etc.
  - Tests for successful download, resume, and error cases
blocked_by: []
labels:
  - download
  - network
  - http
created: 2025-11-03
---

## Context

Current HTTP client is a stub with TODO:
```zig
// TODO: Replace with proper std.http.Client implementation
```

From `.specs/download/requirements.md`:
- FR1.1.4: Display progress (bytes, %, speed, ETA)
- FR1.1.6: Support resumable downloads via HTTP Range requests
- FR1.1.7: Resume from last byte on retry
- FR1.2.1: Support HTTPS from https://16colo.rs

## Implementation Tasks

1. **Basic GET**: Use `std.http.Client` to fetch URL
2. **Range requests**: Send `Range: bytes=N-` header for resume
3. **Progress callback**: Emit bytes/total during download
4. **Error handling**: Map std.http errors to ansilust error set
5. **Tests**:
   - Successful download
   - Resume from offset
   - Network timeout
   - 404 Not Found
   - Invalid SSL cert (should fail)

## Reference

- `reference/bun/` for Zig HTTP patterns
- Zig std.http.Client documentation
- `.specs/download/design.md` for architecture

## Notes

- Progress callback should be optional (null for non-interactive use)
- Must validate SSL certificates (TC3.4.6)
- Rate limiting handled at higher layer (FR1.2.10)
