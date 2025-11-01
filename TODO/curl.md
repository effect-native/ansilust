# curl Integration - Seamless ANSI Art Streaming

## Concept

Enable ansilust to work seamlessly with curl for downloading and displaying ANSI art from the web, with intelligent caching for artpack archives. The goal is to make viewing remote ANSI art as simple as piping curl output to ansilust.

## Core Use Cases

### 1. Single File Streaming

**Basic syntax:**
```bash
curl url/to/ansi.ans | ansilust
```

**Behavior:**
- Read ANSI art from stdin when no file arguments provided
- Auto-detect format (ANSI, Binary, XBin, etc.) from content
- Render immediately to stdout
- No caching (streaming mode)

**Example:**
```bash
# View remote ANSI art
curl https://16colo.rs/pack/acid96/US-JELLY.ANS | ansilust

# Works with redirects
curl -L https://raw.githubusercontent.com/blocktronics/artpacks/main/examples/demo.ans | ansilust

# Can save and view
curl https://16colo.rs/pack/fire43/US-JELLY.ANS > art.ans
ansilust art.ans
```

### 2. Artpack Archive Streaming

**Basic syntax:**
```bash
curl url/to/artpack.zip | ansilust --speed 9600
```

**Behavior:**
- Download ZIP/archive to standard cache location
- Extract to cache directory
- Stream all supported art files to screen at simulated baud rate
- Subsequent runs use cached data (no re-download)
- Smart file filtering (skip non-art files, show unsupported format messages)

**Example:**
```bash
# Download and stream artpack
curl https://16colo.rs/pack/acid96 | ansilust --speed 9600

# Run again - uses cache (instant)
curl https://16colo.rs/pack/acid96 | ansilust --speed 9600

# Different speed
curl https://16colo.rs/pack/acid96 | ansilust --speed 2400

# Clear cache for specific pack
ansilust --clear-cache acid96

# Clear all cache
ansilust --clear-cache
```

## Technical Design

### 1. Stdin Detection

