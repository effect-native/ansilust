# First Publish Analysis - Summary

## Current State (2025-11-29)

### Branch: `feat/publish-v1`
Pushed to: https://github.com/effect-native/ansilust/tree/feat/publish-v1

### What Works
- **Zig build** produces working binaries for Linux and macOS
- **Cross-compilation** works for 8/10 platforms (not Windows)
- **npm launcher.js** detects platform and spawns binary correctly
- **Platform package structure** is correct (tested with local symlink)
- **Changesets** is configured in monorepo
- **GitHub Actions workflows** exist (release.yml, changeset-version.yml)
- **Install scripts** exist (install.sh is complete, install.ps1 exists)

### What's Broken/Missing
1. **Windows build fails** - POSIX API usage in code (deferred to v1.1.0)
2. **npm OIDC not configured** - see MANUAL-STEPS.md for setup
3. **AUR_SSH_KEY secret not configured** - can skip for v1.0.0
4. **Platform packages created by CI** - assembly script ready
5. **No GitHub release yet** - pending OIDC setup

### Critical Path to v1.0.0

```
1. [MANUAL] Configure npm OIDC for effect-native org (see MANUAL-STEPS.md)
2. [MANUAL] Add AUR_SSH_KEY secret (or skip AUR for v1.0.0)
3. [CODE]   Update release.yml to skip Windows target (DONE)
4. [CODE]   Create changeset for v1.0.0
5. [CI]     Push, let changesets create version PR
6. [MANUAL] Merge version PR
7. [CI]     Release workflow runs on version merge
8. [VERIFY] npx ansilust@1.0.0 works
```

### Platforms for v1.0.0

| Platform | Status | Notes |
|----------|--------|-------|
| linux-x64-gnu | READY | Primary target |
| linux-x64-musl | READY | Alpine/containers |
| linux-arm64-gnu | READY | RPi 4, Apple Silicon VMs |
| linux-arm64-musl | READY | Alpine ARM |
| linux-arm-gnu | READY | RPi 2/3 |
| linux-arm-musl | READY | Older embedded |
| darwin-x64 | READY | Intel Macs |
| darwin-arm64 | READY | Apple Silicon |
| win32-x64 | BLOCKED | POSIX API usage |
| linux-i386-musl | UNTESTED | Low priority |

### Commits on feat/publish-v1

1. **9e1c37e** - PREP analysis for v1.0.0 release strategy
2. **dcb786a** - Fix ARM64 arch naming (Darwin=arm64, Linux=aarch64)
3. **dab17f6** - Add manual steps documentation

### Files Modified

- `.github/workflows/release.yml` - Disabled Windows, improved artifact handling
- `packages/ansilust/package.json` - Fixed file: reference in optionalDeps
- `packages/ansilust/bin/launcher.js` - Fixed ARM64 architecture naming
- `scripts/assemble-npm-packages.js` - Added CI/local mode support
- `.gitignore` - Allow launcher.js to be tracked
- `.specs/publish/first/` - PREP analysis and specs

### Immediate Next Steps

1. **[MANUAL]** Configure npm OIDC (see MANUAL-STEPS.md)
2. **[OPTIONAL]** Test release with `v0.0.2-test.1` tag
3. **[MANUAL]** Create PR and merge feat/publish-v1 to main
4. **[MANUAL]** Create changeset for v1.0.0
5. **[AUTO]** Release workflow builds and publishes (using OIDC provenance)

### Later (v1.1.0)

- Fix Windows POSIX API usage
- Add linux-i386-musl build
- Set up AUR SSH key for automatic updates
