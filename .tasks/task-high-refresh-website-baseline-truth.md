---
id: task-high-refresh-website-baseline-truth
level: high
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Refresh Website Baseline Truth

Reconcile the website constitution to the checked-in `website/` app surface and close the still-missing minimum SEO baseline.

## Completion Evidence

- Confirmed the website slice now has checked-in app and asset evidence at `website/app/**`, `website/public/**`, `website/package.json`, and `website/seo-baseline.test.ts`.
- Confirmed `.ok/website.ok.md` is stale against that checked-in surface and remains the next website-truth promotion target.
- Re-ran `bun test seo-baseline.test.ts` in `website/` and confirmed the remaining executable website gap is still the missing owned `/robots.txt` and `/sitemap.xml` baseline.
- Unblocked `task-med-close-website-baseline-truth-gaps` as the next executable website slice task.