Modify `src/main.zig` to detect stdin input:

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip argv0

    // Check if stdin is a pipe/redirect (not a TTY)
    const stdin_is_pipe = !std.posix.isatty(std.posix.STDIN_FILENO);
    
    // Parse CLI flags
    var speed: ?u32 = null;
    var clear_cache = false;
    var clear_cache_target: ?[]const u8 = null;
    var file_paths = std.ArrayList([]const u8).init(allocator);
    defer file_paths.deinit();

    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--speed=")) {
            speed = try std.fmt.parseInt(u32, arg[8..], 10);
        } else if (std.mem.eql(u8, arg, "--clear-cache")) {
            clear_cache = true;
            clear_cache_target = args.next();
        } else {
            try file_paths.append(arg);
        }
    }

    // Handle cache clearing
    if (clear_cache) {
        try clearCache(allocator, clear_cache_target);
        return;
    }

    // Process stdin if it's a pipe and no files specified
    if (stdin_is_pipe and file_paths.items.len == 0) {
        try processStdin(allocator, speed);
    } else if (file_paths.items.len > 0) {
        // Process files normally
        for (file_paths.items) |path| {
            try processFile(allocator, path);
        }
    } else {
        std.debug.print("usage: ansilust <file.ans> [<file2.ans> ...]\n", .{});
        std.debug.print("   or: curl url/to/ansi.ans | ansilust\n", .{});
        std.debug.print("   or: curl url/to/artpack.zip | ansilust --speed 9600\n", .{});
    }
}
```

### 2. Stdin Processing

Two modes based on content type:

#### Mode A: Direct ANSI Rendering (Text Content)

```zig
fn processStdin(allocator: std.mem.Allocator, speed: ?u32) !void {
    const stdin_file = std.fs.File{ .handle = std.posix.STDIN_FILENO };
    
    // Read first chunk to detect content type
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    
    const first_chunk = try stdin_file.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(first_chunk);
    
    // Detect if it's a ZIP/archive (magic bytes)
    if (isArchive(first_chunk)) {
        // Read entire stdin into buffer
        try buffer.appendSlice(first_chunk);
        const rest = try stdin_file.reader().readAllAlloc(allocator, 100 * 1024 * 1024);
        defer allocator.free(rest);
        try buffer.appendSlice(rest);
        
        try processArchiveFromMemory(allocator, buffer.items, speed);
    } else {
        // It's raw ANSI/art content - render directly
        try buffer.appendSlice(first_chunk);
        const rest = try stdin_file.reader().readAllAlloc(allocator, 10 * 1024 * 1024);
        defer allocator.free(rest);
        try buffer.appendSlice(rest);
        
        var doc = try ansilust.parsers.ansi.parse(allocator, buffer.items);
        defer doc.deinit();
        
        const is_tty = std.posix.isatty(std.posix.STDOUT_FILENO);
        const output = try ansilust.renderToUtf8Ansi(allocator, &doc, is_tty);
        defer allocator.free(output);
        
        const stdout = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
        try stdout.writeAll(output);
    }
}
```

#### Mode B: Archive Processing (ZIP Content)

```zig
fn processArchiveFromMemory(
    allocator: std.mem.Allocator,
    archive_data: []const u8,
    speed: ?u32
) !void {
    // 1. Compute hash of archive for cache key
    var hasher = std.crypto.hash.Blake3.init(.{});
    hasher.update(archive_data);
    var hash_bytes: [32]u8 = undefined;
    hasher.final(&hash_bytes);
    
    const cache_key = try std.fmt.allocPrint(
        allocator,
        "{x}",
        .{std.fmt.fmtSliceHexLower(&hash_bytes)}
    );
    defer allocator.free(cache_key);
    
    // 2. Check cache
    const cache_dir = try getCacheDir(allocator);
    defer allocator.free(cache_dir);
    
    const pack_cache_dir = try std.fs.path.join(
        allocator,
        &[_][]const u8{cache_dir, cache_key}
    );
    defer allocator.free(pack_cache_dir);
    
    // 3. Extract to cache if not exists
    var cache_exists = true;
    std.fs.accessAbsolute(pack_cache_dir, .{}) catch {
        cache_exists = false;
    };
    
    if (!cache_exists) {
        std.debug.print("Downloading artpack to cache...\n", .{});
        try extractArchiveToCache(allocator, archive_data, pack_cache_dir);
    } else {
        std.debug.print("Using cached artpack: {s}\n", .{cache_key[0..8]});
    }
    
    // 4. Stream all art files from cache
    try streamArtpackFiles(allocator, pack_cache_dir, speed);
}
```

### 3. Cache Management

**Cache location:**
```
$HOME/.cache/ansilust/artpacks/
├── <hash1>/          # Extracted artpack 1
│   ├── US-JELLY.ANS
│   ├── US-NEON.ANS
│   └── ...
├── <hash2>/          # Extracted artpack 2
└── ...
```

**Cache functions:**

```zig
fn getCacheDir(allocator: std.mem.Allocator) ![]const u8 {
    const home = std.posix.getenv("HOME") orelse return error.NoHomeDir;
    return try std.fs.path.join(
        allocator,
        &[_][]const u8{home, ".cache", "ansilust", "artpacks"}
    );
}

