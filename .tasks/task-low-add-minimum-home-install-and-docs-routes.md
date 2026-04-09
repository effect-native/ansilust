---
id: task-low-add-minimum-home-install-and-docs-routes
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Add Minimum Home Install And Docs Routes

Create the smallest evidence-backed homepage, install, and docs route set.

## Red Phase Update

- Red phase complete.
- Added executable failing coverage in `scripts/website-minimum-routes.test.mjs` that pins the minimum checked-in website route set to `/`, `/install`, and `/docs`.
- The test intentionally accepts multiple common React route-file layouts so the future green implementation can choose a concrete scaffold without weakening the route contract.
- Production website route implementation intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `node --test ./scripts/website-minimum-routes.test.mjs`
- Observed failure: `website scaffold owns the minimum homepage, install, and docs route set` fails because no checked-in homepage route artifact exists yet for `/` in any accepted React route-file layout.
- Cause pinned by RED evidence: the current `website/` scaffold still contains only `website/package.json`, so there is no owned route implementation yet for `/`, `/install`, or `/docs`.
