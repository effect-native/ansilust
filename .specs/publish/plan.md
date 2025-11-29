# Publishing & Distribution - Implementation Plan

**Phase**: 4 - Plan
**Status**: In Progress
**Dependencies**: design.md (Phase 3 complete)

---

## Overview

This document provides a detailed implementation roadmap for the ansilust publishing and distribution system. The plan follows a 5-phase structure with clear milestones, dependencies, and validation checkpoints.

**Approach**: Build incrementally, validate continuously, ship confidently.

**Philosophy**: Trust yourself, test locally, fix forward. No elaborate CI test suites—if `zig build` succeeds for all targets, ship it.

---

## v1.0.0 Scope Decisions

**INCLUDED** ✅:
- npm (npx + global install)
- AUR (Arch Linux)
- Nix (all platforms)
- Bash installer (Linux/macOS)
- PowerShell installer (Windows)
- GitHub Container Registry (GHCR only)
- GitHub releases (manual download)

**EXCLUDED** ❌:
- Homebrew (deferred - low priority)
- iOS APT packages (deferred - no test devices)
- Docker Hub (GHCR sufficient)
- GPG signing (deferred - SHA256 sufficient)
- Install analytics (privacy-first approach)

---

## Implementation Phases

### Phase 1: Foundation Setup ⬜
### Phase 2: Build System & npm Packages ⬜
### Phase 3: Install Scripts & Automation ⬜
### Phase 4: Package Managers & Deployment ⬜
### Phase 5: Validation & Release ⬜

---

## Phase 1: Foundation Setup

**Objective**: Set up monorepo infrastructure, Changesets, and repository structure.

**Duration Estimate**: 1-2 days

### 1.1: Monorepo Configuration

- [ ] **1.1.1**: Create root `package.json` with workspace configuration
  - **Details**:
    ```json
    {
      "name": "ansilust-monorepo",
      "private": true,
      "workspaces": [
        "packages/*"
      ]
    }
    ```
  - **Validation**: `npm install` succeeds, workspace recognized

- [ ] **1.1.2**: Verify existing placeholder packages
  - **Details**: Check `packages/ansilust/`, `packages/16colors/`, `packages/16c/`
  - **Validation**: Each has valid `package.json` at v0.0.1

- [ ] **1.1.3**: Create `.gitignore` entries for node_modules and build artifacts
  - **Details**: Add `node_modules/`, `packages/*/bin/`, `zig-out/`, `.changeset/*.md` exclusions
  - **Validation**: Clean git status after build

- [ ] **1.1.4**: Document monorepo structure in README
  - **Details**: Add section explaining packages/ directory and workspace setup
  - **Validation**: Documentation matches actual structure

**Dependencies**: None

**Validation Checkpoint**:
```bash
npm install
# Should install workspace packages
npm ls --workspaces
# Should list ansilust, 16colors, 16c
```

---

### 1.2: Changesets Initialization

- [ ] **1.2.1**: Install Changesets dependencies
  - **Command**: `npm install -D @changesets/cli @changesets/changelog-github`
  - **Validation**: Packages in devDependencies

- [ ] **1.2.2**: Initialize Changesets
  - **Command**: `npx changeset init`
  - **Details**: Creates `.changeset/` directory with `config.json` and `README.md`
  - **Validation**: `.changeset/config.json` exists

- [ ] **1.2.3**: Configure Changesets for monorepo
  - **Details**: Edit `.changeset/config.json`:
    ```json
    {
      "$schema": "https://unpkg.com/@changesets/config@2.3.0/schema.json",
      "changelog": ["@changesets/changelog-github", { "repo": "effect-native/ansilust" }],
      "commit": false,
      "fixed": [],
      "linked": [["ansilust", "ansilust-*"]],
      "access": "public",
      "baseBranch": "main",
      "updateInternalDependencies": "patch",
      "ignore": []
    }
    ```
  - **Validation**: `npx changeset status` runs without errors

- [ ] **1.2.4**: Create initial changeset for v1.0.0 preparation
  - **Command**: `npx changeset add`
  - **Details**: Mark as `major` for all packages, message: "Initial release infrastructure"
  - **Validation**: `.changeset/*.md` file created

**Dependencies**: 1.1 (Monorepo Configuration)

**Validation Checkpoint**:
```bash
npx changeset status
# Should show pending changesets
npx changeset version --dry-run
# Should preview version bumps
```

---

### 1.3: GitHub Repository Configuration

- [ ] **1.3.1**: Create GitHub Actions secrets
  - **Secrets to add**:
    - `NPM_TOKEN`: npm publish token
  - **Validation**: Secrets visible in repo settings

- [ ] **1.3.2**: Set up separate AUR package repository
  - **Details**: Clone AUR repo for `ansilust` package
  - **Location**: `aur.archlinux.org/ansilust.git`
  - **Validation**: Repository cloned locally

- [ ] **1.3.3**: Create `flake.nix` at repository root
  - **Details**: Nix flake MUST be at root (not in subdirectory)
  - **Structure**:
    ```nix
    {
      description = "ansilust - next-gen text art processing";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      outputs = { self, nixpkgs }: {
        packages = /* ... */;
      };
    }
    ```
  - **Validation**: `nix flake check` succeeds

**Dependencies**: None

**Validation Checkpoint**:
```bash
# Verify secrets configured
gh secret list

# Verify AUR repo cloned
test -d ../aur-ansilust

# Verify Nix flake
nix flake check
```

---

### 1.4: Directory Structure Creation

- [ ] **1.4.1**: Create `scripts/` directory for installers and utilities
  - **Files to create**:
    - `scripts/install.sh` (placeholder)
    - `scripts/install.ps1` (placeholder)
    - `scripts/assemble-npm-packages.js` (placeholder)
    - `scripts/generate-checksums.sh` (placeholder)
  - **Validation**: All files exist with header comments

- [ ] **1.4.2**: Create platform package placeholders in `packages/`
  - **Directories to create**:
    - `packages/ansilust-darwin-arm64/`
    - `packages/ansilust-darwin-x64/`
    - `packages/ansilust-linux-x64-gnu/`
    - `packages/ansilust-linux-x64-musl/`
    - `packages/ansilust-linux-arm64-gnu/`
    - `packages/ansilust-linux-arm64-musl/`
    - `packages/ansilust-linux-armv7-gnu/`
    - `packages/ansilust-linux-armv7-musl/`
    - `packages/ansilust-linux-i386-musl/`
    - `packages/ansilust-win32-x64/`
  - **Validation**: 10 platform package directories exist

