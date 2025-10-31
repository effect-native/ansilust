# Experiment: Terminal Wrap Behavior for UTF8ANSI Renderer

## Goal

Determine whether ANSI escape sequences can reliably disable terminal auto-wrapping so that wide artwork renders correctly irrespective of the user’s terminal width.

## Hypothesis

Using DEC Private Mode 7 (DECAWM) to disable wraparound (`CSI ?7l`) before rendering and re-enabling it (`CSI ?7h`) afterward may keep the terminal from inserting unwanted line wraps. If this fails, we may need to detect the current terminal width and crop or reflow the artwork.

## Steps

1. **Baseline Observation**
   - Run `cat` on several wide ANSI files (e.g., 160 columns) to observe how terminals wrap lines at narrower widths.
   - Record terminals tested: Ghostty, Alacritty, Kitty, WezTerm, xterm.

2. **No-Wrap Escape Test**
   - Manually emit `CSI ?7l` followed by the ANSI content, then `CSI ?7h`.
   - Example command:
     ```bash
     printf '\e[?7l'; cat wide.ans; printf '\e[?7h'
     ```
   - Verify whether terminals honor the no-wrap mode across the entire render.

3. **Alternate Strategies**
   - Test additional sequences:
     - `CSI ? 7 l` (with/without space)
     - `CSI ? 7 h` toggling before/after content
     - Using `CSI 7` / `CSI 8` (save/restore cursor) combined with no-wrap
   - Assess whether terminals reset wrap state automatically on newline or screen clear.

4. **Fallback Strategy (if no-wrap fails)**
   - Detect terminal width via `stty size` or `tput cols`.
   - Compare against artwork width;
   - Option A: Crop to visible width and warn user.
   - Option B: Reflow into multiple sub-frames (likely undesirable for Phase 1).

## Metrics to Capture

- Did the terminal respect no-wrap for the full render?
- Did the terminal restore wrap mode automatically after the test?
- Were there terminals that ignored no-wrap entirely?
- Were there side effects (e.g., wrap mode remaining off for subsequent commands)?

## Artifacts to Collect

- Terminal screenshots for success/failure cases (if possible).
- Notes on terminal-specific quirks.
- Recommended best practice for the renderer (e.g., always emit `CSI ?7l` + `CSI ?7h`, or detect width and warn).

## Ownership

Testing Assistant TBD.

## Timeline

Aim to complete initial testing before the renderer implementation reaches layout handling, so findings can inform the design phase.
