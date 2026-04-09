---
id: task-low-add-sitemap-and-robots-baseline
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Add Sitemap And Robots Baseline

Add the minimum owned SEO metadata surface required for the website to stop being entirely absent.

## Acceptance Extraction

- Add the minimum owned SEO metadata surface required for the website to stop being entirely absent.
- Pin minimum owned baseline behavior for `/robots.txt` and `/sitemap.xml`.
- Keep scope to website route/public-file coverage plus this task file.
- Exclude `website/public/samples/**` and `website/public/gallery/**` from owned baseline work in this task.

## Red Phase

- Added executable failing coverage at `website/seo-baseline.test.ts`.
- Baseline asserted by the new test:
  - `/robots.txt` exists and contains `User-agent: *`, `Allow: /`, and `Sitemap: /sitemap.xml`.
  - `/sitemap.xml` exists, contains `<urlset`, includes owned routes `/`, `/docs`, and `/install`, and does not claim `/samples/` or `/gallery/` URLs.

## Failure Evidence

Command run:

```bash
bun test seo-baseline.test.ts
```

Observed failure summary:

```text
(fail) robots.txt publishes the minimum owned crawl baseline
error: expect(received).toBeTrue()
Received: false

(fail) sitemap.xml publishes the minimum owned routes baseline
error: expect(received).toBeTrue()
Received: false

0 pass
2 fail
```

## Status

- Red phase complete: failing executable coverage now proves the owned sitemap/robots baseline is still absent.
