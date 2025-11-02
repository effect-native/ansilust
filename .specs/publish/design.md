# Publishing & Distribution - Design

**Phase**: 3 - Design  
**Status**: In Progress  
**Dependencies**: requirements.md (Phase 2 complete)

---

## Overview

This document defines the technical architecture and implementation strategy for distributing ansilust binaries across multiple platforms and package managers. The design prioritizes security, automation, and user experience while leveraging battle-tested patterns from esbuild, swc, and Biome for npm distribution.

**Key Design Principles**:
- Zero-download `npx` execution via esbuild-style packaging
- Reproducible builds with cryptographic verification
- Automated release workflow via Changesets
- Platform-specific optimization (musl vs glibc, architecture-specific binaries)
- Security-first install scripts with transparent source links

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workflow                       │
│  1. npx changeset → Add changeset file                       │
│  2. Merge version PR → Triggers release                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions (CI/CD)                     │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │ Build Matrix │→ │ Zig Cross-    │→ │ Package         │  │
│  │ (10 targets) │  │ Compilation   │  │ Assembly        │  │
│  └──────────────┘  └───────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ npm Registry │     │ GitHub       │     │ Package      │
│ (11 packages)│     │ Releases     │     │ Repos        │
│              │     │ (binaries +  │     │ (Homebrew,   │
│ - ansilust   │     │  checksums)  │     │  AUR, Nix)   │
│ - 10 platform│     └──────────────┘     └──────────────┘
│   packages   │                                  │
└──────────────┘                                  │
        │                                         │
        ▼                                         ▼
┌──────────────────────────────────────────────────────────┐
│                      End Users                            │
│  • npx ansilust (instant execution)                       │
│  • npm install -g ansilust                                │
│  • brew install ansilust                                  │
│  • curl ansilust.com/install | bash                       │
│  • nix run, AUR, containers, iOS APT                      │
└──────────────────────────────────────────────────────────┘
```

### Component Relationships

**Build System** (Zig):
- Cross-compiles for 10+ targets
- Produces static binaries where possible
- Outputs to standardized artifact directory

**Package Assembler** (GitHub Actions):
- Creates npm platform packages from Zig binaries
- Generates Homebrew formula
- Updates AUR PKGBUILD
- Builds container images
- Creates .deb packages for iOS

**Distribution Channels**:
- npm (meta package + 10 platform packages)
- GitHub Releases (canonical binary storage)
- Homebrew tap (formula repository)
- AUR (PKGBUILD repository)
- ansilust.com (install scripts)
- Container registries (OCI images)
- iOS APT repository (.deb packages)

---

## Module Organization

### Monorepo Structure

```
ansilust/
├── .changeset/                    # Changesets configuration
│   ├── config.json               # Changeset settings
│   └── *.md                      # Individual changesets
├── .github/workflows/
│   ├── release.yml               # Main release workflow
│   ├── changeset-version.yml     # Version PR automation
│   └── test.yml                  # CI testing
├── packages/                      # npm workspace packages
│   ├── ansilust/                 # Meta package
│   │   ├── package.json
│   │   ├── bin/launcher.js       # Platform detection + spawn
│   │   └── README.md
│   ├── ansilust-darwin-arm64/    # Platform package
│   │   ├── package.json
│   │   ├── index.js              # Exports binPath
│   │   └── bin/ansilust          # Zig binary
│   └── [...9 more platform packages]
├── scripts/                       # Install scripts and utilities
│   ├── install.sh                # Bash installer
│   ├── install.ps1               # PowerShell installer
│   ├── assemble-npm-packages.js  # CI: Create platform packages
│   └── generate-checksums.sh     # CI: SHA256 generation
├── homebrew/                      # Homebrew tap
│   └── ansilust.rb               # Formula template
├── aur/                           # AUR package
│   └── PKGBUILD                  # Build instructions
├── nix/                           # Nix flake
│   └── flake.nix
├── src/                           # Zig source code
├── build.zig                      # Zig build system
├── package.json                   # Workspace root
└── README.md
```

### Package Dependency Graph

```
┌─────────────────────────────────────────────────────┐
│              ansilust (meta package)                 │
│  - Launcher: bin/launcher.js                         │
│  - Dependency: detect-libc@^2.0.3                    │
│  - optionalDependencies: [10 platform packages]      │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┬─────── ... (10 total)
        ▼                               ▼
