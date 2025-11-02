# 16c-screensaver - BBS Art Terminal Screensaver

## Overview

A terminal screensaver CLI command (`16c-screensaver` or `16colo-screensaver`) that displays classic BBS artwork from the 16colors archive in fullscreen terminal mode. Inspired by the Omarchy screensaver pattern (fullscreen Alacritty/Ghostty running custom ANSI script), but integrated with the ansilust/16c ecosystem for authentic retro BBS art display.

**Key Philosophy**: This screensaver showcases the classic BBS art aesthetic with smooth, streaming-style rendering that evokes the dialup modem experience. It integrates seamlessly with the 16colors download functionality and leverages ansilust's rendering capabilities.

## Design Context

### Omarchy Screensaver Pattern

The reference implementation (Obsidian-OS/Omarchy screensaver) follows this pattern:
```bash
#!/bin/bash
# Loops terminal text effects (tte) with random effects
while true; do
  effect=$(tte 2>&1 | grep -oP '{\K[^}]+' | shuf -n1)
  echo "$LOGO" | tte --frame-rate 240 --canvas-width 0 \
    --canvas-height $(($(tput lines) - 2)) --anchor-canvas c --anchor-text c "$effect"
  if read -n 1 -t 3; then exit 0; fi
done
```

**Key Observations**:
- Fullscreen terminal application (run via Alacritty/Ghostty/etc in dedicated window)
- Loops indefinitely until keyboard input detected
- Uses `tte` (Terminal Text Effects) for animated rendering
- Canvas sizing handles terminal dimensions dynamically
- Exit on any user input (keyboard/mouse)

### Integration with Hyprland/systemd

**User Configuration**: `~/.config/hypr/hypridle.conf`
```
timeout 300
  on-timeout loginctl lock-session
timeout 360
  on-timeout hyprctl dispatch dpms off
on-resume hyprctl dispatch dpms on
```

**System Integration**:
- Works with existing idle detection (hypridle, swayidle, xautolock)
- Launched via systemd user service or idle handler
- Respects DPMS/power management
- Dismisses on keyboard/mouse activity

## Core Requirements (EARS Notation)

### FR1.1: CLI Command Interface
FR1.1.1: The system shall provide a `16c-screensaver` CLI command.  
FR1.1.2: The system shall support `16colo-screensaver` as an alias.  
FR1.1.3: WHEN invoked the screensaver shall enter fullscreen mode in the current terminal.  
FR1.1.4: The system shall exit cleanly on any keyboard input.  
FR1.1.5: The system shall exit cleanly on SIGINT/SIGTERM/SIGHUP/SIGQUIT signals.

### FR1.2: Artwork Selection and Display
FR1.2.1: The screensaver shall randomly select BBS artwork from the local 16colors mirror.  
FR1.2.2: WHERE no local mirror exists the screensaver shall display a message directing the user to `16c mirror sync`.  
FR1.2.3: The screensaver shall cycle through multiple artworks with configurable timing.  
FR1.2.4: WHEN displaying artwork the system shall use ansilust rendering (not raw ANSI dump).  
FR1.2.5: The system shall support all ansilust-compatible formats (ANS, ASC, XB, etc.).

### FR1.3: Screen Sizing and Layout
FR1.3.1: The screensaver shall automatically detect terminal dimensions.  
FR1.3.2: WHEN artwork is smaller than terminal the system shall center it without letterboxing.  
FR1.3.3: WHEN artwork is larger than terminal the system shall scale/crop to fit without distortion.  
FR1.3.4: The system shall handle terminal resize events gracefully.  
FR1.3.5: The system shall respect artwork aspect ratio and SAUCE metadata for display hints.

### FR1.4: Streaming/BBS-Style Rendering
FR1.4.1: The system shall render artwork with streaming-style animation (line-by-line or character-by-character).  
FR1.4.2: The streaming speed shall be configurable (default: ~2400 baud simulation).  
FR1.4.3: The system shall support instant rendering mode via `--instant` flag.  
FR1.4.4: WHERE SAUCE metadata indicates specific rendering hints the system shall apply them.

