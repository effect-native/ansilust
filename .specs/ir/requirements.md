# Ansilust IR Requirements (Phase 2)

**Document owner:** Ansilust IR working group  
**Status:** Proposed – implements decisions in [.specs/ir/decisions.md](decisions.md)
**Supersedes:** `.specs/ir/instructions.md` once ratified  
**Related artifacts:**  
- [.specs/ir/prior-art-notes.md](prior-art-notes.md)  
- `reference/ghostty/AGENTS.md`, `reference/ansilove/AGENTS.md`, `reference/bun/AGENTS.md`

---

## 1. Scope

This document defines the normative requirements for the Ansilust Intermediate Representation (IR). The IR is the canonical bridge between all supported text-art parsers and renderers. The scope covers:

- Core data structures (cells, document-level tables, animation frames)
- Encoding, font, palette, and metadata handling
- Public API surface for parsers/renderers
- Serialization format and versioning
- Performance, reliability, and testing criteria

Out of scope: parser specifics, renderer-specific protocols, UI/CLI concerns, and transport formats other than the IR serialization described herein.

---

## 2. Terminology

| Term | Definition |
|------|------------|
| **Cell Grid** | Structure-of-arrays layout representing the 2D art surface (Decision D1) |
| **Cell** | Logical unit containing code units, encoding tag, Unicode scalar/grapheme reference, colors, and attributes |
| **Document** | IR root containing global metadata (palettes, fonts, SAUCE, animation table, etc.) |
| **Frame** | An animation element referencing either a full grid or a delta update (Decisions D8/D9) |
| **Palette** | A shared color table (16 or 256 entries) referenced by cells (Decision D6) |
| **Source Encoding** | Enumerated value describing the code page/charset of the raw bytes (Decision D3) |
| **Grapheme Pool** | Arena storing multi-codepoint sequences referenced by cells (Decision D2) |

---

## 3. Normative Requirements

Requirements are grouped by concern. “SHALL” statements are mandatory. “SHOULD” statements are strong recommendations. References to decisions appear in brackets.

### 3.1 Cell Grid Layout

- **RQ-Cell-1:** The IR SHALL implement the cell grid as a structure-of-arrays layout with parallel slices for each per-cell field [D1].
- **RQ-Cell-2:** The cell grid SHALL store, for each cell:
  - Raw source byte pointer/offset and length
  - Source encoding tag (`SourceEncoding`)
  - Normalized Unicode scalar OR grapheme ID
  - Foreground color
  - Background color
  - Attribute bitflags (32-bit)
  - Wide/spacer flags
  - Hyperlink marker
  - Dirty-state bit (optional but recommended for diffing)
- **RQ-Cell-3:** The cell grid SHALL expose width/height metadata and guarantee bounds-checking on all accessor APIs.

### 3.2 Grapheme Storage

- **RQ-Grapheme-1:** The IR SHALL maintain a grapheme pool arena. Cells store a small integer ID (0 denotes “no grapheme span”) [D2].
- **RQ-Grapheme-2:** Grapheme entries SHALL contain UTF-8 bytes plus length metadata to permit lossless reconstruction.
- **RQ-Grapheme-3:** The IR SHALL provide APIs to map between cell indices and grapheme spans, ensuring ownership semantics are clear (IR retains allocation responsibility).

### 3.3 Source Encodings

- **RQ-Encoding-1:** `SourceEncoding` SHALL be defined as `enum(u16)` using IANA MIBenum IDs whenever available; value `0` SHALL represent `Unknown` [D3].
- **RQ-Encoding-2:** Encodings lacking IANA assignments but required for text-art fidelity (e.g., PETSCII) SHALL reside in a documented vendor range (`65024-65535`) with citations recorded in `.specs/ir/prior-art-notes.md`.
- **RQ-Encoding-3:** A cell’s raw source bytes SHALL NOT be discarded even after normalization to Unicode (Decisions D3/D4).

### 3.4 Raw Byte Storage

- **RQ-Raw-1:** The IR SHALL allocate a contiguous byte arena with per-cell offsets. Payloads ≤ 2 bytes SHOULD be inlined for cache efficiency [D4].
- **RQ-Raw-2:** APIs SHALL allow retrieval of the exact byte slice for any cell.

### 3.5 Unicode Fields

- **RQ-Unicode-1:** The IR SHALL store a 32-bit Unicode scalar per cell OR a sentinel referencing the grapheme pool [D5].
- **RQ-Unicode-2:** Helper APIs SHALL provide Unicode-focused accessors for renderers that do not need raw bytes.

### 3.6 Palette and Color Handling

