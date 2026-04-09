---
id: task-med-close-website-baseline-truth-gaps
level: medium
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Close Website Baseline Truth Gaps

Bring `.ok/website.ok.md` back into alignment with the current repo and finish the minimum crawlable baseline.

## Completion Evidence

- Added `website/public/robots.txt` with the owned minimum crawl directives and a sitemap reference.
- Added `website/public/sitemap.xml` with the current checked-in owned route baseline for `/`, `/docs`, and `/install` while excluding samples/gallery surfaces.
- Re-ran `bun test seo-baseline.test.ts` in `website/` and `node --test scripts/website-minimum-routes.test.mjs scripts/website-root-scaffold.test.mjs` from repo root; both passed.
- Unblocked the next executable website-truth follow-up `task-low-promote-website-app-and-assets-into-website-ok`.
