# PabloDraw Review Index

**Date**: 2024-10-26  
**Status**: Phase 3 Review Complete  
**Audience**: Ansilust IR working group

---

## Overview

This index organizes the comprehensive review of PabloDraw's implementation against Ansilust's IR design. Three main documents were created:

1. **PABLODRAW_AGENTS.md** - Reference guide to PabloDraw codebase
2. **PABLODRAW_COMPARISON.md** - Detailed technical comparison
3. **PABLODRAW_SUMMARY.md** - Executive summary for decision-makers

---

## Document Navigation

### For Decision-Makers (Read First)

**→ PABLODRAW_SUMMARY.md** (10 min read)
- Quick comparison matrix
- Key findings at a glance
- Critical action items (5 tasks with time estimates)
- Approval checklist
- Risk mitigation summary

**Best for**: Tom, Bramwell, stakeholders needing quick understanding

---

### For Architecture Review

**→ PABLODRAW_COMPARISON.md** (30 min read)
- 13 major component comparisons
- Code examples from both systems
- Architectural patterns analysis
- Integration recommendations
- Risk analysis and mitigation

**Sections**:
1. Core Data Structure Design
2. Encoding and Metadata Handling
3. Palette and Color Handling
4. Attributes and Styling
5. SAUCE Metadata Handling
6. Animation Support
7. Grapheme and Wide Character Support
8. Soft Wrapping and Terminal Reflow
9. Hyperlink Support
10. Event Logging
11. Memory Management
12. Serialization Format
13. API Surface

**Best for**: Technical leads, IR architects, parser implementers

---

### For PabloDraw Code Reference

**→ PABLODRAW_AGENTS.md** (40 min read)
- Complete PabloDraw architecture overview
- Module structure and responsibilities
- Core data structures with code examples
- All 7 supported text art formats
- RIPscrip vector graphics support
- SAUCE metadata system details
- Design patterns and key learnings

**Sections**:
- Architecture Overview
- Core Data Structures (Character, Attribute, Canvas, BitFont)
- Character Formats (ANSI, Binary, PCBoard, XBin, etc.)
- RIPscrip Format
- Animated Format
- SAUCE Metadata System
- Document Model
- Palette System
- Undo/Redo System
- Network/Collaborative Features
- Key Design Patterns
- Integration Points for Ansilust
- Development Guidelines

**Best for**: Parser implementers, format specialists, integration engineers

---

## Quick Reference by Topic

### SAUCE Metadata

**Learn**: PABLODRAW_AGENTS.md § "SAUCE Metadata System"  
**Deep Dive**: PABLODRAW_COMPARISON.md § "5. SAUCE Metadata Handling"  
**Study**: `reference/pablodraw/pablodraw/Source/Pablo/Sauce/SauceInfo.cs`

**Key Insights**:
- Complete 128-byte record with comments
- Offset calculation for comment blocks is critical
- Date validation (YYYYMMDD bounds checking)
- Flag decoding (iCE, letter spacing, aspect ratio)
- Parsed fields + raw bytes preservation

---

### Character Encoding

**Learn**: PABLODRAW_AGENTS.md § "Core Data Structures"  
**Deep Dive**: PABLODRAW_COMPARISON.md § "3. Encoding Handling"  
**Study**: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Character.cs`

**Key Insights**:
- 16-bit character supports CP437 + extended Unicode
- Implicit encoding (document-level, not cell-level)
- Ansilust improves with per-cell SourceEncoding tags
- Mixed-encoding support is Ansilust advantage

---

### Color and Palette Handling

**Learn**: PABLODRAW_AGENTS.md § "Palette System"  
**Deep Dive**: PABLODRAW_COMPARISON.md § "4. Palette and Color Handling"  
**Study**: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Attribute.cs`

**Key Insights**:
- 16-color standard + extended palette support
- No true-color in PabloDraw (limitation)
- Ansilust adds RGB union for true-color
- iCE mode converts blink to bright background

---

### Attributes and Styling

**Learn**: PABLODRAW_AGENTS.md § "Core Data Structures"  
**Deep Dive**: PABLODRAW_COMPARISON.md § "6. Attributes and Styling"  
**Study**: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Attribute.cs`

**Key Insights**:
- 8-bit packed: 4-bit color + 1-bit bold per nibble
- Only bold and blink supported
- Ansilust extends to 11 flags + underline color
- Reference-counted styles in Ansilust (deduplication)

---

### Animation Model

**Learn**: PABLODRAW_AGENTS.md § "Animated Format"  
**Deep Dive**: PABLODRAW_COMPARISON.md § "7. Animation Support"  
**Study**: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Animated/AnimatedFormat.cs`

**Key Insights**:
- Baud-rate simulation (modem speeds)
- Frame-based playback with timing
- Delta encoding for efficiency
- Ansilust uses millisecond precision instead

---

### Format-Specific Parsing

**Learn**: PABLODRAW_AGENTS.md § "Format Support"  
**Study**:
- ANSI: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Types/Ansi.cs`
- Binary: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Types/Bin.cs`
- XBin: `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/Types/Xbin.cs`

**Key Insights**:
- Each format has subtle requirements
- ANSI: escape sequence optimization, space compression
- Binary: fixed 160-column width
- XBin: embedded fonts, palette, compression

---

### Font Handling

**Learn**: PABLODRAW_AGENTS.md § "Bitmap Font System"  
**Study**:
- `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/BitFont.cs`
- `reference/pablodraw/pablodraw/Source/Pablo/Formats/Character/BitFontSet.cs`

