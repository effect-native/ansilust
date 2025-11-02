# 16c screensaver - BBS Art Terminal Screensaver

## Overview

The `16c` CLI provides built-in screensaver functionality through simple subcommands. Inspired by the Omarchy screensaver pattern (fullscreen Alacritty/Ghostty running custom ANSI script), but integrated with the ansilust/16c ecosystem for authentic retro BBS art display.

**Key Philosophy**: This screensaver showcases classic BBS art with streaming-style rendering that evokes the dialup modem experience. It reuses the existing `16c` CLI rather than creating a separate command.

**CLI Commands**:
- `16c` - Shows usage information
- `16c random` - Continuously streams random artwork (the heart of the screensaver)
- `16c random-1` - Prints one random artwork as fast as possible and exits
- `16c screensaver` - Like `16c random` but with fullscreen mode and exit-on-input handling

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
FR1.1.1: The system shall provide `16c random` to continuously stream random artwork.  
FR1.1.2: The system shall provide `16c random-1` to display one random artwork and exit.  
FR1.1.3: The system shall provide `16c screensaver` for fullscreen screensaver mode.  
FR1.1.4: WHEN `16c screensaver` is invoked the system shall enter fullscreen mode.  
FR1.1.5: WHEN `16c screensaver` is running the system shall exit on any keyboard input.  
FR1.1.6: The system shall exit cleanly on SIGINT/SIGTERM/SIGHUP/SIGQUIT signals.

### FR1.2: Artwork Selection and Display
FR1.2.1: WHEN `16c random` or `16c screensaver` is invoked the system shall randomly select artwork from the local mirror.  
FR1.2.2: WHERE the local mirror contains artwork the system shall display it immediately.  
FR1.2.3: WHERE the local mirror is empty the system shall display a helpful error and offer to bootstrap.  
FR1.2.4: The `16c random` command shall cycle through artworks with reasonable viewing time between pieces.  
FR1.2.5: The `16c random-1` command shall display one artwork at maximum speed and exit.  
FR1.2.6: WHEN displaying artwork the system shall use ansilust rendering (not raw ANSI dump).  
FR1.2.7: The system shall support all ansilust-compatible formats (ANS, ASC, XB, etc.).

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
FR1.5.1: The system shall support a configuration file at `~/.config/16c/config.toml`.  
FR1.5.2: The configuration shall support artwork filters (year, group, artist, format).  
FR1.5.3: The configuration shall support timing settings (seconds per artwork, streaming speed).  
FR1.5.4: The configuration shall support metadata overlay (artist, pack, date) toggle.  
FR1.5.5: WHERE no configuration exists the system shall use sensible defaults.  
FR1.5.6: Configuration settings shall apply to `16c random`, `16c random-1`, and `16c screensaver`.

### FR1.6: Mirror Bootstrap and Background Sync
FR1.6.1: WHERE the local mirror has pre-cached artwork the system shall display it immediately (no waiting).  
FR1.6.2: WHERE the local mirror is empty the system shall display a helpful message and begin bootstrap.  
FR1.6.3: WHEN bootstrap begins the system shall download curated artwork in background.  
FR1.6.4: WHEN bootstrap downloads complete the system shall add them to the rotation seamlessly.  
FR1.6.5: AFTER initial packs download the system shall begin background sync of mirror metadata.  
FR1.6.6: WHILE displaying artwork the system shall continue downloading additional packs in background.  
FR1.6.7: IF offline AND pre-cached artwork exists the system shall continue displaying indefinitely.  
FR1.6.8: IF offline AND no artwork exists the system shall provide clear instructions to user.  
FR1.6.9: The system shall respect mirror organization (packs by year).  
FR1.6.10: WHEN artwork is selected the system shall read associated `.16colors-meta.json` for metadata.  
FR1.6.11: The system shall cache artwork list for performance (rebuild on mirror changes).

