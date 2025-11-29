# Theoretical Framework: Minimum Viable Publish

## Working Model (Updated from Hypothesis)

After evidence gathering, the hypothesis holds with modifications:

**Original**: GitHub Releases first, npm second
**Revised**: **npm first**, then GitHub Releases

**Rationale**: 
- npm is higher value (users type `npx ansilust`)
- GitHub releases are just file uploads (trivial)
- npm publishing has more moving parts (test it first)

## Execution Plan

### Phase A: Local Testing (30 mins)

1. **Create launcher.js** (~50 lines)
   - Detect platform/arch/libc
   - Map to package name
   - Require package, spawn binary

2. **Create one platform package** for testing
   - `packages/ansilust-linux-x64-gnu/`
   - Copy native binary
   - Generate package.json, index.js

3. **Fix meta package.json**
   - Remove `file:` reference
   - Point all to `1.0.0` (target version)

4. **Test with npm link**
   - `npm link packages/ansilust-linux-x64-gnu`
   - `npm link packages/ansilust`
   - Run `npx ansilust test_16colors.ans`
   - Verify it works

### Phase B: Cross-Compilation Verify (15 mins)

5. **Test one cross-compile target**
   - `zig build -Dtarget=aarch64-linux-gnu -Doptimize=ReleaseSafe`
   - Verify binary created at expected path

6. **Verify assembly script works**
   - Run `node scripts/assemble-npm-packages.js`
   - Check platform packages created

### Phase C: CI Dry Run (30 mins)

7. **Push to branch, test workflow**
   - Create test tag (e.g., `v0.0.2-test.1`)
   - Watch GitHub Actions
   - Fix any issues

### Phase D: First Real Release (15 mins)

8. **Create changeset**
   - `npx changeset add` → major bump
   - Merge version PR

9. **Tag and release**
   - `git tag v1.0.0`
   - `git push origin v1.0.0`
   - Monitor workflow

10. **Verify**
    - `npx ansilust --help` (or just usage)
    - Download from GitHub releases
    - Test install.sh (once hosting configured)

## Critical Path

```
launcher.js → platform package → npm link test → cross-compile test → CI dry-run → release
```

## Files to Create/Modify

### Create:
1. `packages/ansilust/bin/launcher.js` - ~60 lines
2. `packages/ansilust-linux-x64-gnu/` - for local testing

### Modify:
1. `packages/ansilust/package.json` - fix optionalDependencies
2. `scripts/assemble-npm-packages.js` - verify path handling

### Verify:
1. `.github/workflows/release.yml` - check artifact paths
2. `build.zig` - check output location

## Success Criteria

- [ ] `npm link` test passes locally
- [ ] `zig build -Dtarget=X` works for all targets
- [ ] CI workflow completes without error
- [ ] `npx ansilust@1.0.0 test.ans` works after publish
- [ ] GitHub release has all 10 platform archives + checksums
