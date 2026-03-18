---
id: task-high-product-surface-spec-coverage
level: high
status: done
blocked_by: []
expires_at: 2026-03-25T12:46:37-04:00
---

# Product Surface Spec Coverage

Author the remaining constitutions for the download and experience-facing spec areas so every active `.specs/*` directory is represented in `.ok`.

## Evidence

- Verified the product-surface constitution chain is complete: `task-med-author-download-constitution`, `task-med-author-experience-constitutions`, `task-low-derive-download-ok-assertions`, `task-low-link-download-ok-to-existing-evidence`, `task-low-derive-website-and-screensaver-ok-assertions`, and `task-low-derive-durdraw-darkdraw-ok-assertions` are all `status: done` with evidence recorded.
- Verified every active product-surface spec directory under `.specs/` now has a governing constitution: `.specs/download/` -> `.ok/download.ok.md`, `.specs/website/` -> `.ok/website.ok.md`, `.specs/screensaver/` -> `.ok/screensaver.ok.md`, and `.specs/durdraw-darkdraw/` -> `.ok/durdraw-darkdraw.ok.md`.
- Updated `.ok/project-management.ok.md` so the covered-spec-area summary now explicitly lists the website, screensaver, and durdraw-darkdraw slices alongside the existing download entry.