### FR1.7: Systemd/Idle Integration
FR1.7.1: The system shall provide documentation for systemd user service integration.  
FR1.7.2: The service template shall launch `16c screensaver` in a dedicated terminal window.  
FR1.7.3: The service shall support activation via idle detection hooks (hypridle/swayidle).  
FR1.7.4: The service shall respect DPMS power management settings.

## Out of Scope (Dependencies)

These features are **explicitly out of scope** for this spec and rely on other ansilust features:

### Relies on: 16colors Download/Mirror (.specs/download/)
- `16c mirror sync` - Full archive mirroring (manual, advanced users)
- `16c download <pack>` - Individual pack downloads (manual)
- Local mirror structure (`~/Pictures/16colors/` or `~/.local/share/16colors/`)
- `.16colors-meta.json` metadata format
- SAUCE metadata extraction

**Note**: The screensaver uses the download/mirror infrastructure but adds **bootstrap** and **background sync** functionality for zero-wait user experience

### Relies on: Ansilust Rendering
- **Streaming-style rendering** - The exact implementation of line-by-line or character-by-character rendering with timing control
- **Format parsing** - ANS, ASC, XB, PCB, etc. parsers
- **SAUCE metadata handling** - Reading rendering hints from SAUCE records
- **Color/font handling** - CP437, palette, iCE colors mode
- **Aspect ratio** - Respecting DOS aspect ratio (1.35x) hints

**Design Decision**: The screensaver spec focuses on **orchestration** (selecting artwork, handling terminal lifecycle, user input, background downloads) while delegating **rendering mechanics** to the core ansilust system. This maintains clean separation of concerns and ensures rendering improvements automatically benefit the screensaver.

### Zero-Wait Design Philosophy

**Problem**: Traditional screensavers fail if artwork isn't available (missing mirror, offline, fresh install).

**Solution**: Progressive enhancement with pre-cached artwork:

```
Install Package
    ↓
Post-install script runs
    ↓
    Extract pre-cached artwork to mirror location
    ↓
    Generate .16colors-meta.json files
    ↓
    User ready to run immediately
    ↓
Run `16c random` or `16c screensaver`
    ↓
┌─────────────────────────────────────┐
│ Mirror has artwork?                 │
├─────────────────────────────────────┤
│ YES → Display immediately           │
│ NO  → Show helpful error + bootstrap│
└─────────────────────────────────────┘
    ↓
Display artwork immediately (NO WAIT)
    ↓
IF user wants more artwork:
    ↓
    Run `16c random` (starts background sync automatically)
        ↓
        Background Thread: Download curated packs
        ↓
        Download favorites (async)
        ↓
        Extract and index
        ↓
        Add to rotation seamlessly
    ↓
    Background Thread: Continue mirror sync
        ↓
        Download additional packs (throttled)
        ↓
        Build full mirror over time
```

**Key Principles**:
1. **Never block the user** - Post-install pre-caches artwork
2. **Standard mirror location** - Pre-cached art lives in normal mirror structure
3. **Progressive enhancement** - Download more artwork in background during use
4. **Offline resilient** - Works indefinitely with pre-cached artwork
5. **Seamless growth** - Mirror expands transparently while viewing

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

**Location**: `~/.config/16c/config.toml`

**Format**: TOML
```toml
[display]
artwork_duration = 30          # Seconds per artwork (16c random/screensaver)
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

**User Service Example**: `~/.config/systemd/user/16c-screensaver.service`
```ini
[Unit]
Description=16colors BBS Art Screensaver
After=graphical-session.target

[Service]
Type=simple
# Launch in dedicated terminal window
ExecStart=/usr/bin/alacritty --class screensaver -e 16c screensaver
# Or Ghostty:
# ExecStart=/usr/bin/ghostty --class screensaver -e 16c screensaver

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