- [ ] **1.4.3**: Create GitHub Actions workflow directory
  - **Files to create**:
    - `.github/workflows/release.yml` (placeholder)
    - `.github/workflows/changeset-version.yml` (placeholder)
  - **Validation**: Workflow files exist

- [ ] **1.4.4**: Update repository README with installation methods
  - **Sections to add**:
    - Installation (all methods)
    - Platform support matrix
    - Development setup
  - **Validation**: README includes all installation methods

**Dependencies**: 1.1 (Monorepo Configuration)

**Validation Checkpoint**:
```bash
tree packages/ | grep -E 'ansilust-'
# Should show 10 platform packages

tree scripts/
# Should show install scripts and utilities

tree .github/workflows/
# Should show release.yml and changeset-version.yml
```

---

### Phase 1 Completion Criteria

- ✅ Monorepo with workspaces configured
- ✅ Changesets initialized and configured
- ✅ GitHub secrets configured
- ✅ Repository structure created
- ✅ Separate Homebrew/AUR repos set up
- ✅ Nix flake at repository root
- ✅ Documentation updated

**Validation Command**:
```bash
npm install && \
npx changeset status && \
nix flake check && \
test -d packages/ansilust-darwin-arm64 && \
test -f scripts/install.sh && \
test -f .github/workflows/release.yml && \
echo "✅ Phase 1 Complete"
```

---

## Phase 2: Build System & npm Packages

**Objective**: Implement Zig cross-compilation, npm launcher, and platform packages.

**Duration Estimate**: 2-3 days

### 2.1: Zig Build Configuration

- [ ] **2.1.1**: Update `build.zig` with cross-compilation targets
  - **Details**: Add build options for all 10 targets
  - **Targets**:
    - `x86_64-macos`, `aarch64-macos`
    - `x86_64-linux-gnu`, `x86_64-linux-musl`
    - `aarch64-linux-gnu`, `aarch64-linux-musl`
    - `armv7-linux-gnueabihf`, `armv7-linux-musleabihf`
    - `i386-linux-musl`
    - `x86_64-windows`
  - **Validation**: `zig build -Dtarget=x86_64-linux-gnu` succeeds

- [ ] **2.1.2**: Configure output directories for each target
  - **Details**: Output to `zig-out/{target}/ansilust`
  - **Validation**: Binaries placed in correct directories

- [ ] **2.1.3**: Add release optimization flags
  - **Details**: Set `-Doptimize=ReleaseSafe`, strip debug symbols
  - **Validation**: Binary size < 5MB per platform

- [ ] **2.1.4**: Test local builds for all targets
  - **Command**: `zig build -Dtarget={each-target}`
  - **Validation**: All 10 binaries build successfully

**Dependencies**: None (Zig already configured)

**Validation Checkpoint**:
```bash
for target in x86_64-linux-gnu aarch64-macos x86_64-windows; do
  zig build -Dtarget=$target
  test -f zig-out/$target/ansilust || echo "Missing: $target"
done
# All binaries should exist
```

---

### 2.2: npm Meta Package (ansilust)

- [ ] **2.2.1**: Create launcher script `packages/ansilust/bin/launcher.js`
  - **Details**: Implement platform detection, package selection, binary execution
  - **Functions**:
    - `detectPlatform()`: Returns platform string
    - `selectPackage()`: Maps platform to package name
    - `executeBinary()`: Spawns binary with args
  - **Validation**: `node launcher.js --help` works locally

- [ ] **2.2.2**: Add `detect-libc` dependency to meta package
  - **Command**: `cd packages/ansilust && npm install detect-libc@^2.0.3`
  - **Validation**: Dependency in `package.json`

- [ ] **2.2.3**: Update meta package `package.json`
  - **Details**:
    ```json
    {
      "name": "ansilust",
      "version": "0.0.1",
      "bin": { "ansilust": "bin/launcher.js" },
      "dependencies": { "detect-libc": "^2.0.3" },
      "optionalDependencies": {
        "ansilust-darwin-arm64": "0.0.1",
        "ansilust-darwin-x64": "0.0.1",
        /* ...all 10 platform packages */
      }
    }
    ```
  - **Validation**: Valid `package.json`, versions match

- [ ] **2.2.4**: Create platform detection algorithm
  - **Details**: Map `process.platform` + `process.arch` + libc → package name
  - **Platform map**:
    - `darwin` + `arm64` → `ansilust-darwin-arm64`
    - `linux` + `x64` + `glibc` → `ansilust-linux-x64-gnu`
    - `linux` + `x64` + `musl` → `ansilust-linux-x64-musl`
    - (see design.md for complete mapping)
  - **Validation**: Unit tests for all platform combinations

- [ ] **2.2.5**: Implement error handling in launcher
  - **Cases**:
    - Unsupported platform → Error with help message
    - Platform package missing → Install instructions
    - Binary not found → Reinstall instructions
  - **Validation**: Error messages clear and actionable

- [ ] **2.2.6**: Make launcher executable
  - **Command**: `chmod +x packages/ansilust/bin/launcher.js`
  - **Details**: Add shebang `#!/usr/bin/env node`
  - **Validation**: Direct execution works: `./packages/ansilust/bin/launcher.js`

**Dependencies**: 2.1 (Zig builds working)

**Validation Checkpoint**:
```bash
cd packages/ansilust
node bin/launcher.js --version
# Should detect platform and attempt to run binary
```

---

### 2.3: Platform Package Assembly

- [ ] **2.3.1**: Create `scripts/assemble-npm-packages.js` script
  - **Purpose**: Generate platform packages from Zig binaries
  - **Inputs**: `zig-out/{target}/ansilust` binaries, version number
  - **Outputs**: Complete platform package directories
  - **Validation**: Script runs without errors

- [ ] **2.3.2**: Implement package directory creation
  - **Algorithm**:
    1. For each target in build matrix
    2. Create `packages/{npm-package-name}/bin/`
    3. Copy binary: `cp zig-out/{target}/ansilust → packages/{npm-package-name}/bin/`
    4. Generate `package.json`, `index.js`, `README.md`
  - **Validation**: 10 platform packages populated

- [ ] **2.3.3**: Generate platform package `package.json`
  - **Template**:
    ```json
    {
      "name": "ansilust-linux-x64-gnu",
      "version": "VERSION",
      "os": ["linux"],
      "cpu": ["x64"],
      "main": "index.js",
      "files": ["bin/", "index.js", "README.md", "LICENSE"]
    }
    ```
  - **Validation**: All 10 packages have valid `package.json`

- [ ] **2.3.4**: Generate platform package `index.js`
  - **Template**:
    ```javascript
    const path = require('path');
    exports.binPath = path.join(__dirname, 'bin/ansilust');
    ```
  - **Validation**: `require('ansilust-linux-x64-gnu').binPath` returns path

