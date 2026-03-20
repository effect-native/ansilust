---
id: task-low-rewrite-download-design-for-shipped-stage1-architecture
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Rewrite Download Design For Shipped Stage1 Architecture

Update `.specs/download/design.md` so its architecture and module map reflect the shipped Stage 1 runtime rather than the older SQLite-first client design.

## Evidence

- Rewrote `.specs/download/design.md` around the shipped `16c` runtime, `src/download/lib.zig`, Stage 1 random/screensaver flow, hardcoded archive backend, and current storage modules.
- Moved `.index.db`, search, mirror, pack, alias, and multi-protocol work into an explicit future-stage architecture section instead of describing them as shipped baseline.
- Performed a consistency read of the updated design against `.ok/download.ok.md` before closing the task.