**Shell Script Wrapper** (like omarchy-launch-screensaver):
```bash
#!/bin/bash
# Exit early if 16c not installed
command -v 16c &>/dev/null || exit 1

# Exit if already running
pgrep -f "alacritty --class screensaver.*16c screensaver" && exit 0

# Launch on each monitor
for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hyprctl dispatch focusmonitor $m
  hyprctl dispatch exec -- alacritty --class screensaver -e 16c screensaver
done
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
# Show usage information
16c

# Display one random artwork (fast) and exit
16c random-1

# Continuously stream random artwork (reasonable viewing pace)
16c random

# Fullscreen screensaver mode (exits on any input)
16c screensaver
```

### Configuration Options
All configuration is shared across `16c random`, `16c random-1`, and `16c screensaver` via `~/.config/16c/config.toml`.

```bash
# Example config file
cat > ~/.config/16c/config.toml << 'EOF'
[display]
artwork_duration = 30
streaming_speed = "2400baud"
show_metadata = true

[filters]
year_min = 1990
year_max = 2025
groups = ["mistigris", "blocktronics"]
formats = ["ans", "asc"]
exclude_nsfw = true
EOF

# Test with random artwork
16c random-1

# Run screensaver with config
16c screensaver
```

### Systemd Service Setup
```bash
# Create user service directory
mkdir -p ~/.config/systemd/user

# Create service file
cat > ~/.config/systemd/user/16c-screensaver.service << 'EOF'
[Unit]
Description=16colors BBS Art Screensaver
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/alacritty --class screensaver -e 16c screensaver
Restart=no

[Install]
WantedBy=default.target
EOF

# Reload systemd
systemctl --user daemon-reload

# Test the service
systemctl --user start 16c-screensaver.service
# Press any key to exit
```

## Installation Guide

### Prerequisites
```bash
# Install 16c (part of ansilust)
# Build from source or install package

# Ensure 16colors mirror is set up
16c mirror sync --since 2020

# Install terminal (Alacritty or Ghostty recommended)
# Alacritty: pacman -S alacritty
# Ghostty: yay -S ghostty-git

# Test basic functionality
16c random-1  # Should display one random artwork
```

### Systemd Setup (Manual)
```bash
# Create service file (see example above)
mkdir -p ~/.config/systemd/user
$EDITOR ~/.config/systemd/user/16c-screensaver.service

# Configure hypridle (for Hyprland users)
cat >> ~/.config/hypr/hypridle.conf << 'EOF'
timeout 300
  on-timeout systemctl --user start 16c-screensaver.service
on-resume systemctl --user stop 16c-screensaver.service
EOF

# Reload and test
systemctl --user daemon-reload
systemctl --user start 16c-screensaver.service
```

### Configuration
```bash
# Create config directory
mkdir -p ~/.config/16c

# Edit config (create if doesn't exist)
$EDITOR ~/.config/16c/config.toml

# Test config
16c random-1
```

## User Stories

### Story 1: Retro Computing Enthusiast
**As a** retro computing enthusiast  
**I want** my idle terminal to showcase classic BBS art with authentic dialup-style rendering  
**So that** I can enjoy the nostalgia and share the art scene with others

**Acceptance Criteria**:
- Fresh install works immediately with bundled artwork (no setup required)
- Screensaver activates after 5 minutes idle
- Artwork streams line-by-line at configurable speed
- Displays artist and pack name subtly
- Exits cleanly on any keyboard input
- Background downloads curated favorites without disrupting viewing

### Story 2: Art Collector
**As a** text art collector  
**I want** to curate a custom selection of artwork for my screensaver  
**So that** I can showcase my favorite pieces from specific groups or eras

**Acceptance Criteria**:
- Fresh install shows curated bundled artwork immediately (no manual download)
- Configuration file supports year/group/artist filters
- Only artwork matching filters is displayed (bundled + mirror)
- Artwork list is cached for instant startup
- Configuration changes take effect on next run
- Background bootstrap expands collection transparently

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

