# Render UTF8ANSI OK

This file governs ansilust's UTF8ANSI renderer reality. It translates `.specs/render-utf8ansi/` into binary constitutional truth so renderer work stays anchored to shipped behavior and checked-in evidence rather than aspirational spec text.

## Governing References

- `.specs/render-utf8ansi/instructions.md`
- `.specs/render-utf8ansi/requirements.md`
- `.specs/render-utf8ansi/design.md`
- `.specs/render-utf8ansi/plan.md`
- `.specs/render-utf8ansi/experiments/wrap-behavior/RECOMMENDATION.md`

## Ideal End State

- TRUE: UTF8ANSI renderer scope is the conversion of ansilust IR documents into UTF-8 plus ANSI byte streams for terminal display or redirected replay.
- TRUE: The current terminal-safety contract requires a paired DECAWM disable/enable sequence around every render in both TTY and non-TTY modes.
- TRUE: The current interactive-only terminal niceties are cursor hide before render and cursor show after render; automatic clear-screen, cursor-home, and alternate-screen behavior are not required renderer truth.
- TRUE: Current color-fidelity truth is explicit 24-bit SGR emission for DOS/VGA palette indices 0-15, direct 24-bit emission for RGB colors, terminal-default preservation via `SGR 39` and `SGR 49`, and 256-color fallback only for extended palette indices already present in IR.
- TRUE: Current shipped CLI reality is file-argument rendering through the UTF8ANSI path for `ansilust <file>`; stdin-default rendering and renderer-selection flags are not current constitutional guarantees.
- TRUE: Renderer-owned output policy may apply visual substitutions without rewriting IR semantics; current governed examples include UTF-8 scalar emission, NUL-to-space safety, and renderer-local glyph adjustments.
- TRUE: Current renderer output may include OSC 8 hyperlinks when hyperlink data already exists in IR.
- TRUE: `.specs/render-utf8ansi/**` may contain design intent, experiments, and future work, but only assertions promoted into this file are constitutional truth for renderer reconciliation.

## States We Do Not Want

- FALSE: Absolute per-row cursor positioning, screen clearing, cursor homing, or other setup behavior described only in specs are treated as shipped renderer obligations without matching evidence and promotion here.
- FALSE: CLI flags or behaviors that are still spec-only, including `--palette`, `--256color`, `--columns`, and `--no-cleanup`, are treated as current renderer guarantees.
- FALSE: Parser defaults, IR data-model guarantees, deployment promises, or website/screensaver experience concerns are treated as part of UTF8ANSI renderer constitutional scope.
- FALSE: Human-evaluation targets, corpus goals, animation plans, capability auto-detection, or TODO items are treated as present-tense renderer reality without executable or checked-in artifact evidence.
- FALSE: Any `.specs/render-utf8ansi/**` document overrides this file when it disagrees with current shipped renderer truth.

## Required Governance Rules

- TRUE: Changes to the renderer's terminal-control contract, color-emission policy, CLI entry behavior, or renderer-local glyph policy require updating this file in the same reconciliation loop.
- TRUE: Renderer completion claims must be backed by code, tests, or stable checked-in experiment artifacts; plan prose alone is not sufficient evidence.
- TRUE: Downstream work may rely only on renderer guarantees declared TRUE here.
- TRUE: Expanding renderer scope remains binary: a capability is either governed here as current truth or it is still unevidenced, future, or out of scope.