### FR1.5: Configuration and Filtering
FR1.5.1: The screensaver shall support a configuration file at `~/.config/16c/screensaver.toml`.  
FR1.5.2: The configuration shall support artwork filters (year, group, artist, format).  
FR1.5.3: The configuration shall support timing settings (seconds per artwork, streaming speed).  
FR1.5.4: The configuration shall support metadata overlay (artist, pack, date) toggle.  
FR1.5.5: WHERE no configuration exists the system shall use sensible defaults.

### FR1.6: Integration with 16colors Mirror
FR1.6.1: The screensaver shall discover artwork from the standard 16colors mirror location.  
FR1.6.2: The screensaver shall respect mirror organization (packs by year).  
FR1.6.3: WHEN artwork is selected the system shall read associated `.16colors-meta.json` for metadata.  
FR1.6.4: The system shall cache artwork list for performance (rebuild on mirror changes).

### FR1.7: Systemd/Idle Integration
FR1.7.1: The system shall provide a systemd user service template.  
FR1.7.2: The service shall support activation via idle detection hooks.  
FR1.7.3: The service shall launch the screensaver in a dedicated terminal window (Alacritty/Ghostty).  
FR1.7.4: The service shall respect DPMS power management settings.

## Out of Scope (Dependencies)

These features are **explicitly out of scope** for this spec and rely on other ansilust features:

### Relies on: 16colors Download/Mirror (.specs/download/)
- `16c mirror sync` - Full archive mirroring
- `16c download <pack>` - Individual pack downloads
- Local mirror structure (`~/Pictures/16colors/` or `~/.local/share/16colors/`)
- `.16colors-meta.json` metadata format
- SAUCE metadata extraction

### Relies on: Ansilust Rendering
- **Streaming-style rendering** - The exact implementation of line-by-line or character-by-character rendering with timing control
- **Format parsing** - ANS, ASC, XB, PCB, etc. parsers
- **SAUCE metadata handling** - Reading rendering hints from SAUCE records
- **Color/font handling** - CP437, palette, iCE colors mode
- **Aspect ratio** - Respecting DOS aspect ratio (1.35x) hints

**Design Decision**: The screensaver spec focuses on **orchestration** (selecting artwork, handling terminal lifecycle, user input) while delegating **rendering mechanics** to the core ansilust system. This maintains clean separation of concerns and ensures rendering improvements automatically benefit the screensaver.

## Technical Specifications

### Canvas Sizing Strategy

**Problem**: BBS artwork varies widely in size (40x25 to 160x50+), and terminals vary in dimensions. We must avoid letterboxing (black bars) while preserving the artwork's visual integrity.

**Solution**: Adaptive sizing based on content and terminal:

```
Terminal Dimensions (W x H)
       ↓
Artwork Dimensions (AW x AH) from SAUCE or detection
       ↓
Aspect Ratio (AR) = AW / AH
       ↓
┌─────────────────────────────────────┐
│ Is artwork <= terminal dimensions?  │
├─────────────────────────────────────┤
│ YES → Center without scaling        │
│ NO  → Scale to fit (maintain AR)    │
└─────────────────────────────────────┘
```

**Scaling Algorithm** (when artwork > terminal):
```
Available Width = Terminal Width
Available Height = Terminal Height - 1 (status line)

Scale Factor = min(
  Available Width / Artwork Width,
  Available Height / Artwork Height
)

Rendered Width = Artwork Width * Scale Factor
Rendered Height = Artwork Height * Scale Factor

Center Offset X = (Available Width - Rendered Width) / 2
Center Offset Y = (Available Height - Rendered Height) / 2
```

**SAUCE Considerations**:
- **Columns (TInfo1)**: Use as artwork width
- **Lines (TInfo2)**: Use as artwork height
- **AspectRatio flags**: Apply 1.35x vertical stretch if requested
- **Font name**: Select appropriate bitmap font for rendering

