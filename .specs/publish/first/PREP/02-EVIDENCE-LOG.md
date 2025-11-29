# Evidence Log: First Publish Reality Check

## Raw Facts

### [SUPPORTS] Build System Works
- `zig build -Doptimize=ReleaseSafe` completes successfully
- Produces two binaries:
  - `zig-out/bin/ansilust` (8.3MB) - ANSI art renderer
  - `zig-out/bin/16c` (11.0MB) - 16colors archive downloader
- Both binaries execute correctly on native platform (Linux x64)

### [SUPPORTS] npm Infrastructure Exists
- Root `package.json` with workspaces configured
- Changesets installed (`@changesets/cli`, `@changesets/changelog-github`)
- Three placeholder packages published at v0.0.1:
  - `ansilust` - meta package with launcher stub
  - `16colors` - placeholder
  - `16c` - placeholder

### [SUPPORTS] Release Workflow Exists
- `.github/workflows/release.yml` - full matrix build (10 targets)
- `.github/workflows/changeset-version.yml` - version PR automation
- `scripts/install.sh` - complete bash installer (327 lines)
- `scripts/assemble-npm-packages.js` - platform package assembly script

### [SUPPORTS] Package Structure Defined
- `packages/ansilust/package.json` has:
  - `bin: {"ansilust": "bin/launcher.js"}` 
  - `dependencies: {"detect-libc": "^2.1.2"}`
  - `optionalDependencies` for all 10 platform packages
- BUT: One local file reference `"ansilust-linux-x64-gnu": "file:../ansilust-linux-x64-gnu"` - need to fix

### [FALSIFIES] Launcher Not Implemented
- `packages/ansilust/index.js` is just a placeholder console.log
- `packages/ansilust/bin/launcher.js` does NOT exist
- This blocks `npx ansilust` from working

### [FALSIFIES] Platform Packages Not Created
- No `packages/ansilust-*` directories exist (only `ansilust`, `16colors`, `16c`)
- Assembly script exists but hasn't been run
- Would need to create all 10 platform package directories

### [SUPPORTS] Cross-Compilation Targets Defined
Build matrix in release.yml covers:
- linux-x64-gnu, linux-x64-musl
- linux-arm64-gnu, linux-arm64-musl
- linux-armv7-gnu, linux-armv7-musl
- linux-i386-musl
- darwin-x64, darwin-arm64
- win32-x64

### [SUPPORTS] AUR Package Template Exists
- `aur/PKGBUILD` and `aur/.SRCINFO` exist
- Need to verify they reference correct URLs

### [SUPPORTS] Nix Flake Exists
- `flake.nix` at repository root
- Need to verify it's functional

## Critical Gaps

1. **No launcher.js** - npx won't work
2. **No platform packages** - npm install won't get binaries
3. **Local file reference** in optionalDependencies - will break publish
4. **No --version/--help** in ansilust binary - just usage message
5. **Assembly script** expects specific binary locations that don't match CI output

## Quick Wins

1. Create `bin/launcher.js` - ~50 lines of code
2. Create one platform package manually for testing
3. Fix the local file reference in package.json
4. Test `npm link` workflow locally before publishing
