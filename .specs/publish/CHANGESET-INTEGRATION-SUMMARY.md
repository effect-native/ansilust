# ✅ Changesets + esbuild-style npm Integration

## Phase 2 Requirements Updated

### Changes to `.specs/publish/requirements.md`

#### 1. FR1.3: npm Package Requirements (Completely Rewritten)

**Old approach**: Single package with all binaries or postinstall downloader
**New approach**: esbuild-style with meta package + platform packages

**New Requirements (16 total)**:
- FR1.3.1-3: Meta package + platform packages architecture
- FR1.3.4-9: Launcher logic (detect-libc, platform mapping, spawn)
- FR1.3.10-11: Global install + instant npx execution
- FR1.3.12-16: Platform package structure, versioning, documentation

**Platform packages to publish**:
- `ansilust` (meta package with launcher)
- `ansilust-darwin-arm64`, `ansilust-darwin-x64`
- `ansilust-linux-x64-gnu`, `ansilust-linux-x64-musl`
- `ansilust-linux-arm64-gnu`, `ansilust-linux-arm64-musl`
- `ansilust-linux-armv7-gnu`, `ansilust-linux-armv7-musl`
- `ansilust-linux-i386-musl` (for iSH on iOS)
- `ansilust-win32-x64`

#### 2. IR5.1: GitHub Actions Integration (Changesets)

**Added**:
- IR5.1.1: Mandatory Changesets usage
- IR5.1.2: Trigger on changesets version commits
- IR5.1.5: npm publishing via Changesets automation

#### 3. DEP6.2: Build Tools

**Added**:
- DEP6.2.9: @changesets/cli
- DEP6.2.10: @changesets/changelog-github
- Implicit: detect-libc (for launcher)

#### 4. Implementation Notes Section

**Added detailed documentation**:
- Existing npm package reservations (ansilust, 16colors, 16c)
- Changesets integration workflow
- Monorepo structure with workspace
- esbuild-style packaging strategy

---

## File Statistics

- **Before**: 751 lines
- **After**: ~850 lines
- **Added**: ~100 lines of implementation guidance

---

## Package Structure

### Meta Package: `ansilust`

```json
{
  "name": "ansilust",
  "version": "1.0.0",
  "bin": { "ansilust": "bin/launcher.js" },
  "dependencies": { "detect-libc": "^2.0.3" },
  "optionalDependencies": {
    "ansilust-darwin-arm64": "1.0.0",
    "ansilust-darwin-x64": "1.0.0",
    "ansilust-linux-x64-gnu": "1.0.0",
    "ansilust-linux-x64-musl": "1.0.0",
    "ansilust-linux-arm64-gnu": "1.0.0",
    "ansilust-linux-arm64-musl": "1.0.0",
    "ansilust-linux-armv7-gnu": "1.0.0",
    "ansilust-linux-armv7-musl": "1.0.0",
    "ansilust-linux-i386-musl": "1.0.0",
    "ansilust-win32-x64": "1.0.0"
  }
}
```

### Platform Package: `ansilust-linux-x64-gnu`

```json
{
  "name": "ansilust-linux-x64-gnu",
  "version": "1.0.0",
  "os": ["linux"],
  "cpu": ["x64"],
  "files": ["bin/", "index.js"],
  "main": "index.js"
}
```

**Contents**:
- `index.js`: Exports `binPath`
- `bin/ansilust`: Prebuilt Zig binary

---

## Release Workflow (Changesets)

1. Developer: `npx changeset` → Add changeset file
2. CI: Changesets bot creates version PR
3. Merge version PR → Updates package.json versions, generates CHANGELOG
4. CI triggers on version commit:
   - Build Zig binaries (all platforms)
   - Create platform package directories
   - Copy binaries into platform packages
   - `npm publish` all platform packages
   - Update meta package optionalDependencies
   - `npm publish` meta package
   - Create GitHub release with binaries
5. Users: `npx ansilust` works instantly

---

## Benefits

✅ **Zero download on `npx`**: Binary already in npm cache
✅ **Works offline**: After first install
✅ **Fast**: No postinstall downloads
✅ **Automatic**: npm picks correct platform
✅ **Battle-tested**: esbuild, swc, Biome use this
✅ **Changesets**: Proper versioning and changelogs
✅ **Monorepo-ready**: Works with existing packages/ structure

---

## Next Phase: Design (Phase 3)

Will create `design.md` with:

1. **Launcher Implementation**
   - Full launcher.js code
   - Platform detection algorithm
   - Error handling

2. **Platform Package Generation**
   - CI build matrix
   - Package assembly script
   - Version synchronization

3. **Changesets Configuration**
   - .changeset/config.json
   - Root package.json workspaces
   - GitHub Actions workflows

4. **Build System Integration**
   - Zig targets → npm packages
   - Binary placement in platform packages
   - Artifact collection strategy

5. **Install Script Design**
   - Bash installer detailed logic
   - PowerShell installer detailed logic
   - Platform detection algorithms

---

## Current Status

✅ **Phase 1**: Instructions complete
✅ **Phase 2**: Requirements complete (with esbuild-style + Changesets)
⏭️ **Phase 3**: Design phase ready to begin

**npm packages secured**:
- ansilust, 16colors, 16c (v0.0.1 placeholders published)

**Ready for**:
- Changesets initialization
- Launcher implementation
- CI/CD workflow design
