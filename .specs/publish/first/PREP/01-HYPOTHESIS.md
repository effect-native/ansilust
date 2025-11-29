# Hypothesis: First Publish Strategy

## The Prior

Based on the context:
- We have a working Zig build system
- We have placeholder npm packages published (`ansilust`, `16colors`, `16c`)
- We have a comprehensive spec for esbuild-style npm distribution
- We have install.sh and release.yml workflows sketched out
- We have changesets configured

**I expect the fastest path to "published somewhere usable" is:**

1. **GitHub Releases first** - Binary tarballs with checksums
2. **npm second** - Platform packages + meta launcher
3. **Everything else later** - AUR, Nix, install scripts from ansilust.com

**Assumptions:**
- The Zig build already produces working binaries for at least the native platform
- GitHub Actions can cross-compile to other targets
- The npm packages just need the launcher.js and binaries stuffed in
- We can ship v1.0.0 with just npm + GitHub releases working

**Rationale:**
- GitHub Releases is the simplest - just `gh release create` with binaries
- npm is the most user-visible - `npx ansilust` is the dream command
- install.sh from ansilust.com requires hosting setup (more friction)
- AUR/Nix can wait - smaller audience, more maintenance

**Key Question:** Can we get to `npx ansilust file.ans` working in one session?
