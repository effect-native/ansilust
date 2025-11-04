# Ansilust Screensaver for Omarchy Linux

> **Note**: Full specification available at `.specs/screensaver/instructions.md`

## Concept

Create a screensaver for Omarchy Linux that continuously scrolls through classic ANSI art from the [16colo.rs](https://16colo.rs) BBS art archive, bringing retro computing aesthetics to modern Linux systems.

**Status**: Specification complete (see `.specs/screensaver/`)

## Core Features

### Art Display
- Continuously cycle through ANSI art from the 16colo.rs archive
- Smooth scrolling transitions between artworks
- Full-screen display optimized for various terminal sizes
- Support for all ansilust-compatible formats (ANSI, Binary, PCBoard, XBin, etc.)

### Screensaver Behavior
- Activate after configurable idle time
- Dismiss on any keyboard/mouse activity
- Low CPU/memory footprint during operation
- Respect system suspend/hibernation

### Art Selection
- Random selection from the entire archive
- Optional filtering by:
  - Year/era (1990s vs modern)
  - Art group (ACiD, iCE, Blocktronics, etc.)
  - Artist
  - Format type
- Favorite collections support
- "Best of" curated playlists

### Display Options
- Configurable transition effects:
  - Fade in/out
  - Scroll up/down/left/right
  - Instant switch
  - Slow reveal (line-by-line)
- Adjustable timing (seconds per artwork)
- Optional metadata overlay (artist, date, pack)
- Retro scan-line effect (optional)

## Technical Integration

### Omarchy Linux Integration
- XScreenSaver module compatibility
- Wayland/X11 support
- systemd integration for idle detection
- Configuration via standard Linux screensaver settings
- Respect user theme (dark/light mode)

### Architecture
```
screensaver/
├── main.zig              # Screensaver entry point
├── idle_detector.zig     # System idle monitoring
├── art_loader.zig        # 16colo.rs API client
├── display_manager.zig   # Fullscreen rendering
├── transition.zig        # Transition effects
└── config.zig           # User preferences
```

### Data Management
- Local cache of downloaded artpacks
- Background sync with 16colo.rs
- Offline mode (use cached art)
- Bandwidth-friendly updates
- SQLite for metadata/favorites

### Rendering
- Use ansilust rendering engine
- Hardware-accelerated terminal rendering
- Support for modern terminal features (24-bit color)
- Fallback to 16-color for compatibility
- Adaptive sizing for different screen resolutions

## User Experience

### Installation
```bash
# Install ansilust-screensaver package
omarchy-pkg install ansilust-screensaver

# Configure via GUI or CLI
ansilust-screensaver --configure

# Test screensaver
ansilust-screensaver --preview
```

### Configuration Options
- Idle timeout duration
- Art source (full archive, favorites, specific groups)
- Transition style and speed
- Display metadata (on/off)
- Cache size limit
- Update frequency

## Development Phases

### Phase 1: Basic Screensaver
- [ ] XScreenSaver/systemd integration
- [ ] Simple random art display
- [ ] Basic transition effects
- [ ] Configuration file support

### Phase 2: Art Management
- [ ] 16colo.rs API integration
- [ ] Local caching system
- [ ] Offline mode
- [ ] Art filtering options

### Phase 3: Enhanced Display
- [ ] Advanced transition effects
- [ ] Metadata overlay
- [ ] Multiple terminal backend support
- [ ] Performance optimization

### Phase 4: User Customization
- [ ] Favorites/playlists
- [ ] Theme integration
- [ ] GUI configuration tool
- [ ] Statistics tracking

## Why This Matters

**Preservation**: Showcases classic BBS art to modern Linux users

**Aesthetics**: Brings retro computing culture into daily desktop experience

**Education**: Introduces new users to ANSI art history and scene culture

**Showcase**: Demonstrates ansilust rendering capabilities in a practical application

**Community**: Celebrates the work of scene artists past and present

**Nostalgia**: Delights those who remember the BBS era

## Implementation Notes

- Use ansilust for all art rendering
- Leverage Zig for low-level system integration
- Minimal dependencies for easy packaging
- Respect system power management
- Follow Linux screensaver conventions
- Open source (same license as ansilust)

## Inspiration

- XScreenSaver modules (phosphor, apple2, etc.)
- ACiDView.exe slideshow mode
- 16colo.rs website gallery
- Classic BBS welcome screens
- Flying toasters (but with ANSI art!)

## Future Enhancements

- Multi-monitor support
- Synchronized display across machines
- Community voting on featured art
- Artist of the day spotlight
- Integration with other scene archives
- ANSI music/MOD playback during display
- Virtual BBS experience mode

---

**Status**: Concept/Planning Phase  
**Priority**: Low-Medium (fun showcase project)  
**Dependencies**: Ansilust rendering engine, Omarchy Linux packaging  
**Target Audience**: Omarchy Linux users, ANSI art enthusiasts, retro computing fans
