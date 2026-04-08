---
id: task-low-define-pack-enumeration-and-local-archive-source-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Define Pack Enumeration And Local Archive Source Contract

Specify the Stage 2 local archive enumeration boundary before any `.index.db` or mirror-driven selection becomes required.

## Evidence

- Updated `.specs/download/requirements.md` to define the Stage 2 local-archive source contract as a filesystem-derived `packs/` enumeration boundary that stays distinct from shipped Stage 1 local playback and later `.index.db` authority.
- Re-read the edited requirements for consistency with the current hardcoded, local-first runtime and future staged handoff ordering.
