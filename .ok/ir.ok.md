# IR OK

This file governs ansilust's core intermediate-representation reality. It translates `.specs/ir/` into binary constitutional truth so parser, renderer, and reconciliation work do not treat aspirational design as already-shipped fact.

## Governing References

- `.specs/ir/instructions.md`
- `.specs/ir/requirements.md`
- `.specs/ir/decisions.md`
- `.specs/ir/design.md`
- `.specs/ir/design-concerns.md`
- `.specs/ir/plan.md`
- `.specs/ir/prior-art-notes.md`

## Ideal End State

- TRUE: The IR is ansilust's canonical loss-preserving bridge between supported text-art parsers and renderers.
- TRUE: Core IR truth preserves both classic and modern text-art semantics: per-cell source bytes, explicit source encoding, normalized Unicode or grapheme identity, colors, attributes, dimensions, and document metadata.
- TRUE: The IR distinguishes terminal default color from explicit black and preserves both palette-indexed and RGB color data without collapsing them into one representation.
- TRUE: The IR preserves fidelity-critical classic metadata and hints when present, including SAUCE, font identity or embedded font data, letter-spacing hints, aspect-ratio hints, and iCE-color semantics.
- TRUE: The IR treats animation frames, hyperlink tables, and ordered terminal-event capture as first-class document data only when they are represented losslessly enough to replay or serialize without guessing.
- TRUE: Ghostty-aligned terminal semantics are mandatory for IR acceptance; OpenTUI compatibility is allowed only when it does not reduce Ghostty fidelity.
- TRUE: `.specs/ir/**` may contain research, design detail, and implementation plans, but only assertions promoted into this file are constitutional truth for reconciliation.

## States We Do Not Want

- FALSE: IR work discards raw source bytes after Unicode normalization or otherwise makes classic text-art data unrecoverable.
- FALSE: Terminal default color is treated as interchangeable with explicit black.
- FALSE: Parser-specific behavior, renderer-specific output policy, deployment promises, or UX concerns are treated as part of IR constitutional scope.
- FALSE: OpenTUI compatibility or any secondary consumer is allowed to override Ghostty-grade fidelity requirements.
- FALSE: Future-only topics from `.specs/ir/requirements.md` section 7, `.specs/ir/instructions.md` future considerations, or unchecked items in `.specs/ir/plan.md` are treated as current obligations without this file being updated first.
- FALSE: A spec, design, or plan document is treated as active IR authority when it disagrees with this file.

## Required Governance Rules

- TRUE: Changes to what ansilust's IR must preserve or guarantee require updating this file in the same reconciliation loop that changes the governing expectation.
- TRUE: New source encodings without IANA assignments are promoted into IR scope only after `.specs/ir/prior-art-notes.md` records the vendor-range mapping and its citation.
- TRUE: Evidence for IR completion or compliance must come from executable reality such as code, tests, or stable checked-in artifacts; plan prose alone is not sufficient evidence of implementation.
- TRUE: Parser and renderer work may depend on IR guarantees only when those guarantees are declared TRUE here.
- TRUE: Work that expands IR scope must keep the constitution binary: either the capability is currently governed here as TRUE, or it remains out of scope or not-yet-governed.