**Key Insights**:
- Bitmap font structure (width, height, glyph data)
- Code page support (CP437, CP850, etc.)
- Fallback mechanism for missing fonts
- XBin and ArtWorx formats embed fonts

---

## Action Items Checklist

### Immediate (This Week)

- [ ] Read PABLODRAW_SUMMARY.md (10 min)
- [ ] Allocate 2 hours to study `SauceInfo.cs`
- [ ] Review "Critical SAUCE edge cases" section
- [ ] Create SAUCE parser scaffold
- [ ] Document SAUCE offset calculations

### Short-term (Phase 4 - Next 2 weeks)

- [ ] Read PABLODRAW_COMPARISON.md (30 min)
- [ ] Implement SAUCE parser with tests
- [ ] Implement ANSI parser (reference libansilove)
- [ ] Implement Binary parser
- [ ] Create round-trip tests with sixteencolors samples

### Medium-term (Phase 4b - Following 2 weeks)

- [ ] Study XBin parser (PabloDraw reference)
- [ ] Implement XBin parser with embedded fonts
- [ ] Implement ArtWorx parser
- [ ] Implement PCBoard parser
- [ ] Performance benchmarking

### Long-term (Phase 5+)

- [ ] Implement remaining parsers (Tundra, iCE Draw)
- [ ] Add fuzz testing
- [ ] Implement animation playback
- [ ] Event log replay

---

## Key Findings Summary

### What Ansilust Should Adopt from PabloDraw

1. **SAUCE Handling** (CRITICAL)
   - Study: `SauceInfo.cs` (complete file)
   - Action: Replicate edge case handling

2. **Format Abstraction Pattern**
   - Study: `CharacterFormat.cs` (base class)
   - Action: Ensure parser consistency

3. **iCE Color Mode**
   - Study: `Attribute.cs` (Blink property)
   - Action: Document semantic, test color range

4. **Character Encoding**
   - Study: `Character.cs`, `Attribute.cs`
   - Action: Implement mapping to Ansilust styles

5. **Font Handling**
   - Study: `BitFont.cs`, `BitFontSet.cs`
   - Action: Before implementing XBin/ArtWorx

---

### Where Ansilust Correctly Diverges

| Aspect | PabloDraw | Ansilust | Reason |
|--------|-----------|---------|--------|
| **Character** | 16-bit | 32-bit | Full Unicode support |
| **Encoding** | Implicit | Per-cell | Mixed-encoding documents |
| **Attributes** | 8-bit | 32-bit | Modern terminal features |
| **Colors** | Palette only | RGB union | True-color support |
| **Animation** | Baud rate | Milliseconds | More precise timing |
| **Graphemes** | None | Pool-based | Emoji + combining marks |

---

## Risk Mitigation Strategies

| Risk | PabloDraw Lesson | Ansilust Mitigation |
|------|------------------|-------------------|
| **SAUCE Parsing Bugs** | Study offset math | Unit tests + fuzzing |
| **Encoding Issues** | Test round-trips | Per-cell tags + validation |
| **Color Mode Errors** | Document iCE semantics | SAUCE flag tests |
| **Performance Loss** | Benchmark SoA vs AoS | Target ≤1ms/KB |
| **Grapheme Efficiency** | No precedent | Pool dedup + profiling |
| **Format Quirks** | Test with samples | sixteencolors suite |

---

## Related Documentation

- **IR Requirements**: `.specs/ir/requirements.md`
- **IR Design**: `.specs/ir/design.md`
- **IR Decisions**: `.specs/ir/decisions.md`
- **Prior Art Notes**: `.specs/ir/prior-art-notes.md`
- **Ghostty Reference**: `reference/ghostty/AGENTS.md`
- **libansilove Reference**: `reference/libansilove/AGENTS.md`

---

## Document Statistics

| Document | Lines | Read Time | Scope |
|----------|-------|-----------|-------|
| PABLODRAW_AGENTS.md | 625 | 40 min | Complete PabloDraw reference |
| PABLODRAW_COMPARISON.md | 582 | 30 min | Detailed technical analysis |
| PABLODRAW_SUMMARY.md | 207 | 10 min | Executive summary |
| **Total** | **1414** | **80 min** | Comprehensive review |

---

## Next Milestone

**Phase 4 Authorization** (Plan Phase)

**Prerequisites** (from PABLODRAW_SUMMARY.md):
- [ ] SAUCE study (2 hours)
- [ ] Format quirks review (1 hour)
- [ ] Real-world validation (1 hour)
- [ ] Encoding vendor band (1 hour)
- [ ] Parser implementation plan (30 min)

**Approval Gate**: Tom & Bramwell review and sign-off

**Success Criteria**:
- [ ] All design decisions understood
- [ ] SAUCE implementation plan approved
- [ ] Parser stack prioritized
- [ ] Test strategy finalized
- [ ] Risk mitigation accepted

---

## Feedback and Revisions

**To Request Changes**:
1. File issue in `.specs/ir/` with specific section
2. Reference decision in `decisions.md`
3. Include rationale from prior art studies

**To Add New Reference**:
1. Study new system/implementation
2. Create AGENTS.md in `reference/`
3. Link from `prior-art-notes.md`
4. Update this index

---

**Document Owner**: Ansilust IR Working Group  
**Last Updated**: 2024-10-26  
**Status**: Ready for Phase 4 Review  
**Approvers**: Tom, Bramwell