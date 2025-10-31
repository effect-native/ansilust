# Terminal Wrap Behavior Test Findings

## Test Environment

- **Date**: 
- **Tester**: 
- **Terminal Dimensions**: 

## Terminals Tested

### Terminal 1: [Name + Version]

**Configuration:**
- Terminal size: 
- Font: 
- TERM variable: 

**Baseline Test Results:**
- Did colored bars wrap at terminal width? 
- Visual artifacts observed: 
- Color preservation: 

**No-Wrap Mode Test Results:**
- Did CSI ?7l prevent wrapping? 
- Was overflow clipped correctly? 
- Was auto-wrap restored with CSI ?7h? 
- Verification test result: 

**Advanced Tests:**
- Test 1 (Save/Restore): 
- Test 2 (Toggle Mid-Render): 
- Test 3 (Clear Screen): 
- Test 4 (Alternate Buffer): 

**Overall Assessment:**
- Recommended strategy for this terminal: 
- Known issues or quirks: 

---

### Terminal 2: [Name + Version]

**Configuration:**
- Terminal size: 
- Font: 
- TERM variable: 

**Baseline Test Results:**
- Did colored bars wrap at terminal width? 
- Visual artifacts observed: 
- Color preservation: 

**No-Wrap Mode Test Results:**
- Did CSI ?7l prevent wrapping? 
- Was overflow clipped correctly? 
- Was auto-wrap restored with CSI ?7h? 
- Verification test result: 

**Advanced Tests:**
- Test 1 (Save/Restore): 
- Test 2 (Toggle Mid-Render): 
- Test 3 (Clear Screen): 
- Test 4 (Alternate Buffer): 

**Overall Assessment:**
- Recommended strategy for this terminal: 
- Known issues or quirks: 

---

### Terminal 3: [Name + Version]

**Configuration:**
- Terminal size: 
- Font: 
- TERM variable: 

**Baseline Test Results:**
- Did colored bars wrap at terminal width? 
- Visual artifacts observed: 
- Color preservation: 

**No-Wrap Mode Test Results:**
- Did CSI ?7l prevent wrapping? 
- Was overflow clipped correctly? 
- Was auto-wrap restored with CSI ?7h? 
- Verification test result: 

**Advanced Tests:**
- Test 1 (Save/Restore): 
- Test 2 (Toggle Mid-Render): 
- Test 3 (Clear Screen): 
- Test 4 (Alternate Buffer): 

**Overall Assessment:**
- Recommended strategy for this terminal: 
- Known issues or quirks: 

---

## Cross-Terminal Summary

### Working Solutions
- List terminals where CSI ?7l/h worked reliably:

### Failed Solutions
- List terminals that ignored wrap control:

### Fallback Strategy Assessment
- Is terminal width detection necessary? 
- Should we warn users when artwork > terminal width? 
- Should we provide a --force-nowrap flag? 

## Recommendations for UTF8ANSI Renderer

### Primary Strategy
[Describe the recommended approach based on test results]

### Fallback Handling
[Describe what to do when wrap control fails]

### Implementation Notes
- Always pair CSI ?7l with CSI ?7h? 
- Should we test terminal support before using? 
- Edge cases to handle: 

### Code Snippet (Pseudo)
```
// Example renderer logic based on findings
function render_with_wrap_control(artwork) {
    // [Fill in based on test results]
}
```

## References
- VT100 DECAWM: https://vt100.net/docs/vt510-rm/DECAWM.html
- Terminal compatibility: [Add links to terminal documentation]

## Testing Checklist
- [ ] Ghostty
- [ ] Alacritty  
- [ ] Kitty
- [ ] WezTerm
- [ ] xterm
- [ ] GNOME Terminal
- [ ] iTerm2 (macOS)
- [ ] Terminal.app (macOS)
- [ ] Windows Terminal
- [ ] Other: ___________