- [ ] **2.3.5**: Copy LICENSE and README to each platform package
  - **Details**: Use root LICENSE, generate platform-specific README
  - **Validation**: All packages have LICENSE and README

- [ ] **2.3.6**: Test assembly script locally
  - **Command**: `node scripts/assemble-npm-packages.js`
  - **Validation**: 10 platform packages created with binaries

**Dependencies**: 2.1 (Zig builds), 2.2 (Meta package structure)

**Validation Checkpoint**:
```bash
node scripts/assemble-npm-packages.js
ls packages/ansilust-*/bin/ansilust
# Should show 10 binaries

node -e "console.log(require('./packages/ansilust-linux-x64-gnu').binPath)"
# Should print path to binary
```

---

### 2.4: Local npm Package Testing

- [ ] **2.4.1**: Link meta package globally for testing
  - **Command**: `cd packages/ansilust && npm link`
  - **Validation**: `which ansilust` shows linked binary

- [ ] **2.4.2**: Test platform detection on current system
  - **Command**: `ansilust --version`
  - **Validation**: Detects platform, spawns binary, shows version

- [ ] **2.4.3**: Test with missing platform package
  - **Details**: Temporarily remove current platform package
  - **Validation**: Error message displays install instructions

- [ ] **2.4.4**: Test with corrupted binary
  - **Details**: Replace binary with empty file
  - **Validation**: Error message suggests reinstall

- [ ] **2.4.5**: Unlink and clean up test installation
  - **Command**: `npm unlink -g ansilust`
  - **Validation**: `which ansilust` returns nothing

**Dependencies**: 2.2 (Launcher), 2.3 (Platform packages)

**Validation Checkpoint**:
```bash
npm link packages/ansilust
ansilust --version
# Should work
npm unlink -g ansilust
```

---

### Phase 2 Completion Criteria

- ✅ Zig builds all 10 targets successfully
- ✅ npm launcher detects platform and spawns binary
- ✅ Platform packages structured correctly
- ✅ Assembly script generates all packages
- ✅ Local testing passes
- ✅ Error handling robust

**Validation Command**:
```bash
zig build -Dtarget=x86_64-linux-gnu && \
node scripts/assemble-npm-packages.js && \
npm link packages/ansilust && \
ansilust --version && \
npm unlink -g ansilust && \
echo "✅ Phase 2 Complete"
```

---

## Phase 3: Install Scripts & Automation

**Objective**: Implement Bash/PowerShell installers and GitHub Actions workflows.

**Duration Estimate**: 2-3 days

### 3.1: Bash Installer Script

- [ ] **3.1.1**: Create header with source links
  - **Details**: Add header to `scripts/install.sh`:
    ```bash
    #!/usr/bin/env bash
    # ansilust installer script
    #
    # Served from: https://ansilust.com/install
    # Source: https://github.com/effect-native/ansilust/blob/main/scripts/install.sh
    #
    # Usage: curl -fsSL https://ansilust.com/install | bash
    ```
  - **Validation**: Header includes GitHub source URL

- [ ] **3.1.2**: Implement `detect_platform()` function
  - **Detection logic**:
    - OS: `uname -s` → Linux, Darwin
    - Arch: `uname -m` → x86_64, aarch64, armv7l, i686
    - libc (Linux only): Check `/lib/ld-musl*` or `ldd --version | grep musl`
    - Map to: `linux-x64-musl`, `darwin-arm64`, etc.
  - **Validation**: Detects current platform correctly

- [ ] **3.1.3**: Implement `download_binary()` function
  - **Details**:
    - Construct URL: `https://github.com/effect-native/ansilust/releases/latest/download/ansilust-{platform}.tar.gz`
    - Download to `/tmp/ansilust.tar.gz`
    - Retry up to 3 times on failure
  - **Validation**: Downloads succeed with retries

- [ ] **3.1.4**: Implement `verify_checksum()` function
  - **Details**:
    - Download `SHA256SUMS` to `/tmp/`
    - Run `sha256sum --check --ignore-missing SHA256SUMS`
    - Abort if verification fails
  - **Validation**: Rejects corrupted downloads

- [ ] **3.1.5**: Implement `install_binary()` function
  - **Details**:
    - Extract: `tar -xzf ansilust.tar.gz -C /tmp`
    - Install to `~/.local/bin/` or `/usr/local/bin/` (with sudo if needed)
    - Make executable: `chmod +x`
    - Add to PATH if not present
  - **Validation**: Binary installed and executable

- [ ] **3.1.6**: Add cleanup on exit
  - **Details**: `trap cleanup EXIT` to remove temp files
  - **Validation**: `/tmp/ansilust*` removed after script exits

- [ ] **3.1.7**: Test installer locally (dry run)
  - **Command**: `bash -n scripts/install.sh` (syntax check)
  - **Validation**: No syntax errors

**Dependencies**: None

**Validation Checkpoint**:
```bash
bash -n scripts/install.sh
# No errors

# Manual test (requires binaries in GitHub releases):
# bash scripts/install.sh
# ansilust --version
```

---

### 3.2: PowerShell Installer Script

- [ ] **3.2.1**: Create header with source links
  - **Details**: Add header to `scripts/install.ps1`:
    ```powershell
    # ansilust installer script
    #
    # Served from: https://ansilust.com/install.ps1
    # Source: https://github.com/effect-native/ansilust/blob/main/scripts/install.ps1
    #
    # Usage: irm ansilust.com/install.ps1 | iex
    ```
  - **Validation**: Header includes GitHub source URL

- [ ] **3.2.2**: Implement `Detect-Platform` function
  - **Detection logic**:
    - OS: Always `win32`
    - Arch: `$env:PROCESSOR_ARCHITECTURE` → `x64`, `arm64`
    - Return: `win32-x64` or `win32-arm64`
  - **Validation**: Detects correct architecture

- [ ] **3.2.3**: Implement `Download-Binary` function
  - **Details**:
    - Construct URL: `https://github.com/effect-native/ansilust/releases/latest/download/ansilust-win32-x64.zip`
    - Download to `$env:TEMP\ansilust.zip`
    - Use `Invoke-WebRequest` with retry logic
  - **Validation**: Downloads succeed

- [ ] **3.2.4**: Implement `Verify-Checksum` function
  - **Details**:
    - Download `SHA256SUMS`
    - Compute hash: `Get-FileHash -Algorithm SHA256`
    - Compare with expected hash
    - Abort if mismatch
  - **Validation**: Rejects corrupted downloads

