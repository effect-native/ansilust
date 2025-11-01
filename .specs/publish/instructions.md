# Publishing & Distribution - Instructions

## Overview and User Story

As a project maintainer, I want ansilust to be easily installable across all major package managers and platforms so that users can quickly get started with text art processing regardless of their development environment.

The ansilust project needs comprehensive, secure, and automated distribution across:
- **Package Registries**: npm/npx, Homebrew, AUR (Arch User Repository), Nix packages
- **Direct Install Scripts**: Bash installer, PowerShell installer
- **Custom Domain**: ansilust.com hosting install scripts
- **GitHub CI/CD**: Automated builds, releases, and package publishing

All distribution mechanisms must prioritize security, reproducibility, and maintainability.

---

## Core Requirements (EARS Notation)

### Distribution Channels

#### Direct Execution

**CR1**: The project shall be runnable via `npx ansilust`.

**CR2**: The project shall be runnable via `nix run github:effect-native/ansilust` or `nix run nixpkgs#ansilust`.

**CR3**: The project shall be runnable via `bunx ansilust`.

**CR4**: The project shall be runnable via `deno run npm:ansilust`.

**CR5**: The project shall be runnable via container runtimes with `docker run ghcr.io/effect-native/ansilust` or `podman run ghcr.io/effect-native/ansilust`.

#### Explicit Installation

**CR7**: The project shall be installable via npm with `npm install -g ansilust`.

**CR8**: The project shall be installable via Homebrew with `brew install ansilust`.

**CR9**: The project shall be available on AUR (Arch User Repository) for Arch Linux users.

**CR10**: The project shall be installable via Nix with `nix-env -iA nixpkgs.ansilust` or `nix profile install`.

**CR11**: WHEN users access `https://ansilust.com/install` the system shall provide a Bash installer script.

**CR11.1**: The Bash installer script shall include header comments with a deep link to its source code on GitHub.

**CR12**: WHEN users access `https://ansilust.com/install.ps1` the system shall provide a PowerShell installer script.

**CR12.1**: The PowerShell installer script shall include header comments with a deep link to its source code on GitHub.

**CR13**: The project shall support installation on Linux, macOS, and Windows platforms.

**CR13.1**: The project shall support installation on ARM devices including Raspberry Pi (armv7, aarch64).

**CR13.2**: The project shall support installation in Docker containers across all supported architectures.

**CR13.3**: The project shall support installation on VPS environments (Ubuntu, Debian, CentOS, Alpine, etc.).

**CR13.4**: WHERE Termux is available the project shall support installation on Android devices.

### Security & Automation

**CR14**: All package builds and distributions shall be automated via GitHub Actions CI/CD.

**CR15**: All release artifacts shall be cryptographically signed and verifiable.

**CR16**: The build process shall be reproducible to ensure supply chain security.

**CR17**: WHEN a new git tag is created the system shall automatically trigger release workflows.

**CR18**: IF any security scan fails THEN the release workflow shall abort with clear error messages.

**CR19**: Install scripts shall include clear attribution and source code links for transparency and security auditing.

### Package Requirements

**CR20**: Each distribution package shall include the compiled ansilust binary for the target platform.

**CR21**: Each package shall include documentation (README, LICENSE, usage examples).

**CR22**: The npm package shall include Zig-compiled binaries for the current platform.

**CR23**: WHEN explicitly installed the `ansilust` command shall be available in the user's PATH.

**CR24**: WHEN executed directly (npx, nix run, bunx, deno, docker) the command shall work with a single invocation.

---

## Direct Execution vs Installation

### Direct Execution

**Concept**: Run ansilust with a single command, no explicit installation step required.

**How users think about it**: "Just run it immediately without dealing with installation."

**Methods**:

| Method | Command | Platform |
|--------|---------|----------|
| **npx** | `npx ansilust` | All (Node.js) |
| **bunx** | `bunx ansilust` | All (Bun) |
| **deno** | `deno run npm:ansilust` | All (Deno) |
| **nix run** | `nix run nixpkgs#ansilust` | All (Nix) |
| **docker/podman** | `docker run ghcr.io/owner/ansilust`<br>`podman run ghcr.io/owner/ansilust` | All (containers) |