### AC1: Basic Commands Operation
- WHEN the user runs `16c random-1` the system shall display one random artwork and exit
- WHEN the user runs `16c random` the system shall continuously stream random artwork
- WHEN the user runs `16c screensaver` the terminal shall enter fullscreen mode
- The system shall display random artwork from the local mirror
- WHEN in screensaver mode AND the user presses any key the system shall exit cleanly
- The terminal state shall be fully restored on screensaver exit

### AC2: Artwork Sizing and Centering
- WHEN artwork is smaller than terminal the artwork shall be centered without black bars
- WHEN artwork is larger than terminal the artwork shall scale to fit (maintaining aspect ratio)
- SAUCE metadata width/height shall override auto-detection
- Aspect ratio hints from SAUCE shall be applied
- Terminal resize events shall trigger re-centering

### AC3: Configuration and Filtering
- WHEN `~/.config/16c/config.toml` exists the settings shall be applied
- Configuration shall apply to `16c random`, `16c random-1`, and `16c screensaver`
- Year/group/artist filters shall limit artwork selection
- Streaming speed setting shall control render timing
- Metadata overlay toggle shall show/hide artist information
- Missing config shall use sensible defaults

### AC4: Systemd Integration
- The documentation shall provide systemd user service template
- The service template shall launch `16c screensaver` in a dedicated terminal window
- Hypridle integration shall activate/deactivate the service
- DPMS events shall be respected
- Service shall stop cleanly when `16c screensaver` exits on user input

### AC5: Zero-Wait Pre-cache
- WHEN package is installed the post-install script shall pre-cache curated artwork
- Pre-cached artwork shall be placed in standard mirror location
- WHEN first run the system shall display pre-cached artwork immediately
- Background bootstrap shall download additional packs without blocking display
- WHEN a pack download completes the system shall add it to rotation seamlessly
- `.16colors-meta.json` files shall be read for artist/pack/date information
- Artwork list shall be cached for performance
- Cache shall rebuild when mirror changes detected

### AC6: Offline Resilience  
- WHEN offline the system shall work indefinitely with pre-cached artwork
- WHERE pre-cache failed AND offline the system shall display helpful error
- Network failures shall not interrupt artwork display
- Background downloads shall retry gracefully with exponential backoff
- The system shall detect when network becomes available and resume bootstrap

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
16c random|random-1|screensaver
    ↓
Configuration Loading (~/.config/16c/config.toml)
    ↓
Mirror Discovery (~/Pictures/16colors/ or ~/.local/share/16colors/)
    ↓
Artwork Selection (random + filters)
    ↓
IF screensaver mode: Terminal Setup (fullscreen, hide cursor)
    ↓
Loop (or once for random-1):
    Render Artwork (via ansilust renderer)
    IF random|screensaver: Wait (configurable duration)
    IF screensaver: Check Input (non-blocking, exit on any key)
    ↓
    IF random-1: Exit after one artwork
    IF screensaver AND input detected: Exit
    IF random: Continue loop
    ↓
