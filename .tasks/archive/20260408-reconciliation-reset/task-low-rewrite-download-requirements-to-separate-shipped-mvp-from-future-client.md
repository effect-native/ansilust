---
id: task-low-rewrite-download-requirements-to-separate-shipped-mvp-from-future-client
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Rewrite Download Requirements To Separate Shipped MVP From Future Client

Replace the stale pre-Stage-1 download requirements with a staged contract that distinguishes shipped Stage 1 behavior from future archive-client work.

## Evidence

- Rewrote `.specs/download/requirements.md` around the shipped Stage 1 `16c` runtime contract.
- Separated current guarantees (`random`, `screensaver`, `random-1`, local-first playback, minimal flags/config, renderer-backed display) from future archive-client work (`.index.db`, search, pack downloads, mirroring, aliases, protocol expansion, full archive management).
- Performed a consistency read against `.ok/download.ok.md` after the rewrite.