**Rendering Modes**:
1. **Fit Mode** (default): Scale to fit, preserve aspect ratio
2. **Fill Mode** (`--fill`): Crop to fill screen, preserve aspect ratio
3. **Native Mode** (`--native`): Display at original size, crop if needed

### Streaming Rendering Implementation

**Design Dependency**: Streaming rendering is implemented by the ansilust rendering system, not the screensaver. The screensaver merely configures and invokes it.

**Interface to Ansilust Renderer**:
```zig
// Conceptual API (actual implementation in ansilust rendering system)
const RenderOptions = struct {
    streaming: bool = true,
    stream_speed: StreamSpeed = .Baud2400,  // .Instant, .Baud1200, .Baud2400, .Baud9600, .Baud56k
    terminal_width: usize,
    terminal_height: usize,
    center: bool = true,
    // ... other ansilust rendering options
};

pub fn renderToTerminal(artwork_path: []const u8, options: RenderOptions) !void {
    // Implementation in ansilust rendering system
}
```

**Screensaver Responsibility**: Only to select artwork and configure render options.

**Rationale**: Streaming rendering requires deep integration with ANSI escape sequence generation, UTF8/CP437 encoding, and format-specific parsers. This is core ansilust functionality, not screensaver-specific.

### Configuration File Format

**Location**: `~/.config/16c/screensaver.toml`

**Format**: TOML
```toml
[general]
artwork_duration = 30          # Seconds per artwork
streaming_speed = "2400baud"   # "instant", "1200baud", "2400baud", "9600baud"
show_metadata = true           # Display artist/pack overlay
render_mode = "fit"            # "fit", "fill", "native"

[filters]
# Limit to specific years (null = no limit)
year_min = 1990
year_max = 2025

# Limit to specific groups (empty = all groups)
groups = ["mistigris", "blocktronics"]

# Limit to specific formats (empty = all formats)
formats = ["ans", "asc"]

# Exclude NSFW content
exclude_nsfw = true

[advanced]
# Cache artwork list for performance
cache_artwork_list = true
cache_ttl_seconds = 3600

# Refresh mirror check interval
mirror_check_interval = 300    # Seconds
```

### Metadata Overlay

**Display Format** (bottom-left corner):
```
┌──────────────────────────────────────┐
│                                      │
│    [Artwork rendered here]           │
│                                      │
│                                      │
└──────────────────────────────────────┘
  Artist: Cthulu | Pack: MIST1025 | 2025
```

**Positioning**:
- Bottom-left corner, 1 line from bottom
- Dimmed/subtle color (e.g., dark gray)
- Automatically hide if `show_metadata = false`

**Content**:
- **Artist**: From SAUCE author field or filename heuristics
- **Pack**: Pack name (e.g., mist1025)
- **Year**: Pack year or SAUCE date

### Exit Handling

**Signal Handling** (similar to Omarchy pattern):
```zig
// Zig signal handling example
const std = @import("std");

var running = std.atomic.Atomic(bool).init(true);

fn signalHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    running.store(false, .SeqCst);
}

pub fn main() !void {
    // Register signal handlers
    try std.os.sigaction(std.os.SIG.INT, &std.os.Sigaction{
        .handler = .{ .handler = signalHandler },
        .mask = std.os.empty_sigset,
        .flags = 0,
    }, null);
    
    // Main screensaver loop
    while (running.load(.SeqCst)) {
        // Display artwork
        // Check for keyboard input (non-blocking)
    }
}
```

**Cleanup on Exit**:
1. Restore terminal state (cursor visible, alternate screen off)
2. Clear screen
3. Print exit message (optional)

### Terminal Detection and Fullscreen

**Terminal Capabilities**:
```zig
// Detect terminal size
const term_width = try std.os.tcgetwinsize().ws_col;
const term_height = try std.os.tcgetwinsize().ws_row;

// Enter alternate screen buffer (optional, configurable)
// \x1b[?1049h

// Hide cursor
// \x1b[?25l

// Clear screen
// \x1b[2J\x1b[H
```