┌───────────────────┐         ┌───────────────────┐
│ ansilust-linux-   │         │ ansilust-darwin-  │
│   x64-gnu         │         │   arm64           │
│                   │         │                   │
│ - os: ["linux"]   │         │ - os: ["darwin"]  │
│ - cpu: ["x64"]    │         │ - cpu: ["arm64"]  │
│ - Exports binPath │         │ - Exports binPath │
│ - Contains binary │         │ - Contains binary │
└───────────────────┘         └───────────────────┘
```

---

## Data Structures

### Platform Package Metadata

**Purpose**: Describe each npm platform package structure

**Structure**:
```
PlatformPackage {
  name: string              // e.g., "ansilust-linux-x64-gnu"
  os: string[]              // npm os filter: ["linux"]
  cpu: string[]             // npm cpu filter: ["x64"]
  files: string[]           // ["bin/", "index.js", "README.md"]
  main: string              // Entry point: "index.js"
  binPath: string           // Path to binary: "./bin/ansilust"
}
```

**Platform Package Export**:
```javascript
// index.js in platform package
exports.binPath = require('path').join(__dirname, 'bin/ansilust')
```

### Build Matrix Configuration

**Purpose**: Define all target platforms for cross-compilation

**Structure**:
```
BuildTarget {
  name: string              // "linux-x64-gnu"
  zigTarget: string         // "x86_64-linux-gnu"
  npmPackageName: string    // "ansilust-linux-x64-gnu"
  npmOS: string[]           // ["linux"]
  npmCPU: string[]          // ["x64"]
  requiresLibc: boolean     // true for Linux
  libcVariant?: string      // "glibc" | "musl"
  binaryName: string        // "ansilust" (no .exe except Windows)
}
```

**Complete Build Matrix** (10 targets):
- darwin-arm64, darwin-x64
- linux-x64-gnu, linux-x64-musl
- linux-arm64-gnu, linux-arm64-musl
- linux-armv7-gnu, linux-armv7-musl
- linux-i386-musl (for iSH on iOS)
- win32-x64

### Checksum File Format

**Purpose**: Cryptographic verification of all artifacts

**Format**:
```
SHA256SUMS (text file):
<sha256-hash> <filename>
<sha256-hash> <filename>
...

SHA256SUMS.asc (GPG signature):
-----BEGIN PGP SIGNATURE-----
<signature data>
-----END PGP SIGNATURE-----
```

### Changeset Metadata

**Purpose**: Version management and changelog generation

**Structure** (.changeset/some-feature.md):
```markdown
---
"ansilust": minor
"ansilust-darwin-arm64": minor
"ansilust-darwin-x64": minor
[...all platform packages]
---

Brief description of the change
```

---

## Algorithm Approaches

### 1. Platform Detection (Launcher)

**Purpose**: Detect user's OS, architecture, and libc variant

**Inputs**: None (reads from process.platform, process.arch)

**Outputs**: Platform identifier string (e.g., "linux-x64-musl")

**Algorithm**:
```
function detectPlatform():
  1. Read os = process.platform
     - Maps: darwin, linux, win32
  
  2. Read arch = process.arch
     - Maps: x64, arm64, arm, ia32
  
  3. If os == 'linux':
     a. Import detect-libc
     b. Detect libc = detectLibc.family
     c. Default to 'glibc' if detection fails
     d. Return `${os}-${arch}-${libc}`
  
  4. If os == 'win32':
     - Return `win32-${arch}`
  
  5. If os == 'darwin':
     - Return `darwin-${arch}`
  
  6. Else:
     - Throw UnsupportedPlatformError with help message
```

**Error Handling**:
- Unsupported platform → Clear error with list of supported platforms
- Missing detect-libc → Fallback to glibc assumption
- Architecture mismatch → Error with installation instructions

### 2. Binary Selection (Launcher)

**Purpose**: Map platform identifier to npm package name

**Inputs**: Platform identifier (from detectPlatform)

**Outputs**: npm package name

**Algorithm**:
```
platformMap = {
  'darwin-arm64': 'ansilust-darwin-arm64',
  'darwin-x64': 'ansilust-darwin-x64',
  'linux-x64-glibc': 'ansilust-linux-x64-gnu',
  'linux-x64-musl': 'ansilust-linux-x64-musl',
  'linux-arm64-glibc': 'ansilust-linux-arm64-gnu',
  'linux-arm64-musl': 'ansilust-linux-arm64-musl',
  'linux-armv7-glibc': 'ansilust-linux-armv7-gnu',
  'linux-armv7-musl': 'ansilust-linux-armv7-musl',
  'linux-ia32-musl': 'ansilust-linux-i386-musl',
  'win32-x64': 'ansilust-win32-x64',
}

function selectPackage(platform):
  1. Lookup packageName = platformMap[platform]
  2. If not found:
     - Throw UnsupportedPlatformError
  3. Return packageName
