# 16colo.rs TUI - BBS-Style Artpack Viewer

## Concept

Build a terminal-based user interface (TUI) that emulates the experience of visiting an old 1990s BBS to download and view artpacks. The application should feel authentically retro while leveraging modern technology for reliability and performance.

## Core Experience

Users should feel like they've dialed into a classic BBS through a slow modem connection, experiencing the nostalgia of:
- Character-by-character text drawing
- Slow ANSI art reveals
- Classic BBS menus and navigation
- The anticipation of downloading artpacks
- The satisfaction of browsing freshly downloaded art

## Key Features

### 1. Dual-Speed Architecture

The application operates on two distinct speed layers:

**Fast Layer (Backend)**:
- Download artpacks from 16colo.rs at full modern internet speeds
- Pre-fetch and cache data efficiently
- Process and index metadata in the background
- No actual delays in data transfer

**Slow Layer (Presentation)**:
- Emulate 2400-9600 baud modem speeds for visual rendering
- Character-by-character text drawing
- Line-by-line ANSI art reveals
- Classic "downloading..." progress indicators with retro animations
- Configurable speed settings (2400, 9600, 14400, 28800 baud)

### 2. BBS Interface

**Main Menu Style**:
```
╔═══════════════════════════════════════════════════════════╗
║                    16COLO.RS BBS                          ║
║                                                           ║
║  [A]rtpack Browser                                        ║
║  [S]earch Archive                                         ║
║  [R]andom Art                                             ║
║  [D]ownload Manager                                       ║
║  [F]avorites                                              ║
║  [O]ptions (Connection Speed)                             ║
║  [Q]uit                                                   ║
║                                                           ║
║  Choose an option: _                                      ║
╚═══════════════════════════════════════════════════════════╝
```

**Navigation**:
- Classic single-key commands (A, S, R, D, F, Q)
- Arrow key navigation in lists
- Hotkeys for common actions
- Status bar showing connection speed and time

### 3. Artpack Browser

**Browse by**:
- Year (1990s-present)
- Art group (ACiD, iCE, Blocktronics, etc.)
- Artist name
- Format type
- Newest releases

**Display**:
- List view with metadata
- Preview pane (rendered at emulated speed)
- Artpack details (size, file count, release date)
- Download indicator when pre-fetching

### 4. Download Simulation

**Visual Experience**:
```
Connecting to 16colo.rs...
[####################################] 100%

Downloading ACID-1996.ZIP...
[####################                ] 67% (1.2MB/1.8MB)
ETA: 00:45 @ 2400 baud

Extracting files...
[####################################] 100%

138 files extracted successfully!
```

**Actual Behavior**:
- Artpack downloads immediately in background
- Progress bar animates at emulated modem speed
- Creates artificial ETA based on configured baud rate
- Files are available instantly once "download" completes

### 5. Art Viewer

**Features**:
- Full-screen ANSI art display
- Reveal animation (line-by-line at configured speed)
- Skip animation option (space bar)
- Next/Previous navigation (arrow keys, vim keys)
- Metadata overlay (F1 - artist, date, format, size)
- Screenshot/export option
- Return to browser (ESC)

**Rendering**:
- Use ansilust renderer for perfect CP437 display
- Support all ansilust-compatible formats
- Smooth scrolling for oversized art
- Zoom in/out capability

### 6. Connection Speed Settings

**Emulated Speeds**:
- 300 baud (ultra-slow, mostly for laughs)
- 1200 baud (early modems)
- 2400 baud (common 90s speed)
- 9600 baud (faster 90s connection)
- 14400 baud (V.32bis)
- 28800 baud (V.34)
- 56K (late 90s)
- Instant (disable emulation)

**What Speed Affects**:
- ANSI art reveal speed
- Menu text drawing speed
- Progress bar animation speed
- "Download" indicator timing
- NOT actual data transfer (always instant)

### 7. Aesthetic Details

**Visual Elements**:
- CP437 box-drawing characters
- DOS color palette (16 colors)
- Authentic ANSI art styling
- Classic cursor blinking
- Status indicators using ASCII art
- Screen transitions (fade, scroll)

**Sound Effects (Optional)**:
- Modem handshake sound on startup
- Key click sounds
- Download progress beeps
- "You've got art!" notification

## Technical Architecture

### Backend Components

**Data Layer**:
- 16colo.rs API integration
- Local cache for downloaded artpacks
- SQLite database for metadata indexing
- Fast pre-fetch queue
- Background sync service

**Rendering Layer**:
- Ansilust integration for art rendering
- Character-by-character output buffer
- Timing engine for speed emulation
- Frame-based animation system

**TUI Framework**:
- vaxis (Zig TUI library) or similar
- Event-driven input handling
- Async I/O for non-blocking operations
- Multi-threaded: UI thread + download thread

### Speed Emulation Engine