fn clearCache(allocator: std.mem.Allocator, target: ?[]const u8) !void {
    const cache_dir = try getCacheDir(allocator);
    defer allocator.free(cache_dir);
    
    if (target) |t| {
        // Clear specific pack by matching hash prefix
        var dir = try std.fs.openDirAbsolute(cache_dir, .{ .iterate = true });
        defer dir.close();
        
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (std.mem.startsWith(u8, entry.name, t)) {
                std.debug.print("Clearing cache: {s}\n", .{entry.name});
                try dir.deleteTree(entry.name);
            }
        }
    } else {
        // Clear entire cache
        std.debug.print("Clearing all cache...\n", .{});
        std.fs.deleteTreeAbsolute(cache_dir) catch {};
        try std.fs.makeDirAbsolute(cache_dir);
    }
}
```

### 4. Baud Rate Simulation

When `--speed` is specified, simulate old modem speeds:

```zig
fn streamArtpackFiles(
    allocator: std.mem.Allocator,
    pack_dir: []const u8,
    speed: ?u32
) !void {
    var dir = try std.fs.openDirAbsolute(pack_dir, .{ .iterate = true });
    defer dir.close();
    
    // Collect all art files
    var art_files = std.ArrayList([]const u8).init(allocator);
    defer {
        for (art_files.items) |f| allocator.free(f);
        art_files.deinit();
    }
    
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind != .file) continue;
        
        // Check if supported art format
        if (isSupportedArtFormat(entry.name)) {
            try art_files.append(try allocator.dupe(u8, entry.name));
        }
    }
    
    // Sort files alphabetically
    std.mem.sort([]const u8, art_files.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    
    // Stream each file
    for (art_files.items, 0..) |filename, i| {
        std.debug.print("\n=== File {}/{}: {} ===\n", .{i+1, art_files.items.len, filename});
        
        const full_path = try std.fs.path.join(
            allocator,
            &[_][]const u8{pack_dir, filename}
        );
        defer allocator.free(full_path);
        
        const file_data = try dir.readFileAlloc(allocator, filename, 10 * 1024 * 1024);
        defer allocator.free(file_data);
        
        var doc = ansilust.parsers.ansi.parse(allocator, file_data) catch |e| {
            std.debug.print("Skipping (parse error: {})\n", .{e});
            continue;
        };
        defer doc.deinit();
        
        const is_tty = std.posix.isatty(std.posix.STDOUT_FILENO);
        const output = try ansilust.renderToUtf8Ansi(allocator, &doc, is_tty);
        defer allocator.free(output);
        
        if (speed) |baud| {
            // Simulate modem speed
            try streamWithDelay(output, baud);
        } else {
            const stdout = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
            try stdout.writeAll(output);
        }
        
        // Pause between files
        if (i < art_files.items.len - 1) {
            std.time.sleep(1_000_000_000); // 1 second pause
        }
    }
}

fn streamWithDelay(data: []const u8, baud_rate: u32) !void {
    const stdout = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
    
    // Calculate delay per character (in nanoseconds)
    // baud_rate is bits per second, assume 8 bits per byte
    const bytes_per_second = baud_rate / 8;
    const ns_per_byte = 1_000_000_000 / bytes_per_second;
    
    for (data) |byte| {
        try stdout.writeAll(&[_]u8{byte});
        std.time.sleep(ns_per_byte);
    }
}
```

### 5. Archive Format Detection

```zig
fn isArchive(data: []const u8) bool {
    if (data.len < 4) return false;
    
    // ZIP magic: PK\x03\x04
    if (data[0] == 0x50 and data[1] == 0x4B and 
        data[2] == 0x03 and data[3] == 0x04) {
        return true;
    }
    
    // RAR magic: Rar!\x1A\x07
    if (data.len >= 7 and
        data[0] == 0x52 and data[1] == 0x61 and data[2] == 0x72 and
        data[3] == 0x21 and data[4] == 0x1A and data[5] == 0x07) {
        return true;
    }
    
    // 7z magic: 7z\xBC\xAF\x27\x1C
    if (data.len >= 6 and
        data[0] == 0x37 and data[1] == 0x7A and data[2] == 0xBC and
        data[3] == 0xAF and data[4] == 0x27 and data[5] == 0x1C) {
        return true;
    }
    
    return false;
}

fn isSupportedArtFormat(filename: []const u8) bool {
    const extensions = [_][]const u8{
        ".ANS", ".ans",
        ".ANSI", ".ansi",
        ".ASC", ".asc",
        ".BIN", ".bin",
        ".PCB", ".pcb",
        ".XB", ".xb",
        ".XBIN", ".xbin",
        ".TND", ".tnd",
        ".IDF", ".idf",
        ".ADF", ".adf",
    };
    
    for (extensions) |ext| {
        if (std.mem.endsWith(u8, filename, ext)) {
            return true;
        }
    }
    return false;
}
```

### 6. ZIP Extraction

```zig
fn extractArchiveToCache(
    allocator: std.mem.Allocator,
    archive_data: []const u8,
    dest_dir: []const u8
) !void {
    // Create cache directory
    try std.fs.makeDirAbsolute(dest_dir);
    
    // Write archive to temp file (required by zip libraries)
    const temp_zip = try std.fmt.allocPrint(
        allocator,
        "{s}.zip",
        .{dest_dir}
    );
    defer allocator.free(temp_zip);
    
    {
        const file = try std.fs.createFileAbsolute(temp_zip, .{});
        defer file.close();
        try file.writeAll(archive_data);
    }
    
    // Extract using system unzip command (portable)
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "unzip",
            "-q",       // quiet
            "-o",       // overwrite
            "-d",       // destination
            dest_dir,
            temp_zip,
        },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    
    // Clean up temp file
    std.fs.deleteFileAbsolute(temp_zip) catch {};
    
    if (result.term.Exited != 0) {
        return error.ExtractionFailed;
    }
}
```

## CLI Reference

### Commands

```bash
# Single file from stdin
curl url/to/art.ans | ansilust