```

### 3. Binary Execution (Launcher)

**Purpose**: Spawn the platform-specific binary with user arguments

**Inputs**: Package name, command-line arguments

**Outputs**: Exit code from spawned process

**Algorithm**:
```
function executeBinary(packageName, args):
  1. Try to require platform package:
     - platformPackage = require(packageName)
  
  2. If require fails (package not installed):
     - Display error message with install instructions
     - Exit with code 1
  
  3. Get binary path:
     - binPath = platformPackage.binPath
  
  4. Verify binary exists on filesystem:
     - If not exists: Error + reinstall instructions
  
  5. Spawn binary:
     - child_process.spawnSync(binPath, args, {stdio: 'inherit'})
  
  6. Exit with child process exit code
```

**Error Messages**:
```
Platform package not installed:
  "Missing platform package for linux-x64-musl.
   Try: npm install -g ansilust
   Or: npm install ansilust-linux-x64-musl"

Binary not found:
  "Binary not found at {binPath}.
   Try reinstalling: npm install -g ansilust --force"
```

### 4. Platform Package Assembly (CI)

**Purpose**: Create npm platform packages from Zig binaries

**Inputs**: 
- Zig build artifacts (binaries in zig-out/bin/)
- Version number from Changesets
- Build matrix configuration

**Outputs**: 10 npm platform package directories

**Algorithm**:
```
for each target in buildMatrix:
  1. Create package directory:
     - mkdir -p packages/{target.npmPackageName}/bin
  
  2. Copy binary:
     - cp zig-out/{target.name}/ansilust → packages/{target.npmPackageName}/bin/
  
  3. Generate package.json:
     - name: target.npmPackageName
     - version: changesetVersion
     - os: target.npmOS
     - cpu: target.npmCPU
     - files: ["bin/", "index.js"]
     - main: "index.js"
  
  4. Generate index.js:
     - exports.binPath = path.join(__dirname, 'bin', target.binaryName)
  
  5. Copy LICENSE and README:
     - cp LICENSE → packages/{target.npmPackageName}/
     - Generate platform-specific README
```

### 5. Checksum Generation

**Purpose**: Generate SHA256 checksums for all release artifacts

**Inputs**: Directory of binary artifacts

**Outputs**: SHA256SUMS file

**Algorithm**:
```
function generateChecksums(artifactDir):
  1. List all binary files in artifactDir
  
  2. For each file:
     a. Compute SHA256 hash
     b. Append to SHA256SUMS: "{hash} {filename}\n"
  
  3. Sort lines alphabetically by filename
  
  4. Write SHA256SUMS file
  
  5. If GPG signing enabled:
     - Run: gpg --detach-sign --armor SHA256SUMS
     - Output: SHA256SUMS.asc
```

### 6. Bash Installer Platform Detection

**Purpose**: Detect platform and download correct binary

**Inputs**: Environment variables (OS, ARCH)

**Outputs**: Downloaded and installed binary

**Algorithm**:
```
function detect_platform():
  1. Detect OS:
     - uname -s → Linux, Darwin, or Windows (WSL)
  
  2. Detect architecture:
     - uname -m → x86_64, aarch64, armv7l, i686
     - Map to: x64, arm64, armv7, i386
  
  3. If Linux:
     a. Detect libc variant:
        - Check /lib/ld-musl* → musl
        - Check ldd --version | grep musl → musl
        - Default: glibc (gnu)
     b. Return: linux-{arch}-{gnu|musl}
  
  4. If Darwin:
     - Return: darwin-{arch}
  
  5. If Windows/WSL:
     - Return: win32-x64
  
  6. Else:
     - Error: Unsupported platform
```

**Download and Install**:
```
function install_binary(platform):
  1. Construct download URL:
     - base = https://github.com/OWNER/ansilust/releases/latest/download
     - url = {base}/ansilust-{platform}.tar.gz
  
  2. Download binary archive:
     - curl -fsSL {url} -o /tmp/ansilust.tar.gz
     - Retry up to 3 times on failure
  
  3. Download checksums:
     - curl -fsSL {base}/SHA256SUMS -o /tmp/SHA256SUMS
  
  4. Verify checksum:
     - cd /tmp && sha256sum --check --ignore-missing SHA256SUMS
     - If fails: Error + abort
  
  5. Extract binary:
     - tar -xzf ansilust.tar.gz -C /tmp
  
  6. Install to target directory:
     - If ~/.local/bin exists:
       - mv /tmp/ansilust ~/.local/bin/
     - Else if /usr/local/bin writable:
       - mv /tmp/ansilust /usr/local/bin/
     - Else:
       - sudo mv /tmp/ansilust /usr/local/bin/
  
  7. Verify installation:
     - ansilust --version
```

---

## API Surface Design

### Meta Package (ansilust)

**Launcher Interface** (bin/launcher.js):

```javascript
// Entry point: #!/usr/bin/env node

// Exported functions (for testing)
exports.detectPlatform = function(): PlatformInfo
exports.selectPackage = function(platform: string): string
exports.executeBinary = function(packageName: string, args: string[]): never

