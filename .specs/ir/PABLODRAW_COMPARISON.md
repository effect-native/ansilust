# Ansilust IR vs PabloDraw Implementation Review

## Executive Summary

This document compares Ansilust's Intermediate Representation design (currently Phase 2-3: requirements and architecture) against PabloDraw's actual C# implementation. The goal is to identify design strengths, architectural patterns worth adopting, and potential pitfalls to avoid.

**Key Finding**: PabloDraw's implementation is pragmatic and battle-tested, but designed for a single-language ecosystem (.NET + Eto) with managed memory. Ansilust's IR must remain format/language/runtime agnostic while supporting Zig's explicit allocator model. The two approaches are complementary: PabloDraw's SAUCE handling, format abstraction, and character encoding strategies offer valuable lessons for Ansilust's parser implementations, while Ansilust's structure-of-arrays design and event logging will provide better performance and debuggability.

---

## 1. Core Data Structure Comparison

### 1.1 Character Representation

| Aspect | PabloDraw | Ansilust IR | Notes |
|--------|-----------|-----------|-------|
| **Storage Size** | 16-bit `short` | 32-bit `u32` | Ansilust supports 21-bit Unicode codepoints; PabloDraw leverages implicit casting |
| **Type** | Signed integer with implicit conversions | Explicit Unicode scalar or grapheme ID | Ansilust separates concerns: scalar vs. grapheme pool reference |
| **Range** | 0-65535 (CP437 + extended Unicode) | 0-1,114,111 (full Unicode) OR grapheme sentinel | Ansilust handles multi-codepoint sequences natively |
| **Encoding Tag** | Implicit in source format | Explicit per-cell `SourceEncoding` enum | Ansilust enables mixed-encoding grids (PETSCII + ANSI) |

**Assessment**:
- **PabloDraw Strengths**: Simple, compact representation; implicit conversions reduce boilerplate.
- **Ansilust Strengths**: Explicit encoding enables correct multi-format parsing; 32-bit allows full Unicode range.
- **Recommendation**: Ansilust's approach is necessary for a universal IR. However, adopt PabloDraw's pattern of supporting both scalar and extended lookups for renderer convenience.

---

### 1.2 Attribute/Style Representation

| Aspect | PabloDraw | Ansilust IR | Notes |
|--------|-----------|-----------|-------|
| **Storage** | 8-bit packed `Attribute` (2 nibbles) | 32-bit `Attributes` (16 packed flags) | Ansilust reserves upper 16 bits for modern attributes |
| **Foreground** | 4 bits color (0-7) + 1 bit bold (bit 3) | 1 bit bold + 1 bit faint | Ansilust separates bold/faint with room for future |
| **Background** | 4 bits color (0-7) + 1 bit blink (bit 3) | 1 bit blink + 3 bits underline style | Ansilust models underline separately |
| **Layout** | `foreground` and `background` bytes | Packed 16-bit lower section | PabloDraw uses byte-per-component; Ansilust uses bitflags |
| **Style Table** | Implicit (attributes stored per cell) | Reference-counted via `style_id` | Ansilust deduplicates; PabloDraw does not |

**Assessment**:
- **PabloDraw Strengths**: Minimal footprint (8 bits); exact CP437/ANSI parity.
- **Ansilust Strengths**: Modern terminal features (multiple underline styles, faint, overline); style deduplication reduces memory.
- **Recommendation**: Ansilust's reference-counted style table is inspired by Ghostty and scales well. However, ensure backward compatibility by mapping 8-bit attributes to Ansilust styles during ANSI parsing. PabloDraw's iCE color mode (blink → bright background) is a critical edge case; document it explicitly in Ansilust's SAUCE flag handling.

---

### 1.3 Color Model

| Aspect | PabloDraw | Ansilust IR | Notes |
|--------|-----------|-----------|-------|
| **Palette Model** | 16-entry standard (VGA/ANSI) or custom | Shared palette table + index OR RGB | Ansilust uses tagged union |
| **Storage Per Cell** | 2 nibbles (foreground/background color indices) | Tagged union: `Color{ .palette: u8 }` or `Color{ .rgb: RGB }` | Ansilust supports true color |
| **Color None** | Not supported; black is `Palette(0)` | Explicit `Color.none` | Ansilust distinguishes terminal default from black |
| **Palette Access** | Implicit (standard 16-color only) | Explicit table lookup | Ansilust enables custom palettes |
| **Mixing Palettes** | Not directly supported | Palette indices + RGB in same document | Ansilust allows hybrid documents |