**Fullscreen Considerations**:
- Use alternate screen buffer to preserve user's terminal state
- Hide cursor during display
- Restore cursor and screen buffer on exit

### Systemd Integration

**User Service**: `~/.config/systemd/user/16c-screensaver.service`
```ini
[Unit]
Description=16colors BBS Art Screensaver
After=graphical-session.target

[Service]
Type=simple
# Launch in dedicated terminal window
ExecStart=/usr/bin/alacritty --class screensaver -e 16c-screensaver
# Or Ghostty:
# ExecStart=/usr/bin/ghostty --class screensaver -e 16c-screensaver

Restart=no

[Install]
WantedBy=default.target
```

**Idle Detection Integration** (hypridle example):
```
timeout 300
  on-timeout systemctl --user start 16c-screensaver.service
on-resume systemctl --user stop 16c-screensaver.service
```

**Hyprland Window Rules** (for fullscreen):
```
# In ~/.config/hypr/hyprland.conf
windowrulev2 = fullscreen, class:^(screensaver)$
windowrulev2 = noblur, class:^(screensaver)$
windowrulev2 = noshadow, class:^(screensaver)$
```

## CLI Usage Examples

### Basic Usage
```bash
# Start screensaver (runs until keyboard input)
16c-screensaver

# Use alias
16colo-screensaver

# Test mode (display one artwork then exit)
16c-screensaver --test

# Instant rendering (no streaming animation)
16c-screensaver --instant
```

### Configuration Options
```bash
# Specify duration per artwork (seconds)
16c-screensaver --duration 60

# Streaming speed
16c-screensaver --speed instant    # No animation
16c-screensaver --speed 1200baud   # Slow (authentic dialup feel)
16c-screensaver --speed 9600baud   # Fast

# Render mode
16c-screensaver --mode fit         # Scale to fit (default)
16c-screensaver --mode fill        # Crop to fill screen
16c-screensaver --mode native      # Original size, crop if needed

# Show/hide metadata overlay
16c-screensaver --show-metadata
16c-screensaver --no-metadata
```

### Filtering
```bash
# Only 1990s artwork
16c-screensaver --year-min 1990 --year-max 1999

# Specific groups
16c-screensaver --groups mistigris,blocktronics

# Specific formats
16c-screensaver --formats ans,asc

# Exclude NSFW
16c-screensaver --no-nsfw
```

### Setup and Testing
```bash
# Install systemd service
16c-screensaver --install-service

# Test configuration
16c-screensaver --test-config

# Preview mode (short duration, exit after 3 artworks)
16c-screensaver --preview
```

## Installation Guide

### Prerequisites
```bash
# Ensure 16colors mirror is set up
16c mirror sync --since 2020

# Install terminal (Alacritty or Ghostty recommended)
# Alacritty: pacman -S alacritty
# Ghostty: yay -S ghostty-git
```

### Systemd Setup
```bash
# Install systemd service
16c-screensaver --install-service

# Configure hypridle (for Hyprland users)
cat >> ~/.config/hypr/hypridle.conf << 'EOF'
timeout 300
  on-timeout systemctl --user start 16c-screensaver.service
on-resume systemctl --user stop 16c-screensaver.service
EOF

# Reload systemd
systemctl --user daemon-reload

# Test service
systemctl --user start 16c-screensaver.service
# Press any key to exit
```

### Configuration
```bash
# Generate default config
16c-screensaver --init-config

# Edit config
$EDITOR ~/.config/16c/screensaver.toml
```

## User Stories

### Story 1: Retro Computing Enthusiast
**As a** retro computing enthusiast  
**I want** my idle terminal to showcase classic BBS art with authentic dialup-style rendering  
**So that** I can enjoy the nostalgia and share the art scene with others

**Acceptance Criteria**:
- Screensaver activates after 5 minutes idle
- Artwork streams line-by-line at configurable speed
- Displays artist and pack name subtly
- Exits cleanly on any keyboard input