// Main execution
// 1. Detect platform
// 2. Select package
// 3. Execute binary (exits process)
```

### Platform Package (ansilust-{platform})

**Package Interface** (index.js):

```javascript
// Single export: path to binary
exports.binPath = string  // Absolute path to ./bin/ansilust
```

**No functions, no logic - pure data export**

### Install Scripts

**Bash Installer** (scripts/install.sh):

```bash
# Public functions (for testing/debugging)
detect_platform()    # Returns: linux-x64-musl, darwin-arm64, etc.
download_binary()    # Downloads from GitHub releases
verify_checksum()    # SHA256 verification
install_binary()     # Installs to ~/.local/bin or /usr/local/bin

# Main execution
main() {
  platform=$(detect_platform)
  download_binary "$platform"
  verify_checksum
  install_binary
  echo "✅ ansilust installed successfully"
}
```

**PowerShell Installer** (scripts/install.ps1):

```powershell
# Public functions
function Detect-Platform { }       # Returns: win32-x64
function Download-Binary { }       # Downloads from GitHub releases
function Verify-Checksum { }       # SHA256 verification
function Install-Binary { }        # Installs to $env:LOCALAPPDATA\Programs\ansilust

# Main execution
$platform = Detect-Platform
Download-Binary -Platform $platform
Verify-Checksum
Install-Binary
Write-Host "✅ ansilust installed successfully"
```

### GitHub Actions Workflow

**Release Workflow Interface** (.github/workflows/release.yml):

```yaml
# Triggered by: Changesets version commit or tag push

# Jobs:
jobs:
  build:
    # Matrix builds for all 10 platforms
    # Output: zig-out/{platform}/ansilust binaries
  
  assemble-npm:
    # Creates 10 npm platform packages
    # Output: packages/{platform-package}/ directories
  
  publish-npm:
    # Publishes all 11 packages (meta + 10 platforms)
    # Uses: npm publish with Changesets automation
  
  create-release:
    # Creates GitHub release
    # Uploads: binaries, checksums, signatures
  
  update-homebrew:
    # Updates Homebrew tap formula
    # Commits to homebrew-tap repository
  
  update-aur:
    # Updates AUR PKGBUILD
    # Commits to AUR repository
  
  build-containers:
    # Builds multi-arch OCI images
    # Pushes to GitHub Container Registry
```

**Changesets Version Workflow** (.github/workflows/changeset-version.yml):

```yaml
# Triggered by: Push to main branch with changesets

# Job:
jobs:
  version:
    # Runs: npx changeset version
    # Creates PR with version bumps + CHANGELOG updates
    # PR merge triggers release workflow
```

---

## Error Handling Strategy

### Error Categories

**1. Platform Detection Errors**
- Unsupported OS/architecture combination
- Failed libc detection (fallback to glibc)
- Unknown platform string

**Error Response**:
- Clear message: "Platform {os}/{arch} is not supported"
- List of supported platforms
- Link to manual installation instructions

**2. Package Missing Errors**
- Platform package not in node_modules
- Binary file not found in platform package

**Error Response**:
- Installation instructions for specific platform package
- Suggestion to reinstall: `npm install -g ansilust --force`
- Link to GitHub releases for manual download

**3. Download Failures (Install Scripts)**
- Network timeout
- GitHub releases unavailable
- Checksum verification failure

**Error Response**:
- Retry logic: Up to 3 attempts with exponential backoff
- Alternative download sources (mirrors if available)
- Manual download instructions with checksum

**4. Checksum Verification Errors**
- Hash mismatch
- Corrupted download

**Error Response**:
- Abort installation immediately
- Clear message: "Checksum verification failed - installation aborted for security"
- Retry download suggestion
- Manual verification instructions

### Error Propagation

**npm Launcher**:
```
detectPlatform() → throws PlatformError → caught in main → display + exit 1
selectPackage() → throws PackageError → caught in main → display + exit 1
executeBinary() → throws BinaryError → caught in main → display + exit 1
                → spawns process → exits with child exit code
```

**Install Scripts**:
```
All errors → exit with non-zero code
              Display clear error message
              Suggest remediation steps
              Link to documentation
```

### Error Messages

**Template**:
```
❌ Error: {Brief description}

Details: {Technical details}

To fix this:
1. {Step 1}
2. {Step 2}
3. {Step 3}

For help: https://github.com/OWNER/ansilust/issues
```

**Example**:
```
❌ Error: Platform not supported

Details: Detected platform: linux/riscv64
ansilust does not currently support this platform.

Supported platforms:
- Linux: x86_64, aarch64, armv7 (glibc and musl)
- macOS: x86_64 (Intel), aarch64 (Apple Silicon)
- Windows: x86_64
- iOS: arm64 (via APT on jailbroken devices)