**Assessment**:
- **PabloDraw Strengths**: Efficient; matches classic BBS art constraints perfectly.
- **Ansilust Strengths**: Modern terminals, mixed-source documents, explicit distinction of "terminal default" vs. black.
- **Recommendation**: Ansilust's tagged union design is correct. However, provide a palette lookup helper for renderers that want to convert palette indices to RGB (PabloDraw's `Palette.GetDosPalette()`). Ensure parsers correctly set `Color.none` when encountering default color codes (not just black).

---

## 2. Grid Architecture Comparison

### 2.1 Layout Strategy

| Aspect | PabloDraw | Ansilust IR |
|--------|-----------|-----------|
| **Pattern** | Array-of-structs (cells stored as discrete objects) | Structure-of-arrays (parallel slices) |
| **Implementations** | `MemoryCanvas`, `StreamCanvas` | Single `CellGrid` (SoA optimized) |
| **Iteration** | Sequential cell access via indexer | Field-level iteration (color diff scanning) |
| **Cache Behavior** | Per-cell: tight grouping but cache line misses on field access | Per-field: SIMD-friendly; excellent for diffing |
| **Extensibility** | Abstract base class pattern | Concrete SoA with reserved bits |

**Assessment**:
- **PabloDraw Strengths**: Conceptually clean; easy to understand; flexible canvas implementations for streaming.
- **Ansilust Strengths**: SoA is optimal for modern CPUs and diff-based rendering (scan single field at a time).
- **Recommendation**: Ansilust's SoA is the correct choice for terminal rendering. However, consider adding a fallback "array-of-structs" view for parsers that generate cells in arbitrary order (to avoid thrashing the SoA slices). PabloDraw's canvas abstraction is valuable—Ansilust's `DocumentBuilder` pattern achieves similar flexibility during construction.

---

## 3. Encoding and Metadata Handling

### 3.1 Source Format Support

| Format | PabloDraw | Ansilust IR | Status |
|--------|-----------|-----------|--------|
| **ANSI** | ✓ Comprehensive | ✓ Planned | Both high-fidelity |
| **Binary** | ✓ Full support | ✓ Planned | PabloDraw treats as fixed-160-col |
| **PCBoard** | ✓ Full support | ✓ Planned | Both parse color codes |
| **ArtWorx (.adf)** | ✓ Full support | ✓ Planned | Both support embedded fonts |
| **XBin** | ✓ Full support | ✓ Planned | Both support embedded fonts + compression |
| **Tundra** | ✓ Full support | ✓ Planned | Both support Tundra color codes |
| **iCE Draw** | ✓ Full support | ✓ Planned | Both enforce iCE color mode |
| **RIPscrip** | ✓ Vector support | ✗ Out of scope | PabloDraw has full vector graphics |
| **UTF8ANSI** | ✗ Not supported | ✓ Planned | Ansilust's modern terminal target |
| **Ansimation** | ✓ Baud-rate based | ✓ Delta-based | Different animation models |

**Assessment**:
- **PabloDraw Strengths**: Complete format coverage for classic BBS art; RIPscrip support.
- **Ansilust Strengths**: Planned UTF8ANSI support for modern terminals; cleaner animation delta model.
- **Recommendation**: Ansilust should study PabloDraw's format-specific parsers (especially XBin and SAUCE handling) before implementing its own. The format abstraction pattern (base class with `Load/Save/FillSauce`) is elegant; Ansilust's function-based approach is equally valid but must ensure consistency across parsers.

---

### 3.2 SAUCE Metadata Preservation

