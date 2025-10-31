# UTF8ANSI Renderer - Requirements Specification

## Overview

This document captures the high-level requirements for the UTF8ANSI renderer using the EARS (Easy Approach to Requirements Syntax) standard. The emphasis is on user-facing behavior and outcomes rather than low-level implementation details.

---

## FR1: Functional Requirements

### FR1.1: Input Acceptance & Defaults

**FR1.1.1**: The renderer shall accept any IR document produced by Ansilust parsers without additional preprocessing.

**FR1.1.2**: WHEN SAUCE metadata is present the renderer shall honor its rendering hints (columns, palette choice, ice colors, aspect hints) before applying defaults.

**FR1.1.3**: WHERE SAUCE metadata is missing the renderer shall assume an 80-column layout unless the caller explicitly overrides it.

**FR1.1.4**: WHEN invoked without file arguments the renderer shall read IR data from standard input so that piping (`cat file | ansilust`) works by default.

**FR1.1.5**: IF the renderer receives empty content THEN it shall exit successfully without emitting terminal control sequences.

### FR1.2: Color Fidelity

**FR1.2.1**: The renderer shall reproduce the classic 16-color DOS/VGA palette so that ANSI art colors match the author’s intent regardless of terminal theme.

**FR1.2.2**: WHEN the user opts into 24-bit color the renderer shall emit colors using the exact RGB values defined by the selected palette.

**FR1.2.3**: WHERE the IR provides a custom palette the renderer shall apply it automatically without requiring additional flags or permissions so the artwork honors the source specification.

**FR1.2.4**: IF a color is unspecified (terminal default) THEN the renderer shall leave the terminal’s foreground or background unchanged to respect user themes.

### FR1.3: Character Fidelity

**FR1.3.1**: The renderer shall translate CP437 glyphs (including box drawing, shading, suits, arrows, accented text) into visually equivalent Unicode codepoints, starting from the libansilove mapping and adjusting as needed to match the artist’s intent.

**FR1.3.2**: WHEN the IR already contains Unicode characters the renderer shall preserve them verbatim without re-mapping.

**FR1.3.3**: IF the renderer encounters a codepoint it cannot map THEN it shall substitute a safe placeholder (e.g. space) and continue so the render never aborts mid-frame.

### FR1.4: Layout & Flow

**FR1.4.1**: The renderer shall position each row of the artwork explicitly so that no terminal auto-wrap behavior is required for correct layout.

**FR1.4.2**: WHEN multi-cell characters (wide glyphs, grapheme clusters) appear the renderer shall keep their cells together and never split them across rows.

**FR1.4.3**: WHILE rendering a document the renderer shall coalesce adjacent cells that share the same visual style to reduce terminal churn.

**FR1.4.4**: IF the IR specifies animation frames THEN the Phase 1 renderer shall render only the first frame (static baseline) and clearly document that limitation.

**FR1.4.5**: The renderer shall preserve the full IR width in the emitted stream so redirected output (e.g., `ansilust art.ans > art.utf8ansi`) retains every column without cropping.

### FR1.5: Terminal Experience

**FR1.5.1**: The renderer shall wrap the output with appropriate setup and teardown sequences when writing to an interactive TTY so the terminal is restored to its prior state after viewing.

**FR1.5.2**: WHEN the renderer detects that stdout is not a TTY (e.g., redirected to a file) it shall omit cursor-hide and clear-screen sequences but still emit DECAWM wrap toggles and cursor positioning commands so replaying the saved `.utf8ansi` preserves layout exactly.

**FR1.5.3**: WHEN an error occurs mid-render on a TTY the renderer shall still perform terminal cleanup before surfacing the failure.

**FR1.5.4**: WHERE possible the renderer shall avoid terminal features that leave persistent side effects (palette mutation, alternate screen) during the Phase 1 baseline.

**FR1.5.5**: The renderer shall bracket every interactive render with DECAWM disable/enable so wide artwork is not reflowed by the terminal, regardless of whether output is live or redirected for later playback.

**FR1.5.6**: IF the caller requests debugging output (e.g., `--no-cleanup`) THEN the renderer shall skip cleanup intentionally and warn the user about the altered behavior.

### FR1.6: IR Authority & Environment

**FR1.6.1**: The renderer shall treat the IR metadata as the authoritative source for palette selection, ice colors, column width, and other rendering hints.

**FR1.6.2**: WHERE CLI or application-level overrides are required, the parser shall encode those choices into the IR before rendering so the renderer does not reinterpret arguments.

**FR1.6.3**: WHEN the runtime environment cannot honor an IR directive (for example, lack of truecolor support) the renderer shall degrade gracefully and surface a warning while preserving overall layout.

### FR1.7: Error Handling & Messaging

**FR1.7.1**: IF the renderer cannot parse its input THEN it shall return a descriptive error that names the failing file or stream.

**FR1.7.2**: WHEN rendering succeeds the renderer shall exit with status code 0 so shell pipelines continue normally.

