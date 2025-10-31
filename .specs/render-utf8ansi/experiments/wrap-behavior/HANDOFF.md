# Handoff: Terminal Wrap Behavior Testing

## For: Bramwell (or other human tester)

## What We Need

We need empirical data on how different terminal emulators handle ANSI wrap control sequences (DECAWM - `CSI ?7l` and `CSI ?7h`). This will inform how the UTF8ANSI renderer handles wide artwork (e.g., 160-column ANSI art) that exceeds the terminal width.

## Why This Matters

The renderer needs to know:
1. Can we reliably disable terminal auto-wrap using escape sequences?
2. If not, do we need to detect terminal width and warn/crop?
3. Are there terminal-specific quirks we need to handle?

## What's Ready

All test scripts are in `.specs/render-utf8ansi/experiments/wrap-behavior/`:

```
├── run-all-tests.sh          # Master test runner (START HERE)
├── baseline-test.sh          # Test 1: Natural wrapping behavior
├── nowrap-test.sh            # Test 2: DECAWM wrap control
├── advanced-test.sh          # Test 3: Edge cases & strategies
├── detect-terminal.sh        # Terminal info collector
├── test-wide.ans             # 160-column test artwork
├── findings.md               # Template for recording results
├── TESTING.md                # Detailed testing guide
└── RESULTS_SUMMARY.md        # Results aggregation template
```

## How to Run Tests

### Option 1: Run Everything (Recommended for first-time testing)
```bash
cd .specs/render-utf8ansi/experiments/wrap-behavior
./run-all-tests.sh
```

This runs all three test suites with prompts explaining what to look for.

### Option 2: Run Individual Tests
```bash
./baseline-test.sh    # See natural wrapping
./nowrap-test.sh      # Test wrap control
./advanced-test.sh    # Test edge cases
```

### Option 3: Quick Terminal Info
```bash
./detect-terminal.sh  # Get terminal capabilities
```

## What to Test

**Priority terminals** (test these first):
1. **Ghostty** - Our reference terminal (modern, Zig-based)
2. **Alacritty** - Popular GPU-accelerated terminal
3. **Kitty** - Advanced features, good VT support
4. **WezTerm** - Cross-platform, extensive VT support
5. **xterm** - Classic VT100 reference

**Secondary terminals** (if time permits):
- GNOME Terminal
- iTerm2 (macOS)
- Terminal.app (macOS)
- Windows Terminal
- Konsole (KDE)

## What to Record

For each terminal, fill out the template in `findings.md`. Key observations:

### Baseline Test
- ✅ Did colored bars wrap at terminal width?
- ✅ Were there visual artifacts (seams, color breaks)?
- ✅ Did colors remain correct?

### No-Wrap Mode Test
- ✅ Did `CSI ?7l` prevent wrapping?
- ✅ Was overflow clipped cleanly at terminal edge?
- ✅ Did `CSI ?7h` restore auto-wrap?
- ✅ Did the restoration test work correctly?

### Advanced Tests
- ✅ Which strategies worked (save/restore, toggle, clear, alt buffer)?
- ✅ Any side effects on terminal state?
- ✅ Any unexpected behavior?

## Expected Time Investment

- **Per terminal**: ~5-10 minutes
- **Priority terminals (5)**: ~30-50 minutes total
- **Full suite (10+ terminals)**: ~1-2 hours

## What We'll Do With Results

Based on your findings, we'll implement one of these strategies in the renderer:

**Strategy A**: DECAWM works everywhere
→ Always use `CSI ?7l` ... artwork ... `CSI ?7h`

**Strategy B**: DECAWM is unreliable
→ Detect terminal width, warn user, use DECAWM with fallback

**Strategy C**: DECAWM doesn't work
→ Detect width, crop content, or error out

## Questions to Answer

After testing, we need to know:

1. **Does DECAWM work reliably across modern terminals?**
2. **Are there terminals that ignore it completely?**
3. **Do we need terminal-specific detection/handling?**
4. **Should we provide a CLI flag (--force-wrap, --no-wrap, etc.)?**
5. **What's the recommended default behavior?**

## Deliverables

Please provide:

1. ✅ Completed `findings.md` with data for each terminal tested
2. ✅ Summary recommendation in `RESULTS_SUMMARY.md`
3. ✅ Screenshots (optional but helpful) showing success/failure cases
4. ✅ Your recommendation for renderer implementation strategy

## Contact

If you hit issues or have questions:
- Check `TESTING.md` for troubleshooting
- Scripts are well-commented - read the source if behavior is unclear
- Tests are non-destructive - safe to run multiple times

## Thank You!

This testing will directly inform the renderer design and ensure we handle terminal compatibility correctly from the start. Your empirical data is invaluable!

---

**Status**: Ready for testing
**Created**: 2025-10-30
**Waiting on**: Test execution and findings
