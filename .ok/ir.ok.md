# IR OK

This file governs ansilust's core intermediate-representation reality. It translates `.specs/ir/` into binary constitutional truth so parser, renderer, and reconciliation work do not treat aspirational design as already-shipped fact.

## Governing References

- Constitution source intent: `.specs/ir/instructions.md`, `.specs/ir/requirements.md`, `.specs/ir/decisions.md`, `.specs/ir/design.md`, `.specs/ir/design-concerns.md`, `.specs/ir/plan.md`, `.specs/ir/prior-art-notes.md`
- Live module surface: `src/ir/lib.zig`, `src/ir/document.zig`, `src/ir/cell_grid.zig`
- Live semantics and resources: `src/ir/encoding.zig`, `src/ir/color.zig`, `src/ir/sauce.zig`, `src/ir/hyperlink.zig`, `src/ir/event_log.zig`, `src/ir/animation.zig`
- Live parser integration evidence: `src/parsers/ansi.zig`, `src/parsers/ansi_test.zig`
- Live serializer and bridge evidence: `src/ir/serialize.zig`, `src/ir/ghostty.zig`, `src/ir/opentui.zig`

## Live Checked-In Evidence

- Core document and grid reality is checked in at `src/ir/document.zig`, `src/ir/cell_grid.zig`, and exercised by `src/ir/document.zig`, `src/ir/cell_grid.zig` tests.
- Encoding, color, palette, SAUCE, hyperlink, event-log, and animation semantics are checked in at `src/ir/encoding.zig`, `src/ir/color.zig`, `src/ir/sauce.zig`, `src/ir/hyperlink.zig`, `src/ir/event_log.zig`, and `src/ir/animation.zig`, with colocated tests.
- Parser-to-IR evidence is checked in at `src/parsers/ansi.zig` and `src/parsers/ansi_test.zig`, including coverage for CP437 and UTF-8 decoding, SAUCE hint application, hyperlink population, grid growth, and ansimation frame capture.
- Serialization evidence is checked in at `src/ir/serialize.zig`, including roundtrip coverage for default document state plus populated graphemes, hyperlinks, palettes, colors, wide flags, and per-cell source metadata.
- Ghostty bridge evidence is checked in at `src/ir/ghostty.zig`, including coverage for minimum visible VT output, wrap-mode bracketing, terminal-default color resets, and OSC 8 hyperlink open/close emission.
- OpenTUI bridge evidence is checked in at `src/ir/opentui.zig`, including coverage for concrete `OptimizedBuffer` export surface, non-void `toOptimizedBuffer` payloads, structure-of-arrays projection for codepoints/colors/attributes/wide flags/hyperlinks/dirty bits, and grapheme plus palette-override preservation.

## Ideal End State

