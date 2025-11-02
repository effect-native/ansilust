# Phase 4: Testing & Validation Guide

**Purpose**: Manual testing procedures for AUR, Nix, domain, and container components.

---

## Testing Matrix

| Component | Local Test | CI Test | Status |
|-----------|-----------|---------|--------|
| **AUR Package** | `makepkg -si` | ❌ N/A | Ready |
| **Nix Flake** | `nix run . --` | Part of release | Ready |
| **Domain** | `curl https://ansilust.com` | N/A | Awaiting config |
| **Containers** | `docker build && docker run` | Release job | Ready |

---

## 4.1 - AUR Package Testing

### Prerequisites
- Arch Linux system or container
- `base-devel` package group installed

### Installation Test

```bash
# 1. Navigate to AUR directory
cd aur/

# 2. Verify PKGBUILD is valid
bash -c "source PKGBUILD; echo 'PKGBUILD valid'"

# 3. Generate .SRCINFO (requires makepkg)
makepkg --printsrcinfo > .SRCINFO

# 4. Mock binary for testing (since we don't have a release yet)
mkdir -p bin
touch ansilust
chmod +x ansilust
echo '#!/usr/bin/env bash' > ansilust
echo 'echo "ansilust v0.0.1"' >> ansilust

# 5. Build package
makepkg

# 6. Install locally
sudo pacman -U ansilust-0.0.1-1-x86_64.pkg.tar.zst

# 7. Verify installation
which ansilust
ansilust --version

# 8. Cleanup
sudo pacman -R ansilust
rm -f *.pkg.tar.zst
```

### PKGBUILD Update Test

```bash
# Test the update script with mock checksums
cd scripts/

# Create test checksums file
cat > test_checksums.txt << 'EOF'
abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234 ansilust-linux-x64-gnu.tar.gz
efgh5678901234efgh5678901234efgh5678901234efgh5678901234efgh5678 ansilust-linux-arm64-gnu.tar.gz
ijkl9012345678ijkl9012345678ijkl9012345678ijkl9012345678ijkl9012 ansilust-linux-armv7-gnu.tar.gz
EOF

# Run update script
./update-aur-pkgbuild.sh 0.1.0 test_checksums.txt

# Verify changes
cat ../aur/PKGBUILD | grep "pkgver="
cat ../aur/PKGBUILD | grep "sha256sums_"

# Cleanup
rm test_checksums.txt
```

### AUR Repository Push Test

```bash
# After setting up AUR repository
cd ../aur-ansilust  # This is your separate AUR repo clone

# Copy updated files from main repo
cp ../ansilust/aur/PKGBUILD .
cp ../ansilust/aur/.SRCINFO .

# Git commit
git add PKGBUILD .SRCINFO
git commit -m "Update to v0.1.0"

# Push to AUR (requires SSH key configured)
git push
```

---

## 4.2 - Nix Flake Testing

### Prerequisites
- NixOS or Nix installed
- `nix` command available

### Flake Validation

```bash
# Check flake syntax
nix flake show

# Validate flake
nix flake check

# Show available systems
nix flake show --allow-import-from-derivation
```

### Development Shell Test

```bash
# Enter dev environment
nix develop

# Verify tools available
which zig
which node
which pkg-config

# Exit when done
exit
```

### Flake Package Test (When Binary Available)

```bash
# Build from local flake
nix build . --allow-import-from-derivation

# Run built package
./result/bin/ansilust --version

# Cleanup
rm -rf result
```

### Remote Flake Test (After GitHub Release)

```bash
# Run directly from GitHub
nix run github:effect-native/ansilust -- --version

# Install to profile
nix profile install github:effect-native/ansilust

# Use installed version
ansilust --version

# Remove from profile
nix profile remove ansilust
```

### Nix Flake Update Test

```bash
cd scripts/

# Create test checksums
cat > test_checksums.txt << 'EOF'
abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234 ansilust-linux-x64-gnu.tar.gz
efgh5678901234efgh5678901234efgh5678901234efgh5678901234efgh5678 ansilust-linux-arm64-gnu.tar.gz
ijkl9012345678ijkl9012345678ijkl9012345678ijkl9012345678ijkl9012 ansilust-darwin-x64.tar.gz
mnop3456789012mnop3456789012mnop3456789012mnop3456789012mnop3456 ansilust-darwin-arm64.tar.gz
EOF

# Run update script
./update-nix-flake.sh 0.1.0 test_checksums.txt

# Verify changes
cat ../flake.nix | grep "version ="
cat ../flake.nix | grep "sha256 ="

# Cleanup
rm test_checksums.txt
```

---

## 4.3 - Domain Hosting Testing

### Prerequisites
- `curl` command available
- Domain configured (ansilust.com)

### HTTPS Verification

```bash
# Test HTTPS connectivity
curl -I https://ansilust.com/

# Expected output:
# HTTP/1.1 200 OK
# Strict-Transport-Security: max-age=31536000
```

### Install Script Delivery

```bash
# Test Bash installer download
curl -fsSL https://ansilust.com/install | head -5
# Should show: #!/usr/bin/env bash

# Test PowerShell installer download
curl -fsSL https://ansilust.com/install.ps1 | head -5
# Should show: # ansilust installer script

# Test with actual installation (in test environment)
curl -fsSL https://ansilust.com/install | bash -s -- --help
```

