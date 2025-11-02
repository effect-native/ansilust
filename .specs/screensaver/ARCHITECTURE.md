# 16c-screensaver Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User's Desktop                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Idle Detection                          │  │
│  │  (hypridle / swayidle / xautolock)                  │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │ Idle timeout reached             │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          systemd --user                              │  │
│  │  start 16c-screensaver.service                      │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │ Launch terminal window           │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Alacritty / Ghostty (fullscreen)                   │  │
│  │  --class screensaver                                │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │         16c-screensaver                        │ │  │
│  │  │                                                │ │  │
│  │  │  ┌──────────────────────────────────────────┐ │ │  │
│  │  │  │  1. Load Config                          │ │ │  │
│  │  │  │     ~/.config/16c/screensaver.conf       │ │ │  │
│  │  │  └──────────────────────────────────────────┘ │ │  │
│  │  │                   │                            │ │  │
│  │  │  ┌────────────────▼──────────────────────────┐ │ │  │
│  │  │  │  2. Discover Mirror                       │ │ │  │
│  │  │  │     ~/Pictures/16colors/                  │ │ │  │
│  │  │  │     ~/.local/share/16colors/              │ │ │  │
│  │  │  └───────────────────────────────────────────┘ │ │  │
│  │  │                   │                            │ │  │
│  │  │  ┌────────────────▼──────────────────────────┐ │ │  │
│  │  │  │  3. Build Artwork List                    │ │ │  │
│  │  │  │     - Scan packs/YYYY/*                   │ │ │  │
│  │  │  │     - Apply filters (year/group/artist)   │ │ │  │
│  │  │  │     - Cache results                       │ │ │  │
│  │  │  └───────────────────────────────────────────┘ │ │  │
│  │  │                   │                            │ │  │
│  │  │  ┌────────────────▼──────────────────────────┐ │ │  │
│  │  │  │  4. Setup Terminal                        │ │ │  │
│  │  │  │     - Enter fullscreen                    │ │ │  │
│  │  │  │     - Hide cursor                         │ │ │  │
│  │  │  │     - Clear screen                        │ │ │  │
│  │  │  │     - Detect dimensions                   │ │ │  │
│  │  │  └───────────────────────────────────────────┘ │ │  │
│  │  │                   │                            │ │  │
│  │  │  ┌────────────────▼──────────────────────────┐ │ │  │
│  │  │  │  5. Main Loop                             │ │ │  │
│  │  │  │     ┌─────────────────────────────────┐   │ │ │  │
│  │  │  │     │ Select Random Artwork           │   │ │ │  │
│  │  │  │     └─────────────────┬───────────────┘   │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │     ┌─────────────────▼───────────────┐   │ │ │  │
│  │  │  │     │ Read .16colors-meta.json        │   │ │ │  │
│  │  │  │     │ (artist, pack, date)            │   │ │ │  │
│  │  │  │     └─────────────────┬───────────────┘   │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │     ┌─────────────────▼───────────────┐   │ │ │  │
│  │  │  │     │ Render via Ansilust             │   │ │ │  │
│  │  │  │     │ - Streaming mode (2400 baud)    │   │ │ │  │
│  │  │  │     │ - Fit to terminal               │   │ │ │  │
│  │  │  │     │ - Center artwork                │   │ │ │  │
│  │  │  │     └─────────────────┬───────────────┘   │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │     ┌─────────────────▼───────────────┐   │ │ │  │
│  │  │  │     │ Display Metadata Overlay        │   │ │ │  │
│  │  │  │     │ (if enabled)                    │   │ │ │  │
│  │  │  │     └─────────────────┬───────────────┘   │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │     ┌─────────────────▼───────────────┐   │ │ │  │
│  │  │  │     │ Wait / Check Input              │   │ │ │  │
│  │  │  │     │ - Sleep for duration            │   │ │ │  │
│  │  │  │     │ - Poll for keyboard input       │   │ │ │  │
│  │  │  │     └─────────────────┬───────────────┘   │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │                       │ Input? ──────────►│ │ │  │
│  │  │  │                       │     Exit          │ │ │  │
│  │  │  │                       │                   │ │ │  │
│  │  │  │                       │ No input          │ │ │  │
│  │  │  │                       └─────► Loop        │ │ │  │
│  │  │  │                                           │ │ │  │
│  │  │  └───────────────────────────────────────────┘ │ │  │
│  │  │                   │                            │ │  │
│  │  │  ┌────────────────▼──────────────────────────┐ │ │  │
│  │  │  │  6. Cleanup on Exit                       │ │ │  │
│  │  │  │     - Restore cursor                      │ │ │  │
│  │  │  │     - Exit fullscreen                     │ │ │  │
│  │  │  │     - Clear screen (optional)             │ │ │  │
│  │  │  └───────────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │ Terminal closes                  │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          systemd --user                              │  │
│  │  stop 16c-screensaver.service                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### 16c-screensaver (This Spec)
**Role**: Orchestrator

**Responsibilities**:
- CLI command parsing
- Configuration loading (TOML)
- Mirror discovery and artwork enumeration
- Artwork selection (random + filters)
- Terminal lifecycle (fullscreen, cursor, cleanup)
- User input detection (exit on keypress)
- Metadata overlay rendering
- Signal handling (SIGINT, SIGTERM)

**Does NOT**:
- Implement artwork rendering
- Download or sync artwork
- Parse ANS/XB/ASC formats
- Handle SAUCE metadata extraction

### Ansilust Renderer (Out of Scope)
**Role**: Rendering Engine

**Responsibilities**:
- Streaming-style rendering (line-by-line, baud rate simulation)
- Format parsing (ANS, ASC, XB, PCB, etc.)
- SAUCE metadata reading and application
- Color/palette handling (CP437, iCE colors, 24-bit RGB)
- Aspect ratio adjustments (DOS 1.35x)
- Canvas sizing and centering logic

**Interface**:
```zig
pub const RenderOptions = struct {
    streaming: bool = true,
    stream_speed: StreamSpeed = .Baud2400,
    terminal_width: usize,
    terminal_height: usize,
    center: bool = true,
    mode: RenderMode = .Fit,  // .Fit, .Fill, .Native
};

pub fn renderToTerminal(artwork_path: []const u8, options: RenderOptions) !void {
    // Implementation in ansilust core
}
```

### 16c CLI (Out of Scope)
**Role**: Mirror Management

**Responsibilities**:
- `16c mirror sync` - Full archive mirroring
- `16c download <pack>` - Individual pack downloads
- Local mirror structure creation
- `.16colors-meta.json` generation
- SAUCE metadata extraction and caching

**Directory Structure**:
```
~/Pictures/16colors/  (or ~/.local/share/16colors/)
├── packs/
│   ├── 1990/
│   ├── 1996/
│   ├── 2025/
│   │   ├── mist1025.zip
│   │   └── mist1025/
│   │       ├── .16colors-meta.json  ← Screensaver reads this
│   │       ├── FILE_ID.DIZ
│   │       └── *.ANS, *.ASC, *.XB, etc.
│   └── ...
└── .16colors-manifest.json
```

## Data Flow

### Artwork Selection Flow
```
Config Filters ─────┐
                    │
Mirror Discovery ───┤
                    │
Artwork Scan ───────┼──► Filtered List ──► Random Selection ──► Path
                    │
Cache Check ────────┘
```

### Rendering Flow
```
Artwork Path ───┐
                │
Metadata Read ──┤
                │
Terminal Size ──┼──► Render Options ──► Ansilust Renderer ──► ANSI Output
                │                                                    │
Config ─────────┘                                                    │
                                                                     ▼
                                                              Terminal Display
```

### Exit Flow
```
User Input ─────────┐
                    │
Signal (INT/TERM) ──┼──► Set Exit Flag ──► Cleanup ──► systemd Stop
                    │
Timeout ────────────┘
```

## Configuration Layers

```
1. Built-in Defaults
       │
       ▼
2. Config File (~/.config/16c/screensaver.conf)
       │
       ▼
3. CLI Flags (override all)
       │
       ▼
   Final Config
```

**Example**:
```toml
# ~/.config/16c/screensaver.conf
[general]
artwork_duration = 30
streaming_speed = "2400baud"

# Override via CLI:
$ 16c-screensaver --duration 60 --speed instant
# Result: duration=60, speed=instant (CLI wins)
```

## Signal Flow (Systemd Integration)

```
User Idle (5 min)
       │
       ▼
hypridle detects idle
       │
       ▼
systemctl --user start 16c-screensaver.service
       │
       ▼
Launch Alacritty --class screensaver -e 16c-screensaver
       │
       ▼
Hyprland window rule: fullscreen
       │
       ▼
16c-screensaver running
       │
       ├─► User presses key ──► 16c-screensaver exits
       │                              │
       └─► User moves mouse ───────►  │
                                      ▼
                         systemctl --user stop 16c-screensaver.service
                                      │
                                      ▼
                              Resume user session
```

## Caching Strategy

### Artwork List Cache

**Location**: `~/.cache/16colors-tools/ansilust/screensaver-artwork-cache.json`

**Structure**:
```json
{
  "version": 1,
  "generated_at": "2025-11-01T23:30:00Z",
  "mirror_path": "~/Pictures/16colors",
  "filters": {
    "year_min": 1990,
    "year_max": 2025,
    "groups": [],
    "exclude_nsfw": true
  },
  "artwork": [
    {
      "path": "~/Pictures/16colors/packs/2025/mist1025/CXC-STICK.ASC",
      "pack": "mist1025",
      "year": 2025,
      "artist": "Cthulu",
      "format": "asc",
      "size_bytes": 4096
    },
    ...
  ],
  "count": 12847
}
```

**Invalidation**:
- Mirror directory `mtime` changed
- Config filters changed
- TTL expired (default: 1 hour)
- Manual: `16c-screensaver --rebuild-cache`

### Performance Impact
- **Cold start** (no cache): 2-5 seconds (scan 4000+ packs)
- **Warm start** (cache hit): < 100ms (read JSON)
- **Cache miss** (outdated): Rebuild in background, use stale cache

## Error Handling

### Mirror Not Found
```
Error: No 16colors mirror found.

Expected locations:
  ~/Pictures/16colors/
  ~/.local/share/16colors/

To download artwork:
  16c mirror sync --since 2020

Or download a specific pack:
  16c download mist1025

For more info: 16c --help
```

### No Artwork Matches Filters
```
Warning: No artwork found matching filters.

Current filters:
  Year: 1990-1995
  Groups: mistigris, blocktronics
  Formats: ans, asc

Try relaxing filters in ~/.config/16c/screensaver.conf
or run without filters: 16c-screensaver --no-filters
```

### Rendering Error
```
Error: Failed to render artwork
  Path: ~/Pictures/16colors/packs/2025/mist1025/corrupted.ans
  Reason: Invalid ANSI escape sequence at byte 1234

Skipping to next artwork...
```

## Thread Model (Future Consideration)

For Phase 4+ (advanced features), consider multi-threading:

```
Main Thread
    ├─► UI Thread (input detection, terminal refresh)
    ├─► Render Thread (ansilust rendering, heavy CPU)
    └─► Cache Thread (background artwork list refresh)
```

**Current Phase 1-3**: Single-threaded (simpler, sufficient for current needs)

---

**Last Updated**: 2025-11-01  
**Status**: Architecture Design Complete
