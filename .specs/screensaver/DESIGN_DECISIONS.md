# 16c-screensaver Design Decisions

## Key Architectural Decisions

### 1. Rendering Delegation
**Decision**: Screensaver orchestrates, ansilust renders.

**Rationale**: 
- Streaming-style rendering (line-by-line, BBS dialup feel) is a core ansilust feature
- Screensaver focuses on artwork selection, terminal lifecycle, and user input
- Clean separation of concerns: orchestration vs. rendering mechanics
- Rendering improvements automatically benefit screensaver

**Impact**: The screensaver spec references but does not define the streaming renderer implementation.

---

### 2. Canvas Sizing Strategy
**Decision**: Adaptive sizing with three modes (fit/fill/native), no letterboxing.

**Problem**: BBS artwork varies widely (40x25 to 160x50+), terminals vary in size.

**Solution**:
- **Fit mode** (default): Scale to fit, preserve aspect ratio, center
- **Fill mode**: Crop to fill screen, preserve aspect ratio
- **Native mode**: Original size, crop if needed

**Rationale**: 
- Letterboxing (black bars) breaks immersion
- Aspect ratio preservation maintains artistic intent
- Multiple modes satisfy different user preferences

---

### 3. Fullscreen Terminal Pattern (Omarchy-Inspired)
**Decision**: Launch in dedicated terminal window via systemd service.

**Reference Implementation**:
```bash
# Launch via systemd
ExecStart=/usr/bin/alacritty --class screensaver -e 16c-screensaver

# Hyprland fullscreen rule
windowrulev2 = fullscreen, class:^(screensaver)$
```

**Rationale**:
- Proven pattern from Omarchy/ObsidianOS screensavers
- Clean separation from user's working terminal
- Native window manager integration (fullscreen, focus rules)
- Works with existing idle detection (hypridle, swayidle)

---

### 4. Configuration Philosophy
**Decision**: TOML config file with sensible defaults, all settings override-able via CLI flags.

**Location**: `~/.config/16c/screensaver.conf`

**Rationale**:
- TOML is human-readable and well-suited to configuration
- Defaults work out-of-box for most users
- Power users can fine-tune filters and timing
- CLI flags enable one-off overrides without editing config

---

### 5. Streaming Speed as Baud Rate Simulation
**Decision**: Configurable speeds modeled after classic modem speeds.

**Options**:
- `instant`: No animation
- `1200baud`: Slow (authentic early BBS)
- `2400baud`: Default (common mid-90s speed)
- `9600baud`: Fast (late 90s)
- `56kbaud`: Very fast (dial-up peak)

**Rationale**:
- Evokes nostalgia for dialup BBS experience
- Clear mental model (users understand "2400 baud")
- Easy to explain: "how fast would this have appeared on a modem"

---

### 6. Mirror Dependency (No Bundled Artwork)
**Decision**: Screensaver requires local 16colors mirror, does not bundle artwork.

**Rationale**:
- 16colors archive is 50+ GB (impractical to bundle)
- Users control what artwork they download (year ranges, groups, filters)
- Respects bandwidth and storage constraints
- Encourages engagement with full 16c ecosystem (`16c mirror sync`)

**Error Handling**: Clear message directing users to `16c mirror sync` if no mirror found.

---

### 7. Exit on Any Input (No Interaction)
**Decision**: Screensaver exits immediately on any keyboard/mouse input, no interaction.

**Rationale**:
- Matches traditional screensaver behavior
- Simple mental model: "press anything to exit"
- No complex interaction logic needed
- Prevents accidental commands while screensaver active

---

### 8. Metadata Overlay (Subtle, Togglable)
**Decision**: Bottom-left corner overlay showing artist/pack/year, dimmed color, user-configurable.

**Format**: `Artist: Cthulu | Pack: MIST1025 | 2025`

**Rationale**:
- Gives credit to artists and groups
- Educates users about the BBS scene
- Subtle positioning and color minimize distraction
- Can be disabled for purists (`--no-metadata`)