| Aspect | PabloDraw | Ansilust IR | Notes |
|--------|-----------|-----------|-------|
| **Storage** | Complete 128-byte record + parsed fields | Complete record + parsed fields | Both preserve fidelity |
| **Comments** | `SauceComment` struct with `Comments: List<string>` | `comments: [][]const u8` (raw slices) | Ansilust defers UTF-8 parsing |
| **Flags** | `SauceBitFlag`, `SauceTwoBitFlag` (strongly typed) | `SauceFlags` bitfield | PabloDraw more ergonomic |
| **Font Name** | `TInfoS` (up to 22 bytes) | `font_name` stored in separate `FontInfo` | Both preserve it |
| **Columns/Rows** | `TInfo1`/`TInfo2` mapped to width/height | `columns`/`rows` in SAUCE | Both required for rendering |
| **Aspect Ratio** | `TInfo4` with flag interpretation | `aspect_ratio: ?f32` (1.35 for DOS) | Ansilust is more explicit |
| **File Type** | Enum `CharacterFileType` with 10 types | `SourceFormat` enum (planned alignment) | Both categorize source |

**Assessment**:
- **PabloDraw Strengths**: Exhaustive SAUCE handling; strongly-typed flags reduce errors; intuitive API (`SauceBitFlag.BoolValue`).
- **Ansilust Strengths**: Explicit aspect ratio as f32; cleaner integration with IR metadata.
- **Recommendation**: **This is Ansilust's most critical learning opportunity.** PabloDraw's `SauceInfo.cs` should be studied line-by-line before finalizing Ansilust's SAUCE parsing. Specifically:
  1. Comment block detection and parsing (offset calculation: `stream.Length - SauceSize - (numComments * CommentSize) - 5`).
  2. Flag decoding (especially iCE colors and letter spacing).
  3. File type validation and conversion to rendering hints.
  4. Date string parsing with validation (not all YYYYMMDD values are valid).
  
  Ansilust's raw comment storage is fine, but add a lazily-parsed UTF-8 view for convenience.

---

## 4. Animation Model Comparison

| Aspect | PabloDraw | Ansilust IR | Notes |
|--------|-----------|-----------|-------|
| **Frame Storage** | `AnimatedDocument.Commands` (RIP) or sequences | `Animation { frames: [] }` + delta support | Different animation types |
| **Timing** | Baud rate simulation (modem speed playback) | Millisecond precision (`u32 ms`) | Ansilust more precise |
| **Delta Encoding** | Implicit in RIP command stream | Explicit `Frame.Delta([]DeltaCell)` | Ansilust provides choice |
| **Compression** | RIP command compression (vendor-specific) | Optional delta frames | Ansilust lighter-weight |
| **Loop Support** | Document-level `AnimateView` flag | Global loop count (0 = infinite) | Both support looping |
| **Frame Association** | Commands applied sequentially | Frame index with optional event log | Ansilust supports non-frame events |

**Assessment**:
- **PabloDraw Strengths**: Baud rate simulation is historically accurate; RIP command model is complete.
- **Ansilust Strengths**: Delta frames reduce memory; millisecond precision is standard; event log captures non-modeled sequences.
- **Recommendation**: Ansilust's animation model is superior for text art. However, PabloDraw's baud rate simulation could be valuable for authentic playback—consider adding a `playback_speed: BaudRate?` hint to Ansilust's SAUCE flags. Ensure delta validation: every delta cell must reference a valid coordinate and not exceed grid bounds (catch this in builder).

---

## 5. API and Architecture Patterns

### 5.1 Document Model

**PabloDraw**:
```csharp
public class CharacterDocument : Document
{
    public List<Page> Pages { get; }  // Multi-page support
    public Palette Palette { get; set; }
    public BitFontSet FontSet { get; set; }
    public bool ICEColours { get; set; }
    public SauceInfo Sauce { get; set; }
}
```

**Ansilust IR**:
```zig
pub const Document = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    cells: []Cell,
    style_table: std.ArrayList(Style),
    grapheme_map: std.AutoHashMap(u32, []u32),
    palette: PaletteType,
    sauce: ?SauceRecord,
    source_format: SourceFormat,
    // ...
};
```

