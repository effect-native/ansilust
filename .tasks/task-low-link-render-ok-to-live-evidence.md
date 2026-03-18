---
id: task-low-link-render-ok-to-live-evidence
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Link Render Constitution To Evidence

Anchor the future renderer constitution to current code, tests, and validation evidence so it can be reconciled mechanically.

## Evidence

- Rewrote `.ok/render-utf8ansi.ok.md` to cite live checked-in renderer evidence from `src/root.zig`, `src/renderers/utf8ansi.zig`, `src/renderers/utf8ansi_test.zig`, `src/parsers/ansi.zig`, and `src/parsers/ansi_test.zig` instead of relying on `.specs/render-utf8ansi/**` intent alone.
- Added an explicit live-evidence section to `.ok/render-utf8ansi.ok.md` that points to current code and test coverage, and recorded that no stronger checked-in renderer artifact evidence currently exists.
- Demoted spec-only renderer claims in `.ok/render-utf8ansi.ok.md` for clear-screen homing, absolute row positioning, spacer handling, and a renderer-local CP437 lookup table because `src/renderers/utf8ansi.zig` does not implement them today.
- Promoted only evidence-backed current behavior in `.ok/render-utf8ansi.ok.md`, including DECAWM bracketing, TTY cursor handling, newline-based row layout, 24-bit palette emission, hyperlink output, row trimming, NUL-to-space rendering, and current tilde substitution.