---

### 9. Systemd Integration Over Custom Idle Detection
**Decision**: Provide systemd service template, integrate with existing idle detectors.

**Rationale**:
- Don't reinvent the wheel (hypridle, swayidle, xautolock exist)
- Systemd is standard on modern Linux
- Users already have idle detection configured
- Clean integration with window manager power management

---

### 10. Caching for Performance
**Decision**: Cache artwork list with TTL, rebuild on mirror changes.

**Rationale**:
- Scanning 4000+ packs on every startup is slow
- Cache enables instant startup
- TTL ensures new artwork appears without manual refresh
- Mirror change detection (mtime checks) triggers rebuild

---

## Out-of-Scope Clarifications

### Why Streaming Rendering is Out of Scope
The screensaver spec references but does not implement streaming rendering because:

1. **Core Ansilust Feature**: Line-by-line/character-by-character rendering with timing control is fundamental to ansilust's mission
2. **Format-Specific**: Different formats (ANS, XB, etc.) require different streaming strategies
3. **Reusability**: Other ansilust features will benefit from streaming renderer
4. **Complexity**: Deep integration with ANSI escape sequence generation, encoding, and parsers

**Spec Responsibility**: Define the interface (`RenderOptions`) and desired behavior (baud rate simulation).

**Ansilust Responsibility**: Implement the renderer that satisfies the interface.

---

### Why 16colors Download is Out of Scope
Download/mirror functionality is defined in `.specs/download/instructions.md` because:

1. **Shared Infrastructure**: Multiple tools (screensaver, viewer, CLI) use the same mirror
2. **Complex Feature**: FTP/HTTP/RSYNC protocol selection, filtering, caching
3. **Standalone Value**: Users can download artwork without using the screensaver

**Dependency**: Screensaver assumes mirror exists and follows standard structure.

---

## User Experience Principles

### 1. Zero Configuration for Defaults
Out-of-box experience should work without config file:
- Random artwork from entire mirror
- 2400 baud streaming speed
- 30 seconds per artwork
- Metadata overlay enabled
- Fit mode (scale to fit, preserve aspect ratio)

### 2. Progressive Disclosure
Advanced features are opt-in:
- Basic: `16c-screensaver` (just works)
- Filtered: `16c-screensaver --groups mistigris`
- Customized: Edit `~/.config/16c/screensaver.conf`

### 3. Fail Gracefully with Helpful Messages
If mirror doesn't exist:
```
Error: No 16colors mirror found.

To download artwork, run:
  16c mirror sync --since 2020

Or download a specific pack:
  16c download mist1025

For more info: 16c --help
```

---

## Technical Constraints

### Terminal Compatibility
- **Minimum**: ANSI color support (8-bit)
- **Recommended**: 24-bit RGB color support
- **Tested**: Alacritty, Ghostty, Kitty, WezTerm

### Performance Targets
- **Startup**: < 1 second (with cached artwork list)
- **Render start**: < 500ms (after artwork selected)
- **Memory**: < 100MB (even with large artwork)
- **CPU**: Minimal when idle between artworks

### Platform Support
- **Primary**: Linux (systemd, hypridle integration)
- **Future**: macOS, BSD (manual idle detection integration)
- **Not Planned**: Windows (WSL works, native TBD)

---

## Comparison to Reference Implementation (Omarchy)

### What We Keep
- Fullscreen terminal pattern
- Exit on input
- Systemd service integration
- Signal handling (SIGINT/SIGTERM)

### What We Change
- **Content**: BBS artwork (not terminal text effects)
- **Rendering**: Ansilust (not `tte`)
- **Selection**: 16colors mirror (not hardcoded content)
- **Configuration**: TOML file (not inline bash)

### What We Add
- Artwork filtering (year/group/artist)
- Metadata overlay
- Multiple render modes
- Caching for performance
- Integration with 16c ecosystem

---

**Status**: Design Phase Complete  
**Next Steps**: Implementation (Phase 1 - Minimal Viable Screensaver)
