# IR Pre-Requirements Decision Log

## Purpose
Before drafting `requirements.md`, we need explicit, opinionated decisions that will anchor the formal specification. This document captures those calls, my recommendations, and the references that back them. Edit in place as needed—once we agree, I will codify them in the Phase 2 requirements.

## Decision Inventory

### D1. Cell Grid Structure
- **Decision**: Adopt a structure-of-arrays (SoA) layout for all per-cell fields.
- **Recommendation**: Use SoA with parallel slices for raw bytes, encoding tag, Unicode scalar/grapheme ID, foreground color, background color, and attribute bitflags.
- **Rationale**: Ghostty-inspired workloads benefit from cache-friendly iteration over individual fields (e.g., color diffs). OpenTUI’s OptimizedBuffer uses SoA; matching that keeps conversion simple while honoring our primary Ghostty focus.
- **References**: `.specs/ir/instructions.md` (Cell Grid requirements), Ghostty `Screen.zig`, OpenTUI OptimizedBuffer notes.

### D2. Grapheme Cluster Storage
- **Decision**: Separate grapheme storage from primary cell arrays.
- **Recommendation**: Maintain a grapheme pool (arena of byte slices + metadata) with small integer IDs stored per cell; ID zero means “no grapheme span.”
- **Rationale**: Ghostty uses reference-counted grapheme storage; this avoids duplicating multi-codepoint sequences across cells and keeps diffing efficient.
- **References**: Ghostty `Terminal.zig` grapheme pooling, `.specs/ir/instructions.md` R5.4.

### D3. Source Encoding Tag
- **Decision**: Enumerate source encodings explicitly for each cell.
- **Recommendation**: Define `SourceEncoding` as `enum(u16)` whose discriminants reuse the IANA Character Set Registry (MIBenum) identifiers whenever they exist, rather than inventing bespoke numbering. Reserve `0` for `Unknown`, and document the exact mappings we depend on (e.g., `IBM437`, `IBM737`, `IBM775`, `IBM850`, `IBM852`, `IBM855`, `IBM857`, `IBM858`, `IBM860`, `IBM861`, `IBM862`, `IBM863`, `IBM864`, `IBM865`, `IBM866`, `IBM869`, `ISO_8859_1`, `ISO_8859_2`, `ISO_8859_7`, `ISO_8859_15`, `windows-1251`, `KOI8-R`, `UTF-8`) with citations to their registry entries so peers can audit each choice.
  - Encodings that lack an IANA registration but are required for textmode art fidelity (`PETSCII`, `ATASCII`, `ZX_Spectrum`, `Teletext`, `Viewdata`, `BBCMicro`, etc.) live in a clearly documented vendor-extension band (e.g., `65024-65535`) and must cite the archival source describing their byte→glyph mapping.
  - Leave remaining values unused until additional standards or archival findings justify inclusion, keeping the divergence from canonical registries explicit for future reviewers.
- **Rationale**: Our IR must handle mixed-encoding inputs (classic BBS + PETSCII) without guessing. Tagging per cell lets renderers branch on their own lookup tables.
- **References**: Recent discussion with user, `.specs/ir/instructions.md` R1.4/R2 updates.

### D4. Raw Source Bytes Representation
- **Decision**: Store raw source bytes per cell even when normalized Unicode exists.
- **Recommendation**: Use a contiguous byte arena with offsets/lengths per cell; small payloads (≤2 bytes) can be inlined in a fixed-size field to avoid allocations.
- **Rationale**: Many classic formats are byte-oriented; renderers like PNG need exact bytes for bitmap font lookups. Arena + inline optimization balances fidelity with memory usage.
- **References**: Instructions update on encoding, libansilove loaders’ byte semantics.

### D5. Normalized Unicode Field
- **Decision**: Keep a normalized Unicode scalar or grapheme ID per cell.
- **Recommendation**: Prefer a 32-bit scalar; use special sentinel for “refer to grapheme pool.” Provide helper API for renderers that only care about Unicode.
- **Rationale**: Ghostty renderers expect Unicode-ready data. Sentinel + pool keeps us compatible with multi-codepoint clusters.
- **References**: Ghostty `Screen.zig` cell struct, `.specs/ir/instructions.md` character representation section.

### D6. Palette Model
- **Decision**: Support shared palette objects with reference IDs.
- **Recommendation**: Keep a palette struct (16 or 256 entries) referenced from the IR root. Cells store palette indices when applicable; true-color cells store RGB.
- **Rationale**: Reduces duplication and keeps palette mutation centralized. Aligns with classic SAUCE metadata usage and XBin embedded palettes.
- **References**: libansilove palette handling, instructions R2.3/R2.5.

### D7. Attribute Bitflags
- **Decision**: Standardize on a 32-bit bitflag field per cell with reserved bits.
- **Recommendation**: Lower 16 bits mirror classic ANSI attributes; upper bits handle modern flags (faint, overline, hyperlink markers). Document bit layout now to avoid churn.
- **Rationale**: 16 bits is tight once we add modern features. 32 bits keeps storage predictable and leaves room for future toggles (e.g., underline styles encoded elsewhere).
- **References**: Ghostty attribute richness, instructions R3.x.

