# UTF8ANSI Renderer - Wrap Control Recommendation

## Test Results Summary

✅ **DECAWM (CSI ?7l/h) works reliably across all tested terminals**

**Terminals tested (3/3 passed):**
- Ghostty (xterm-ghostty)
- Zed Editor terminal (xterm-256color)
- VS Code terminal (xterm-256color)

**Results:**
- Prevents wrapping: ✅ Yes
- Clips overflow correctly: ✅ Yes  
- Restores auto-wrap: ✅ Yes
- No visual artifacts: ✅ Confirmed
- Works in alternate screen: ✅ Yes

## Recommended Implementation

### Primary Strategy: Use DECAWM

The UTF8ANSI renderer should emit DECAWM sequences to control wrapping:

```
CSI ?7l    - Disable auto-wrap before rendering
[artwork]  - Render ANSI content
CSI ?7h    - Re-enable auto-wrap after rendering
```

### Implementation Pattern

```typescript
export function renderAnsiArtwork(artwork: string): void {
  // Disable auto-wrap (DECAWM reset)
  process.stdout.write('\x1b[?7l');
  
  // Render the artwork
  process.stdout.write(artwork);
  
  // Re-enable auto-wrap (DECAWM set)
  process.stdout.write('\x1b[?7h');
}
```

### Why This Works

1. **Wide artwork (160+ cols) renders correctly** even on narrower terminals
2. **Overflow is clipped** at terminal edge (no ugly wrapping mid-line)
3. **Terminal state is preserved** - auto-wrap restores after render
4. **No side effects** - subsequent shell commands work normally
5. **Modern terminals support it** - VT100 standard (DECAWM)

### Edge Cases to Handle

**If rendering multiple frames (animation):**
- Toggle wrap per frame OR disable once at start, enable at end
- Test which approach has better performance

**If rendering to alternate screen buffer:**
- DECAWM works correctly (confirmed in testing)
- No special handling needed

**If user terminal doesn't support DECAWM:**
- Unlikely for modern terminals
- Consider adding `--detect-width` fallback flag in Phase 2
- Could detect terminal width and warn if artwork > width

## Optional: Width Detection Fallback (Phase 2)

If we encounter terminals where DECAWM fails:

```typescript
function getTerminalWidth(): number {
  // Try stty first
  const sttyResult = execSync('stty size 2>/dev/null', { encoding: 'utf8' });
  if (sttyResult) {
    const cols = sttyResult.trim().split(' ')[1];
    return parseInt(cols, 10);
  }
  
  // Fallback to tput
  const tputResult = execSync('tput cols 2>/dev/null', { encoding: 'utf8' });
  return parseInt(tputResult.trim(), 10) || 80;
}

export function renderWithFallback(artwork: string, artworkWidth: number): void {
  const termWidth = getTerminalWidth();
  
  if (artworkWidth > termWidth) {
    console.warn(`⚠️  Artwork is ${artworkWidth} cols, terminal is ${termWidth} cols`);
    console.warn('Output may be clipped. Resize terminal or use --force.');
  }
  
  // Still use DECAWM even with warning
  process.stdout.write('\x1b[?7l');
  process.stdout.write(artwork);
  process.stdout.write('\x1b[?7h');
}
```

## CLI Flags to Consider (Phase 2)

- `--no-wrap-control` - Skip DECAWM, let terminal wrap naturally
- `--force-wrap` - Force wrapping even if artwork is wide
- `--detect-width` - Check terminal size and warn before rendering

## Action Items

### Phase 1 (Current)
- [x] Test DECAWM in target terminals (3 terminals tested)
- [x] Confirm wrap control works reliably (100% success rate)
- [ ] Implement DECAWM in UTF8ANSI renderer
- [ ] Test with real ANSI artwork from corpus

### Phase 2 (Future)
- [ ] Test additional standalone terminals (Alacritty, Kitty, WezTerm, xterm)
- [ ] Add width detection fallback if needed
- [ ] Implement CLI flags for edge cases
- [ ] Handle animation frame wrap control

## References

- [VT100 DECAWM Documentation](https://vt100.net/docs/vt510-rm/DECAWM.html)
- Test results: `test-results.md`
- Test scripts: `interactive-test.sh`

---

**Status**: ✅ Ready to implement  
**Confidence**: Very High - DECAWM works reliably across 3 different terminals (100% success)  
**Risk**: Very Low - VT100 standard, universally supported in all tested environments