**User benefits**:
- No separate installation step
- Easy to try without commitment
- Good for CI/CD and one-off usage
- Version can be specified inline

### Installation (Explicit)

**Concept**: Explicitly install ansilust, then run it.

**How users think about it**: "Install once, use many times."

**Methods**:

| Method | Install Command | Run Command | Platform |
|--------|----------------|-------------|----------|
| **npm global** | `npm install -g ansilust` | `ansilust` | All (Node.js) |
| **Homebrew** | `brew install ansilust` | `ansilust` | macOS/Linux |
| **AUR** | `yay -S ansilust` | `ansilust` | Arch Linux |
| **Nix profile** | `nix profile install nixpkgs#ansilust` | `ansilust` | All (Nix) |
| **Bash installer** | `curl -fsSL ansilust.com/install \| bash` | `ansilust` | Linux/macOS |
| **PowerShell** | `irm ansilust.com/install.ps1 \| iex` | `ansilust` | Windows |

**User benefits**:
- Command available in PATH
- Managed by package manager
- Clear update/uninstall path
- Familiar workflow for each platform

### Recommended User Workflows

**Casual User / First Time**:
```bash
# Just run it
npx ansilust file.ans

# Like it? Install it
npm install -g ansilust
ansilust file.ans
```

**CI/CD Pipeline**:
```yaml
# Direct execution
- run: npx ansilust file.ans
```

**Power User / Developer**:
```bash
# Install via preferred package manager
brew install ansilust  # macOS
yay -S ansilust       # Arch Linux
nix profile install nixpkgs#ansilust  # NixOS
```

---

## Technical Specifications

### Platforms & Architectures
- **Linux**: x86_64, aarch64, armv7 (32-bit ARM for older Raspberry Pi)
- **macOS**: x86_64 (Intel), aarch64 (Apple Silicon)
- **Windows**: x86_64
- **Special Environments**:
  - Docker containers (all architectures, including Alpine Linux musl)
  - VPS/Cloud providers (standard Linux distributions)
  - Raspberry Pi (armv7, aarch64)
  - Android via Termux (aarch64, armv7)

### Distribution Formats

#### Direct Execution Formats
- **npx/bunx/deno**: Run from npm registry with single command
- **nix run**: Run from nixpkgs or flake repository
- **docker/podman**: Run from container registry (OCI-compatible)

#### Explicit Installation Formats
- **npm global**: Package installed to npm global bin directory
- **Homebrew**: Formula with bottle builds
- **AUR**: PKGBUILD for Arch Linux
- **Nix profile**: Derivation installed to user profile
- **Installer scripts**: Bash/PowerShell scripts that download and install binary
- **Manual**: Binary archives (tar.gz, zip) for manual extraction

### Domain & Hosting
- **Domain**: ansilust.com (OWNED - confirmed)
- **Install Scripts**: Static hosting (GitHub Pages, Cloudflare Pages, Netlify, or similar)
- **SSL**: Required for all install script endpoints (automatic with modern hosting)

### GitHub CI/CD
- **Triggers**: Git tags (v*), pull requests (build only), main branch commits
- **Workflows**:
  - Build matrix for all platforms/architectures:
    - Linux: x86_64, aarch64, armv7 (musl and glibc variants)
    - macOS: x86_64, aarch64
    - Windows: x86_64
  - Run tests and validation on all architectures
  - Cross-compilation using Zig's native cross-compile support
  - Sign artifacts (checksums, GPG signatures)
  - Create GitHub releases with all architecture variants
  - Publish to npm registry
  - Update Homebrew formula repository
  - Update AUR package repository
  - Update Nix package repository (nixpkgs PR or overlay)

---

## Acceptance Criteria

### Direct Execution

**AC1**: A user shall successfully run `npx ansilust` and have it work immediately.

**AC2**: A user shall successfully run `bunx ansilust` and have it work immediately.

**AC3**: A user shall successfully run `deno run npm:ansilust` and have it work immediately.

**AC4**: A user shall successfully run `nix run github:owner/ansilust` and have it work immediately.