# Artpack from stdin (with speed simulation)
curl url/to/pack.zip | ansilust --speed 9600

# Process local file (existing behavior)
ansilust file.ans

# Process multiple local files (existing behavior)
ansilust file1.ans file2.ans

# Clear all cache
ansilust --clear-cache

# Clear specific pack by hash prefix
ansilust --clear-cache a3f2e1

# Combine with other tools
curl url/to/art.ans | ansilust > output.utf8ansi
```

### Baud Rate Speeds

Common modem speeds for `--speed` flag:
- `2400` - 2400 baud (very slow, authentic 1980s BBS experience)
- `9600` - 9600 baud (common 1990s speed)
- `14400` - 14.4k modem
- `28800` - 28.8k modem
- `56000` - 56k modem (late 1990s)

## Implementation Phases

### Phase 1: Basic Stdin Support
- [x] Detect stdin pipe vs TTY
- [ ] Read from stdin when no files specified
- [ ] Auto-detect ANSI vs archive content
- [ ] Direct ANSI rendering from stdin
- [ ] Update usage message

### Phase 2: Archive Support
- [ ] Magic byte detection (ZIP, RAR, 7z)
- [ ] Cache directory structure
- [ ] Hash-based cache keys
- [ ] ZIP extraction to cache
- [ ] File enumeration and filtering
- [ ] Sequential artpack streaming

### Phase 3: Speed Simulation
- [ ] `--speed` flag parsing
- [ ] Baud rate calculation
- [ ] Character-by-character streaming
- [ ] Inter-file delays
- [ ] Progress indicators

### Phase 4: Cache Management
- [ ] `--clear-cache` command
- [ ] Selective cache clearing by hash
- [ ] Cache size reporting
- [ ] Cache expiration (optional)

### Phase 5: Polish
- [ ] Better error messages
- [ ] Download progress indicators
- [ ] Format-specific handling (RAR, 7z)
- [ ] Support for nested archives
- [ ] Parallel extraction (performance)

## Edge Cases & Considerations

### 1. Large Archives
- Memory limit for stdin buffering (100MB default)
- Stream to temp file if too large
- Streaming extraction for huge archives

### 2. Network Failures
- Partial downloads (corrupted archives)
- Retry logic (or rely on curl's retry)
- Validation after extraction

### 3. Unsupported Formats
- Gracefully skip non-art files
- Report format detection failures
- Suggest format auto-detection improvements

### 4. Cache Collisions
- Hash collisions (extremely unlikely with Blake3)
- Cache corruption detection
- Safe cleanup on extraction failure

### 5. Performance
- Avoid re-hashing large files
- Parallel file processing in artpacks
- Lazy extraction (only extract when viewing)

### 6. Security
- Validate archive contents (no path traversal)
- Size limits on extraction
- Sanitize filenames

## Examples

### Real-World Usage

```bash
# View classic BBS art from 16colors.net
curl https://16colo.rs/pack/acid96/file/US-JELLY.ANS | ansilust

# Download entire artpack and browse at 9600 baud
curl https://16colo.rs/pack/acid96/download | ansilust --speed 9600

# View random art from GitHub
curl https://raw.githubusercontent.com/blocktronics/artpacks/main/examples/demo.ans | ansilust

# Chain with other tools
curl url/to/art.ans | ansilust | less -R

# Save processed output
curl url/to/art.ans | ansilust > modern.utf8ansi