**Assessment**:
- **PabloDraw Strengths**: Multi-page documents; fluent API via getter/setter; separate font management.
- **Ansilust Strengths**: Single-frame focus (no multi-page overhead); explicit allocator ownership; grapheme pool integrated.
- **Recommendation**: Ansilust's single-frame approach is correct for initial IR. Multi-page can be added later as a wrapper. PabloDraw's `Page` abstraction with independent palettes/fonts per page is elegant; if Ansilust later supports multi-page, adopt this pattern.

---

### 5.2 Format Abstraction

**PabloDraw** (Base Class Pattern):
```csharp
public abstract class CharacterFormat : AnimatedFormat
{
    public abstract void Load(Stream fs, CharacterDocument doc, CharacterHandler handler);
    public virtual void Save(Stream stream, CharacterDocument document);
    public virtual void FillSauce(SauceInfo sauce, CharacterDocument document);
}
```

**Ansilust IR** (Planned Function-Based):
```zig
// src/parsers/ansi.zig
pub fn parse(allocator: std.mem.Allocator, stream: anytype) !Document {
    // ...
}
```

**Assessment**:
- **PabloDraw Strengths**: Polymorphism enables format discovery; `FillSauce` ensures metadata consistency; handler pattern manages lifecycle.
- **Ansilust Approach**: Function-based is simpler for a Zig IR module; no inheritance needed.
- **Recommendation**: Ansilust's function-based approach is appropriate. However, ensure each parser function:
  1. Accepts a `DocumentBuilder` facade (not direct `Document` mutation) to enforce invariants.
  2. Calls `builder.finalize()` before returning to migrate arenas.
  3. Populates SAUCE fields via a standardized helper (inspired by PabloDraw's `FillSauce`).

---

### 5.3 Error Handling

**PabloDraw** (Exceptions + Try/Catch):
```csharp
try {
    var sauce = new SauceInfo(stream);
    // ...
} catch (Exception ex) {
    std.log.err("SAUCE parsing failed: {}", ex.Message);
}
```

**Ansilust IR** (Error Unions):
```zig
pub fn parse(allocator: std.mem.Allocator, stream: anytype) !Document {
    // error{OutOfMemory, InvalidEncoding, SerializationFailed}
}
```

**Assessment**:
- **PabloDraw Strengths**: Exceptions provide rich context; debugging support.
- **Ansilust Strengths**: Explicit error sets; no hidden control flow; Zig idioms.
- **Recommendation**: Ansilust's approach is correct. However, emulate PabloDraw's contextual logging by including the error context in error messages (e.g., `error.SerializationFailed` with attached string explaining why).

---

## 6. Memory Management

### 6.1 Allocator Discipline

**PabloDraw** (Managed Memory):
- Uses .NET's garbage collector.
- Manual `Dispose()` patterns for unmanaged resources.
- Arenas handled implicitly.

**Ansilust IR** (Explicit):
- Requires `std.mem.Allocator` argument.
- All allocations tracked and freed in `deinit()`.
- Arena optimization: parser uses `ArenaAllocator`, finalize migrates to slab.

**Assessment**:
- **PabloDraw Strengths**: GC simplifies reasoning; no leak risk.
- **Ansilust Strengths**: Predictable memory usage; embedded-friendly; no stop-the-world pauses.
- **Recommendation**: Ansilust's approach is essential for a universal IR. Ensure the `DocumentBuilder` pattern clearly documents that builders own temporary allocations, which are released during `finalize()`. Add tests using `std.testing.allocator` leak detection.

---

### 6.2 Data Structure Efficiency

**PabloDraw**:
- Packed struct for `Attribute` (8 bits, `LayoutKind.Sequential`).
- Character stored as `short` (16 bits).
- Separate allocations for canvas, palette, font set.

**Ansilust IR**:
- Packed struct for `Cell` (72 bits: 32-bit char + 16-bit style_id + 24-bit flags).
- SoA with contiguous slices.
- Unified `Document` allocator with sub-arenas.

**Assessment**:
- **PabloDraw Strengths**: Minimal per-cell overhead (~10 bytes in MemoryCanvas).
- **Ansilust Strengths**: Better cache locality for scanning; easier to parallelize.
- **Recommendation**: Ansilust's SoA is optimal. However, measure memory usage empirically; if it exceeds 1.5× of PabloDraw for equivalent content, optimize slice allocation (combine related slices into structs).

---

## 7. Specific Technical Insights

### 7.1 CP437 and Code Page Handling

**PabloDraw** Approach:
- Character stored as 16-bit, supporting full CP437 range (0-255).
- Bitmap fonts store glyph data directly; code page encoded in `BitFontSet`.
- Fallback mechanism if font is missing.

**Ansilust IR** Approach:
- Character stored as 32-bit Unicode; `SourceEncoding` tag indicates CP437, PETSCII, etc.
- Grapheme pool for multi-codepoint sequences.
- Normalization to Unicode on load; fallback to raw bytes if needed.

**Recommendation**: 
- Ansilust's approach is more future-proof (supports any encoding).
- However, ensure CP437 → Unicode mapping is correct and reversible (for ANSI/Binary output).
- PabloDraw's bitmap font handling is production-tested; study `BitFont.cs` and `BitFontSet.cs` before implementing XBin parsing.

### 7.2 iCE Color Mode

**PabloDraw** Handling:
- SAUCE flag `ByteFlags & 0x01` enables iCE mode.
- In iCE mode, blink bit becomes bright background (16 colors total, not 8 + blink).
- `Attribute.Blink` property handles the dual interpretation.

**Ansilust IR** Plan:
- SAUCE flag `ice_colors: bool` in `SauceFlags` bitfield.
- Document-level `ice_colors: bool` applied at render time.
- Attributes store blink as normal; renderer interprets based on document flag.

**Recommendation**:
- Ansilust's separation of document-level flag from per-cell blink is correct.
- However, ensure parsers correctly identify iCE mode from SAUCE and propagate it to `Document.ice_colors`.
- Add test case: 16 background colors in iCE mode should render without data loss.

### 7.3 Letter Spacing (9-bit characters)

**PabloDraw** Handling:
- SAUCE flag `ByteFlags & 0x02` indicates 9-bit character width.
- Stored in `Document.ICEColours` and applied during rendering.

**Ansilust IR** Plan:
- SAUCE flag `letter_spacing_9bit: bool` in `SauceFlags`.
- Document-level `letter_spacing: u8` (8 or 9).
- Hint used by renderers for pixel width calculations.

**Recommendation**:
- Ensure the flag is parsed correctly from SAUCE and validated (only 8 or 9 are valid).
- Document rendering impact: 9-bit affects PNG/canvas width calculations.

---

## 8. Weaknesses and Gaps

### 8.1 PabloDraw Limitations (Ansilust Should Avoid)

1. **No Unicode Beyond 16-bit**: CP437-centric design makes extending to full Unicode awkward.
   - **Ansilust Fix**: 32-bit character + SourceEncoding tag enables seamless multi-format support.

2. **No Color None**: Terminal default not distinguished from black.
   - **Ansilust Fix**: Explicit `Color.none` variant in tagged union.

3. **No Hyperlink Metadata**: OSC 8 support missing.
   - **Ansilust Fix**: Document-level hyperlink table + per-cell `hyperlink_id`.

4. **No Event Log**: Non-modeled sequences lost.
   - **Ansilust Fix**: Event log captures OSC, APC, PM sequences for deterministic replay.

5. **Single Canvas Implementation**: Streaming/lazy-load not supported.
   - **Ansilust Fix**: Builder pattern during parsing; slab-backed after finalization.

6. **Network Serialization Only**: No stable file format for long-term storage.
   - **Ansilust Fix**: Custom binary format with versioning + serialization tests.

### 8.2 Ansilust Risks (Based on PabloDraw's Experience)

1. **Over-Generalization**: Supporting too many encodings without shipping parsers.
   - **Mitigation**: Ship ANSI, Binary, XBin in Phase 1; others deferred per `.specs/ir/prior-art-notes.md`.

2. **Allocator Complexity**: Zig's explicit allocator is powerful but error-prone.
   - **Mitigation**: Comprehensive unit tests with `std.testing.allocator` leak detection.

3. **SAUCE Parsing**: Subtle bugs in offset/length calculations.
   - **Mitigation**: Study PabloDraw's `SauceInfo.LoadSauce()` line-by-line; add property-based fuzz tests.

4. **Animation Timing**: Millisecond precision may not match historical BBS playback.
   - **Mitigation**: Document precision constraints; provide baud rate hint if needed.

---

## 9. Integration Recommendations

### 9.1 Parser Implementation Order

**Phase 1 (MVP)**:
1. ANSI (requires escape sequence parser + SAUCE handling)
2. Binary (simplest: raw char/attr pairs, fixed 160 cols)
3. UTF8ANSI (modern terminal baseline)

**Phase 2 (Extended)**:
1. XBin (embedded font support)
2. ArtWorx (palette embedding)
3. PCBoard (color code parsing)

**Phase 3+ (Optional)**:
1. Tundra (Tundra-specific codes)
2. iCE Draw (iCE mode enforcement)
3. RIPscrip (vector graphics, out of scope for IR but renderable)

**Rationale**: Prioritize formats that cover 80% of sixteencolors archive. PabloDraw's format support is comprehensive; Ansilust can defer less common formats without sacrificing value.

### 9.2 Renderer Implementation Order

**Phase 1 (MVP)**:
1. Ghostty Stream (UTF8ANSI output for modern terminals)
2. HTML Canvas (browser-based viewer)

**Phase 2 (Extended)**:
1. OpenTUI Bridge (optimization target for embedded TUIs)
2. PNG/bitmap (static image export, inspired by ansilove)

**Phase 3+ (Optional)**:
1. Sixel (terminal graphics)
2. Kitty graphics protocol (modern terminal images)

---

## 10. Specific Code Patterns to Adopt

### 10.1 SAUCE Comment Parsing (From PabloDraw)

```zig
// Inspired by SauceInfo.LoadSauce()
const comment_pos = sauce_start - (num_comments * COMMENT_SIZE) - "COMNT".len;
if (comment_pos >= 0) {
    stream.seekTo(comment_pos);
    // Validate "COMNT" marker before reading
    var marker: [5]u8 = undefined;
    _ = try stream.readNoEof(&marker);
    if (!std.mem.eql(u8, &marker, "COMNT")) {
        return error.InvalidSauceComments;
    }
    // Read comments...
}
```

### 10.2 Attribute Mapping (From PabloDraw)

```zig
// Convert PabloDraw's 8-bit Attribute to Ansilust Style
fn attributeToStyle(attr: u8) Style {
    const fg = attr & 0x0F;
    const bg = (attr >> 4) & 0x0F;
    const bold = (fg & 0x08) != 0;
    const blink = (bg & 0x08) != 0;
    
    return Style{
        .fg = Color{ .palette = fg & 0x07 },
        .bg = Color{ .palette = bg & 0x07 },
        .attributes = Attributes{
            .bold = bold,
            .blink = blink,
        },
        .underline_color = null,
        .hyperlink = null,
    };
}
```

### 10.3 SAUCE Flag Interpretation (From PabloDraw)

```zig
// Parse SAUCE flags like SauceBitFlag
fn parseSauceFlags(byte_flags: u8) !SauceFlags {
    return SauceFlags{
        .ice_colors = (byte_flags & 0x01) != 0,
        .letter_spacing_9bit = (byte_flags & 0x02) != 0,
        // Bits 2-3: aspect ratio (0=1.0, 1=0.833, 2=1.35, 3=reserved)
        .aspect_ratio_index = (byte_flags >> 2) & 0x03,
    };
}

// Aspect ratio lookup
fn aspectRatioFromFlags(index: u2) ?f32 {
    return switch (index) {
        0 => 1.0,
        1 => 0.833,
        2 => 1.35,
        3 => null, // Reserved
    };
}
```

---

## 11. Testing Strategy Informed by PabloDraw

### 11.1 Format Round-Trip Tests

**PabloDraw Approach**: Loaders tested against sample files from sixteencolors archive.

**Ansilust Plan**:
- Collect ANSI, Binary, XBin samples from sixteencolors.
- For each format: parse → IR → re-render → compare output to original.
- Validate pixel-perfect for ANSI/Binary; allow minor diffs for UTF8ANSI.

### 11.2 SAUCE Edge Cases

**PabloDraw Lessons**:
- Invalid YYYYMMDD dates (e.g., 20001301 for December 31st).
- Comment offset calculations are error-prone.
- File type validation catches malformed records.

**Ansilust Tests**:
```zig
test "SAUCE date validation" {
    // Valid: 20240131
    try expectValid(parseSauceDate("20240131"));
    
    // Invalid: 20241301 (month out of range)
    try expectError(parseSauceDate("20241301"));
}

test "SAUCE comment offset" {
    // Comment block must precede SAUCE record exactly
    try expectValidComments(stream, COMMENT_SIZE * num_comments);
}
```

### 11.3 Encoding Preservation

**Ansilust Plan**:
- Verify CP437 byte round-trip (raw → Unicode → render).
- Test mixed-encoding grids (ANSI cells + PETSCII cells).
- Validate grapheme pool for multi-codepoint sequences.

---

## 12. Conclusion and Next Steps

### Summary of Key Takeaways

| Aspect | PabloDraw Insight | Ansilust Action |
|--------|-------------------|-----------------|
| **SAUCE Handling** | Comprehensive with edge cases | Study `SauceInfo.cs` line-by-line before Phase 4 |
| **Format Abstraction** | Elegant base class pattern | Adopt standardized parser builder pattern |
| **Character Encoding** | 16-bit CP437-centric works for classic BBS | 32-bit Unicode + SourceEncoding tag is necessary for universality |
| **Attributes** | 8-bit packed is minimal but inflexible | 32-bit with reference-counted styles scales to modern terminals |
| **Color Model** | Implicit palette, no true-color support | Tagged union (None/Palette/RGB) enables future-proofing |
| **Animation** | Baud rate simulation is historically authentic | Millisecond precision + delta frames is more efficient |
| **Allocator** | Managed (.NET GC) simplifies but hides costs | Explicit allocator (Zig) is essential for embedded/performance targets |
| **Testing** | Format round-trips with sixteencolors samples | Property-based + fuzz testing adds robustness |

### Recommended Immediate Actions (for Tom/Bramwell)

1. **Allocate 2 hours to study PabloDraw's SAUCE implementation**:
   - Focus on `reference/pablodraw/pablodraw/Source/Pablo/Sauce/SauceInfo.cs` (complete file).
   - Note edge cases: comment offset calculation, date validation, flag decoding.

2. **Create Ansilust SAUCE parser scaffold** before Phase 4:
   - Use PabloDraw as reference for offset math.
   - Add comprehensive unit tests.
   - Include fuzzing for malformed SAUCE records.

3. **Validate Ansilust IR against real-world samples**:
   - Extract 5 ANSI files from sixteencolors with varying widths/palettes/animations.
   - Implement minimal ANSI parser in Ansilust.
   - Round-trip through IR → Ghostty renderer; compare outputs.

4. **Document encoding vendor band** (Decision D3):
   - Add PETSCII, ATASCII, etc., to `prior-art-notes.md` with citations.
   - Assign vendor-range IDs (65024-65535) and document mapping.

5. **Plan Phase 5 testing** with PabloDraw lessons in mind:
   - SAUCE edge case suite (date validation, comment offsets).
   - Format coverage matrix (ANSI, Binary, XBin samples).
   - Performance benchmarks against PabloDraw for parity.

### Long-Term Collaboration Opportunity

Consider contributing SAUCE and ANSI parsing insights back to PabloDraw's community if Ansilust's approach reveals improvements. Cross-pollination benefits both projects.

---

## References

- **PabloDraw AGENTS.md**: `/ansilust/reference/pablodraw/AGENTS.md`
- **Ansilust IR Requirements**: `/.specs/ir/requirements.md`
- **Ansilust IR Decisions**: `/.specs/ir/decisions.md`
- **Ansilust IR Design**: `/.specs/ir/design.md`
- **Prior Art Notes**: `/.specs/ir/prior-art-notes.md`

---

**Document Owner**: Ansilust IR Working Group  
**Status**: Review Ready (Phase 3)  
**Last Updated**: 2024-10-26  
**Next Review**: Phase 4 (Plan Phase) Authorization