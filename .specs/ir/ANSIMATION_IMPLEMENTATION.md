# Ansimation Implementation Summary

**Status**: Multi-frame parsing complete ✅  
**Date**: 2025-11-01  
**Implementation**: `src/parsers/ansi.zig`, `src/ir/animation.zig`, `src/ir/sauce.zig`

## Overview

Ansilust now successfully parses ansimation (ANSI animation) files with multiple frames. The implementation captures all frames into the IR's `animation_data` structure without freezing or timing out, even on large files.

## Architecture

### Frame Detection Pattern

Ansimation files use a specific pattern to denote frame boundaries:

```
ESC[2J          # Clear screen (ED - Erase Display)
[content]       # Frame content (text, colors, cursor movements)
ESC[1;1H        # Cursor home (return to top-left)
```

This pattern repeats for each frame in the animation.

### Implementation Details

**Parser State** (`src/parsers/ansi.zig`):
- `seen_clear_screen`: Flag set when ESC[2J is encountered
- `has_content_after_clear`: Flag set when content is written after clear
- Frame boundary detection in `handleCursorPosition()` when cursor returns to (1,1)

**Frame Capture** (`src/parsers/ansi.zig:captureAnimationFrame()`):
- Clones current grid state into a `Snapshot`
- Adds snapshot to `animation_data.frames`
- Resets detection flags for next frame
- Automatically initializes `animation_data` on first frame

**Animation IR** (`src/ir/animation.zig`):
- `Animation` - Container with frames array, dimensions, loop mode
- `Frame` - Union of `Snapshot` (full grid) or `Delta` (cell updates)
- `Snapshot` - Complete grid + duration + delay
- `AnimationMetadata` - Title, author, description, fps_hint

## Performance

**Test case**: WZKM-MERMAID.ANS
- Size: 1.2 MB
- Frames: 55
- Parse time: ~242ms
- Memory: Allocates 55 full grid snapshots

**Before optimization**:
- Timeout: 30+ seconds (caused by malformed SAUCE dimensions)
- Issue: SAUCE TInfo fields had ASCII text instead of binary dimensions
- Result: Parser tried to allocate 8272×8200 grid (67 million cells)

**After optimization**:
- Added SAUCE dimension validation (`src/ir/sauce.zig`)
- Reject width > 1024, height > 4096
- Return `null` for unreasonable values → parser uses defaults
- Result: 242ms parse time ✅

## Test Coverage

**Total tests**: 123/123 passing

**Ansimation-specific tests** (3):
1. Frame detection: Verify ESC[2J + content + ESC[1;1H triggers capture
2. Multi-frame parsing: Parse file with 3 frames, verify all captured
3. SAUCE validation: Reject unreasonable dimensions from malformed metadata

**Related tests**:
- UTF8ANSI roundtrip: Ensures ansimation output can be re-parsed
- Parser integrity: All 46 ANSI parser tests still passing

## Git Commits

All changes committed with TDD discipline (RED→GREEN→REFACTOR):

1. **`63a2a77`** - GREEN: Implement ansimation frame detection
   - Added `seen_clear_screen` and `has_content_after_clear` flags
   - Initially stopped parsing at frame boundary (basic detection)

2. **`89a9845`** - Enable all 121 renderer tests
   - Fixed module import issue (direct import → module dependency)
   - Changed `@import("../parsers/lib.zig")` → `@import("parsers")`

3. **`8dd9a61`** - Document Zig module import patterns
   - Updated AGENTS.md with module dependency guidance
   - Prevents future "file exists in multiple modules" errors

4. **`5abf1d2`** - GREEN: Fix parse hang from malformed SAUCE dimensions
   - Added dimension validation in `sauce.zig`
   - Performance: 30s timeout → 24ms parse ✅

5. **`cd00f83`** - GREEN: Parse all animation frames into animation_data
   - Changed strategy from "stop at boundary" → "capture frames"
   - Added `captureAnimationFrame()` method
   - Initialize `animation_data` on first frame
   - Set `source_format = .ansimation`

## Current Behavior

**Parsing**: ✅ Complete
- All frames parsed and stored in `animation_data`
- Each frame is a full grid snapshot
- Source format set to `.ansimation`

**Rendering**: ⚠️ Shows last frame only
- Renderer currently outputs final frame (frame 55 of WZKM-MERMAID.ANS)
- No animation playback support yet

## Next Steps (Future Work)

### Phase 2: SAUCE Timing Extraction (TDD)
1. **RED**: Add test expecting frame durations from SAUCE baud rate
2. **GREEN**: Extract baud rate from SAUCE TInfo3/4, calculate frame duration
3. Update `Snapshot.duration` from default 100ms to calculated value

### Phase 3: Animation Rendering (TDD)
1. **RED**: Add test for rendering multiple frames
2. **GREEN**: Modify renderer to output frames sequentially
3. Options:
   - CLI flag `--frame N` to render specific frame
   - CLI flag `--animate` to output all frames with timing
   - Default: show first frame (not last)

### Design Question
**Should renderer output**:
- A) First frame only (static preview) - Best for quick view
- B) Last frame only (current behavior) - Shows final state
- C) All frames with delays (true animation) - Requires timing implementation
- D) User choice via CLI flag - Most flexible

**Recommendation**: Implement (A) as default, with `--animate` flag for (C).

## References

- **SAUCE Spec**: http://www.acid.org/info/sauce/sauce.htm
- **Ansimation Pattern**: Observed from sixteencolors-archive corpus
- **IR Design**: `.specs/ir/design.md`
- **Animation IR**: `src/ir/animation.zig`
- **Test Corpus**: `reference/sixteencolors/animated/`

## Validation

```bash
# Test ansimation parsing (no timeout)
timeout 3 zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
# Exit code: 0 ✅

# Run all tests
zig build test --summary all
# Build Summary: 7/7 steps succeeded; 123/123 tests passed ✅

# Count total tests
rg '^test ' src/ --count-matches | awk -F: '{sum += $2} END {print sum}'
# Total tests: 123 ✅
```

All code is tested, committed, and pushed to GitHub!