# Batch process from a list
cat urls.txt | xargs -n1 curl -s | ansilust
```

### Workflow Examples

```bash
# Browse artpack once (download and cache)
curl https://16colo.rs/pack/fire43/download | ansilust --speed 9600

# Browse again (instant, uses cache)
curl https://16colo.rs/pack/fire43/download | ansilust --speed 2400

# Different artpack
curl https://16colo.rs/pack/ice96/download | ansilust --speed 9600

# Clear old caches
ansilust --clear-cache

# Start fresh
curl https://16colo.rs/pack/acid96/download | ansilust --speed 9600
```

## Why This Matters

### For Users
- **Simplicity**: One command to view remote ANSI art
- **Nostalgia**: Speed simulation recreates BBS experience
- **Efficiency**: Smart caching avoids re-downloads
- **Flexibility**: Works with any curl-compatible URL

### For the Project
- **Unix Philosophy**: Composable tools via pipes
- **Real-world Testing**: Forces handling of diverse formats
- **Discoverability**: Easy to demo and share art
- **Integration**: Works with existing web infrastructure

### For the Community
- **Preservation**: Makes historic art accessible
- **Distribution**: Easy sharing of art collections
- **Education**: Demonstrates ANSI art history
- **Creativity**: Enables new art delivery mechanisms

## Future Enhancements

### Streaming Optimizations
- [ ] Streaming ZIP parser (no full buffer)
- [ ] Progressive rendering (start before full download)
- [ ] Parallel downloads for multi-file packs

### Format Support
- [ ] RAR archive support
- [ ] 7z archive support
- [ ] TAR.GZ support
- [ ] Direct support for 16colo.rs API

### Interactive Features
- [ ] `--interactive` mode with file selection menu
- [ ] `--shuffle` flag for random order
- [ ] `--filter` by artist, date, or format
- [ ] Playlist support (M3U-like for ANSI)

### Cache Intelligence
- [ ] LRU cache eviction
- [ ] Cache size limits
- [ ] Cache analytics (hit rate, size)
- [ ] Distributed cache support

### Network Integration
- [ ] Built-in HTTP client (no curl dependency)
- [ ] Resume partial downloads
- [ ] Mirror support (fallback URLs)
- [ ] BitTorrent support for artpacks

## Related Work

### Similar Tools
- **curl | ansi2png**: Similar pipe pattern for conversion
- **youtube-dl**: Inspiration for caching strategy
- **feh**: Image viewer with similar cache patterns
- **mpv**: Video player with archive support

### Integration Points
- **16colors.net API**: Direct artpack streaming
- **GitHub repos**: Blocktronics and other art collections
- **BBS platforms**: terminal.shop-style integrations
- **Archive.org**: Historic artpack preservation

## Testing Strategy

### Unit Tests
- [ ] Stdin detection logic
- [ ] Archive magic byte detection
- [ ] Cache key generation (hash stability)
- [ ] Baud rate calculations
- [ ] File filtering logic

### Integration Tests
- [ ] Pipe simple ANSI through stdin
- [ ] Pipe ZIP archive through stdin
- [ ] Cache hit/miss scenarios
- [ ] Multiple sequential runs
- [ ] Speed simulation timing

### Manual Testing
- [ ] Real curl commands with 16colors.net
- [ ] Large artpacks (100+ files)
- [ ] Slow network conditions
- [ ] Cache clearing workflow
- [ ] Different terminal emulators

## Documentation Updates

- [ ] Update README.md with pipe examples
- [ ] Add curl section to main docs
- [ ] Create PIPES.md guide
- [ ] Update --help text
- [ ] Add man page (future)

## Success Criteria

1. **Simplicity**: `curl url | ansilust` works intuitively
2. **Performance**: Cache makes repeated views instant
3. **Reliability**: Handles network/format errors gracefully
4. **Compatibility**: Works with major archive formats
5. **Experience**: Speed simulation feels authentic

## Notes

- Syntax should feel natural to Unix users
- Caching is essential (artpacks can be 10-100MB)
- Speed simulation is optional but adds nostalgia
- Must handle both single files and archives seamlessly
- Cache management should be simple and predictable
