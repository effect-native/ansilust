# Horizontal Scrolling Alternatives to Clipping

## The Question

Instead of clipping wide artwork at the terminal edge (with DECAWM), can we enable horizontal scrolling so users can pan left/right to see the full artwork?

## VT/ANSI Sequence Options

### 1. **Horizontal Scrolling Mode (DECLRMM - Left/Right Margin Mode)**

**Sequence:** `CSI ?69h` (enable) / `CSI ?69l` (disable)

**What it does:**
- Enables left/right margins for scrolling regions
- Designed for split-screen applications
- **Does NOT enable horizontal scrolling of wide content**

**Verdict:** ❌ Not suitable - controls margins, not scrolling behavior

---

### 2. **Terminal Width Manipulation**

**Sequences:**
- `CSI 8 ; height ; width t` - Resize terminal to width × height
- `CSI 3 ; x ; y t` - Move terminal window

**What it does:**
- Resizes the terminal window itself
- Not standardized, many terminals ignore for security

**Verdict:** ❌ Not suitable - invasive, unreliable, bad UX

---

### 3. **Alternate Screen Buffer with Manual Panning**

**Concept:**
- Switch to alternate screen (`CSI ?1049h`)
- Render full artwork to virtual buffer
- Use arrow keys to manually reposition viewport
- Implement custom panning with cursor positioning

**Sequences needed:**
- `CSI ?1049h` - Enter alternate screen
- `CSI row ; col H` - Position cursor
- `CSI ? 25l` - Hide cursor
- Application reads arrow keys and re-renders visible region

**Pros:**
- Full control over what's visible
- Can show full artwork in chunks
- Interactive exploration

**Cons:**
- Requires interactive mode (can't just pipe to terminal)
- Complex implementation (event loop, key handling)
- Not suitable for simple "render and exit" use case
- User must manually pan with arrow keys

**Verdict:** ⚠️ Possible but complex - only for interactive viewer mode

---

### 4. **Less/More Pager Pattern**

**Concept:**
- Pipe artwork through a pager like `less -S` or `most`
- Pager handles horizontal scrolling natively

**Implementation:**
```bash
ansilust render artwork.ans | less -S -R
```

**Flags:**
- `less -S` - Chop long lines (enable horizontal scrolling)
- `less -R` - Raw control characters (preserve ANSI colors)
- Arrow keys scroll left/right

**Pros:**
- ✅ Users already know how to use `less`
- ✅ Zero implementation complexity
- ✅ Horizontal scrolling works perfectly
- ✅ Vertical scrolling too
- ✅ Search, jump to line, all free

**Cons:**
- Requires `less` installed (usually available)
- Adds extra step for user
- ANSI color support varies by pager

**Verdict:** ✅ Best option for horizontal scrolling

---

### 5. **Terminal Sixel Graphics / Kitty Graphics Protocol**

**Concept:**
- Render ANSI artwork to an image (PNG)
- Display image in terminal using graphics protocol
- Terminal handles zoom/pan of image

**Sequences:**
- Sixel: `ESC P ... ESC \`
- Kitty: `ESC _G ... ESC \`

**Pros:**
- Perfect pixel-accurate rendering
- Can zoom and pan (terminal-dependent)
- No wrapping issues at all

**Cons:**
- Defeats the purpose of ANSI text art (loses text properties)
- Requires image rendering pipeline
- Not all terminals support graphics
- Can't copy/paste text from artwork
- Bitmap fonts get rasterized (no longer text)

**Verdict:** ❌ Wrong approach - we want text art, not images

---

### 6. **HTML/Web Rendering**

**Concept:**
- Convert ANSI to HTML with `<pre>` and CSS
- Open in browser with horizontal scrollbar
- Full pan/zoom control

**Pros:**
- Perfect rendering
- Browser handles all scrolling
- Can add interactive features (click to copy, color picker, etc.)

**Cons:**
- Not a terminal solution
- Requires browser
- Different use case (HTML renderer, not UTF8ANSI renderer)

**Verdict:** ⚠️ Valid but different - this is the HTML Canvas renderer (separate module)

---

## Recommendations

### For CLI UTF8ANSI Renderer

**Primary:** Use DECAWM (clips at terminal edge)
```bash
ansilust render artwork.ans
# Wide content is clipped, but renders instantly
```

**Optional flag:** `--pager` mode
```bash
ansilust render artwork.ans --pager
# Pipes through less -S -R for horizontal scrolling
```

**Implementation:**
```typescript
if (options.pager) {
  // Spawn less -S -R and pipe artwork
  const less = spawn('less', ['-S', '-R'], { stdio: 'pipe' });
  less.stdin.write(artwork);
  less.stdin.end();
} else {
  // Direct render with DECAWM
  process.stdout.write('\x1b[?7l');
  process.stdout.write(artwork);
  process.stdout.write('\x1b[?7h');
}
```

### For Interactive Viewer (Future)

If you build an interactive ANSI viewer later:
- Use alternate screen buffer
- Implement arrow key panning
- Show viewport indicator (e.g., "Viewing cols 1-80 of 160")
- Allow 'q' to quit, 'h/j/k/l' or arrows to pan

**Example:**
```bash
ansilust view artwork.ans
# Interactive mode: arrow keys pan, 'q' quits
```

---

## Decision Matrix

| Approach | Horizontal Scroll | Complexity | Terminal Support | Use Case |
|----------|-------------------|------------|------------------|----------|
| DECAWM (clip) | ❌ No | Very Low | Universal | Default render |
| Pipe to `less -S` | ✅ Yes | Low | High | `--pager` flag |
| Interactive panning | ✅ Yes | High | Universal | Future viewer |
| Sixel/Graphics | N/A | Medium | Limited | Wrong approach |
| HTML renderer | ✅ Yes | Medium | N/A | Separate module |

---

## Proposed Implementation

### Phase 1 (Current)
- Implement DECAWM clipping (default)
- Add `--pager` flag to pipe through `less -S -R`
- Document that wide artwork may be clipped without `--pager`

### Phase 2 (Future - if needed)
- Build interactive viewer with arrow key panning
- Separate command: `ansilust view` vs `ansilust render`

### Example Usage

```bash
# Quick render (clips at terminal edge)
ansilust render wide.ans

# Scrollable render (uses less)
ansilust render wide.ans --pager

# Interactive viewer (future)
ansilust view wide.ans
```

---

## Conclusion

**Answer:** Yes, horizontal scrolling is possible!

**Best approach:** Pipe through `less -S -R`
- Simple to implement
- Users already familiar with `less`
- Works universally
- Adds horizontal + vertical scrolling
- Preserves ANSI colors with `-R` flag

**Implementation priority:**
1. ✅ DECAWM (clips) - Phase 1, default behavior
2. ✅ `--pager` flag - Phase 1, easy addition
3. ⏸️ Interactive viewer - Phase 2, if demand exists

The pager approach gives you horizontal scrolling "for free" without complex terminal control sequences.