- **RQ-Palette-1:** Document-level palette tables, where present, SHALL be shared objects referenced by cells using palette indices and SHALL record their entry count (commonly 16 or 256 entries) [D6].
- **RQ-Palette-2:** Cells SHALL express colors using a tagged union: `None` (terminal default), `Palette(u8)`, or `Rgb(u8,u8,u8)`; the `Rgb` variant SHALL support true-color data even when no palette entry applies.
- **RQ-Palette-3:** The document root SHALL preserve all palettes supplied by the source (standard or custom).
- **RQ-Palette-4:** Color conversions SHALL distinguish terminal default (`None`) from explicit black (`Palette(0)` or `Rgb(0,0,0)`).
- **RQ-Palette-5:** Dynamic palette updates (e.g., OSC 4/10/11/12 sequences) SHALL be recorded in an ordered event list that captures the updated indices and color values; when animations are present these events SHALL be associated with the corresponding frame or delta.

### 3.7 Attribute Bitflags

- **RQ-Attr-1:** Attribute bitfields SHALL occupy 32 bits per cell with documented bit layout [D7]. Lower 16 bits mirror classic ANSI flags; upper 16 bits are reserved for modern attributes (faint, overline, hyperlink markers, underline style encoding).
- **RQ-Attr-2:** Underline style SHALL allow at least: none, single, double, curly, dotted, dashed.
- **RQ-Attr-3:** Separate underline color SHALL be supported and stored in the style table.

### 3.8 Fonts and Rendering Hints

- **RQ-Font-1:** Document metadata SHALL preserve font names and embedded bitmap data when present (e.g., XBin) [D4/D6].
- **RQ-Font-2:** Font records SHALL include dimensions (width, height), glyph count, and code-point mapping information.
- **RQ-Font-3:** Document metadata SHALL include letter-spacing hints (8-bit vs 9-bit) and aspect ratio hints (e.g., DOS 1.35x) [D4].
- **RQ-Font-4:** Renderers lacking support for embedded fonts SHALL degrade gracefully by using a documented fallback table, but the IR itself MUST remain lossless.

### 3.9 Animation

- **RQ-Anim-1:** The IR SHALL represent animations via a document-level `Animation` struct containing an ordered list of frames plus global loop metadata [D8].
- **RQ-Anim-2:** Each frame record SHALL reference either:
  - A full cell grid snapshot, or
  - A delta list (coordinate + new cell state) relative to the previous frame [D9].
- **RQ-Anim-3:** Duration and optional delay SHALL be stored as `u32` milliseconds per frame [D10].
- **RQ-Anim-4:** Parsers SHOULD emit delta frames where beneficial, but MUST support decoding to full grids.
- **RQ-Anim-5:** When animations are absent, single-frame documents MUST NOT pay a storage penalty beyond the base grid.

### 3.10 SAUCE and Metadata

- **RQ-SAUCE-1:** The IR SHALL store the complete 128-byte SAUCE record verbatim plus parsed fields for convenience [D11].
- **RQ-SAUCE-2:** SAUCE comment blocks SHALL be preserved as raw byte slices with encoding tags; lazily parsed UTF-8 views MAY be provided.
- **RQ-Meta-1:** The document SHALL record source format identification to support renderer optimizations.
- **RQ-Meta-2:** Additional metadata (creation timestamps, checksums, etc.) MAY be stored but SHALL NOT replace the canonical SAUCE record.

### 3.11 API Surface

- **RQ-API-1:** The initial public API SHALL expose:
  - `getCell`, `setCell`, `resize`
  - `iterateDiff` for animation-aware renderers
  - `toGhosttyStream` (prototype helper focused on Ghostty compatibility) [D14]
- **RQ-API-2:** The API SHALL require a `std.mem.Allocator` for all construction paths and SHALL provide `deinit`/`free` functions [D13].
- **RQ-API-3:** Future batch mutation APIs SHALL be deferred until Phase 3; scope is intentionally constrained.

### 3.12 Serialization

- **RQ-Ser-1:** Serialization SHALL use a custom binary format with header `"ANSILUSTIR\0"` and `u16` version number [D12].
- **RQ-Ser-2:** Sections SHALL be little-endian and include, at minimum: header, document metadata, palette table(s), font table(s), SAUCE, animation table, cell arrays, grapheme pool, raw byte arena.
- **RQ-Ser-3:** Version bumps SHALL be mandatory for breaking changes; backward-compatible additions SHALL utilize reserved bits/sections.

### 3.13 Error Handling

- **RQ-Err-1:** The IR error set SHALL include at least: `error{OutOfMemory, InvalidCoordinate, InvalidEncoding, UnsupportedAnimation, SerializationFailed}` [D17].
- **RQ-Err-2:** All APIs SHALL document error semantics with examples.

### 3.14 Ghostty Alignment

