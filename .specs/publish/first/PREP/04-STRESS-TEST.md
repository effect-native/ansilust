# Stress Test: What Could Break?

## What-If Scenarios

### WIF-1: NPM_TOKEN Secret Missing
**What if**: GitHub Actions runs but NPM_TOKEN isn't configured?
**Impact**: npm publish fails, CI workflow breaks
**Mitigation**: Check secrets before first release
**Test**: `gh secret list` should show NPM_TOKEN

### WIF-2: Platform Package Names Wrong
**What if**: npm package names don't match what launcher expects?
**Impact**: `require('ansilust-linux-x64-gnu')` fails, users get errors
**Mitigation**: Verify name consistency across:
- TARGETS map in assemble script
- optionalDependencies in meta package.json
- Platform detection in launcher.js
**Current Issue**: Names use different patterns:
- Script: `ansilust-linux-aarch64-gnu`
- Package.json: `ansilust-linux-aarch64-gnu`
- Need to verify arm vs aarch64 naming

### WIF-3: Binary Not at Expected Path
**What if**: CI produces binary at different path than assembler expects?
**Impact**: Platform packages have empty/wrong bin directory
**Mitigation**: 
- CI uploads `zig-out/bin/ansilust`
- Assembler expects `zig-out/bin/ansilust`
- Need to verify path matching in workflow

### WIF-4: Cross-Compilation Fails for Some Target
**What if**: Zig can't cross-compile to armv7 or i386?
**Impact**: Missing platform packages, angry ARM users
**Mitigation**: Test cross-compilation locally before CI
**Test**: `zig build -Dtarget=armv7-linux-gnueabihf`

### WIF-5: Windows Binary Missing .exe
**What if**: Windows binary doesn't have .exe extension?
**Impact**: Windows users can't run
**Mitigation**: Check Zig output for Windows target
**Current**: Binary names in launcher check for `.exe`

### WIF-6: npm Publish Order Wrong
**What if**: Meta package published before platform packages?
**Impact**: Meta package can't find optionalDependencies
**Mitigation**: Publish platform packages first, then meta
**Workflow**: release.yml does this correctly

### WIF-7: Version Mismatch
**What if**: Meta package references v1.0.0 but platform packages are v0.0.1?
**Impact**: npm can't resolve dependencies
**Mitigation**: Changesets bumps all versions together
**Verify**: All packages have same version before publish

### WIF-8: launcher.js Not Executable
**What if**: Missing shebang or wrong permissions?
**Impact**: `npx ansilust` fails with "permission denied"
**Mitigation**: Add shebang, git tracks as executable

### WIF-9: detect-libc Fails
**What if**: Library can't detect glibc vs musl?
**Impact**: Wrong platform package selected on Alpine/musl
**Mitigation**: Fallback to glibc (most common)
**Current**: launcher.js needs to handle this gracefully

### WIF-10: User Has No Native Package Available
**What if**: User on unsupported platform (e.g., FreeBSD)?
**Impact**: No binary, confusing error
**Mitigation**: Clear error message with supported platforms

## Absurd Edge Cases

### E1: What if someone runs `npx ansilust` on a smartwatch?
**Response**: Unsupported platform error. They'll survive.

### E2: What if npm registry goes down during publish?
**Response**: Retry. Also, we have GitHub releases as backup.

### E3: What if someone npm unpublishes our packages?
**Response**: Only we can do that. And npm has 24-hour grace period.

### E4: What if binary is 500MB due to debug symbols?
**Response**: Use ReleaseSafe, strip debug symbols. Currently 8MB.

## Priority Failure Points

1. **CRITICAL**: launcher.js must exist and work
2. **CRITICAL**: Platform package names must match exactly
3. **HIGH**: All 10 platform packages must publish before meta
4. **HIGH**: NPM_TOKEN must be configured
5. **MEDIUM**: Cross-compilation must succeed for all targets
6. **LOW**: Help/version flags in binary (nice to have)
