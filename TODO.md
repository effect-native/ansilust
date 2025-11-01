# Ansilust TODO

## Critical Issues

### UTF8ANSI Roundtrip Support
**Status**: ❌ Not implemented  
**Priority**: HIGH

Ansilust must support both CP437 and UTF8ANSI as input types without issues.
zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
**Test case**:
```bash
# Render CP437 ANSI to UTF8ANSI
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > reference/sixteencolors/fire-43/US-JELLY.utf8ansi

# Re-render UTF8ANSI (should work identically)
zig build run -- reference/sixteencolors/fire-43/US-JELLY.utf8ansi
```

**Current status**: ❌ CONFIRMED BUG - Freezes on UTF8ANSI input (timeout after 3s)
**Required**: Parser must detect UTF8ANSI vs CP437 input and handle both

**Test results (2025-10-31)**:
```bash
# CP437 → UTF8ANSI works fine
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > /tmp/us-jelly.utf8ansi
# Exit code: 0 ✅

# UTF8ANSI input FREEZES
timeout 3 zig build run -- /tmp/us-jelly.utf8ansi
# Exit code: 124 (timeout) ❌
```

### Animation Handling - No Freezing
**Status**: ❌ Not implemented  
**Priority**: HIGH

Ansilust must not freeze on ansimation files. Should render instantly or fail gracefully.

**Test case**:
```bash
# Must complete in <3 seconds (no freeze/hang)
timeout 3 zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
```

**Current status**: ⚠️ NEEDS TESTING - Likely freezes on animation sequences  
**Required**: 
- Detect ansimation control sequences
- Either render first frame only, or
- Fail fast with clear error message

**Files to test**:
- `reference/sixteencolors/animated/WZKM-MERMAID.ANS`
- Other files in `reference/sixteencolors/animated/`

## Implementation Tasks

### 1. Input Format Detection
- [ ] Add auto-detection of CP437 vs UTF8ANSI input
- [ ] Check for UTF-8 BOM or high-bit characters
- [ ] Fallback to CP437 if ambiguous

### 2. UTF8ANSI Parser
- [ ] Implement UTF8ANSI input parser
- [ ] Handle modern terminal sequences (already in IR)
- [ ] Map to same IR as CP437 parser

### 3. Animation Handling
- [ ] Detect ansimation control sequences (ANSI Music, timing codes)
- [ ] Add `--first-frame-only` flag for animations
- [ ] Add timeout protection in parser
- [ ] Graceful error for unsupported animation features

### 4. Validation Tests
- [ ] Test US-JELLY.ANS roundtrip
- [ ] Test all animated files with timeout
- [ ] Add CI check for timeout/freeze conditions

## Nice to Have (Lower Priority)

### Parser Improvements
- [ ] Better error messages for malformed files
- [ ] Progress indicator for large files
- [ ] Streaming parse mode

### Renderer Improvements
- [ ] Text attributes (bold, underline, blink)
- [ ] Animation playback support
- [ ] Hyperlinks (OSC 8)

## Completed ✅

- [x] UTF8ANSI renderer implementation
- [x] CP437 glyph mapping
- [x] DOS palette colors
- [x] Null byte handling (renders as spaces)
- [x] Zig 0.15 compatibility
- [x] 102/102 tests passing