**AC5**: A user shall successfully run `nix run nixpkgs#ansilust` and have it work immediately.

**AC6**: A user shall successfully run `docker run ghcr.io/owner/ansilust` and have it work immediately.

**AC7**: A user shall successfully run `podman run ghcr.io/owner/ansilust` and have it work immediately.

### Explicit Installation

**AC8**: A user shall successfully install ansilust globally with `npm install -g ansilust`.

**AC9**: A user shall successfully install ansilust with `brew install ansilust` on macOS or Linux.

**AC10**: An Arch Linux user shall successfully install ansilust from AUR using `yay -S ansilust` or `paru -S ansilust`.

**AC11**: A Nix user shall successfully install ansilust with `nix profile install nixpkgs#ansilust` or `nix-env -iA nixpkgs.ansilust`.

**AC12**: A user shall successfully install ansilust on Linux/macOS with:
```bash
curl -fsSL https://ansilust.com/install | bash
```

**AC13**: A user shall successfully install ansilust on Windows with:
```powershell
powershell -c "irm ansilust.com/install.ps1 | iex"
```

**AC14**: A user shall successfully install ansilust on Raspberry Pi (armv7/aarch64) using the bash installer.

**AC15**: A user shall successfully install ansilust in a Docker container with the bash installer.

**AC16**: A user shall successfully install ansilust on a VPS (DigitalOcean, AWS, Hetzner, etc.) with the bash installer.

**AC17**: A user shall successfully install ansilust on Android via Termux using the bash installer.

**AC18**: WHEN explicitly installed the `ansilust` command shall be available in PATH for subsequent use.

### Security & Verification

**AC19**: WHEN a user downloads ansilust the system shall provide SHA256 checksums for all artifacts.

**AC20**: WHEN examining the release workflow the process shall be fully automated via GitHub Actions.

**AC21**: WHEN reviewing build artifacts the builds shall be reproducible given the same source and toolchain version.

**AC22**: The install scripts shall verify checksums before extracting binaries.

**AC23**: The install scripts shall fail gracefully with clear error messages on verification failures.

### Package Quality

**AC24**: Each distributed package shall include up-to-date documentation.

**AC25**: Each package shall correctly set up the `ansilust` command in the user's PATH.

**AC26**: WHEN running `ansilust --version` the command shall display the correct version number.

**AC27**: WHEN running `ansilust --help` the command shall display comprehensive usage information.

---

## Out of Scope

The following are explicitly **out of scope** for this feature:

- **Windows Package Managers**: Chocolatey, Scoop, winget (future consideration)
- **Linux Package Managers**: apt/deb, yum/rpm, snap, flatpak (future consideration)
- **Pre-built Container Images**: Official container images (in scope for direct execution via existing registries)
- **Language-Specific Managers**: cargo install, go install (not applicable)
- **Auto-Update Mechanism**: Built-in auto-updater within ansilust binary
- **Telemetry**: Usage analytics or crash reporting
- **Premium/Commercial Distribution**: Enterprise licensing or support tiers

---

## Success Metrics

**SM1**: Ansilust is executable via at least 5 direct execution methods (npx, bunx, deno, nix run, docker/podman).

**SM1.1**: Ansilust is installable via at least 6 explicit installation methods (npm global, brew, AUR, nix profile, bash script, PowerShell script).

**SM2**: GitHub Actions workflows successfully build and publish releases for all platforms on every tagged version.

**SM3**: Install scripts complete successfully on fresh systems within 60 seconds.

**SM4**: All package managers correctly install the binary and make it available in PATH.

**SM5**: Security scans (checksums, signatures) pass for 100% of published artifacts.

**SM6**: Documentation for each installation method is clear and accurate.

---

## Future Considerations

### Expanded Platform Support
- Windows package managers (Chocolatey, Scoop, winget)
- Linux distribution packages (apt/deb, yum/rpm, snap, flatpak)
- Container images (Docker Hub, GitHub Container Registry)
- Additional ARM platforms (RISC-V, other embedded devices)
- WebAssembly builds for browser execution

