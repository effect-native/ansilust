# Wrap Behavior Experiment – Results

## Summary

- **Outcome**: DECAWM (wrap disable) strategy validated.
- **Terminals Tested**: 3/3 success (Ghostty, Zed integrated terminal, VS Code integrated terminal).
- **Confidence**: High—no anomalies observed across environments.

## Detailed Findings

1. **No-Wrap Success**
   - Sending `CSI ?7l` before content prevented the terminal from wrapping lines, ensuring artwork exceeding terminal width was not reflowed.
   - Overflow content clipped as expected when terminal width was smaller than artwork width.

2. **Restoration**
   - Sending `CSI ?7h` after content restored wrap behavior immediately.
   - Wrap state persisted correctly across subsequent commands (no residual side effects).

3. **Per-Line Toggle**
   - Toggling wrap mode per line yielded consistent behavior; no unexpected resets mid-render.

4. **Alternate Screen Compatibility**
   - Tested with alternate screen buffers; DECAWM remained effective and cleanup restored the terminal.

5. **Visual Artifacts**
   - No visual artifacts were observed; rendering remained crisp and accurate.

## Recommendation

Adopt the DECAWM strategy in the UTF8ANSI renderer:

```text
CSI ?7l    # Disable autowrap
...        # Render artwork
CSI ?7h    # Re-enable autowrap
```

Ensure cleanup occurs even on error paths to restore terminal state.
