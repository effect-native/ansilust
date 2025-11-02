# .specs/screensaver

## Overview

This directory contains the specification for **16c-screensaver**, a terminal screensaver that displays classic BBS artwork from the 16colors archive with authentic dialup-style streaming rendering.

## Documents

### [instructions.md](instructions.md)
**Primary specification document** following the EARS (Easy Approach to Requirements Syntax) notation.

**Contents**:
- Core requirements (FR1.1 - FR1.7)
- Technical specifications (canvas sizing, streaming rendering, configuration)
- CLI usage examples
- User stories and acceptance criteria
- Implementation roadmap (Phase 1-4)

### [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md)
**Architectural decisions and rationale** for key design choices.

**Contents**:
- Rendering delegation (screensaver vs. ansilust)
- Canvas sizing strategy (fit/fill/native modes)
- Fullscreen terminal pattern (Omarchy-inspired)
- Configuration philosophy (TOML + CLI flags)
- Streaming speed as baud rate simulation
- Out-of-scope clarifications

## Quick Start

### For Developers
1. Read `instructions.md` for complete requirements
2. Review `DESIGN_DECISIONS.md` for architectural context
3. Check dependencies: `.specs/download/` (16colors mirror) and ansilust rendering
4. Start with Phase 1 implementation (minimal viable screensaver)

### For Users (Future)
```bash
# Install and sync artwork
16c mirror sync --since 2020

# Run screensaver
16c-screensaver

# Install systemd service
16c-screensaver --install-service

# Configure
$EDITOR ~/.config/16c/screensaver.conf
```

## Key Dependencies

### In-Scope (This Spec)
- CLI command (`16c-screensaver`)
- Artwork selection and cycling
- Terminal lifecycle management
- User input handling
- Configuration and filtering
- Systemd integration

### Out-of-Scope (Other Specs)
- **16colors download/mirror** (`.specs/download/instructions.md`)
  - `16c mirror sync`
  - Local mirror structure
  - `.16colors-meta.json` format
  - SAUCE metadata extraction

- **Ansilust rendering** (core feature)
  - Streaming-style rendering (line-by-line, baud rate simulation)
  - Format parsing (ANS, ASC, XB, etc.)
  - SAUCE metadata handling
  - Color/font/aspect ratio rendering

## Design Philosophy

### Orchestration, Not Implementation
The screensaver **orchestrates** the viewing experience:
- Selects artwork from local mirror
- Configures render options (speed, size, mode)
- Handles terminal setup/teardown
- Detects and responds to user input

The screensaver **does not implement**:
- Artwork rendering (ansilust's job)
- Format parsing (ansilust's job)
- Download/mirror management (16c CLI's job)

This clean separation ensures:
- Rendering improvements benefit all ansilust features
- Mirror improvements benefit all 16c features
- Screensaver stays focused on UX orchestration

## Inspiration and References

### Omarchy/ObsidianOS Screensaver
- **Pattern**: Fullscreen terminal via systemd service
- **Integration**: hypridle/swayidle activation
- **Exit**: Any keyboard input dismisses
- **Reference**: https://github.com/Obsidian-OS/screensaver

### Terminal Text Effects (TTE)
- **Concept**: Animated ANSI rendering in terminal
- **Effects**: Multiple visual effects (beams, rain, matrix, etc.)
- **Library**: Python-based visual effects engine
- **Reference**: https://github.com/ChrisBuilds/terminaltexteffects

### Classic BBS Experience
- **Streaming**: Line-by-line rendering (2400 baud simulation)
- **Artwork**: ANS, ASC, XB formats from 16colors archive
- **Authenticity**: CP437 encoding, DOS aspect ratio, iCE colors

## Status

- **Specification**: Complete ✓
- **Design Decisions**: Documented ✓
- **Implementation**: Not started (Phase 1 next)
- **Testing**: Not started
- **Documentation**: User docs pending

## Next Steps

### Phase 1: Minimal Viable Screensaver
1. Implement CLI command (`16c-screensaver`)
2. Random artwork selection from mirror
3. Fullscreen terminal mode (ANSI escape sequences)
4. Exit on keyboard input (signal handling)
5. Basic rendering via ansilust (delegate to renderer)
6. Terminal size detection and centering

**Success Criteria**: Can display random artwork in fullscreen and exit cleanly.

### Phase 2: Configuration and Filtering
1. TOML config file support (`~/.config/16c/screensaver.conf`)
2. Year/group/artist filtering
3. Streaming speed configuration
4. Metadata overlay toggle
5. Artwork list caching for performance

**Success Criteria**: Users can customize artwork selection and display options.

### Phase 3: Systemd Integration
1. `--install-service` command
2. Systemd user service template
3. Hypridle/swayidle integration docs
4. Fullscreen window rules (Hyprland/Sway)
5. DPMS awareness

**Success Criteria**: Screensaver activates automatically on idle and integrates with system power management.

### Phase 4: Advanced Features
1. Multiple render modes (fit/fill/native)
2. Transition effects between artworks
3. Playlist support (curated sequences)
4. Statistics tracking (most displayed artwork)
5. Remote mirror support (stream from 16colo.rs)

**Success Criteria**: Power users can fine-tune the experience and track their viewing history.

## Contributing

When updating this spec:
1. Maintain EARS notation for requirements
2. Document design decisions in `DESIGN_DECISIONS.md`
3. Update implementation phases in `instructions.md`
4. Keep dependencies section current
5. Preserve out-of-scope boundaries

## Questions?

- **General ansilust questions**: See main project README
- **16colors download/mirror**: See `.specs/download/`
- **Rendering implementation**: See ansilust core rendering docs
- **This spec**: File an issue or discussion

---

**Last Updated**: 2025-11-01  
**Status**: Specification Complete, Implementation Pending