### Enhanced Security
- GPG signature verification for all packages
- SLSA (Supply chain Levels for Software Artifacts) compliance
- Software Bill of Materials (SBOM) generation
- Vulnerability scanning integration

### Distribution Improvements
- Version pinning and rollback mechanisms
- Delta updates for faster downloads
- Mirror hosting for reliability
- CDN integration for global distribution

### Ecosystem Integration
- IDE extensions (VSCode, Vim, etc.)
- Shell completions (bash, zsh, fish)
- Man page distribution
- Integration with package manager search/discovery

---

## Testing Requirements

### Functional Testing

**FT1**: The system shall verify installation succeeds on clean systems for each distribution method.

**FT2**: The system shall verify the installed binary runs and displays correct version information.

**FT3**: The system shall verify all install scripts handle network failures gracefully.

**FT4**: The system shall verify checksum verification correctly rejects corrupted downloads.

### Platform Testing

**PT1**: Installation shall be tested on:
- Ubuntu 22.04, 24.04 (Linux/x86_64)
- Debian 12 (Linux/x86_64)
- Arch Linux (latest) (Linux/x86_64)
- macOS 13 (Intel), macOS 14 (Apple Silicon)
- Windows 11 (x86_64)
- Raspberry Pi OS (armv7, aarch64)
- Alpine Linux (x86_64, aarch64) for Docker/minimal environments
- Android Termux (aarch64)

**PT2**: Each platform shall support at least 2 installation methods.

**PT3**: Installation in isolated environments (Docker containers, VMs) shall succeed.

**PT4**: Installation shall be tested in common VPS environments:
- DigitalOcean Ubuntu droplet
- AWS EC2 Amazon Linux
- Hetzner Cloud Debian instance
- Oracle Cloud ARM instance (aarch64)

**PT5**: Installation shall be tested in Docker containers:
- `ubuntu:latest`, `debian:slim`, `alpine:latest`
- Multi-arch containers (x86_64, aarch64, armv7)

### Security Testing

**ST1**: Install scripts shall be scanned for shell injection vulnerabilities.

**ST2**: All HTTPS endpoints shall use valid SSL certificates.

**ST3**: Checksum verification shall detect and reject modified binaries.

**ST4**: GitHub Actions workflows shall use pinned action versions for security.

### Integration Testing

**IT1**: The CI/CD pipeline shall successfully build, test, and publish on every tagged release.

**IT2**: GitHub releases shall be created with all required artifacts and checksums.

**IT3**: Package repositories shall be updated automatically after successful builds.

### Documentation Testing

**DT1**: Installation documentation shall be tested by following instructions verbatim.

**DT2**: WHEN users follow installation docs the process shall complete without additional research.

**DT3**: Error messages in install scripts shall be clear and actionable.

**DT4**: Install script headers shall include valid GitHub source code links.

**DT5**: GitHub source code links in install scripts shall resolve to the correct file and branch.

---

## Dependencies

### External Services
- **npm Registry**: For npm package publishing
- **Homebrew**: Tap repository for formula hosting
- **AUR**: User repository access for package publishing
- **Nix**: nixpkgs repository or personal overlay
- **Domain Registrar**: For ansilust.com domain
- **GitHub**: Actions, Releases, repository hosting

### Tooling
- **GitHub Actions**: CI/CD orchestration
- **Zig**: Cross-compilation for all platforms
- **GPG/SHA256**: Artifact signing and verification
- **tar/zip**: Archive creation for distribution

### Accounts & Access
- npm account with publishing permissions
- Homebrew tap repository (GitHub)
- AUR maintainer account
- ansilust.com domain (OWNED) with hosting configured
- GPG keys for signing
- GitHub repository with Actions enabled

---

## Research & Reference Projects

### Package Distribution Examples

**Bun Runtime** (`reference/bun/`):
- Cross-platform binary distribution
- npm package with platform-specific binaries
- Homebrew formula with bottle builds
- Install script patterns (`curl | bash`)
- GitHub Actions release automation