### Story 2: Art Collector
**As a** text art collector  
**I want** to curate a custom selection of artwork for my screensaver  
**So that** I can showcase my favorite pieces from specific groups or eras

**Acceptance Criteria**:
- Configuration file supports year/group/artist filters
- Only artwork matching filters is displayed
- Artwork list is cached for instant startup
- Configuration changes take effect on next run

### Story 3: Hyprland User
**As a** Hyprland user  
**I want** the screensaver to integrate with hypridle  
**So that** it activates automatically and respects power management

**Acceptance Criteria**:
- Systemd service installs easily
- Hypridle configuration provided in docs
- Fullscreen window rules work out of box
- DPMS events are respected

### Story 4: Minimal Distractions
**As a** minimalist user  
**I want** the screensaver to display artwork without overlays or animations  
**So that** I can enjoy clean, unmodified artwork

**Acceptance Criteria**:
- `--instant` flag disables streaming animation
- `--no-metadata` hides artist/pack overlay
- Native mode displays artwork at original size
- No unnecessary visual effects or borders

## Acceptance Criteria (EARS Patterns)

### AC1: Basic Screensaver Operation
- WHEN the user runs `16c-screensaver` the terminal shall enter fullscreen mode
- The system shall display a random artwork from the local mirror
- The artwork shall render with streaming animation (unless `--instant` specified)
- WHEN the user presses any key the screensaver shall exit cleanly
- The terminal state shall be fully restored on exit

### AC2: Artwork Sizing and Centering
- WHEN artwork is smaller than terminal the artwork shall be centered without black bars
- WHEN artwork is larger than terminal the artwork shall scale to fit (maintaining aspect ratio)
- SAUCE metadata width/height shall override auto-detection
- Aspect ratio hints from SAUCE shall be applied
- Terminal resize events shall trigger re-centering

### AC3: Configuration and Filtering
- WHEN `~/.config/16c/screensaver.toml` exists the settings shall be applied
- Year/group/artist filters shall limit artwork selection
- Streaming speed setting shall control render timing
- Metadata overlay toggle shall show/hide artist information
- Missing config shall use sensible defaults

### AC4: Systemd Integration
- The `--install-service` command shall create a systemd user service
- The service shall launch the screensaver in a dedicated terminal window
- Hypridle integration shall activate/deactivate the service
- DPMS events shall be respected
- Service shall stop cleanly on user input

### AC5: Mirror Integration
- The screensaver shall discover the local 16colors mirror automatically
- WHERE no mirror exists the system shall display a helpful error message
- `.16colors-meta.json` files shall be read for artist/pack/date information
- Artwork list shall be cached for performance
- Cache shall rebuild when mirror changes detected

## Success Metrics

### SM1: User Experience
- Screensaver activates within 1 second of invocation
- Artwork selection feels random and varied
- Streaming animation speed matches configured baud rate simulation
- Exit is instant on any keyboard input
- No visual glitches or artifacts during rendering

### SM2: Integration Quality
- Systemd service installs without errors
- Hypridle/swayidle integration works out of box
- Fullscreen window rules apply correctly
- DPMS power management is respected
- Configuration changes take effect without restart

### SM3: Performance
- Artwork list cache loads in < 100ms
- Mirror discovery completes in < 200ms
- Terminal resize handling is smooth (no flicker)
- Memory usage remains stable during long runs
- CPU usage is minimal when idle between artworks

### SM4: Flexibility
- Users can filter to specific years/groups/artists
- Streaming speed is adjustable from instant to slow dialup
- Metadata overlay can be toggled on/off
- Render modes support different artwork sizes
- Configuration is easy to understand and modify

## Testing Requirements

### Unit Tests
- Artwork selection algorithm (random, filtered)
- Configuration file parsing (TOML)
- Terminal size detection
- Canvas sizing calculations (fit/fill/native modes)
- SAUCE metadata extraction
- Cache invalidation logic