- **RQ-Ghostty-1:** Ghostty semantics (wrap flags, “color None”, hyperlink metadata) SHALL be treated as non-negotiable acceptance criteria [D15].
- **RQ-Ghostty-2:** Reference conversions to OpenTUI MAY exist but SHALL NOT compromise Ghostty fidelity.

### 3.15 Hyperlink Metadata

- **RQ-Link-1:** The IR SHALL maintain a document-level table for OSC8 hyperlink definitions (ID, target URI, optional parameters) and cells SHALL reference entries in that table via their hyperlink markers.
- **RQ-Link-2:** Parsers SHALL preserve all OSC8 attributes present in the source stream; renderers MAY ignore hyperlinks but MUST tolerate their presence without data loss.

### 3.16 Terminal Event Log

- **RQ-Event-1:** The IR SHALL maintain a chronological event log for escape/control sequences that are not directly modeled elsewhere (including vendor-specific OSC codes, focus hints, clipboard offers, and graphics protocols such as Sixel or Kitty images).
- **RQ-Event-2:** Each event entry SHALL include the raw payload, canonical identifier (when known), and an optional frame association so custom renderers can reproduce the behavior without guessing; consumers lacking support SHALL ignore entries without data loss.

---

## 4. Serialization & Data Model Summary

```
Document
├─ Version header
├─ Metadata (format ID, default encoding, dimensions, hints)
├─ SAUCE block (raw + parsed)
├─ Palette table(s)
├─ Font table(s)
├─ Grapheme pool arena
├─ Raw byte arena
├─ Animation table
└─ Cell Grid
   ├─ Encoding tags []
   ├─ Raw byte ranges []
   ├─ Unicode scalars / grapheme IDs []
   ├─ Foreground colors []
   ├─ Background colors []
   ├─ Attribute flags []
   ├─ Wide/spacer flags []
   ├─ Hyperlink markers []
   └─ Dirty bits []
```

---

## 5. Performance & Reliability Targets

- **Perf-1:** Parsing a 1 KB ANSI file into IR SHALL complete ≤ 1 ms on the reference laptop (Ryzen 7 or Apple M1) [D16].
- **Perf-2:** Parsing a 10-frame ansimation totaling ≤ 10 KB SHALL complete ≤ 5 ms.
- **Perf-3:** Serialization/deserialization round-trips SHALL be lossless and complete without heap leaks (allocator instrumentation).
- **Perf-4:** Memory overhead SHOULD remain within 1.5× of the equivalent Ghostty page layout for comparable content.

---

## 6. Testing Requirements

Testing expectations extend the matrix defined in the instructions and Decision D18:

1. **Unit Tests**
   - Cell grid operations (`get/set`, resizing, bounds errors)
   - Encoding preservation (CP437, PETSCII, UTF-8)
   - Color conversions and `None` semantics
   - Attribute flag combinations and underline color handling
   - SAUCE storage/retrieval, including comment encodings
   - Font embedding (XBin) and fallback heuristics
2. **Integration Tests**
   - Format round-trips: ANSI, Binary, XBin (embedded font), UTF8ANSI, ansimation timelines
   - Ghostty renderer integration (`toGhosttyStream`)
   - OpenTUI conversion (optional but recommended)
3. **Property-Based Tests**
   - Parser fuzzing (invalid SAUCE, malformed escape sequences)
   - Grid invariants (dimensions vs. slice lengths)
   - Animation timeline consistency (frame ordering, zero/large durations)
4. **Performance Tests**
   - Benchmarks for typical file sizes and animation workloads
   - Memory profiling for parser lifecycle

Each public API entry SHALL include doc comments with runnable snippets verifying correct behavior under `std.testing`.

---

## 7. Open Issues / Future Work

The following topics remain open for Phase 3+ and are not required for initial implementation:

- Batch mutation APIs and bulk diffing helpers (deferred from D14)
- Lossless transport of non-text graphics (sixel, kitty images)
- Layered documents (multiple grids with blend modes)
- Accessibility metadata (alt text, semantic hints)
- Compression schemes beyond the delta frame structure
- Additional encoding families requiring new vendor-range entries

All future work SHALL document rationale and prior art in `.specs/ir/prior-art-notes.md` before modifying requirements.

---

## 8. Acceptance Checklist

Implementation is considered complete when:

1. All requirements in Sections 3–6 are implemented and verified.
2. Automated tests cover the matrix described in Section 6 with no memory leaks.
3. Serialization format is versioned and documented.
4. Ghostty alignment tests pass with no divergences.
5. Documentation (public API comments, README updates) is up to date.
6. Performance targets in Section 5 are met or justified via documented deviations.

---

## 9. Change Control

- Modifications to this document require consensus between Tom and Bramwell.
- All approved changes SHALL reference supporting research or decisions in `decisions.md`.
- Version history SHALL be recorded at the end of this document once it leaves draft status.

---