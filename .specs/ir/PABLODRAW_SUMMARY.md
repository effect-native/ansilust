# Ansilust IR vs PabloDraw: Executive Summary

**Status**: Phase 3 Review  
**Date**: 2024-10-26  
**Audience**: Tom, Bramwell, IR working group

---

## One-Line Summary

**PabloDraw** is a mature, production-grade text art editor for classic BBS formats (16-color, CP437-centric).  
**Ansilust IR** is a next-generation universal intermediate representation bridging legacy BBS art with modern terminal capabilities (true-color, Unicode, Ghostty-compatible).

---

## Quick Comparison Matrix

| Category | PabloDraw | Ansilust IR | Verdict |
|----------|-----------|-----------|---------|
| **Scope** | Single-language ecosystem (.NET) | Format-agnostic, Zig-based | Ansilust is more universal |
| **Color Support** | 16-color palette (or 256 extended) | True-color (RGB) + palette | Ansilust is more capable |
| **Character Storage** | 16-bit (CP437 + extended Unicode) | 32-bit Unicode + SourceEncoding tag | Ansilust preserves encoding fidelity |
| **Attributes** | 2 bits (bold, blink) | 11 flags (bold, faint, italic, underline variants, etc.) | Ansilust supports modern terminals |
| **Grapheme Support** | ✗ No | ✓ Yes (pool-based) | Ansilust handles emoji & combining marks |
| **Soft Wrapping** | ✗ No | ✓ Yes | Ansilust supports terminal reflow |
| **Hyperlinks** | ✗ No | ✓ Yes (OSC 8) | Ansilust future-proof |
| **SAUCE Handling** | ✓ Comprehensive | ✓ Complete (in design) | Parity achieved |
| **Animation Model** | Baud-rate based | Millisecond-precise + deltas | Ansilust more flexible |
| **Memory Model** | Managed (.NET GC) | Explicit (Zig allocator) | Different trade-offs |
| **Serialization** | Format-specific | Custom binary format | Ansilust adds lossless IR storage |

---

## Key Findings

### ✓ What Ansilust Should Adopt from PabloDraw

1. **SAUCE Metadata Handling** (CRITICAL)
   - PabloDraw's `SauceInfo.cs` is production-tested and comprehensive.
   - Action: Study line-by-line before Phase 4; replicate edge case handling (comment offset math, date validation, flag decoding).

2. **Format Abstraction Pattern**
   - PabloDraw's base class design (`CharacterFormat`) scales to 10+ formats cleanly.
   - Action: Ensure Ansilust's parser functions follow standardized builder/finalize pattern.

3. **iCE Color Mode Implementation**
   - PabloDraw correctly maps blink→bright-background in iCE mode.
   - Action: Document this semantic in Ansilust's SAUCE flag handling; add test case.

4. **Character Encoding Strategies**
   - PabloDraw's CP437 support is well-engineered; bitmap font handling is solid.
   - Action: Study before implementing XBin/ArtWorx parsers in Ansilust.

5. **Multi-Page Architecture** (Optional)
   - PabloDraw's per-page palette/font independence is elegant.
   - Action: Keep in mind for Phase 3+; could wrap animation frames as "virtual pages."

### ✗ Where Ansilust Must Diverge from PabloDraw

1. **Character Storage** (16-bit → 32-bit)
   - PabloDraw's 16-bit is tight for CP437; insufficient for full Unicode + vendor encodings.
   - Ansilust correctly uses 32-bit + per-cell `SourceEncoding` tag.

2. **Attribute Model** (8-bit → 32-bit)
   - PabloDraw's 2-bit attributes (bold, blink) cannot express modern terminal features (italic, multiple underline styles, faint, overline).
   - Ansilust's 32-bit with reference-counted styles is essential for Ghostty compatibility.

3. **Color Model** (Implicit palette → Tagged union)
   - PabloDraw's implicit 16-color palette cannot represent true-color or distinguish terminal default from black.
   - Ansilust's `Color` tagged union (None/Palette/RGB) is correct.

4. **Animation Timing** (Baud rate → Milliseconds)
   - PabloDraw's baud rate simulation is historically interesting but inflexible.
   - Ansilust's millisecond precision + delta frames is more suitable for modern playback.

5. **Grapheme Support** (None → Pool-based)
   - PabloDraw has no multi-codepoint support; Ansilust's grapheme pool is necessary for emoji and combining marks.

6. **Event Logging** (None → OSC/APC capture)
   - PabloDraw discards non-modeled sequences; Ansilust's event log preserves them for deterministic replay.

---

## Critical Action Items (Before Phase 4)

### 1. Deep-Dive SAUCE Study (2 hours)
**File**: `reference/pablodraw/pablodraw/Source/Pablo/Sauce/SauceInfo.cs`