**Implementation**:
```zig
const BaudRate = enum {
    baud_300,
    baud_1200,
    baud_2400,
    baud_9600,
    baud_14400,
    baud_28800,
    baud_56k,
    instant,

    pub fn charsPerSecond(self: BaudRate) f64 {
        return switch (self) {
            .baud_300 => 30.0,
            .baud_1200 => 120.0,
            .baud_2400 => 240.0,
            .baud_9600 => 960.0,
            .baud_14400 => 1440.0,
            .baud_28800 => 2880.0,
            .baud_56k => 5600.0,
            .instant => std.math.inf(f64),
        };
    }

    pub fn delayBetweenChars(self: BaudRate) u64 {
        // Returns nanoseconds between characters
        const cps = self.charsPerSecond();
        if (std.math.isInf(cps)) return 0;
        return @intFromFloat(1_000_000_000.0 / cps);
    }
};
```

**Character Output**:
- Buffer complete output (pre-rendered)
- Emit character-by-character with timing delays
- Allow skip/fast-forward with key press
- Instant mode for impatient users

### File Organization

```
TODO/
└── 16colors-tui-bbs-viewer.md  (this file)

Future Implementation:
src/
├── tui/
│   ├── main.zig           # Application entry point
│   ├── bbs_interface.zig  # BBS-style menus
│   ├── art_viewer.zig     # Full-screen art display
│   ├── browser.zig        # Artpack browsing
│   ├── speed_emulator.zig # Baud rate emulation
│   └── effects.zig        # Visual effects
└── backend/
    ├── sixteencolors_api.zig  # API client
    ├── cache.zig              # Local caching
    ├── downloader.zig         # Background downloads
    └── indexer.zig            # Metadata indexing
```

## User Scenarios

### Scenario 1: First-Time User
1. Launch application (modem handshake sound plays)
2. Main menu draws character-by-character
3. User presses 'A' for Artpack Browser
4. Browser menu animates in at configured speed
5. User browses by year → 1996
6. Sees list of 1996 artpacks (ACiD, iCE, Fire, etc.)
7. Selects ACiD 1996
8. "Downloading..." animation plays (artpack pre-cached instantly)
9. File list appears
10. User selects US-JELLY.ANS
11. Art reveals line-by-line at 2400 baud speed
12. User enjoys the nostalgia

### Scenario 2: Power User
1. Launch with instant mode enabled
2. Main menu appears immediately
3. User presses 'R' for random art
4. Random artwork displays instantly
5. User cycles through art rapidly with arrow keys
6. User switches to 9600 baud for authentic feel
7. Art reveals at medium speed

### Scenario 3: Download Marathon
1. User queues 20 artpacks for "download"
2. Each downloads in background at full speed
3. UI shows slow progress bars for nostalgia
4. User browses already-downloaded art while "waiting"
5. All artpacks available instantly once UI catches up

## Development Phases

### Phase 1: MVP
- [ ] Basic TUI with main menu
- [ ] Simple art viewer (no emulation)
- [ ] 16colo.rs API integration
- [ ] Local cache system
- [ ] Browse by year/group

### Phase 2: Speed Emulation
- [ ] Implement baud rate emulation
- [ ] Character-by-character rendering
- [ ] Download progress animation
- [ ] ANSI art line-by-line reveal

### Phase 3: Full BBS Experience
- [ ] Complete menu system
- [ ] Search functionality
- [ ] Favorites system
- [ ] Enhanced visual effects
- [ ] Configurable settings

### Phase 4: Polish
- [ ] Sound effects
- [ ] Advanced navigation
- [ ] Keyboard shortcuts
- [ ] Statistics tracking
- [ ] User preferences persistence

## Why This Matters

**Nostalgia**: Recreates authentic BBS experience for those who remember it.

**Education**: Introduces younger users to BBS culture and history.

**Preservation**: Makes 16colo.rs archive accessible and engaging.

**Performance**: Demonstrates ansilust rendering capabilities.

**Fun**: Delivers genuine enjoyment of the "slow reveal" aesthetic without actual slow downloads.

**Practical**: Best of both worlds - modern speed with retro feel.

## Implementation Notes

- Use ansilust for rendering all ANSI art
- Leverage Zig's async/await for non-blocking downloads
- SQLite for local metadata and cache tracking
- HTTP/2 for efficient API communication
- Memory-efficient streaming for large artpacks
- Configurable cache size and retention
- Optional telemetry for popular artpacks

## Inspiration

- Classic BBS systems (1990s era)
- ACiDView.exe (DOS art viewer)
- terminal.shop (modern SSH BBS)
- 16colo.rs website
- Scene art culture

## Future Enhancements

- Multi-user support (shared viewing sessions)
- Chat/comment system
- Art upload capability
- Collection management
- Artpack statistics
- Integration with other scene archives
- Mobile TUI support (termux)
- Web version with authentic terminal emulation

---

**Status**: Concept/Planning Phase  
**Priority**: Medium (showcase project)  
**Dependencies**: Ansilust rendering engine  
**Target Audience**: ANSI art enthusiasts, retro computing fans, BBS nostalgia seekers
