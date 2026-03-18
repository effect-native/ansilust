---
id: task-low-link-download-ok-to-existing-evidence
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Link Download Constitution To Evidence

Anchor the future download constitution to current code and workflow evidence so it can be reconciled mechanically.

## Evidence

- Rewrote `.ok/download.ok.md` to anchor the download constitution to live checked-in build wiring, CLI surface, backend modules, and tests instead of relying on `.specs/download/**` intent alone.
- Added an explicit live-evidence section to `.ok/download.ok.md` covering `build.zig`, `src/cli/sixteenc.zig`, `src/download/lib.zig`, `src/download/commands/random.zig`, the hardcoded database, HTTP/storage modules, and the current download test files.
- Recorded current negative evidence in `.ok/download.ok.md` for unevidenced SQLite indexing, extraction, mirror sync, alias executables, local-art management, renderer-backed display, and protocol fallback claims so future reconciliation stays mechanical.