To install manually:
Visit: https://github.com/OWNER/ansilust/releases

For help: https://github.com/OWNER/ansilust/issues
```

---

## Memory Management Strategy

### npm Launcher (JavaScript)

**Allocations**:
- Minimal: Only string manipulation and process spawning
- No long-lived objects
- Process exits after spawning binary

**Pattern**:
- Let JavaScript GC handle cleanup
- No manual memory management needed
- Process termination cleans all resources

### Install Scripts (Bash/PowerShell)

**Temporary Files**:
- Downloaded archives: /tmp/ansilust.tar.gz
- Checksum files: /tmp/SHA256SUMS
- Extracted binaries: /tmp/ansilust

**Cleanup Strategy**:
```bash
# Bash: trap ensures cleanup on exit
trap cleanup EXIT
cleanup() {
  rm -f /tmp/ansilust.tar.gz
  rm -f /tmp/SHA256SUMS
  rm -f /tmp/ansilust
}
```

```powershell
# PowerShell: try/finally ensures cleanup
try {
  Download-Binary
  Install-Binary
} finally {
  Remove-Item -Path "$env:TEMP\ansilust*" -Force -ErrorAction SilentlyContinue
}
```

### GitHub Actions (CI)

**Artifact Storage**:
- Build artifacts: zig-out/ (cleaned between jobs)
- npm packages: packages/ (published then cleaned)
- Upload artifacts: Stored by GitHub (automatic cleanup)

**Pattern**:
- Each job starts with clean workspace
- No state carried between workflow runs
- GitHub automatically cleans old artifacts after 90 days

---

## Testing Approach

### Unit Testing

**npm Launcher Tests**:
```
test/launcher.test.js:
  - detectPlatform() returns correct values
  - selectPackage() maps platforms correctly
  - Error handling for unsupported platforms
  - Mock process.platform and process.arch
```

**Install Script Tests**:
```
test/install.bats (Bash Automated Testing System):
  - detect_platform() on various OS/arch combinations
  - download_binary() with mocked curl
  - verify_checksum() with known checksums
  - install_binary() to test directory
```

### Integration Testing

**End-to-End Installation**:
```
test/e2e/:
  - Test matrix: All supported platforms
  - Docker containers for each OS/arch
  - Run install script in container
  - Verify binary works
  - Verify --version and --help
```

**Platform-Specific**:
```
test/platforms/:
  ubuntu-22.04-x64/
  debian-12-x64/
  alpine-3.18-x64/
  macos-13-x64/
  macos-14-arm64/
  windows-11-x64/
  raspberrypi-4-arm64/
  ios-14-arm64/ (jailbroken)
```

### CI/CD Testing

**GitHub Actions**:
```
.github/workflows/test.yml:
  - Matrix build test: Verify all platforms compile
  - npm package test: Install meta package + verify execution
  - Install script test: Run in Docker containers
  - Checksum test: Verify SHA256SUMS generation
  - Documentation test: Verify links and examples
```

### Validation Checklist

**Pre-Release**:
- [ ] All platform binaries build successfully
- [ ] All checksums match
- [ ] Meta package requires correct platform packages
- [ ] Launcher selects correct platform
- [ ] Install script works on all platforms
- [ ] Homebrew formula validates
- [ ] Container images build and run
- [ ] Documentation is accurate

**Post-Release**:
- [ ] npm packages are published and downloadable
- [ ] GitHub release has all artifacts
- [ ] Install scripts download correct binaries
- [ ] Checksums verify successfully
- [ ] Homebrew tap is updated
- [ ] Container images are accessible

---

## Integration Points

### 1. Zig Build System → GitHub Actions

**Integration**:
- GitHub Actions runs `zig build` with target flags
- Binaries output to `zig-out/{target}/ansilust`
- CI script copies binaries to staging directory

**Contract**:
```
zig build -Dtarget=x86_64-linux-gnu
  → Produces: zig-out/x86_64-linux-gnu/ansilust

zig build -Dtarget=aarch64-macos
  → Produces: zig-out/aarch64-macos/ansilust