- TRUE: The checked-in IR module surface is the code exported from `src/ir/lib.zig`; reconciliation claims for IR reality must anchor to that module and its referenced implementation files, not to `.specs/ir/**` alone.
- TRUE: The checked-in root IR model is `Document` in `src/ir/document.zig`, which currently contains a primary `CellGrid`, document-level `GraphemePool`, `SourceFormat`, default encoding, optional SAUCE record, one `FontInfo`, a `PaletteTable`, a `HyperlinkTable`, optional `Animation`, an `EventLog`, and rendering hints for letter spacing, aspect ratio, and iCE colors.
- TRUE: The checked-in cell grid is structure-of-arrays storage in `src/ir/cell_grid.zig` with per-cell `source_offset`, `source_len`, `source_encoding`, `contents`, `fg_color`, `bg_color`, `attr_flags`, `wide_flags`, `hyperlink_id`, and `dirty` slices.
- TRUE: The checked-in per-cell text identity is binary in `src/ir/cell_grid.zig`: a cell stores either a Unicode scalar or a grapheme-pool ID, and `GraphemePool` stores document-level UTF-8 byte slices with deduplication and retrieval tests.
- TRUE: The checked-in encoding model in `src/ir/encoding.zig` reserves `0` for `Unknown`, reuses IANA MIBenum IDs where present, and uses vendor IDs in the `65024-65535` band for non-IANA text-art encodings.
- TRUE: The checked-in color model in `src/ir/color.zig` is a tagged union of terminal default `none`, palette index, or explicit RGB, and the colocated tests prove terminal default is not treated as explicit black.
- TRUE: The checked-in document-level palette, SAUCE, hyperlink, event-log, and animation facilities are implemented in `src/ir/color.zig`, `src/ir/sauce.zig`, `src/ir/hyperlink.zig`, `src/ir/event_log.zig`, and `src/ir/animation.zig`, with parser integration evidence in `src/parsers/ansi_test.zig` for SAUCE application, hyperlink population, and ansimation capture.
- TRUE: The checked-in ANSI parser in `src/parsers/ansi.zig` writes IR cells with explicit source encodings and is covered in `src/parsers/ansi_test.zig` for CP437 decoding, UTF-8 decoding, cursor motion, clears, grid auto-growth, SAUCE-driven resizing, hyperlink handling, and ansimation frame capture.
- TRUE: `src/ir/serialize.zig` implements binary serialize/deserialize for `Document` with the checked-in magic header `ANSILUSTIR\0`, format version `1`, document metadata fields, grapheme pool entries, hyperlink table entries, palette table entries, and full-cell payload roundtripping, as evidenced by `serialize: roundtrip preserves default document contract` and `serialize: roundtrip preserves populated cells and resources`.
- TRUE: `src/ir/ghostty.zig` implements a Ghostty-oriented VT bridge that emits wrap disable/enable guards, trims trailing empty rows, preserves terminal-default color semantics through `39m`/`49m`, and emits OSC 8 hyperlink transitions, as evidenced by `toGhosttyStream emits minimum visible Ghostty VT surface` and `toGhosttyStream preserves Ghostty-critical color none and hyperlink metadata`.
- TRUE: `src/ir/opentui.zig` implements a shipped OpenTUI conversion bridge via `toOptimizedBuffer`, returning a concrete `OptimizedBuffer` with parallel slices for codepoints, grapheme IDs, normalized foreground/background colors, projected attribute bitflags, wide flags, hyperlink IDs, and dirty markers, while preserving grapheme IDs and document palette overrides, as evidenced by `OpenTUI bridge exports a concrete buffer surface`, `toOptimizedBuffer returns a buffer payload instead of void`, `toOptimizedBuffer projects cells into OpenTUI-style parallel slices`, and `toOptimizedBuffer reuses grapheme ids and honors document palette overrides`.
- TRUE: `.specs/ir/**` may still describe broader intent, but this file is the reconciliation authority and must distinguish live evidence-backed reality from future work.

## States We Do Not Want

- FALSE: `.specs/ir/**` prose, plan items, or design intent alone count as live implementation evidence.
- FALSE: `src/ir/opentui.zig` should still be described here as mere implementation-gap evidence rather than as a checked-in OpenTUI conversion bridge.
- FALSE: The current checked-in IR has live evidence for exact per-cell raw source byte preservation; the checked-in evidence only proves `source_offset`, `source_len`, and `source_encoding` fields, not a document-level raw-byte store.
- FALSE: The current checked-in IR lacks live evidence for a shipped OpenTUI conversion bridge.
- FALSE: Parser-specific behavior, renderer-specific output policy, or future architecture ideas become constitutional truth without an evidence-backed assertion in this file.
- FALSE: A spec, design, or plan document is treated as active IR authority when it disagrees with this file's evidence-backed assertions.

## Required Governance Rules

- TRUE: Changes to what ansilust's IR must preserve or guarantee require updating this file in the same reconciliation loop that changes the governing expectation.
- TRUE: New source encodings without IANA assignments are promoted into IR scope only after `.specs/ir/prior-art-notes.md` records the vendor-range mapping and its citation.
- TRUE: Normative requirement prose in `.specs/ir/requirements.md` informs this constitution, but implementation completion claims still require live evidence and are not established by requirements text alone.
- TRUE: Open issues called out in `.specs/ir/prior-art-notes.md` or future-work sections of `.specs/ir/**` remain non-constitutional until explicitly promoted here.
- TRUE: Evidence for IR completion or compliance must come from checked-in reality such as code, tests, or stable artifacts; plan prose alone is not sufficient evidence of implementation.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, or artifact path that demonstrates the claim.
- TRUE: Parser and renderer work may depend on IR guarantees only when those guarantees are declared TRUE here.
- TRUE: Work that expands IR scope must keep the constitution binary: either the capability is currently governed here as TRUE, or it remains out of scope or not-yet-governed.