**FR1.7.3**: WHERE the renderer encounters unsupported features (e.g., animations, sixels) it shall log a friendly warning and skip those sections rather than crashing.

---

## NFR2: Non-Functional Requirements

### NFR2.1: User Experience

**NFR2.1.1**: The renderer shall produce output that Bramwell (human evaluator) agrees looks visually faithful to reference renders for at least 90% of the test corpus.

**NFR2.1.2**: WHEN artwork contains signature CP437 glyphs (box borders, shading blocks) Bramwell shall report that they render as expected rather than as generic squares.

### NFR2.2: Performance & Responsiveness

**NFR2.2.1**: The renderer shall display a typical 80×200 ANSI in well under one second on modern hardware to preserve an interactive feel.

**NFR2.2.2**: The renderer shall generate the full ANSI output in memory before emitting it so that terminal state changes (wrap disable/enable, cleanup) are applied exactly once.

### NFR2.3: Reliability & Safety

**NFR2.3.1**: The renderer shall leave the terminal in a usable state even if the user interrupts execution (Ctrl-C) mid-render.

**NFR2.3.2**: IF a memory allocation fails THEN the renderer shall surface an error without leaking previously allocated resources.

### NFR2.4: Maintainability

**NFR2.4.1**: The renderer shall expose a clear Zig API (documented public functions, options) so future render targets (HTML, PNG) can reuse the same IR contract.

**NFR2.4.2**: WHEN new glyph mappings or palettes are discovered the renderer shall allow extending lookup tables without invasive rewrites.

---

## TC3: Technical Constraints

**TC3.1**: The renderer shall target Zig 0.11 or later and rely only on the standard library plus existing ansilust modules.

**TC3.2**: WHILE running the renderer shall avoid using global mutable state so that multiple renders can execute safely in parallel if needed.

**TC3.3**: IF the renderer is built with different optimization levels (Debug, ReleaseSafe, ReleaseFast) THEN all builds shall produce identical visual output.

---

## DR4: Data Requirements

**DR4.1**: The renderer shall rely on the IR cell grid, palette metadata, and SAUCE records exactly as produced by the parsers—no bespoke data structures.

**DR4.2**: WHEN emitting text the renderer shall output UTF-8 encoded bytes suitable for direct writing to stdout or a file.

**DR4.3**: The renderer shall maintain reusable lookup tables for CP437→Unicode mappings and canonical palette definitions derived from libansilove.

---

## IR5: Integration Requirements

**IR5.1**: The renderer shall plug into the existing `ansilust` CLI so that running `ansilust <file>` routes through the new rendering pathway by default.

**IR5.2**: WHEN future renderers (HTML, PNG) are introduced the CLI shall keep UTF8ANSI as the default unless the user explicitly selects another backend.

**IR5.3**: WHERE OpenTUI or other downstream consumers require access to rendered output the renderer shall expose a function that returns the generated ANSI stream without writing to stdout automatically.

---

## DEP6: Dependencies & Reuse

**DEP6.1**: The renderer shall reuse the CP437 mapping and palette definitions from the effect-native/libansilove reference wherever applicable to stay aligned with prior art.

**DEP6.2**: WHEN test fixtures are needed the renderer team shall borrow known-good ANSI samples from the acdu0395 corpus and existing ansilove regression suites.

---

## SC7: Success Criteria

**SC7.1**: Bramwell (human evaluator) reports that colors and glyphs look “correct” compared to the baseline PNG renders for at least 90% of sampled files.

**SC7.2**: After viewing multiple artworks with `ansilust <file>` the terminal reports no lingering errors (e.g., unknown terminal type) once the command exits.

**SC7.3**: The renderer passes automated regression tests covering palette mapping, glyph translation, SAUCE handling, and terminal cleanup.

**SC7.4**: The renderer can display a random ANSI from Bramwell’s Downloads folder using `find … | shuf -n1 | ansilust` without crashing or leaving the terminal in a broken state.

---

## Requirements Traceability Snapshot

| Requirement Group | Key Source in Instructions.md | Primary Validation Method |
|-------------------|--------------------------------|---------------------------|
| FR1 Inputs & Defaults | CLI UX, SAUCE handling | Unit + integration tests |
| FR1 Color & Glyph Fidelity | Color palette, CP437 mapping | Golden corpus comparison |
| FR1 Layout & Terminal Safety | Layout & positioning, terminal safety | Manual + automated tests |
| FR1 Options & Errors | CLI behavior, error handling | CLI smoke tests |
| NFR2 User Experience | Bramwell feedback loop | Human evaluation |
| NFR2 Reliability | Terminal safety contract | Integration tests |
| IR5 Integration | CLI UX, future renderer notes | CLI tests + code review |

---

## Phase 2 Status

- Functional requirements rewritten at a higher level (EARS-compliant).
- Non-functional, technical, data, integration, dependency, and success criteria updated to emphasize user-facing outcomes.
- Ready for your review and authorization to proceed to **Phase 3: Design Phase**.