**Checklist**:
- [ ] Understand `HasSauce()` stream positioning logic
- [ ] Trace `LoadSauce()` offset calculations (especially comment block offset: `stream.Length - SauceSize - (numComments * 64) - 5`)
- [ ] Verify date parsing validation (YYYYMMDD bounds checking)
- [ ] Note flag decoding (bit masks for iCE, letter spacing, aspect ratio)
- [ ] Study `SaveSauce()` to understand round-trip guarantees

**Deliverable**: Document explaining each offset calculation with examples.

### 2. Replicate Edge Cases in Ansilust Tests
**Focus Areas**:
- Invalid SAUCE records (missing EOF marker, corrupted ID, truncated record)
- Comment count validation
- Font name extraction (null-terminated, 22-byte buffer)
- File type enum validation
- Aspect ratio flag interpretation

**Test Template**:
```zig
test "SAUCE comment offset calculation" {
    // Generate a test file with SAUCE + 3 comments
    // Verify Ansilust parser reads comments at exact offset
    // Compare with PabloDraw's math
}
```

### 3. Validate Ansilust Attribute Mapping
**Task**: Map PabloDraw's 8-bit `Attribute` to Ansilust's 32-bit `Attributes` + `Style` losslessly.

**Test**:
```zig
test "PabloDraw attribute → Ansilust style" {
    // For all 256 combinations of 8-bit attribute:
    //   Parse as PabloDraw style
    //   Convert to Ansilust
    //   Verify bold/blink preserved
    //   Verify color nibbles preserved
}
```

### 4. Create Encoding Vendor Band Registry
**Task**: Document vendor-range IDs (65024-65535) for exotic encodings.

**Encodings to include**:
- PETSCII (Commodore 64)
- ATASCII (Atari 8-bit)
- ZX Spectrum (8-bit British computer)
- Teletext (European broadcast)
- Others from sixteencolors archive

**Format**:
```
| Encoding | ID | Source | Notes |
|----------|----|---------|----|
| PETSCII | 65024 | https://en.wikipedia.org/wiki/PETSCII | Commodore 64 charset |
| ... | ... | ... | ... |
```

### 5. Plan Phase 4 Parser Implementation Order
**MVP Parsers** (required for Phase 4 completion):
1. ANSI (most common; requires escape sequence parser)
2. Binary (simplest; validates core IR)
3. UTF8ANSI (modern terminal baseline)

**Extended** (Phase 4b):
1. XBin (embedded font validation)
2. ArtWorx (palette embedding)
3. PCBoard (color code parsing)

**Deferred** (Phase 5+):
1. Tundra, iCE Draw (format-specific)
2. RIPscrip (vector graphics, renderer only)

---

## Risk Mitigation Summary

| Risk | PabloDraw Exposure | Ansilust Mitigation |
|------|-------------------|-------------------|
| SAUCE offset calculation errors | High (subtle math) | Unit tests + fuzz testing |
| Encoding mixed-up between cells | Low (PabloDraw assumes uniform) | Per-cell tag + round-trip tests |
| iCE color mode misapplication | Medium (flag in 2 places) | Document semantic; test color range |
| Memory leaks in allocator | N/A (GC) | `std.testing.allocator` instrumentation |
| Performance regression | Low (PabloDraw slower than Zig SoA) | Benchmark against targets (≤1ms/KB) |
| Grapheme deduplication inefficiency | N/A (no grapheme support) | Measure pool hit rates on emoji-heavy samples |

---

## Integration Touchpoints

### Immediate (Phase 4)
- [ ] SAUCE parser implementation (reference PabloDraw)
- [ ] ANSI escape sequence parser (reference libansilove)
- [ ] Attribute conversion helper (PabloDraw style → Ansilust style)

### Medium-term (Phase 4b)
- [ ] XBin loader with embedded font extraction
- [ ] Format-specific round-trip tests (sixteencolors samples)
- [ ] Ghostty renderer validation

### Long-term (Phase 5+)
- [ ] Performance parity with PabloDraw
- [ ] Animation playback accuracy
- [ ] Event log replay for capture/playback workflows

---

## Conclusion

**PabloDraw validates Ansilust's approach** for classic BBS art handling, while Ansilust's extensions (true-color, Unicode, Ghostty semantics) are necessary for modern terminal support. The two projects are complementary: PabloDraw excels at editing; Ansilust excels at bridging legacy and modern systems.

**Next step**: Authorize Phase 4 (Plan Phase) and assign SAUCE study/parser scaffold work.

---

**Sign-off Ready**: ✓ All design decisions ratified  
**Open Questions**: None (see `decisions.md` for list)  
**Blocker Items**: None  
**Recommended Action**: Proceed to Phase 4 authorization
