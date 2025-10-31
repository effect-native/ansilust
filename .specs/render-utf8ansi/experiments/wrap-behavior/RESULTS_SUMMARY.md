# Wrap Behavior Test Results - Summary

## Quick Reference: Escape Sequences Tested

| Sequence | Name | Purpose |
|----------|------|---------|
| `CSI ?7l` | DECAWM Reset | Disable auto-wrap (lines don't wrap at right margin) |
| `CSI ?7h` | DECAWM Set | Enable auto-wrap (lines wrap at right margin) |
| `CSI 7` | DECSC | Save cursor position |
| `CSI 8` | DECRC | Restore cursor position |
| `CSI 2J` | ED | Erase display (clear screen) |
| `CSI H` | CUP | Cursor to home position (1,1) |
| `CSI ?1049h` | - | Switch to alternate screen buffer |
| `CSI ?1049l` | - | Switch to normal screen buffer |

## Test Matrix

Fill in this table after running tests on each terminal:

| Terminal | Version | Baseline Wrap | CSI ?7l Works | Restoration Works | Recommended |
|----------|---------|---------------|---------------|-------------------|-------------|
| Ghostty | | | | | |
| Alacritty | | | | | |
| Kitty | | | | | |
| WezTerm | | | | | |
| xterm | | | | | |
| GNOME Terminal | | | | | |
| iTerm2 | | | | | |
| Terminal.app | | | | | |
| Windows Terminal | | | | | |

**Recommended values:**
- ✅ Use DECAWM (works reliably)
- ⚠️  Use with fallback (may have issues)
- ❌ Don't use DECAWM (detect width instead)

## Common Findings Patterns

### Pattern 1: Full DECAWM Support
- CSI ?7l prevents wrapping
- Overflow is clipped at terminal edge
- CSI ?7h restores wrap mode
- No side effects

**Renderer strategy**: Always use DECAWM

### Pattern 2: Partial DECAWM Support  
- CSI ?7l prevents wrapping BUT
- Wrap mode doesn't restore reliably OR
- Side effects on cursor/screen state

**Renderer strategy**: Use DECAWM with explicit verification

### Pattern 3: No DECAWM Support
- CSI ?7l ignored (content still wraps)
- Terminal doesn't support wrap control

**Renderer strategy**: Detect width, warn/crop content

## Implementation Recommendations

Based on test results, complete ONE of these sections:

### If DECAWM works universally:
```typescript
function renderWithWrapControl(artwork: string): void {
  process.stdout.write('\x1b[?7l');  // Disable wrap
  process.stdout.write(artwork);
  process.stdout.write('\x1b[?7h');  // Re-enable wrap
}
```

### If DECAWM is unreliable:
```typescript
function renderWithFallback(artwork: string, artworkWidth: number): void {
  const termWidth = getTerminalWidth();  // stty size or tput cols
  
  if (artworkWidth <= termWidth) {
    // Fits, render normally
    process.stdout.write(artwork);
  } else {
    // Try DECAWM, warn user
    console.warn(`Artwork is ${artworkWidth} columns, terminal is ${termWidth}`);
    console.warn('Output may wrap. Use --crop or resize terminal.');
    
    process.stdout.write('\x1b[?7l');
    process.stdout.write(artwork);
    process.stdout.write('\x1b[?7h');
  }
}
```

### If DECAWM fails completely:
```typescript
function renderWithCrop(artwork: string, artworkWidth: number): void {
  const termWidth = getTerminalWidth();
  
  if (artworkWidth > termWidth) {
    console.warn(`Artwork requires ${artworkWidth} columns, but terminal is ${termWidth}`);
    console.warn('Content will be cropped. Resize terminal or use --force.');
    
    // Crop artwork to terminal width
    artwork = cropToWidth(artwork, termWidth);
  }
  
  process.stdout.write(artwork);
}
```

## Terminal Width Detection Methods

```bash
# Method 1: tput (most portable)
tput cols

# Method 2: stty (more direct)
stty size | cut -d' ' -f2

# Method 3: ANSI query (not universally supported)
printf '\e[18t'  # Reports terminal size
```

## Next Steps

1. Run tests on all available terminals
2. Fill in the test matrix above
3. Identify the dominant pattern
4. Implement recommended strategy
5. Add configuration option for users with edge-case terminals
6. Update `.specs/render-utf8ansi/requirements.md`

## Open Questions

- [ ] Should renderer auto-detect and adapt to terminal?
- [ ] Should there be a --force-wrap or --no-wrap CLI flag?
- [ ] How to handle artwork wider than any reasonable terminal (e.g., 320 cols)?
- [ ] Should we support horizontal scrolling (alternate approach)?
- [ ] What about animated ANSI - does wrap control work frame-by-frame?

## References

- [VT100 DECAWM Documentation](https://vt100.net/docs/vt510-rm/DECAWM.html)
- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
- [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [Terminal Compatibility List](https://terminalguide.namepad.de/mode/p7/)