### Integration Tests
- End-to-end screensaver run (spawn, display, exit)
- Configuration file application
- Mirror discovery and artwork enumeration
- Systemd service installation
- Signal handling (SIGINT, SIGTERM)
- Terminal state restoration

### Manual Tests
- Visual inspection of artwork centering
- Streaming animation timing verification
- Metadata overlay positioning
- Fullscreen behavior in different terminals
- Hypridle integration testing
- Long-running stability test

## Implementation Notes

### Architecture
```
16c-screensaver (CLI)
    ↓
Configuration Loading (~/.config/16c/screensaver.toml)
    ↓
Mirror Discovery (~/Pictures/16colors/ or ~/.local/share/16colors/)
    ↓
Artwork Selection (random + filters)
    ↓
Terminal Setup (fullscreen, hide cursor)
    ↓
Loop:
    Render Artwork (via ansilust renderer)
    Wait (configurable duration)
    Check Input (non-blocking)
    ↓
    Exit if input detected
    ↓
Cleanup (restore terminal, show cursor)
```

### Technology Stack
- **Language**: Zig (consistency with ansilust)
- **Config**: TOML parsing (zig-toml or similar)
- **Terminal**: ANSI escape sequences, termios
- **Rendering**: Ansilust renderer (dependency)
- **Mirror**: 16colors standard directory structure

### Phase 1: Minimal Viable Screensaver
- [x] CLI command `16c-screensaver`
- [ ] Random artwork selection from mirror
- [ ] Fullscreen terminal mode
- [ ] Exit on keyboard input
- [ ] Basic ANSI rendering (via ansilust)
- [ ] Terminal size detection

### Phase 2: Configuration and Filtering
- [ ] TOML config file support
- [ ] Year/group/artist filtering
- [ ] Streaming speed configuration
- [ ] Metadata overlay toggle
- [ ] Artwork list caching

### Phase 3: Systemd Integration
- [ ] `--install-service` command
- [ ] Systemd user service template
- [ ] Hypridle integration docs
- [ ] Fullscreen window rules
- [ ] DPMS awareness

### Phase 4: Advanced Features
- [ ] Multiple render modes (fit/fill/native)
- [ ] Transition effects between artworks
- [ ] Playlist support (curated sequences)
- [ ] Statistics tracking (most displayed artwork)
- [ ] Remote mirror support (stream from 16colo.rs)

## Dependencies

### External Dependencies
- **ansilust renderer**: Core rendering engine (in-repo)
- **16colors mirror**: Local artwork repository (user-installed)
- **Terminal**: Alacritty, Ghostty, or any modern terminal emulator
- **systemd**: User service management (Linux)
- **Idle detector**: hypridle, swayidle, xautolock, etc.

### Internal Dependencies
- **16c CLI**: Mirror sync and download functionality
- **SAUCE parser**: Metadata extraction
- **Format parsers**: ANS, ASC, XB, etc. support

## Security Considerations

- **Input validation**: Sanitize paths and config values
- **Resource limits**: Prevent excessive memory usage from large artwork
- **Signal safety**: Proper signal handler cleanup
- **File permissions**: Config file should be user-readable only
- **No network**: Screensaver operates offline (uses local mirror)

## Future Enhancements

### Advanced Rendering
- **Shader effects**: CRT scan lines, phosphor glow
- **Color cycling**: Animate palette shifts (classic BBS trick)
- **Music integration**: Play SID/MOD files from packs

### Community Features
- **Voting**: Mark favorite artwork during display
- **Statistics**: Track most viewed/favorite pieces
- **Sharing**: Generate social media posts of artwork

### Multi-Monitor
- **Span mode**: Single artwork across multiple displays
- **Independent mode**: Different artwork per monitor
- **Sync mode**: Synchronized transitions

---

**Status**: Specification Phase  
**Priority**: Medium (showcase feature)  
**Dependencies**: 16colors mirror (.specs/download/), ansilust rendering  
**Target Audience**: Linux/Hyprland users, BBS art enthusiasts, retro computing fans
