---
id: task-low-define-fallback-order-before-index-db
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Fallback Order Before Index DB

Define the selection fallback order among curated seeds, filesystem scanning, `random/`, `packs/`, `local/`, and hardcoded remote sources before `.index.db` exists.

## Evidence

- Updated `.specs/screensaver/design.md` to add an explicit pre-`.index.db` fallback ladder: curated local seeds, filesystem discovery with `random/` then `packs/` then `local/`, and hardcoded remote fetch only as a last resort.
- Kept the policy aligned with current repo evidence by preserving `random-1` compatibility and treating the existing hardcoded archive entry plus `random/` cache behavior as the only shipped remote-backed path.
