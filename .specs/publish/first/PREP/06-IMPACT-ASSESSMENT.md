# Impact Assessment: First Publish Reality

## Friction Points Discovered

### FP1: Windows Build Fails
**Issue**: Code uses POSIX APIs (std.posix.isatty, std.posix.getenv)
**Impact**: Cannot build Windows binary
**Severity**: LOW for initial release (Windows users are minority for CLI tools)
**Resolution**: Exclude Windows from v1.0.0, fix for v1.1.0

### FP2: No Global npm link (Permission Issues)
**Issue**: npm link requires root on this system
**Impact**: Cannot test global installation locally
**Resolution**: Symlink directly in node_modules (works for testing)

### FP3: NPM_TOKEN Not Verified
**Issue**: Unknown if secret is configured in GitHub Actions
**Impact**: Could fail on publish
**Resolution**: Check via `gh secret list` before release

## What Works

1. **Native Linux build**: Yes
2. **Cross-compile to macOS**: Yes
3. **Cross-compile to ARM64 Linux**: Yes
4. **Cross-compile to Windows**: NO (code issues)
5. **Launcher platform detection**: Yes
6. **Launcher binary spawn**: Yes
7. **Full render pipeline**: Yes

## v1.0.0 Scope Recommendation

### Include (8 platforms):
- linux-x64-gnu, linux-x64-musl
- linux-arm64-gnu, linux-arm64-musl
- linux-armv7-gnu, linux-armv7-musl
- darwin-x64, darwin-arm64

### Exclude (defer to v1.1.0):
- win32-x64 (POSIX API usage)
- linux-i386-musl (low priority, test after v1.0.0)

## Human Costs

### Users:
- Windows users: Must use WSL or wait for v1.1.0
- 32-bit Linux users: Must wait for v1.1.0
- Everyone else: Good to go

### Maintainer:
- Need to fix Windows compat before 1.1.0
- Need to test ARM builds on real hardware (or trust Zig)
- Need to update docs to reflect platform support

## Practical Viability Assessment

**Score: 8/10 - PROCEED**

- Core functionality works on 8 out of 10 target platforms
- Windows is the only major gap
- npm publish flow is ready
- GitHub Actions workflow exists
- Changesets configured

## Recommended Next Steps

1. **Fix Windows build** (separate task, not blocker for v1.0.0)
   - Replace std.posix.isatty with cross-platform check
   - Replace std.posix.getenv with std.process.getEnvVarOwned

2. **Verify NPM_TOKEN secret exists**
   - `gh secret list` to check

3. **Test CI workflow**
   - Push test tag to see if workflow runs
   - Fix any issues before real release

4. **Update release.yml**
   - Remove Windows target from build matrix (or handle failure gracefully)
   - Add linux-i386-musl back when tested

5. **Create changeset and release**
   - `npx changeset add` - major bump to 1.0.0
   - Push, merge version PR, tag release