### Certificate Validation

```bash
# Check SSL certificate
curl -I --cacert /etc/ssl/certs/ca-certificates.crt https://ansilust.com/

# Check certificate details
openssl s_client -connect ansilust.com:443 -showcerts < /dev/null

# Should show:
# - Valid date range
# - Subject matching ansilust.com
# - Issued by trusted CA (Let's Encrypt)
```

### Redirect Testing

```bash
# Test HTTP → HTTPS redirect
curl -I http://ansilust.com/install
# Should return 301/302 to https://

# Test file redirects
curl -I https://ansilust.com/install
# Should resolve to install.sh with 200 OK
```

---

## 4.4 - Container Testing

### Prerequisites
- Docker or Podman installed
- Internet connection for image pulls

### Local Build Test

```bash
# Build Docker image locally
docker build -t ansilust:test .

# Verify image created
docker images | grep ansilust

# Test basic execution
docker run --rm ansilust:test --version

# Test with --help
docker run --rm ansilust:test --help

# Inspect image layers
docker history ansilust:test

# Check image size
docker images ansilust:test
```

### Multi-arch Build Test (Linux only)

```bash
# Enable Docker buildx for multi-platform builds
docker run --rm --privileged docker/binfmt:latest

# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t ansilust:multiarch .

# Load single architecture (requires docker driver)
docker buildx build --platform linux/amd64 -t ansilust:amd64 -o type=docker .
docker run --rm ansilust:amd64 --version
```

### GHCR Push Test (Requires Credentials)

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin

# Tag image for GHCR
docker tag ansilust:test ghcr.io/effect-native/ansilust:test

# Push to GHCR
docker push ghcr.io/effect-native/ansilust:test

# Verify push
curl -I https://ghcr.io/v2/effect-native/ansilust/manifests/test

# Test pulling from GHCR
docker pull ghcr.io/effect-native/ansilust:test
docker run --rm ghcr.io/effect-native/ansilust:test --version
```

### Podman Testing (Arch Linux)

```bash
# Build with Podman
podman build -t ansilust:test .

# Run with Podman
podman run --rm ansilust:test --version

# Push to GHCR with Podman
podman push ansilust:test ghcr.io/effect-native/ansilust:test
```

### Security Scan Test

```bash
# Scan image for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ansilust:test

# Should show:
# - No critical vulnerabilities
# - Minimal base image (alpine/scratch)
# - Only one binary
```

---

## Integration Testing

### Complete Flow Test

```bash
# Test all components together
echo "=== Testing AUR ==="
cd aur && makepkg --printsrcinfo > .SRCINFO && cd ..

echo "=== Testing Nix ==="
nix flake check

echo "=== Testing Docker ==="
docker build -t ansilust:test .
docker run --rm ansilust:test --version

echo "=== Testing Domain (if configured) ==="
curl -fsSL https://ansilust.com/install | head -1

echo "✅ All Phase 4 components validated"
```

---

## Troubleshooting

### AUR Issues

**Problem**: `makepkg: command not found`
```bash
# Solution: Install base-devel
sudo pacman -S base-devel
```

**Problem**: `PKGBUILD: line 1: syntax error`
```bash
# Solution: Check for DOS line endings
dos2unix aur/PKGBUILD
```

### Nix Issues

**Problem**: `error: flake 'git+file://...' does not provide attribute`
```bash
# Solution: Ensure flake.nix is at repository root (not subdirectory)
test -f ./flake.nix && echo "✅ OK" || echo "❌ Missing"
```

### Docker Issues

**Problem**: `docker: command not found`
```bash
# Solution: Install Docker
# Ubuntu: sudo apt-get install docker.io
# Arch: sudo pacman -S docker
```

**Problem**: `Got permission denied while trying to connect to Docker daemon`
```bash
# Solution: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Domain Issues

**Problem**: `curl: (6) Could not resolve host`
```bash
# Solution: DNS not yet configured
# Check domain status: nslookup ansilust.com
# Configure DNS at domain registrar
```

---

## Acceptance Criteria Validation

- [ ] AUR PKGBUILD builds successfully with `makepkg -si`
- [ ] PKGBUILD syntax valid: `bash -c "source aur/PKGBUILD; echo OK"`
- [ ] .SRCINFO generated from PKGBUILD: `makepkg --printsrcinfo`
- [ ] Nix flake syntax valid: `nix flake check`
- [ ] Docker image builds: `docker build -t ansilust:test .`
- [ ] Docker image runs: `docker run --rm ansilust:test --version`
- [ ] Install scripts accessible via domain (when configured)
- [ ] HTTPS certificate valid and working
- [ ] Multi-arch container images build (with buildx)
- [ ] GHCR authentication works for push/pull

---

## Quick Reference

```bash
# AUR
cd aur && makepkg -si && cd ..

# Nix
nix flake check && nix run . -- --version

# Docker
docker build -t ansilust:test . && docker run --rm ansilust:test --version

# Domain (after config)
curl -fsSL https://ansilust.com/install | head -1

# All updates
scripts/update-aur-pkgbuild.sh 1.0.0 SHA256SUMS
scripts/update-nix-flake.sh 1.0.0 SHA256SUMS
scripts/generate-srcinfo.sh
```