Cleanup (restore terminal if screensaver mode)
```

### Technology Stack
- **Language**: Zig (consistency with ansilust)
- **Config**: TOML parsing (zig-toml or similar)
- **Terminal**: ANSI escape sequences, termios
- **Rendering**: Ansilust renderer (dependency)
- **Mirror**: 16colors standard directory structure

### Phase 1: Pre-cache and Basic Display
- [ ] Create curated artwork archive for pre-caching (~50-100 pieces, 1-2MB compressed)
- [ ] Post-install script to extract pre-cache to standard mirror location
- [ ] Package manager integration (Debian, Arch, Homebrew post-install hooks)
- [ ] CLI command `16c random-1` - Display one random artwork and exit
- [ ] CLI command `16c random` - Continuously stream random artwork
- [ ] CLI command `16c screensaver` - Fullscreen mode with exit-on-input
- [ ] Random artwork selection from mirror (includes pre-cached)
- [ ] Helpful error message when no artwork available
- [ ] Fullscreen terminal mode (screensaver only)
- [ ] Exit on keyboard input (screensaver only)
- [ ] Basic ANSI rendering (via ansilust)
- [ ] Terminal size detection

### Phase 2: Bootstrap and Background Sync
- [ ] Bootstrap manifest download (ansilust-bootstrap.json from 16colo.rs)
- [ ] Background thread for pack downloads (non-blocking)
- [ ] Curated pack downloads (4-5 hand-picked favorites)
- [ ] Seamless integration of downloaded artwork into rotation
- [ ] Offline detection and graceful fallback to bundled artwork
- [ ] Download throttling and rate limiting
- [ ] Progress indication (subtle, non-intrusive)

### Phase 3: Configuration and Filtering
- [ ] TOML config file support (~/.config/16c/config.toml)
- [ ] Year/group/artist filtering
- [ ] Streaming speed configuration
- [ ] Metadata overlay toggle
- [ ] Artwork list caching
- [ ] Mirror discovery and preference

### Phase 4: Systemd Integration
- [ ] Systemd user service documentation and templates
- [ ] Hypridle integration docs
- [ ] Fullscreen window rules (Hyprland/Sway)
- [ ] DPMS awareness
- [ ] Multi-monitor support examples

### Phase 5: Advanced Features
- [ ] Multiple render modes (fit/fill/native)
- [ ] Full mirror background sync (after bootstrap)
- [ ] Transition effects between artworks
- [ ] Playlist support (curated sequences)
- [ ] Statistics tracking (most displayed artwork)
- [ ] Download progress UI (optional, configurable)

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

### FR1.8: Pre-cached Artwork
FR1.8.1: The installation package shall include a curated selection of artwork for pre-caching.  
FR1.8.2: The pre-cached artwork shall represent high-quality pieces across different eras and styles.  
FR1.8.3: The pre-cached artwork shall be hand-picked favorites suitable for first impression.  
FR1.8.4: WHEN the package is installed a post-install script shall populate the local mirror with pre-cached artwork.  
FR1.8.5: The pre-cached artwork shall be placed in the standard mirror location (`~/Pictures/16colors/` or `~/.local/share/16colors/`).  
FR1.8.6: The pre-cached artwork shall be sufficient for indefinite offline usage.  
FR1.8.7: WHERE pre-cached artwork is displayed the system shall show metadata from `.16colors-meta.json`.

### FR1.9: Background Download Management
FR1.9.1: WHEN bootstrap begins the system shall download curated packs asynchronously.  
FR1.9.2: The download process shall not block artwork display.  
FR1.9.3: WHEN a download completes the system shall extract and index the artwork.  
FR1.9.4: The newly available artwork shall appear in rotation on next selection cycle.  
FR1.9.5: IF download fails the system shall continue with available artwork (bundled or previously downloaded).  
FR1.9.6: The system shall prioritize user experience (smooth display) over download speed.  
FR1.9.7: WHERE bandwidth is limited the system shall throttle downloads to avoid disrupting system performance.

### Pre-cached Artwork Strategy

**Package Structure**:
```
ansilust-package/
├── bin/
│   └── 16c                           # CLI binary
├── share/
│   └── ansilust/
│       └── precache/
│           ├── packs/
│           │   ├── favorites.tar.zst  # Curated artwork archive
│           │   └── manifest.json      # Pack metadata
│           └── install.sh             # Post-install script
```

**Post-Install Script** (`install.sh`):
```bash
#!/bin/bash
# Post-install script to pre-cache artwork

# Determine mirror location (platform-specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
    MIRROR_BASE="$HOME/Pictures/16colors"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    MIRROR_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/16colors"
else
    MIRROR_BASE="$HOME/.local/share/16colors"
fi

PRECACHE_SOURCE="/usr/share/ansilust/precache"
MIRROR_PACKS="$MIRROR_BASE/packs"

# Create mirror structure
mkdir -p "$MIRROR_PACKS"

