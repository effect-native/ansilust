---
id: task-low-derive-render-utf8ansi-ok-assertions
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Derive Render UTF8ANSI OK Assertions

Extract the binary, evergreen assertions from `.specs/render-utf8ansi/` that should govern renderer reality.

## Evidence

- Tightened `.ok/render-utf8ansi.ok.md` with binary assertions derived from `.specs/render-utf8ansi/instructions.md`, `.specs/render-utf8ansi/requirements.md`, `.specs/render-utf8ansi/design.md`, `.specs/render-utf8ansi/plan.md`, and `.specs/render-utf8ansi/experiments/wrap-behavior/RECOMMENDATION.md`.
- Removed unevidenced shipped-language drift by distinguishing constitutional assertions from spec-only or future behavior.
- Promoted explicit renderer contract details for DECAWM bracketing, TTY-vs-non-TTY behavior, absolute positioning, color policy, CP437 mapping scope, and forbidden persistent terminal mutations.
