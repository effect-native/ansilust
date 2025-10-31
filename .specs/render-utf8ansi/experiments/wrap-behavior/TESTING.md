# How to Run Wrap Behavior Tests

## Quick Start

```bash
cd .specs/render-utf8ansi/experiments/wrap-behavior
./run-all-tests.sh
```

This will run all three test suites in sequence.

## Individual Tests

### 1. Baseline Test
Observes natural terminal wrapping without any escape sequences:
```bash
./baseline-test.sh
```

### 2. No-Wrap Mode Test  
Tests DECAWM (CSI ?7l/h) wrap control:
```bash
./nowrap-test.sh
```

### 3. Advanced Tests
Tests cursor save/restore, mid-render toggling, screen clear, and alternate buffer:
```bash
./advanced-test.sh
```

## Test Files

- `test-wide.ans` - 160-column colored bars for visual testing
- `findings.md` - Template for recording observations
- `README.md` - Experiment goals and methodology

## What to Look For

### Baseline Test
- Do the colored bars wrap at your terminal width?
- Are there visible seams where wrapping occurs?
- Do colors remain correct across wrapped lines?

### No-Wrap Mode Test  
- Do bars stay on single lines (no wrapping)?
- Is overflow clipped at the terminal edge?
- Does the restoration test show auto-wrap working again?

### Advanced Tests
- Which strategies successfully prevent wrapping?
- Are there side effects on terminal state?
- Does alternate screen buffer affect wrap mode behavior?

## Recording Results

Edit `findings.md` and fill in the template for each terminal you test. Include:

1. Terminal name and version
2. Results for each test (success/failure)
3. Visual observations (artifacts, clipping, color issues)
4. Whether wrap mode restoration worked
5. Overall assessment and recommended approach

## Terminals to Test

Priority targets:
- **Ghostty** - Modern Zig-based terminal (reference implementation)
- **Alacritty** - GPU-accelerated, VT100 compliant
- **Kitty** - Advanced features, good VT100 support
- **WezTerm** - Cross-platform, extensive VT support
- **xterm** - Classic VT100 reference

Secondary targets:
- GNOME Terminal
- iTerm2 (macOS)
- Terminal.app (macOS)
- Windows Terminal
- Konsole (KDE)

## Expected Outcomes

Based on VT100 specification:
- `CSI ?7l` (DECAWM reset) should disable auto-wrap
- `CSI ?7h` (DECAWM set) should enable auto-wrap  
- Modern terminals should honor these sequences
- Content exceeding terminal width should be clipped when wrap is disabled

If terminals don't respect wrap control, renderer must:
1. Detect terminal width via `stty size` or `tput cols`
2. Compare against artwork width
3. Warn user or crop content accordingly

## Troubleshooting

**Colors look wrong**: Check that your terminal supports 256-color or true color mode.

**Script won't run**: Ensure scripts are executable with `chmod +x *.sh`

**Terminal crashes**: Some very old terminals may not handle ANSI properly. Document this as a finding.

**Wrap state stuck**: If auto-wrap doesn't restore, manually run: `printf '\033[?7h'`

## Next Steps

After testing is complete:
1. Summarize findings in `findings.md`
2. Update `.specs/render-utf8ansi/requirements.md` with terminal compatibility notes
3. Implement recommended strategy in the UTF8ANSI renderer
4. Consider adding a `--no-wrap-control` flag for problematic terminals
