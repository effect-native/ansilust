# Render UTF8ANSI OK

This file governs ansilust's UTF8ANSI renderer reality. It translates `.specs/render-utf8ansi/` intent into binary constitutional truth anchored to the checked-in renderer code and tests that exist today.

## Governing References

- Constitution source intent: `.specs/render-utf8ansi/instructions.md`, `.specs/render-utf8ansi/requirements.md`, `.specs/render-utf8ansi/design.md`, `.specs/render-utf8ansi/plan.md`, `.specs/render-utf8ansi/experiments/wrap-behavior/RECOMMENDATION.md`
- Live module surface: `src/root.zig`, `src/renderers/utf8ansi.zig`
- Live renderer test evidence: `src/renderers/utf8ansi_test.zig`
- Live parser integration evidence: `src/parsers/ansi.zig`, `src/parsers/ansi_test.zig`
- Live artifact status: no checked-in renderer-specific artifact directory currently provides stronger evidence than the code and tests above

## Live Checked-In Evidence

- The exported renderer surface is checked in at `src/root.zig` and `src/renderers/utf8ansi.zig`, with the public entrypoints `render` and `renderToBuffer` backed by direct implementation.
- Terminal-guard behavior is checked in at `src/renderers/utf8ansi.zig` and exercised by `src/renderers/utf8ansi_test.zig`, including DECAWM disable/restore, TTY-only cursor hide/show, and file-mode omission of cursor hiding.
- Row emission, color emission, batching, hyperlink output, NUL-to-space handling, and tilde substitution are checked in at `src/renderers/utf8ansi.zig` and covered in `src/renderers/utf8ansi_test.zig`.
- Parser-to-renderer hyperlink roundtrip evidence is checked in at `src/parsers/ansi.zig`, `src/parsers/ansi_test.zig`, and `src/renderers/utf8ansi_test.zig`.
- Evidence for clear-screen homing, absolute row positioning, spacer-head or spacer-tail handling, and a renderer-local CP437 lookup table is currently negative: those behaviors are not implemented in `src/renderers/utf8ansi.zig` and therefore cannot be claimed as live renderer reality.

## Ideal End State

- TRUE: The checked-in UTF8ANSI renderer surface is the code exported from `src/root.zig` and implemented in `src/renderers/utf8ansi.zig`; reconciliation claims for renderer reality must anchor there, not to `.specs/render-utf8ansi/**` alone.
- TRUE: The checked-in renderer scope is converting an ansilust IR `Document` into UTF-8 plus ANSI byte streams for terminal display or replayable redirected output.
- TRUE: Both TTY and non-TTY renders disable DECAWM with `CSI ?7l` before artwork bytes and restore DECAWM with `CSI ?7h` during cleanup.
- TRUE: TTY renders additionally hide the cursor with `CSI ?25l`, restore it with `CSI ?25h`, and append two trailing newlines during cleanup for scrollback safety.
- TRUE: The checked-in row-layout policy is sequential row-major emission separated by newline bytes; the current implementation does not use absolute `CSI {row};1H` positioning.
- TRUE: The checked-in renderer trims trailing fully blank rows via `rowHasContent`, but within each rendered row it still walks the full document width so trailing spaces and background color reach the right edge.
- TRUE: The checked-in default color policy in `src/renderers/utf8ansi.zig` emits DOS palette indices `0` through `15` as explicit 24-bit RGB SGR, emits `Color::rgb` directly as 24-bit SGR, emits `Color::none` as `SGR 39` and `SGR 49`, and falls back to `38;5` or `48;5` only for palette indices above `15`.
- TRUE: The checked-in renderer batches consecutive cells with unchanged foreground and background colors and emits `SGR 0` before reapplying colors when the color state changes.
- TRUE: The checked-in renderer emits OSC 8 hyperlink open and close sequences from per-cell `hyperlink_id` values and closes active hyperlinks when the link changes or the row ends.
- TRUE: The checked-in renderer emits Unicode scalar content directly from IR, renders scalar `0` as a space instead of a literal NUL byte, and currently substitutes `~` with U+02DC SMALL TILDE for presentation.
- TRUE: `.specs/render-utf8ansi/**` may still describe broader or future renderer intent, but only the evidence-backed assertions promoted here are constitutional truth for reconciliation.

## States We Do Not Want

- FALSE: `.specs/render-utf8ansi/**` prose, plan items, or experiments alone count as live renderer evidence.
- FALSE: TTY renders are treated as clearing the screen with `CSI 2J` or homing the cursor with `CSI H`; the checked-in renderer does not currently do either.
- FALSE: Non-TTY renders are treated as using absolute cursor positioning or any other auto-wrap-independent cursor addressing scheme; the checked-in renderer currently relies on newline-separated rows.
- FALSE: Wide-character spacer-head or spacer-tail handling is treated as shipped renderer behavior without checked-in implementation and tests in `src/renderers/utf8ansi.zig`.
- FALSE: The current checked-in renderer is treated as owning a complete CP437-to-Unicode lookup table; checked-in CP437 lookup evidence lives in `src/parsers/ansi.zig`, while the renderer consumes already-decoded IR scalars.
- FALSE: Renderer-specific checked-in artifacts are assumed to exist beyond code and tests when no such stable artifact evidence is currently present.
- FALSE: Any spec, design, or plan document overrides this file when it conflicts with the evidence-backed assertions declared here.

## Required Governance Rules

- TRUE: Changes to terminal-control behavior, row layout policy, color emission policy, hyperlink emission, or glyph substitution rules require updating this file in the same reconciliation loop.
- TRUE: New renderer completion claims must be backed by checked-in code, tests, or stable artifacts; spec prose alone is insufficient.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, or artifact path that demonstrates the claim.
- TRUE: Parser-side evidence may support renderer-adjacent roundtrip claims only when the renderer-side behavior is also checked in and cited here.
- TRUE: Expanding renderer scope stays binary: a behavior is either governed here as live evidence-backed reality or it remains future, unevidenced, or out of scope.