### D8. Ansimation Frame Representation
- **Decision**: Treat animation frames as first-class citizens in the IR root.
- **Recommendation**: Use a top-level `Animation` struct with:
  - Vector of frame records (`grid_reference`, `duration_ms`, optional `delay_ms`, `loop_break` flags).
  - Frame records point to either full grids or delta objects.
  - Global loop count (0 == infinite).
- **Rationale**: Ansimation is now mandatory. Splitting frames from the base grid keeps single-frame documents cheap while enabling animation-aware parsers.
- **References**: Instructions AC5 (ansimation), sixteencolors ansimation docs.

### D9. Frame Delta Strategy
- **Decision**: Support both full-frame and delta-frame storage.
- **Recommendation**: Provide two representations:
  - Full snapshot grid.
  - Delta list (cell coord + new state), referencing previous frame.
  Make delta optional but strongly encouraged in parsers to reduce RAM.
- **Rationale**: Many ansimations only change a handful of cells. Deltas keep IR lightweight but we can fall back to full frames if parsing complexity is prohibitive.
- **References**: Libansilove animation loaders, instructions FC1.

### D10. Timing Metadata
- **Decision**: Use millisecond precision for frame durations and delays.
- **Recommendation**: Store unsigned 32-bit durations in milliseconds; allow 0 for immediate transitions. Provide helper to convert to floating seconds for renderers that want it.
- **Rationale**: Historical formats (e.g., ANSIs) typically encode in 1/60th or 1/100th sec; millisecond precision is fine-grained and easy to map both directions.
- **References**: ANSI animation specs, Ghostty timer resolution.

### D11. SAUCE Comment Storage
- **Decision**: Preserve comment blocks as raw CP437 byte arrays plus parsed lines.
- **Recommendation**: Keep raw comment slices alongside a lazily-parsed vector of strings with explicit encoding tags. Do not normalize whitespace.
- **Rationale**: Some tools embed non-ASCII data or rely on spacing. Dual storage keeps fidelity without sacrificing ergonomics.
- **References**: libansilove SAUCE handling, instructions section on metadata.

### D12. Serialization Format
- **Decision**: Define a custom Zig-struct-based binary format with versioning.
- **Recommendation**: Use a versioned header (`ANSILUSTIR\0`, version u16), followed by little-endian sections (metadata, palette, animation, cell arrays). Provide serde helpers.
- **Rationale**: JSON is too bulky and can’t handle raw byte arenas efficiently. A stable binary layout keeps deserialization fast and future-proof via version bumping.
- **References**: Instructions R6.2, desire for efficient round-trips.

### D13. Allocator Ownership
- **Decision**: The IR owns all allocations and exposes explicit release APIs.
- **Recommendation**: Require `std.mem.Allocator` during construction; IR tracks all buffers internally and provides `deinit` to free them. No external ownership of slices.
- **Rationale**: Prevents leaks and avoids shared ownership pitfalls. Matches Zig patterns and Ghostty’s allocator usage.
- **References**: Instructions R6.1, Zig best practices in `.specs/AGENTS.md`.

### D14. API Surface Scope
- **Decision**: Keep the initial public API minimal but deterministic.
- **Recommendation**: Expose:
  - `getCell`, `setCell`, `resize`
  - `iterateDiff` helper for ansimation-aware renderers
  - `toGhosttyStream` (prototype helper)
  Delay batch mutation APIs until Phase 3.
- **Rationale**: Keeps focus on core behaviors while ensuring we can drive Ghostty-style renderers immediately.
- **References**: Instructions API draft, Ghostty integration priority.

### D15. Ghostty Semantics Priority
- **Decision**: Align behaviors (wrap flags, color None, hyperlink metadata) with Ghostty before any other consumer.
- **Recommendation**: Mark Ghostty compatibility as a non-negotiable acceptance criterion; treat OpenTUI conversion as optional utility.
- **Rationale**: Ghostty is an actual terminal; OpenTUI is a convenience. Our IR must be terminal-grade first.
- **References**: User directive, instructions integration section.

### D16. Performance Baseline
- **Decision**: Use a mid-tier laptop CPU (e.g., Ryzen 7 / M1) as reference.
- **Recommendation**: Quantify performance tests against ≤1 ms parse for 1 KB ANSI and ≤5 ms for 10-frame ansimation. Document hardware in README for reproducibility.
- **Rationale**: Keeps expectations realistic and gives QA a concrete target.
- **References**: Instructions AC11, Zig testing guidelines.

### D17. Error Model
- **Decision**: Prefer explicit Zig errors over optional returns.
- **Recommendation**: Define a dedicated error set (`error{OutOfMemory, InvalidCoordinate, InvalidEncoding, UnsupportedAnimation, SerializationFailed}`) and use it consistently.
- **Rationale**: Aligns with instructions R7.x and Zig idioms; avoids generic `anyerror`.
- **References**: `.specs/AGENTS.md` Zig best practices, instructions error handling.

### D18. Testing Strategy Scope
- **Decision**: Implement unit/property/performance tests in Phase 5 but specify them now.
- **Recommendation**: Keep the expanded test matrix (encoding tags, ansimation, fuzzing) in the requirements so we budget engineering time for it.
- **Rationale**: Tests drive the design; missing them now means scramble later.
- **References**: Testing section of instructions, user emphasis on fidelity.

---

_Edit this file to accept/reject recommendations or add new decisions. Once stabilized, I’ll translate the agreed points into `requirements.md`._