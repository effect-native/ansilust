---
id: task-low-add-sitemap-and-robots-baseline
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Add Sitemap And Robots Baseline

Add the minimum owned SEO metadata surface required for the website to stop being entirely absent from crawlable baseline behavior.

## Completion Evidence

- Added `website/public/robots.txt` with the minimum owned crawl policy and sitemap link.
- Added `website/public/sitemap.xml` for the checked-in `/`, `/docs`, and `/install` route baseline.
- Confirmed `bun test seo-baseline.test.ts` passes in `website/`.