**Key Learnings from Bun**:
- Platform detection in install scripts (OS, architecture, libc variant)
- Binary selection based on OS/architecture (including ARM variants)
- Homebrew tap repository structure
- npm postinstall scripts for binary setup
- Release artifact organization
- Cross-compilation strategies for ARM targets
- Docker multi-arch build patterns
- Zig's native cross-compilation for all targets

### Zig Projects Distribution
- **zls (Zig Language Server)**: AUR, Nix, Homebrew
- **zigmod**: npm distribution with Zig binary
- **zoxide**: Multi-platform installer patterns

### Security Best Practices
- **SLSA Framework**: Supply chain security levels
- **Reproducible Builds**: Deterministic compilation
- **Sigstore**: Keyless signing (future consideration)
- **Transparent Install Scripts**: Source code links for security auditing

### Install Script Header Format

All install scripts served from ansilust.com shall include header comments with source links:

**Bash Installer (`install` or `install.sh`):**
```bash
#!/usr/bin/env bash
# ansilust installer script
# 
# This script is served from: https://ansilust.com/install
# Source code: https://github.com/owner/ansilust/blob/main/scripts/install.sh
# 
# Usage: curl -fsSL https://ansilust.com/install | bash
# 
# For security, you should review this script before running:
# curl -fsSL https://ansilust.com/install | less
#
```

**PowerShell Installer (`install.ps1`):**
```powershell
# ansilust installer script
# 
# This script is served from: https://ansilust.com/install.ps1
# Source code: https://github.com/owner/ansilust/blob/main/scripts/install.ps1
# 
# Usage: irm ansilust.com/install.ps1 | iex
# 
# For security, you should review this script before running:
# irm ansilust.com/install.ps1 | more
#
```

**Benefits**:
- **Transparency**: Users can audit the source code before running
- **Security**: Clear path to verify script integrity
- **Trust**: Open-source visibility builds confidence
- **Debugging**: Easy to file issues against specific script versions

**Implementation Notes**:
- GitHub links should point to `main` branch for latest installer
- Consider version-specific links for tagged releases (e.g., `/blob/v1.0.0/scripts/install.sh`)
- Scripts should be in version control at predictable paths (e.g., `scripts/install.sh`, `scripts/install.ps1`)
- Consider adding script version/hash in comments for traceability

---

## Risk Assessment

### High Priority Risks

**R1**: **Security Vulnerability in Install Scripts**
- *Mitigation*: Code review, shellcheck/PSScriptAnalyzer, security scanning, source code transparency with GitHub links

**R2**: **GitHub Actions Quota Limits**
- *Mitigation*: Optimize builds, use caching, conditional workflows

**R3**: **Breaking Changes in Package Managers**
- *Mitigation*: Pin dependencies, monitor deprecations, maintain tests

### Medium Priority Risks

**R4**: **Domain Expiration or Compromise**
- *Mitigation*: Auto-renewal enabled, DNS monitoring, DNSSEC if supported
- *Status*: Domain owned and under control

**R5**: **Build Reproducibility Failures**
- *Mitigation*: Pin toolchain versions, document build environment

**R6**: **npm/Homebrew Publishing Failures**
- *Mitigation*: Dry-run testing, manual fallback procedures

### Low Priority Risks

**R7**: **Platform Support Bitrot**
- *Mitigation*: Regular testing, automated compatibility checks

**R8**: **Documentation Drift**
- *Mitigation*: Automated doc generation, version-specific docs

---

## Notes

- This feature focuses on **distribution infrastructure** rather than ansilust application features
- Security and automation are paramount given the attack surface of install scripts
- GitHub Actions will be the single source of truth for all builds and releases
- All distribution methods should install the same verified, tested binary
- Install scripts must be idempotent and handle partial failures gracefully
- Version numbering should follow SemVer for clear upgrade paths
- **ARM Support**: Zig's cross-compilation makes ARM support straightforward
- **Musl vs Glibc**: Alpine/Docker environments may need musl-linked binaries
- **Termux**: Android support via Termux requires aarch64 or armv7 binaries
- **Install Script Intelligence**: Detect platform, architecture, and libc variant automatically
- **Binary Variants**: May need separate builds for glibc (standard Linux) and musl (Alpine/embedded)