```

### 2. Changesets → npm Publishing

**Integration**:
- Changesets manages version bumps in package.json
- Version commit triggers release workflow
- Workflow uses `npm publish` with Changesets auth

**Contract**:
```
.changeset/*.md → npx changeset version
  → Updates package.json versions
  → Generates CHANGELOG.md
  → Creates version commit

Version commit pushed
  → Triggers release workflow
  → Publishes all packages with matching versions
```

### 3. GitHub Releases → Install Scripts

**Integration**:
- Install scripts download from GitHub releases
- URL pattern: `https://github.com/OWNER/ansilust/releases/latest/download/{artifact}`
- Checksums verified before extraction

**Contract**:
```
GitHub Release v1.0.0:
  - ansilust-linux-x64-gnu.tar.gz
  - ansilust-darwin-arm64.tar.gz
  - [...all platforms]
  - SHA256SUMS
  - SHA256SUMS.asc (if GPG enabled)

Install script:
  - Downloads: ansilust-{platform}.tar.gz
  - Downloads: SHA256SUMS
  - Verifies checksum
  - Extracts and installs
```

### 4. Platform Packages → Meta Package

**Integration**:
- Meta package lists platform packages as optionalDependencies
- npm automatically installs matching platform package
- Launcher requires platform package and spawns binary

**Contract**:
```
ansilust/package.json:
  optionalDependencies: {
    "ansilust-linux-x64-gnu": "1.0.0",
    "ansilust-darwin-arm64": "1.0.0",
    ...
  }

npm install ansilust (on Linux x64 with glibc):
  → Installs ansilust@1.0.0
  → Installs ansilust-linux-x64-gnu@1.0.0 (optional dep matched)

Launcher execution:
  → Detects: linux-x64-glibc
  → Requires: ansilust-linux-x64-gnu
  → Spawns: ansilust-linux-x64-gnu/bin/ansilust
```

---

## Performance Considerations

### npm Package Performance

**Goal**: Zero-delay `npx` execution

**Strategy**:
- esbuild-style packaging: Binary pre-downloaded with meta package
- No postinstall downloads
- Platform selection at runtime (< 10ms overhead)
- Binary spawn via stdio:'inherit' (no buffering)

**Expected Performance**:
```
npx ansilust (first run):
  - npm fetch meta package: ~500ms
  - npm fetch platform package: ~2s (binary size)
  - Launcher overhead: < 10ms
  - Total: ~2.5s

npx ansilust (cached):
  - npm check cache: ~50ms
  - Launcher overhead: < 10ms
  - Total: ~60ms (near-instant)
```

### Install Script Performance

**Goal**: Complete installation in < 60 seconds

**Strategy**:
- Single binary download (no dependencies)
- Minimal checksum verification overhead
- Direct extraction to final destination

**Expected Performance**:
```
curl ansilust.com/install | bash:
  - Download binary: ~5s (5MB @ 1MB/s)
  - Checksum verification: < 1s
  - Extraction: < 1s
  - Installation: < 1s
  - Total: ~8s on typical connection
```

### Build Performance

**Goal**: Complete matrix build in < 30 minutes

**Strategy**:
- Parallel compilation (GitHub Actions matrix)
- Zig's fast cross-compilation (no Docker required)
- Incremental builds where possible
- Cached dependencies

**Expected Performance**:
```
GitHub Actions Matrix Build:
  - 10 platforms in parallel
  - Each platform: ~5 minutes compile time
  - Artifact upload: ~2 minutes
  - Total: ~7 minutes for all platforms
```

### Binary Size

**Goal**: Keep binaries under 10MB per platform

**Strategy**:
- Static linking reduces size vs dynamic
- Strip debug symbols in release builds
- Zig's small runtime overhead
- No unnecessary dependencies

**Expected Sizes**:
```
Linux (musl, static):    ~3-5 MB
Linux (glibc, dynamic):  ~2-4 MB
macOS:                   ~3-5 MB
Windows:                 ~3-5 MB
```

---

## Security Considerations

### Supply Chain Security

**Threats**:
- Compromised binaries in distribution
- Man-in-the-middle attacks during download
- Package substitution on npm

**Mitigations**:
1. **Reproducible Builds**:
   - Pinned Zig version in CI
   - Deterministic compilation flags
   - Documented build environment

2. **Cryptographic Verification**:
   - SHA256 checksums for all artifacts
   - GPG signatures (where enabled)
   - npm package integrity checks

3. **Secure Distribution**:
   - HTTPS-only downloads
   - npm registry integrity
   - GitHub releases authenticity

### Install Script Security

**Threats**:
- Malicious install script modification
- Curl | bash execution risks
- Binary injection during download

**Mitigations**:
1. **Transparency**:
   - Source code links in script headers
   - Users encouraged to review before running
   - Scripts in version control

2. **Verification**:
   - Checksum verification before extraction
   - Abort on verification failure
   - Clear error messages

3. **Minimal Privileges**:
   - Install to user directories where possible
   - Only request sudo when necessary
   - Clear prompts for elevated privileges

### Access Control

**GitHub Actions Secrets**:
- npm token (NPM_TOKEN)
- GPG private key (GPG_PRIVATE_KEY, if used)
- Homebrew tap deploy key

**Principle of Least Privilege**:
- Workflow permissions limited to required scopes
- No write access to main branch from workflows
- Separate tokens for each service

### Audit Trail

**Tracking**:
- Git commits for all package updates
- GitHub Actions logs for all builds
- npm audit log for all publishes
- GPG signatures for verification

---

## Deployment Strategy

### Initial Deployment (v1.0.0)

**Phase 1: Infrastructure Setup**
1. Configure Changesets in monorepo
2. Set up GitHub Actions workflows
3. Reserve npm package names (✅ DONE)
4. Set up Homebrew tap repository
5. Set up AUR package repository
6. Configure ansilust.com hosting

**Phase 2: First Release**
1. Create initial changeset for v1.0.0
2. Merge version PR
3. Trigger release workflow
4. Verify all artifacts published
5. Test installation on all platforms

**Phase 3: Documentation**
1. Update README with all installation methods
2. Create installation guide for each platform
3. Document troubleshooting common issues
4. Publish to ansilust.com

### Continuous Deployment

**Workflow**:
```
Developer adds changeset:
  → npx changeset add
  → Commit changeset file
  → Push to main

Changesets bot:
  → Creates version PR
  → Updates package.json versions
  → Generates CHANGELOG entries

Maintainer merges version PR:
  → Triggers release workflow
  → Builds all platforms
  → Publishes to npm
  → Creates GitHub release
  → Updates package repositories
  → Deploys install scripts
```

**Release Cadence**:
- Patch releases: As needed for critical fixes
- Minor releases: Monthly or when features accumulate
- Major releases: Rare, for breaking changes

---

## Rollback Strategy

### npm Package Rollback

**Scenario**: Published package has critical bug

**Response**:
1. Deprecate broken version:
   ```bash
   npm deprecate ansilust@1.2.3 "Critical bug - use 1.2.2"
   ```

2. Publish patch version:
   - Create changeset with fix
   - Merge version PR
   - Publish v1.2.4

3. Update installation docs:
   - Document known issues in v1.2.3
   - Recommend upgrade to v1.2.4

**Prevention**:
- Pre-release testing on all platforms
- Staged rollout (publish to npm last)
- Quick patch release process

### Install Script Rollback

**Scenario**: Install script has critical bug

**Response**:
1. Revert install script in git:
   ```bash
   git revert <bad-commit>
   git push
   ```

2. Deploy reverted script to ansilust.com:
   - Automated via GitHub Actions
   - Users get fixed script immediately

3. Notify users if needed:
   - GitHub issue announcement
   - Twitter/social media if widespread

**Prevention**:
- Test install scripts in CI before merge
- Review changes to install scripts carefully
- Version install scripts (e.g., install-v1.sh)

### GitHub Release Rollback

**Scenario**: Release artifacts are broken

**Response**:
1. Delete broken release:
   ```bash
   gh release delete v1.2.3 --yes
   git tag -d v1.2.3
   git push origin :refs/tags/v1.2.3
   ```

2. Fix issue and re-release:
   - Create new tag with fixed version
   - Trigger release workflow again

3. Update documentation:
   - Note that v1.2.3 was deleted
   - Recommend v1.2.4 or v1.2.2

**Prevention**:
- Automated testing in CI before release
- Checksum verification in workflow
- Manual verification for major releases

---

## Monitoring and Observability

### Metrics to Track

**Installation Success Rate**:
- npm downloads (npmjs.com stats)
- GitHub release downloads
- Install script executions (if telemetry added)

**Platform Distribution**:
- Which platforms are most used
- Identify platforms needing support
- Optimize build priorities

**Error Rates**:
- Failed npm installs (via npm audit logs)
- Failed install script downloads
- Checksum verification failures

### Health Checks

**Automated Checks**:
```
Daily Cron Job (.github/workflows/health-check.yml):
  - Verify latest release is downloadable
  - Test npm install ansilust
  - Test curl ansilust.com/install
  - Verify checksums match
  - Test Homebrew formula
  - Alert on failures
```

**Manual Checks**:
- Weekly: Test installation on real devices
- Before major release: Full platform matrix test
- After major release: Monitor for 24 hours

---

## Open Questions and Decisions

### Resolved Decisions

✅ **npm packaging strategy**: esbuild-style (meta + platform packages)
✅ **Version management**: Changesets
✅ **Binary distribution**: GitHub Releases + npm
✅ **Checksum algorithm**: SHA256
✅ **Domain**: ansilust.com (owned)

### Pending Decisions

🔲 **GPG signing**: Enable GPG signatures for releases?
   - Pros: Additional security, supply chain verification
   - Cons: Key management complexity, user experience
   - Recommendation: Phase 2 feature after initial release

🔲 **Homebrew bottles**: Build pre-compiled bottles?
   - Pros: Faster installation for Homebrew users
   - Cons: Additional CI complexity, storage
   - Recommendation: Enable if Homebrew usage is significant

🔲 **Container registry**: Use GitHub Container Registry exclusively?
   - Pros: Integrated with releases, free for public repos
   - Cons: Vendor lock-in
   - Recommendation: Start with GHCR, add Docker Hub if needed

🔲 **iOS APT repository**: Self-host or submit to Procursus?
   - Pros (Procursus): Official repo, trusted by users
   - Cons (Procursus): Submission process, review delays
   - Recommendation: Start self-hosted, submit to Procursus for v1.0

🔲 **Install script analytics**: Add anonymous usage tracking?
   - Pros: Understand platform distribution, failure modes
   - Cons: Privacy concerns, implementation complexity
   - Recommendation: No analytics for v1.0, revisit if needed

---

## Next Steps

**Awaiting Authorization to Proceed to Phase 4: Plan Phase**

Upon approval, Phase 4 will create `plan.md` with:
- Detailed implementation roadmap
- Task hierarchies with dependencies
- Validation checkpoints for each milestone
- Progress tracking system
- Risk mitigation strategies

---

## References

### Prior Art

**esbuild npm distribution**:
- Meta package: `esbuild`
- Platform packages: `@esbuild/darwin-arm64`, etc.
- Source: https://github.com/evanw/esbuild/tree/main/npm

**swc npm distribution**:
- Meta package: `@swc/core`
- Platform packages: `@swc/core-darwin-arm64`, etc.
- Source: https://github.com/swc-project/swc/tree/main/npm

**Biome npm distribution**:
- Meta package: `@biomejs/biome`
- Platform packages: `@biomejs/cli-darwin-arm64`, etc.
- Source: https://github.com/biomejs/biome/tree/main/npm

**Changesets Documentation**:
- https://github.com/changesets/changesets
- https://github.com/changesets/changesets/blob/main/docs/intro-to-using-changesets.md

**Zig Cross-Compilation**:
- https://ziglang.org/learn/overview/#cross-compiling-is-a-first-class-use-case
- `zig targets` output for supported platforms

---

## Appendix: Platform Package Details

### Complete Platform Package List

1. **ansilust-darwin-arm64**
   - OS: macOS
   - CPU: Apple Silicon (M1, M2, M3)
   - Zig target: `aarch64-macos`

2. **ansilust-darwin-x64**
   - OS: macOS
   - CPU: Intel x86_64
   - Zig target: `x86_64-macos`

3. **ansilust-linux-x64-gnu**
   - OS: Linux
   - CPU: x86_64
   - libc: glibc (standard distros)
   - Zig target: `x86_64-linux-gnu`

4. **ansilust-linux-x64-musl**
   - OS: Linux
   - CPU: x86_64
   - libc: musl (Alpine, minimal containers)
   - Zig target: `x86_64-linux-musl`

5. **ansilust-linux-arm64-gnu**
   - OS: Linux
   - CPU: aarch64 (64-bit ARM)
   - libc: glibc
   - Zig target: `aarch64-linux-gnu`

6. **ansilust-linux-arm64-musl**
   - OS: Linux
   - CPU: aarch64 (64-bit ARM)
   - libc: musl
   - Zig target: `aarch64-linux-musl`

7. **ansilust-linux-armv7-gnu**
   - OS: Linux
   - CPU: armv7 (32-bit ARM, Raspberry Pi 2/3)
   - libc: glibc
   - Zig target: `armv7-linux-gnueabihf`

8. **ansilust-linux-armv7-musl**
   - OS: Linux
   - CPU: armv7 (32-bit ARM)
   - libc: musl
   - Zig target: `armv7-linux-musleabihf`

9. **ansilust-linux-i386-musl**
   - OS: Linux (via iSH emulator on iOS)
   - CPU: i386 (32-bit x86)
   - libc: musl (static binary)
   - Zig target: `i386-linux-musl`

10. **ansilust-win32-x64**
    - OS: Windows
    - CPU: x86_64
    - Zig target: `x86_64-windows`

### Platform Package Size Estimates

```
darwin-arm64:     ~4 MB (binary + package metadata)
darwin-x64:       ~4 MB
linux-x64-gnu:    ~3 MB
linux-x64-musl:   ~4 MB (static binary larger)
linux-arm64-gnu:  ~3 MB
linux-arm64-musl: ~4 MB
linux-armv7-gnu:  ~3 MB
linux-armv7-musl: ~4 MB
linux-i386-musl:  ~4 MB
win32-x64:        ~4 MB

Total npm package size (all platforms): ~36 MB
Meta package (ansilust): ~20 KB (launcher only)
```

**Total install size for user**:
- Meta package + 1 platform package: ~4-5 MB
- Much smaller than bundling all platforms (~36 MB)
- Instant `npx` with esbuild-style approach