# Extract pre-cached favorites
if [[ -f "$PRECACHE_SOURCE/packs/favorites.tar.zst" ]]; then
    echo "Pre-caching curated artwork to $MIRROR_BASE..."
    
    # Extract to mirror location
    tar --zstd -xf "$PRECACHE_SOURCE/packs/favorites.tar.zst" -C "$MIRROR_PACKS"
    
    # Copy metadata
    if [[ -f "$PRECACHE_SOURCE/packs/manifest.json" ]]; then
        cp "$PRECACHE_SOURCE/packs/manifest.json" "$MIRROR_BASE/.precache-manifest.json"
    fi
    
    echo "Pre-cached $(find "$MIRROR_PACKS" -name "*.ans" -o -name "*.asc" -o -name "*.xb" | wc -l) artworks"
    echo "Run '16c random-1' to test!"
fi
```

**Curated Selection Criteria**:
1. **High quality** - Visually impressive pieces that represent BBS art at its best
2. **Diverse eras** - Mix of 1990s classics and modern pieces (2010s-2020s)
3. **Varied styles** - ASCII, ANSI, block art, scene art, underground
4. **Iconic groups** - ACiD, iCE, Blocktronics, Mistigris, etc.
5. **Safe content** - No NSFW, suitable for professional/public display
6. **Reasonable size** - ~50-100 pieces, compressed to ~1-2MB in package

**Pre-cache Archive Contents**:
```
favorites.tar.zst (compressed)
└── packs/
    ├── 1994/
    │   └── acid-classics/
    │       ├── .16colors-meta.json
    │       ├── acid-trip.ans
    │       ├── rad-logo.ans
    │       └── ...
    ├── 1995/
    │   └── ice-favorites/
    │       ├── .16colors-meta.json
    │       ├── ice-logo.ans
    │       └── ...
    ├── 2024/
    │   └── bloc0524/
    │       ├── .16colors-meta.json
    │       └── ... (selection from recent Blocktronics)
    └── 2025/
        └── mist1025/
            ├── .16colors-meta.json
            └── ... (selection from recent Mistigris)
```

**Manifest Format**:
```json
{
  "version": "1.0.0",
  "created_at": "2025-11-02T00:00:00Z",
  "curated_by": "ansilust",
  "description": "Hand-picked favorites for instant screensaver experience",
  "packs": [
    {
      "name": "acid-classics",
      "year": 1994,
      "group": "ACiD",
      "piece_count": 12,
      "description": "Classic ACiD artwork from the golden era"
    },
    {
      "name": "ice-favorites",
      "year": 1995,
      "group": "iCE",
      "piece_count": 15,
      "description": "iCE Draw masterpieces"
    }
  ],
  "total_pieces": 73,
  "total_size_bytes": 1835008
}
```

**Package Manager Integration**:

**Debian/Ubuntu** (`debian/postinst`):
```bash
#!/bin/bash
set -e

# Run pre-cache script for user who invoked sudo
if [ -n "$SUDO_USER" ]; then
    su - "$SUDO_USER" -c "/usr/share/ansilust/precache/install.sh"
fi
```

**Arch Linux** (`PKGBUILD`):
```bash
post_install() {
    echo "Ansilust installed!"
    echo "Pre-cached artwork will be set up on first run for each user."
    echo "Or run: /usr/share/ansilust/precache/install.sh"
}
```

**Homebrew** (`Formula/ansilust.rb`):
```ruby
def post_install
  system "#{share}/ansilust/precache/install.sh"
end
```

### Background Bootstrap Process

**Bootstrap Sequence**:
```
WHEN no mirror exists:
    ↓
1. Display bundled artwork (user sees content immediately)
    ↓
2. Spawn background thread/process
    ↓
3. Check network availability
    ↓
    IF offline:
        Continue with bundled artwork indefinitely
        Periodic retry network check (every 5 min)
    ↓
    IF online:
        ↓
