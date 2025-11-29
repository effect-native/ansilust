# Constants: Undeniable Truths and Constraints

## Technical Constants

### C1: Zig Cross-Compilation
- Zig can cross-compile to all target platforms from any host
- No need for platform-specific CI runners
- Single `ubuntu-latest` can build all 10 targets

### C2: npm Package Names Reserved
- `ansilust`, `16colors`, `16c` are published at v0.0.1
- We own these names; no squatting risk
- Next publish must be >=0.0.2 or use `--force`

### C3: GitHub Repository
- `effect-native/ansilust` exists
- GitHub Actions enabled
- GitHub Actions must be configured for npm OIDC authentication (no NPM_TOKEN secret required)

### C4: Binary Works
- Native build produces working binaries
- `ansilust test.ans` renders ANSI correctly
- `16c random-1` downloads and displays art

### C5: esbuild-style Packaging Pattern
- Meta package + optional platform packages
- Launcher detects platform → requires platform package → spawns binary
- Well-documented pattern, battle-tested by esbuild, swc, biome

## Constraints

### Hard Constraints

1. **npm optionalDependencies must be published packages**
   - Cannot use `file:` references in published packages
   - All platform packages must be published first, then meta package

2. **Version synchronization required**
   - All packages must use same version
   - Changesets handles this for us

3. **Binary must be in correct location**
   - Platform package exports `binPath`
   - Launcher requires this path
   - Binary must be at `bin/ansilust` (or `bin/ansilust.exe`)

4. **Launcher must exist at bin entry**
   - `packages/ansilust/bin/launcher.js` must exist
   - Must be executable (`#!/usr/bin/env node`)
   - Must handle platform detection + binary spawn

### Soft Constraints

1. **GitHub Actions minutes**
   - Free tier has limits
   - Sequential builds on single runner conserve minutes
   - ~7-12 minutes for all 10 platforms

2. **npm publish rate limits**
   - Can't spam publishes
   - 10 platform packages + 1 meta = 11 publishes per release

3. **User expectations**
   - `npx ansilust --help` should work
   - Currently binary doesn't have --help (just usage on no args)
   - Acceptable for v1.0.0? (Yes - functional is enough)

## Immutable Dependencies

### For npm Publish
1. NPM_TOKEN secret in GitHub Actions
2. All platform packages created and ready
3. launcher.js implemented
4. optionalDependencies point to npm packages (not local files)

### For GitHub Release
1. Binaries built for all platforms
2. SHA256SUMS file generated
3. Archives created (tar.gz/zip)
4. Release created with assets attached

### For Local Testing
1. `npm link` to test meta package
2. Platform package with binary for current platform
3. launcher.js that can detect and spawn
