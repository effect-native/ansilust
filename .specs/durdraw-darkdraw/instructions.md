# Durdraw & Darkdraw Format Expansion – Instructions (Phase 1)

## Overview

This specification captures the future expansion work required to ingest Durdraw (`.dur`) and Darkdraw (`.ddw`, `.scr`) projects into the Ansilust IR once the current IR baseline ships. The goal is to preserve the rich metadata, animation semantics, and palette behaviors of these modern editors without diluting the existing requirements already allocated to the Phase 5 parser roadmap.

## User Story

**As a** text art developer who collaborates with Durdraw and Darkdraw artists  
**I want** Ansilust to load, inspect, and re-export their native project files  
**So that** the IR can act as a universal bridge between legacy BBS art, modern terminal art, and contemporary tooling.

## Scope & Constraints

- Work commences **after** the current `.specs/ir` baseline reaches Phase 5 sign-off.  
- No changes to the core IR decision log until this spec is authorized; all new requirements live here.  
- Output parity is measured against Durdraw CLI (`durdraw`, `durview`) and Darkdraw VisiData plugin exports (`save_ans`, `save_png`).

## Core Requirements (EARS Notation)

### FR1 – Durdraw Ingestion

- **FR1.1**: The system shall parse Durdraw `DurMovie` metadata (formatVersion, colorFormat, encoding, preferredFont, framerate, columns, lines, extra) into IR document extensions.
- **FR1.2**: WHEN a Durdraw frame declares `delay` seconds the system shall convert that delay to millisecond precision in the IR animation table.
- **FR1.3**: WHEN a Durdraw color map contains legacy palette indices the system shall apply the migration tables defined in `durdraw_movie.py` to normalize foreground/background colors while retaining the original indices for round-trip export.
- **FR1.4**: WHEN Durdraw files mix CP437 and Unicode content the system shall tag each cell with both the declared file encoding and the inferred Unicode scalar so renderers can choose the correct glyph source.
- **FR1.5**: IF a Durdraw file embeds `extra` JSON payloads THEN the system shall store the payload verbatim in document metadata so downstream tools can surface custom extensions.

### FR2 – Darkdraw Ingestion

- **FR2.1**: The system shall parse Darkdraw drawing rows (`x`, `y`, `text`, `color`, `tags`, `group`, `frame`, `ref`) into IR cells while preserving grouping relationships.
- **FR2.2**: WHEN Darkdraw color strings specify attributes (bold, italic, underline, reverse, dim, blink) the system shall map each attribute to the IR flag set.
- **FR2.3**: WHEN Darkdraw assigns rows to frame IDs the system shall translate those memberships into IR animation frames using delta updates.
- **FR2.4**: IF Darkdraw samples reference palette masks from `.scr` loader metadata THEN the system shall capture those palette definitions and associate them with document palette tables.
- **FR2.5**: WHEN Darkdraw references clipboard or tag metadata the system shall persist that information in document-level extension tables for optional UI integration.

### FR3 – Round-Trip Fidelity

- **FR3.1**: The system shall provide exporters that reconstruct `.dur` and `.ddw` artifacts from IR with no observable changes when re-opened in the source applications.
- **FR3.2**: WHEN exporting ANSI from IR that originated in Darkdraw the system shall match `save_ans.py` output cell-for-cell, including attribute resets.
- **FR3.3**: WHEN exporting HTML or PNG from IR that originated in Durdraw the system shall match Durdraw’s HTML/PNG exporter pixel colors for the sampled fixtures.

### NFR4 – Performance & Limits

- **NFR4.1**: Typical Durdraw projects (≤ 1 MB, ≤ 500 frames) shall import within 100 ms on reference hardware (Ryzen 7 / M1).  
- **NFR4.2**: Typical Darkdraw projects (≤ 50 k rows) shall import within 100 ms on reference hardware.  
- **NFR4.3**: Memory overhead for auxiliary metadata shall remain ≤ 1.25× the serialized project size.

### TC5 – Technical Constraints

- **TC5.1**: Implementation shall reuse the existing `DocumentBuilder` façade once Phase 5 lands, extending it with Durdraw/Darkdraw-specific helpers.  
- **TC5.2**: No new third-party dependencies are permitted; parsing must rely on Zig stdlib facilities.  
- **TC5.3**: Serialization format updates shall bump the IR version only after cross-team review.

### IR6 – Integration Requirements

- **IR6.1**: WHEN Durdraw metadata is present the system shall expose it through the public IR API via optional extension queries (`Document.getExtension(.durdraw)`).
- **IR6.2**: WHEN Darkdraw grouping metadata is present the system shall expose it through the IR API so renderers can reconstruct grouped selections.
- **IR6.3**: Exporters shall be wired into the CLI once the IR-level support is validated.

## Acceptance Criteria

1. Import Durdraw fixture suite (selected `.dur`, `.gz`, animated projects) and confirm IR serialization/deserialization is lossless.  
2. Import Darkdraw sample pack, regenerate ANSI via IR exporter, and diff results against `save_ans.py`.  
3. Export Durdraw-derived IR back to `.dur` and confirm Durdraw CLI renders identical playback (frame timing ±1 ms tolerance).  
4. Execute automated regression tests for palette, attribute, and metadata fidelity.  
5. Document the extension APIs and update the general README once the feature leaves embargo.

## Out of Scope

- Real-time editing UX for Durdraw/Darkdraw projects.  
- Implementing VisiData or Durdraw UI wrappers around the IR.  
- Additional format converters (e.g., `.visidata`, `.jsonl` beyond Darkdraw spec).  
- Enhancements to the base IR unrelated to metadata extensions.

## Success Metrics

- SM1: ≥ 95% of provided Durdraw/Darkdraw fixtures round-trip without diffs.  
- SM2: Performance targets in NFR4 met on CI benchmark hardware.  
- SM3: Zero memory leaks reported by `std.testing.allocator` during import/export tests.  
- SM4: Documentation coverage reaches 100% for new public APIs.

## Future Considerations

- FC1: Optional converter to common interchange formats (e.g., `.jsonl` for analytics).  
- FC2: Visualization of Durdraw brush definitions or Darkdraw clipboard slots in downstream tooling.  
- FC3: Support for Durdraw plugin scripts (Python) through event log integration.

## Testing Requirements (Preview)

- T1: Unit tests for Durdraw metadata parsing and animation conversion.  
- T2: Unit tests for Darkdraw color parsing and attribute mapping.  
- T3: Integration tests validating `.dur` ⇄ IR ⇄ `.dur` and `.ddw` ⇄ IR ⇄ `.ddw`.  
- T4: Golden ANSI diff tests against Darkdraw `save_ans.py` output.  
- T5: Performance benchmarks covering fixture import/export.

## Phase Gating

- **Phase 1 (this document)**: Await authorization.  
- **Phase 2**: Author formal requirements and constraints (likely building atop this instructions file).  
- **Phase 3**: Produce detailed design once the baseline IR is signed off.  
- **Phase 4**: Implementation plan aligning with XP/TDD discipline.  
- **Phase 5**: Execution, validation, and rollout.

> **Authorization Required:** Do not begin Phase 2 until Tom explicitly approves these instructions after the core IR spec is delivered.