4. Download bootstrap manifest (small JSON file listing curated packs)
   URL: https://16colo.rs/ansilust-bootstrap.json
    ↓
5. Download curated packs (async, one at a time)
   - mist1025.zip (recent Mistigris)
   - bloc0524.zip (recent Blocktronics)
   - acid_classics.zip (curated ACiD collection)
   - ice_favorites.zip (curated iCE collection)
    ↓
6. FOR EACH downloaded pack:
    - Extract to mirror location
    - Generate .16colors-meta.json
    - Add to artwork rotation (seamless)
    - User sees new art appear naturally
    ↓
7. AFTER bootstrap complete (4-5 packs):
    - Begin background mirror sync
    - Download additional packs (throttled, low priority)
    - Build full mirror over hours/days
```

**Bootstrap Manifest Format**:
```json
{
  "version": "1.0.0",
  "curated_packs": [
    {
      "name": "mist1025",
      "year": 2025,
      "url": "https://16colo.rs/archive/2025/mist1025.zip",
      "size_bytes": 5242880,
      "checksum_sha256": "...",
      "priority": 1,
      "reason": "Recent high-quality Mistigris pack"
    },
    {
      "name": "bloc0524",
      "year": 2024,
      "url": "https://16colo.rs/archive/2024/bloc0524.zip",
      "size_bytes": 3145728,
      "checksum_sha256": "...",
      "priority": 2,
      "reason": "Recent Blocktronics artpack"
    }
  ]
}
```

**Download Throttling**:
```zig
const BootstrapDownloader = struct {
    allocator: Allocator,
    http_client: std.http.Client,
    
    const max_concurrent_downloads = 1;  // One at a time during bootstrap
    const rate_limit_bytes_per_sec = 500_000;  // 500KB/s max
    const retry_count = 3;
    const timeout_seconds = 60;
    
    pub fn downloadPack(self: *Self, pack: Pack) !void {
        // Download with rate limiting
        // Extract and index
        // Add to rotation
        // Emit progress event (optional UI feedback)
    }
};
```

**Seamless Integration**:
```zig
const ArtworkManager = struct {
    mirror_artwork: []ArtworkFile,
    
    pub fn selectRandom(self: *Self, allocator: Allocator) !ArtworkFile {
        // Load artwork from mirror (includes pre-cached + downloaded)
        if (self.mirror_artwork.len == 0) {
            // Discover mirror artwork (pre-cached or synced)
            self.mirror_artwork = try discoverMirrorArtwork(allocator);
        }
        
        if (self.mirror_artwork.len == 0) {
            // No artwork available - return error with helpful message
            return error.NoArtworkAvailable;
        }
        
        // Select random artwork from mirror
        const idx = random.int(usize) % self.mirror_artwork.len;
        return self.mirror_artwork[idx];
    }
    
    pub fn addDownloadedPack(self: *Self, allocator: Allocator, pack: Pack) !void {
        // Extract artwork from pack to mirror location
        // Rebuild mirror artwork list
        // No interruption to display loop
        // New artwork appears in next random selection
        self.mirror_artwork = try discoverMirrorArtwork(allocator);
    }
};
```

**Progress Indication** (Optional, non-blocking):
```
# While displaying pre-cached art, subtle indicator if downloading:
┌──────────────────────────────────────┐
│                                      │
│    [Artwork rendered here]           │
│                                      │
└──────────────────────────────────────┘
  Artist: RaD Man | ACiD | 1994 (pre-cached)
  ⬇ Downloading favorites... 2/5 packs
```

**Error Handling - No Artwork Available**:
```
Error: No artwork found in mirror

Your local 16colors mirror is empty.

Quick start options:
1. Re-run post-install: /usr/share/ansilust/precache/install.sh
2. Download favorites:  16c bootstrap
3. Full mirror sync:    16c mirror sync --since 2020

The screensaver works best with artwork pre-cached or downloaded.
```