- [ ] **3.2.5**: Implement `Install-Binary` function
  - **Details**:
    - Extract: `Expand-Archive` to `$env:LOCALAPPDATA\Programs\ansilust\`
    - Add to PATH: Modify user environment variable
    - Display success message
  - **Validation**: Binary installed and in PATH

- [ ] **3.2.6**: Add try/finally cleanup
  - **Details**: Remove temp files in `finally` block
  - **Validation**: Temp files removed

- [ ] **3.2.7**: Test installer locally (syntax check)
  - **Command**: `powershell -File scripts/install.ps1 -WhatIf` (if available)
  - **Validation**: No syntax errors

**Dependencies**: None

**Validation Checkpoint**:
```powershell
# Syntax check (Windows)
Get-Content scripts/install.ps1 | Out-Null
# No errors

# Manual test (requires binaries in GitHub releases):
# .\scripts\install.ps1
# ansilust --version
```

---

### 3.3: Checksum Generation Script

- [ ] **3.3.1**: Create `scripts/generate-checksums.sh`
  - **Details**:
    - List all files in artifact directory
    - Compute SHA256 for each
    - Write to `SHA256SUMS` file
    - Sort alphabetically
  - **Validation**: Checksums match binary hashes

- [ ] **3.3.2**: ~~Add GPG signing support~~ **SKIPPED** (deferred to v1.1.0+)
  - **Rationale**: SHA256 checksums sufficient for v1.0.0

- [ ] **3.3.3**: Test checksum script locally
  - **Command**: `bash scripts/generate-checksums.sh zig-out/`
  - **Validation**: `SHA256SUMS` file created with all binaries

**Dependencies**: 2.1 (Zig builds)

**Validation Checkpoint**:
```bash
zig build -Dtarget=x86_64-linux-gnu
bash scripts/generate-checksums.sh zig-out/
sha256sum --check SHA256SUMS
# All: OK
```

---

### 3.4: GitHub Actions Release Workflow

- [ ] **3.4.1**: Create `.github/workflows/release.yml`
  - **Trigger**: Tag push matching `v*` pattern
  - **Jobs**: build, assemble-npm, publish-npm, create-release, update-aur, build-containers
  - **Validation**: Workflow file valid YAML

- [ ] **3.4.2**: Implement build job with matrix
  - **Matrix**: All 10 targets
  - **Steps**:
    1. Checkout code
    2. Setup Zig
    3. Build for target
    4. Upload artifact
  - **Validation**: Matrix defined for all platforms

- [ ] **3.4.3**: Implement assemble-npm job
  - **Steps**:
    1. Download all build artifacts
    2. Run `scripts/assemble-npm-packages.js`
    3. Upload platform packages as artifacts
  - **Validation**: All platform packages created

- [ ] **3.4.4**: Implement publish-npm job
  - **Steps**:
    1. Download platform packages
    2. Set npm auth token
    3. Publish all platform packages
    4. Publish meta package
  - **Validation**: Publishes to npm registry

- [ ] **3.4.5**: Implement create-release job
  - **Steps**:
    1. Download all binaries
    2. Generate checksums
    3. Create GitHub release
    4. Upload binaries and checksums
  - **Validation**: GitHub release created with assets

- [ ] **3.4.6**: Implement update-aur job
  - **Steps**:
    1. Clone AUR repository
    2. Update PKGBUILD with new version and checksums
    3. Generate .SRCINFO
    4. Commit and push to AUR
  - **Validation**: AUR package updated

- [ ] **3.4.7**: Implement build-containers job
  - **Steps**:
    1. Download binaries
    2. Build multi-arch container images
    3. Push to GitHub Container Registry
  - **Validation**: Container images available at `ghcr.io/effect-native/ansilust`

**Dependencies**: 2.1 (Zig), 2.3 (Assembly script), 3.3 (Checksums)

**Validation Checkpoint**:
```bash
# Validate workflow syntax
gh workflow view release.yml
# Should show workflow structure

# Dry-run (requires tag):
# git tag v0.1.0-test
# git push --tags
# (monitor GitHub Actions)
```

---

### 3.5: Changesets Version Workflow

- [ ] **3.5.1**: Create `.github/workflows/changeset-version.yml`
  - **Trigger**: Push to `main` branch
  - **Job**: Version PR creation
  - **Validation**: Workflow file valid

- [ ] **3.5.2**: Implement version PR job
  - **Steps**:
    1. Checkout code
    2. Setup Node.js
    3. Run `npx changeset version`
    4. Create PR with version bumps
  - **Validation**: PR created with updated versions

- [ ] **3.5.3**: Configure Changesets GitHub action
  - **Details**: Use `changesets/action@v1`
  - **Inputs**: GitHub token, publish command
  - **Validation**: Action runs on changesets

**Dependencies**: 1.2 (Changesets setup)

**Validation Checkpoint**:
```bash
# Test locally
npx changeset add
# Add changeset

