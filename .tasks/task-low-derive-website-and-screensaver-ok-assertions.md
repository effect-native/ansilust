---
id: task-low-derive-website-and-screensaver-ok-assertions
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Derive Website And Screensaver Assertions

Extract the binary, evergreen assertions for `.specs/website/` and `.specs/screensaver/` into future constitutions.

## Evidence

- Tightened `.ok/website.ok.md` with additional binary assertions derived from `.specs/website/**` so stack, route, content, deployment, SEO, and UX requirements remain explicitly future until backed by website-specific checked-in artifacts.
- Tightened `.ok/screensaver.ok.md` with additional binary assertions derived from `.specs/screensaver/**` so rotation, fullscreen behavior, config, mirror/bootstrap orchestration, renderer modes, and system integration stay demoted until backed by checked-in evidence.