git add .changeset/*.md
git commit -m "Add test changeset"
git push

# Monitor GitHub Actions for version PR creation
```

---

### Phase 3 Completion Criteria

- ✅ Bash installer works on Linux/macOS
- ✅ PowerShell installer works on Windows
- ✅ Checksum generation automated
- ✅ GitHub Actions release workflow complete
- ✅ Changesets version workflow complete
- ✅ All workflows validated (syntax + dry-run)

**Validation Command**:
```bash
bash -n scripts/install.sh && \
bash scripts/generate-checksums.sh zig-out/ && \
gh workflow view release.yml && \
gh workflow view changeset-version.yml && \
echo "✅ Phase 3 Complete"
```

---

## Phase 4: Package Managers & Deployment

**Objective**: Set up AUR, Nix, and domain hosting.

**Duration Estimate**: 1-2 days

**Note**: Homebrew EXCLUDED from v1.0.0 (deferred indefinitely)

---

### 4.1: AUR Package

- [ ] **4.1.1**: Create PKGBUILD in separate AUR repository
  - **Location**: `aur-ansilust/PKGBUILD` (at root, NOT in subdirectory)
  - **Why**: AUR packages MUST have PKGBUILD at root
  - **Validation**: AUR repo cloned locally

- [ ] **4.1.2**: Implement PKGBUILD
  - **Details**:
    ```bash
    pkgname=ansilust
    pkgver=VERSION
    pkgrel=1
    pkgdesc="Next-generation text art processing"
    arch=('x86_64' 'aarch64' 'armv7h')
    url="https://github.com/effect-native/ansilust"
    license=('MIT')
    source_x86_64=("$url/releases/download/v$pkgver/ansilust-linux-x64-gnu.tar.gz")
    source_aarch64=("$url/releases/download/v$pkgver/ansilust-linux-arm64-gnu.tar.gz")
    sha256sums_x86_64=('CHECKSUM')
    sha256sums_aarch64=('CHECKSUM')

    package() {
      install -Dm755 ansilust "$pkgdir/usr/bin/ansilust"
    }
    ```
  - **Validation**: PKGBUILD syntax valid (`makepkg --printsrcinfo`)

- [ ] **4.1.3**: Generate .SRCINFO
  - **Command**: `makepkg --printsrcinfo > .SRCINFO`
  - **Validation**: .SRCINFO matches PKGBUILD

- [ ] **4.1.4**: Test package locally
  - **Command**: `makepkg -si` (in AUR repo directory)
  - **Validation**: Installs and `ansilust --version` works

- [ ] **4.1.5**: Create update script for CI
  - **Purpose**: Update PKGBUILD + .SRCINFO on release
  - **Validation**: Script updates both files correctly

**Dependencies**: 2.1 (Binaries), 3.4 (GitHub releases)

**Validation Checkpoint**:
```bash
# In aur-ansilust repo
makepkg --printsrcinfo > .SRCINFO
makepkg -si
ansilust --version
```

---

### 4.2: Nix Flake

- [ ] **4.2.1**: Implement `flake.nix` at repository root
  - **Location**: `/flake.nix` (MUST be at root, not subdirectory)
  - **Why**: Nix flakes MUST be at repository root
  - **Details**:
    ```nix
    {
      description = "ansilust - next-generation text art processing";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      };

      outputs = { self, nixpkgs }: {
        packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
          let pkgs = nixpkgs.legacyPackages.${system};
          in {
            default = pkgs.stdenv.mkDerivation {
              pname = "ansilust";
              version = "VERSION";
              src = fetchTarball {
                url = "https://github.com/effect-native/ansilust/releases/download/vVERSION/ansilust-${system}.tar.gz";
                sha256 = "CHECKSUM";
              };
              installPhase = ''
                mkdir -p $out/bin
                cp ansilust $out/bin/
              '';
            };
          }
        );
      };
    }
    ```
  - **Validation**: `nix flake check` succeeds

- [ ] **4.2.2**: Test flake locally
  - **Command**: `nix run . -- --version`
  - **Validation**: Runs ansilust from flake

- [ ] **4.2.3**: Test from GitHub
  - **Command**: `nix run github:effect-native/ansilust -- --version`
  - **Validation**: Works from remote repository

- [ ] **4.2.4**: Create update script for CI
  - **Purpose**: Update VERSION and CHECKSUM on release
  - **Validation**: Script updates flake.nix correctly

**Dependencies**: 2.1 (Binaries), 3.4 (GitHub releases)

**Validation Checkpoint**:
```bash
nix flake check
nix run . -- --version
# Should work
```

---

### 4.3: Domain Hosting (ansilust.com)

**Cross-reference**: See `.specs/website/` for full website specification. The website will be deployed via Kamal to VPS with Docker, serving both the marketing site and install scripts.

- [ ] **4.3.1**: Configure static hosting for install scripts
  - **Method**: Deployed as part of website via Kamal (see `.specs/website/`)
  - **Setup**: Deploy `scripts/install.sh` to `ansilust.com/install`
  - **Validation**: `curl https://ansilust.com/install` returns script

- [ ] **4.3.2**: Configure SSL certificate
  - **Details**: Automatic with modern hosting (Let's Encrypt)
  - **Validation**: `https://` works with valid certificate

- [ ] **4.3.3**: Set up URL routing
  - **Routes**:
    - `ansilust.com/install` → `install.sh`
    - `ansilust.com/install.ps1` → `install.ps1`
  - **Validation**: Both URLs accessible

- [ ] **4.3.4**: Create deployment workflow
  - **Trigger**: Push to `main` or release
  - **Steps**:
    1. Copy install scripts to hosting provider
    2. Deploy to ansilust.com
  - **Validation**: Automated deployment works

- [ ] **4.3.5**: Test install scripts from domain
  - **Bash**: `curl -fsSL https://ansilust.com/install | bash -s -- --help`
  - **PowerShell**: `irm https://ansilust.com/install.ps1 | iex`
  - **Validation**: Scripts download and display usage

**Dependencies**: 3.1 (Bash installer), 3.2 (PowerShell installer)

**Validation Checkpoint**:
```bash
curl -fsSL https://ansilust.com/install | head -20
# Should show script header

curl -fsSL https://ansilust.com/install.ps1 | head -20
# Should show PowerShell header
```

---

### 4.4: Container Images (GHCR Only)

- [ ] **4.4.1**: Create Dockerfile for minimal image
  - **Base**: `scratch` or `alpine:latest`
  - **Contents**: Static binary only
  - **Entrypoint**: `/ansilust`
  - **Validation**: Dockerfile syntax valid

- [ ] **4.4.2**: Test local container build
  - **Command**: `docker build -t ansilust:test .`
  - **Validation**: Image builds successfully

- [ ] **4.4.3**: Test container execution
  - **Command**: `docker run --rm ansilust:test --version`
  - **Validation**: Runs and shows version

- [ ] **4.4.4**: Implement multi-arch build in CI
  - **Details**: Use `docker buildx` for `linux/amd64`, `linux/arm64`, `linux/arm/v7`
  - **Validation**: Multi-arch manifest created

- [ ] **4.4.5**: Push to GitHub Container Registry (GHCR only)
  - **Location**: `ghcr.io/effect-native/ansilust:VERSION`
  - **Tags**: `latest`, `vX.Y.Z`, `vX.Y`, `vX`
  - **Note**: Docker Hub EXCLUDED (GHCR sufficient)
  - **Validation**: Images pullable from ghcr.io

**Dependencies**: 2.1 (Binaries)

**Validation Checkpoint**:
```bash
docker build -t ansilust:test .
docker run --rm ansilust:test --version
docker push ghcr.io/effect-native/ansilust:test
```

---

### Phase 4 Completion Criteria

- ✅ AUR package in separate AUR repository
- ✅ Nix flake at repository root
- ✅ ansilust.com serving install scripts over HTTPS
- ✅ Container images available on GHCR (not Docker Hub)
- ✅ All package managers tested locally

**Validation Command**:
```bash
nix run github:effect-native/ansilust -- --version && \
curl -fsSL https://ansilust.com/install | head -1 && \
docker pull ghcr.io/effect-native/ansilust:latest && \
echo "✅ Phase 4 Complete"
```

---

## Phase 5: Validation & Release

**Objective**: Comprehensive testing, documentation, and first release.

**Duration Estimate**: 1-2 days

### 5.1: Pre-Release Testing

- [ ] **5.1.1**: Test Zig build for all targets
  - **Command**: Build all 10 targets sequentially
  - **Validation**: All binaries created, no compilation errors

- [ ] **5.1.2**: Test each binary execution
  - **Details**: Run `--version` and `--help` for each platform binary
  - **Validation**: All binaries executable, output correct

- [ ] **5.1.3**: Test npm package locally
  - **Command**: `npm pack` → install from tarball → test execution
  - **Validation**: Package installs and runs correctly

- [ ] **5.1.4**: Test install scripts (dry run)
  - **Bash**: Check syntax with `bash -n`
  - **PowerShell**: Review for errors
  - **Validation**: No syntax errors

- [ ] **5.1.5**: Test AUR package (local)
  - **Command**: `makepkg -si`
  - **Validation**: Builds and installs

- [ ] **5.1.6**: Test Nix flake (local)
  - **Command**: `nix run . -- --version`
  - **Validation**: Runs successfully

**Dependencies**: All previous phases

**Validation Checkpoint**:
```bash
# Run comprehensive test suite
./scripts/test-all-platforms.sh
# (create this script to automate all tests)
```

---

### 5.2: Documentation Completion

- [ ] **5.2.1**: Update README with installation methods
  - **Sections**:
    - Quick start (npx)
    - Installation (npm, AUR, Nix, install scripts, containers)
    - Platform support matrix
    - Usage examples
  - **Note**: Homebrew EXCLUDED from docs
  - **Validation**: All installation methods documented

- [ ] **5.2.2**: Create INSTALL.md with detailed instructions
  - **Contents**: Step-by-step for each platform
  - **Validation**: Clear instructions for all methods

- [ ] **5.2.3**: Document troubleshooting common issues
  - **Issues**:
    - Platform not supported
    - Checksum verification failed
    - Binary not found
    - Permission errors
  - **Validation**: Solutions provided for each

- [ ] **5.2.4**: Create CONTRIBUTING.md
  - **Contents**: How to build, test, and contribute
  - **Validation**: Complete development workflow documented

- [ ] **5.2.5**: Update project badges in README
  - **Badges**: npm version, downloads, license, build status
  - **Validation**: Badges display correctly

**Dependencies**: None

**Validation Checkpoint**:
```bash
# Verify documentation
grep -q "npm install" README.md
grep -q "brew install" README.md
grep -q "Troubleshooting" README.md
echo "✅ Documentation complete"
```

---

### 5.3: First Release (v1.0.0)

- [ ] **5.3.1**: Create changeset for v1.0.0
  - **Command**: `npx changeset add`
  - **Type**: `major` for all packages
  - **Message**: "Initial public release"
  - **Validation**: Changeset file created

- [ ] **5.3.2**: Run `changeset version` locally
  - **Command**: `npx changeset version`
  - **Validation**: All package.json versions updated to 1.0.0

- [ ] **5.3.3**: Review CHANGELOG.md
  - **Details**: Ensure changelog accurately describes release
  - **Validation**: Changelog includes all changes

- [ ] **5.3.4**: Commit version changes
  - **Command**: `git add . && git commit -m "chore: release v1.0.0"`
  - **Validation**: Version commit created

- [ ] **5.3.5**: Create and push git tag
  - **Command**: `git tag v1.0.0 && git push origin main --tags`
  - **Validation**: Tag pushed to GitHub

- [ ] **5.3.6**: Monitor GitHub Actions workflow
  - **Details**: Watch release workflow execution
  - **Validation**: All jobs complete successfully

- [ ] **5.3.7**: Verify GitHub release created
  - **Check**: Release at `github.com/effect-native/ansilust/releases/tag/v1.0.0`
  - **Assets**: All binaries, checksums, signatures
  - **Validation**: Release published with all artifacts

**Dependencies**: All previous phases

**Validation Checkpoint**:
```bash
git tag v1.0.0
git push origin main --tags
# Monitor: https://github.com/effect-native/ansilust/actions
# Verify: https://github.com/effect-native/ansilust/releases
```

---

### 5.4: Post-Release Verification

- [ ] **5.4.1**: Test npm installation
  - **Command**: `npx ansilust@latest --version`
  - **Validation**: Shows v1.0.0

- [ ] **5.4.2**: Test install script from ansilust.com
  - **Command**: `curl -fsSL https://ansilust.com/install | bash`
  - **Validation**: Installs v1.0.0

- [ ] **5.4.3**: Test AUR package
  - **Command**: `yay -S ansilust` (on Arch Linux)
  - **Validation**: Installs v1.0.0

- [ ] **5.4.4**: Test Nix flake
  - **Command**: `nix run github:effect-native/ansilust -- --version`
  - **Validation**: Shows v1.0.0

- [ ] **5.4.5**: Test container image
  - **Command**: `docker run ghcr.io/effect-native/ansilust:latest --version`
  - **Validation**: Shows v1.0.0

- [ ] **5.4.6**: Verify checksums
  - **Details**: Download binary and verify against published checksum
  - **Validation**: Checksums match

**Dependencies**: 5.3 (First release)

**Validation Checkpoint**:
```bash
npx ansilust@latest --version
nix run github:effect-native/ansilust -- --version
docker run ghcr.io/effect-native/ansilust:latest --version
# All should show v1.0.0
```

---

### 5.5: Platform Matrix Testing

**Philosophy**: Test locally where possible, fix forward if issues arise.

- [ ] **5.5.1**: Test on Linux x86_64 (Ubuntu 22.04)
  - **Methods**: npm, bash installer, container
  - **Validation**: All methods work

- [ ] **5.5.2**: Test on macOS Intel (if available)
  - **Methods**: npm, bash installer
  - **Validation**: All methods work

- [ ] **5.5.3**: Test on macOS Apple Silicon (if available)
  - **Methods**: npm, bash installer
  - **Validation**: All methods work

- [ ] **5.5.4**: Test on Windows 11 x64 (if available)
  - **Methods**: npm, PowerShell installer
  - **Validation**: All methods work

- [ ] **5.5.5**: Test on Raspberry Pi (if available)
  - **Methods**: bash installer, container
  - **Validation**: ARM binary works

- [ ] **5.5.6**: Test on Alpine Linux (Docker)
  - **Methods**: bash installer (musl binary), container
  - **Validation**: musl binary works

- [ ] **5.5.7**: Document any platform-specific issues
  - **Details**: Create GitHub issues for failures
  - **Validation**: Issues tracked, fixes planned

**Dependencies**: 5.4 (Post-release verification)

**Notes**:
- Not all platforms may be available for testing
- Document what was tested vs. what wasn't
- Community can report issues for untested platforms
- Fix forward with patch releases

**Validation Checkpoint**:
```bash
# Create test matrix report
cat > TESTING.md << EOF
# Platform Testing Report

## Tested Platforms
- [x] Ubuntu 22.04 x86_64 (npm, bash, docker)
- [x] macOS 14 ARM64 (npm, bash)
- [ ] Windows 11 x64 (not available for testing)

## Known Issues
- None

## Untested Platforms
- Raspberry Pi (hardware not available)
- iOS devices (jailbroken/iSH - hardware not available)
EOF
```

---

### Phase 5 Completion Criteria

- ✅ All pre-release tests passed
- ✅ Documentation complete and accurate
- ✅ v1.0.0 released successfully
- ✅ Post-release verification passed
- ✅ Platform testing completed (where available)
- ✅ Any issues documented and tracked

**Validation Command**:
```bash
npx ansilust@latest --version && \
curl -fsSL https://ansilust.com/install | head -1 && \
docker run ghcr.io/effect-native/ansilust:latest --version && \
test -f CHANGELOG.md && \
echo "✅ Phase 5 Complete - v1.0.0 Released!"
```

---

## Risk Mitigation

### High-Priority Risks

**R1: GitHub Actions quota limits**
- **Mitigation**: Single-runner sequential builds (cost-optimized)
- **Fallback**: Manual local builds if quota exceeded
- **Monitoring**: Check Actions usage monthly

**R2: npm package name conflicts**
- **Status**: ✅ Mitigated (packages reserved: ansilust, 16colors, 16c)
- **Validation**: All v0.0.1 placeholders published

**R3: Checksum verification failures**
- **Mitigation**: Test checksum script locally before release
- **Fallback**: Regenerate checksums if needed
- **Validation**: Automated verification in CI

**R4: Domain expiration (ansilust.com)**
- **Mitigation**: Enable auto-renewal
- **Monitoring**: Set calendar reminder 3 months before expiration
- **Fallback**: Distribute scripts from GitHub raw URLs

### Medium-Priority Risks

**R5: Platform build failures**
- **Mitigation**: Test all targets locally before tagging
- **Fallback**: Skip broken platform, fix in next release
- **Monitoring**: CI sends notifications on failure

**R6: Package manager rejections**
- **AUR**: Test PKGBUILD locally before pushing
- **npm**: Validate package.json before publishing
- **Nix**: Test flake before pushing
- **Monitoring**: Manual review before submission

**R7: Install script bugs**
- **Mitigation**: Syntax check (`bash -n`, `PSScriptAnalyzer`)
- **Fallback**: Revert and redeploy fixed script
- **Monitoring**: GitHub issues for user reports

### Low-Priority Risks

**R8: Documentation drift**
- **Mitigation**: Update docs in same PR as code changes
- **Monitoring**: Monthly doc review

**R9: Unused platform packages**
- **Mitigation**: Monitor npm download stats
- **Decision**: Keep all platforms unless significant maintenance burden

---

## Success Criteria

### Phase-Level Success

- [x] **Phase 1**: Foundation setup complete, Changesets initialized ⬜
- [x] **Phase 2**: Build system working, npm packages structured ⬜
- [x] **Phase 3**: Install scripts and CI/CD workflows implemented ⬜
- [x] **Phase 4**: All package managers configured and tested ⬜
- [x] **Phase 5**: v1.0.0 released, post-release verification passed ⬜

### Overall Success Criteria

- [ ] Users can run `npx ansilust` instantly (zero-download execution)
- [ ] Users can install via preferred package manager (npm, AUR, Nix, install scripts)
- [ ] Install scripts work on Linux, macOS, Windows
- [ ] All binaries cryptographically verified with SHA256
- [ ] GitHub Actions fully automates releases
- [ ] Documentation covers all installation methods
- [ ] No manual steps required for standard releases
- [ ] Community can contribute via well-documented process

### Quality Gates

**Before tagging v1.0.0**:
- [ ] `zig build` succeeds for all 10 targets
- [ ] Spot-check 2-3 binaries execute `--version` successfully
- [ ] Install scripts pass syntax checks
- [ ] Documentation reviewed and accurate
- [ ] Changeset created with release notes

**After releasing v1.0.0**:
- [ ] `npx ansilust@latest --version` works
- [ ] Install script accessible at `ansilust.com/install`
- [ ] GitHub release created with all assets
- [ ] npm packages published successfully
- [ ] No critical issues reported within 24 hours

---

## Timeline Estimate

| Phase | Duration | Tasks |
|-------|----------|-------|
| Phase 1: Foundation | 1-2 days | Monorepo, Changesets, repo structure |
| Phase 2: Build & npm | 2-3 days | Zig builds, launcher, platform packages |
| Phase 3: Scripts & CI | 2-3 days | Installers, workflows, automation |
| Phase 4: Package Mgrs | 1-2 days | AUR, Nix, hosting, containers |
| Phase 5: Validation | 1-2 days | Testing, docs, release |
| **Total** | **7-11 days** | **~70 tasks** |

**Notes**:
- Assumes full-time dedicated work
- Parallelization possible for independent tasks
- First release takes longer; subsequent releases faster
- Adjust based on available testing devices

---

## Progress Tracking

### Current Status: Phase 1 Complete, Phase 2-5 Pending ⏳

**Completed**: ~25 / ~70 tasks (~35%)

**Phase 1 Status** (Foundation Setup): ✅ COMPLETE
- [x] 1.1.1 Root package.json with workspaces (`package.json` exists)
- [x] 1.1.2 Placeholder packages verified (`packages/ansilust/`, `packages/16colors/`, `packages/16c/`)
- [x] 1.2.1-1.2.4 Changesets initialized (`.changeset/config.json`, `.changeset/README.md`)
- [x] 1.3.3 Nix flake at root (`flake.nix`)
- [x] 1.4.1 Scripts directory (`scripts/install.sh`, `install.ps1`, `assemble-npm-packages.js`, `generate-checksums.sh`)
- [x] 1.4.3 GitHub Actions workflows (`.github/workflows/release.yml`, `changeset-version.yml`)
- [x] AUR package (`aur/PKGBUILD`, `aur/.SRCINFO`)

**Phase 2 Status** (Build System & npm): 🔄 PARTIAL
- [ ] 2.1.1-2.1.4 Zig cross-compilation targets (not tested)
- [ ] 2.2.1-2.2.6 npm launcher script (placeholder exists, not functional)
- [ ] 2.3.1-2.3.6 Platform package assembly (script exists, not validated)

**Phase 3 Status** (Install Scripts): 🔄 PARTIAL
- [x] 3.1.1 Bash installer header (`scripts/install.sh` exists)
- [x] 3.2.1 PowerShell installer header (`scripts/install.ps1` exists)
- [ ] 3.1.2-3.1.7 Bash installer implementation (incomplete)
- [ ] 3.2.2-3.2.7 PowerShell installer implementation (incomplete)
- [ ] 3.3.1-3.3.3 Checksum generation (script exists, not validated)
- [ ] 3.4.1-3.4.7 Release workflow (workflow exists, not tested)

**Phase 4 Status** (Package Managers): 🔄 PARTIAL
- [x] 4.1.1-4.1.3 AUR PKGBUILD (`aur/PKGBUILD` exists)
- [x] 4.2.1 Nix flake (`flake.nix` at root)
- [ ] 4.3.1-4.3.5 Domain hosting (not configured)
- [ ] 4.4.1-4.4.5 Container images (Dockerfile exists, not tested)

**Phase 5 Status** (Validation & Release): ⬜ NOT STARTED

**Next Actions**:
1. Test Zig cross-compilation for all 10 targets
2. Implement npm launcher script platform detection
3. Complete install script implementations
4. Test release workflow with dry-run

---

## Continuous Improvement

### Post-v1.0.0 Enhancements

**P1 (High Priority)**:
- [ ] Add shell completions (bash, zsh, fish)
- [ ] Create man page
- [ ] Add `ansilust update` command for self-updating
- [ ] Publish to additional package managers (Chocolatey, Scoop, winget)

**P2 (Medium Priority)**:
- [ ] Enable GPG signing for releases
- [ ] Add SLSA provenance for supply chain security
- [ ] Create pre-release (beta) distribution channel
- [ ] Add telemetry (opt-in, anonymous) for platform analytics

**P3 (Low Priority)**:
- [ ] Submit to nixpkgs official repository
- [ ] Create snap/flatpak packages
- [ ] Build native Windows installer (MSI)

**P4 (Deferred Indefinitely)**:
- [ ] Homebrew tap/formula (personal decision - excluded)

### Metrics to Monitor

**Installation Methods**:
- npm downloads (npmjs.com/package/ansilust)
- GitHub release download counts
- Container image pulls (ghcr.io/effect-native/ansilust)
- Install script usage (if analytics added later)

**Platform Distribution**:
- Which platforms are most used (via npm platform packages)
- Identify platforms needing optimization
- Prioritize support for popular platforms

**Issues & Support**:
- GitHub issues by category (install, platform, bugs)
- Response time for critical issues
- Community contributions

---

## Notes & Decisions

### Key Architectural Decisions

✅ **npm packaging**: esbuild-style (meta + 10 platform packages)
- **Rationale**: Zero-download `npx` execution, battle-tested pattern

✅ **Version management**: Changesets
- **Rationale**: Automated changelog, monorepo support, industry standard

✅ **Binary distribution**: GitHub Releases as canonical source
- **Rationale**: Free, reliable, integrated with git tags

✅ **Single-runner CI**: Sequential builds on ubuntu-latest
- **Rationale**: Cost-optimized (80-90% savings vs. matrix), Zig cross-compiles all targets

✅ **Repository structure**: Main repo + separate AUR repo
- **Rationale**: AUR package manager requirements (PKGBUILD at root)

✅ **Nix flake location**: At repository root
- **Rationale**: Nix flake MUST be at root (technical constraint)

### Design Updates Applied

**Update 1: Simplified Testing**
- **Change**: Removed elaborate CI test suites
- **Approach**: Trust yourself, test locally, fix forward
- **Gate**: `zig build` success = ship it

**Update 2: Repository Locations**
- **AUR**: Separate AUR repository with PKGBUILD at root
- **Nix**: `flake.nix` at repository root (NOT in subdirectory)
- **Homebrew**: EXCLUDED from v1.0.0 (deferred indefinitely)

**Update 3: GitHub Actions Cost Optimization**
- **Change**: Single ubuntu-latest runner, sequential builds
- **Savings**: ~80-90% cost reduction vs. matrix builds
- **Trade-off**: 7-12 minutes total build time (acceptable)

**Update 4: v1.0.0 Scope Decisions** ✅
- **Homebrew**: EXCLUDED (deferred indefinitely - personal decision)
- **iOS**: EXCLUDED (deferred - no test devices)
- **GPG signing**: EXCLUDED (deferred - SHA256 sufficient)
- **Docker Hub**: EXCLUDED (GHCR sufficient)
- **Analytics**: EXCLUDED (privacy-first approach)

---

## Appendix: Quick Reference

### Essential Commands

**Development**:
```bash
# Build all targets
zig build -Dtarget=x86_64-linux-gnu

# Assemble npm packages
node scripts/assemble-npm-packages.js

# Test launcher locally
npm link packages/ansilust
ansilust --version
npm unlink -g ansilust

# Add changeset
npx changeset add

# Version packages (local)
npx changeset version
```

**Testing**:
```bash
# Syntax checks
bash -n scripts/install.sh
shellcheck scripts/install.sh

# Local AUR test
cd aur-ansilust && makepkg -si

# Nix flake test
nix run . -- --version
```

**Release**:
```bash
# Create release
npx changeset add
git add .changeset/*.md
git commit -m "Add changeset"
git push

# (Merge version PR created by CI)

# Tag and push
git tag v1.0.0
git push origin main --tags

# Monitor release
gh run watch
```

### File Locations

**Main Repository**:
- `packages/ansilust/` - Meta package
- `packages/ansilust-*/` - 10 platform packages
- `scripts/install.sh` - Bash installer
- `scripts/install.ps1` - PowerShell installer
- `.github/workflows/release.yml` - Release automation
- `flake.nix` - Nix flake (at root)

**Separate Repositories**:
- `aur-ansilust/PKGBUILD` - AUR package (at root)

**Hosted Externally**:
- `https://ansilust.com/install` - Bash installer
- `https://ansilust.com/install.ps1` - PowerShell installer
- `ghcr.io/effect-native/ansilust` - Container images

---

## Changelog

**2025-XX-XX - Plan Created**
- Initial implementation plan for v1.0.0 release
- 5-phase structure with ~70 tasks
- Estimated 7-11 days for completion
- Homebrew EXCLUDED (deferred indefinitely)
- iOS EXCLUDED (deferred - no test devices)
- GHCR only (no Docker Hub)
- No GPG signing or analytics in v1.0.0

---

**End of Plan Document**

**Status**: Ready for Phase 1 implementation
**Next Step**: Create root package.json with workspaces (Task 1.1.1)
