#!/usr/bin/env bash
# ansilust installer script
#
# Served from: https://ansilust.com/install
# Source: https://github.com/effect-native/ansilust/blob/main/scripts/install.sh
#
# Usage: curl -fsSL https://ansilust.com/install | bash
#
# For security, you should review this script before running:
# curl -fsSL https://ansilust.com/install | less
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="effect-native/ansilust"
INSTALL_DIR="${HOME}/.local/bin"
GITHUB_RELEASES="https://github.com/${REPO}/releases"
TEMP_DIR=$(mktemp -d)

# Cleanup on exit
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Helper functions
print_info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

print_success() {
  echo -e "${GREEN}✓${NC} $*"
}

print_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

# Detect platform
detect_platform() {
  local os
  local arch
  local libc
  
  os=$(uname -s)
  arch=$(uname -m)
  
  # Normalize architecture names
  case "$arch" in
    x86_64) arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv7l|armv7) arch="armv7" ;;
    i686|i386) arch="i386" ;;
  esac
  
  # Normalize OS names
  case "$os" in
    Linux)
      os="linux"
      # Detect libc variant (glibc vs musl)
      if command -v ldd &> /dev/null && ldd --version 2>&1 | grep -q musl; then
        libc="musl"
      elif [ -f /lib/ld-musl-* ] || [ -f /lib64/ld-musl-* ]; then
        libc="musl"
      else
        libc="gnu"
      fi
      ;;
    Darwin)
      os="darwin"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      os="win32"
      ;;
    *)
      print_error "Unsupported OS: $os"
      return 1
      ;;
  esac
  
  # Format platform string
  if [ "$os" = "win32" ]; then
    echo "${os}-${arch}"
  elif [ "$os" = "darwin" ]; then
    echo "${os}-${arch}"
  else
    echo "${os}-${arch}-${libc}"
  fi
}

# Download binary with retry
download_binary() {
  local platform="$1"
  local url="${GITHUB_RELEASES}/latest/download/ansilust-${platform}.tar.gz"
  local output="$TEMP_DIR/ansilust.tar.gz"
  local max_retries=3
  local retry=0
  
  print_info "Downloading ansilust for $platform..."
  
  while [ $retry -lt $max_retries ]; do
    if curl -fsSL --max-time 30 "$url" -o "$output"; then
      if [ -f "$output" ] && [ -s "$output" ]; then
        print_success "Downloaded successfully"
        echo "$output"
        return 0
      fi
    fi
    
    retry=$((retry + 1))
    if [ $retry -lt $max_retries ]; then
      print_warning "Download failed, retrying... ($retry/$max_retries)"
      sleep 2
    fi
  done
  
  print_error "Failed to download after $max_retries attempts"
  print_error "Please check:"
  print_error "  - Your internet connection"
  print_error "  - The platform '$platform' is supported"
  print_error "  - Latest release exists at: $GITHUB_RELEASES"
  return 1
}

# Verify checksum
verify_checksum() {
  local tarball="$1"
  local platform="$2"
  local checksums_file="$TEMP_DIR/SHA256SUMS"
  local expected_hash
  local actual_hash
  
  print_info "Downloading checksums..."
  
  if ! curl -fsSL "${GITHUB_RELEASES}/latest/download/SHA256SUMS" -o "$checksums_file"; then
    print_warning "Could not download checksums, skipping verification"
    return 0
  fi
  
  print_info "Verifying checksum..."
  
  expected_hash=$(grep "ansilust-${platform}.tar.gz" "$checksums_file" | awk '{print $1}')
  
  if [ -z "$expected_hash" ]; then
    print_warning "Checksum for platform '$platform' not found, skipping verification"
    return 0
  fi
  
  actual_hash=$(sha256sum "$tarball" | awk '{print $1}')
  
  if [ "$expected_hash" = "$actual_hash" ]; then
    print_success "Checksum verified"
    return 0
  else
    print_error "Checksum mismatch!"
    print_error "  Expected: $expected_hash"
    print_error "  Got:      $actual_hash"
    return 1
  fi
}

# Install binary
install_binary() {
  local tarball="$1"
  local platform="$2"
  
  print_info "Extracting binary..."
  
  # Create temp extract directory
  local extract_dir="$TEMP_DIR/extract"
  mkdir -p "$extract_dir"
  
  if ! tar -xzf "$tarball" -C "$extract_dir"; then
    print_error "Failed to extract tarball"
    return 1
  fi
  
  # Find the binary (might be in root or in a subdirectory)
  local binary
  if [ -f "$extract_dir/ansilust" ]; then
    binary="$extract_dir/ansilust"
  elif [ -f "$extract_dir/bin/ansilust" ]; then
    binary="$extract_dir/bin/ansilust"
  else
    print_error "Could not find 'ansilust' binary in tarball"
    return 1
  fi
  
  if [ ! -x "$binary" ]; then
    chmod +x "$binary"
  fi
  
  # Create install directory if needed
  if [ ! -d "$INSTALL_DIR" ]; then
    print_info "Creating $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
  fi
  
  print_info "Installing to $INSTALL_DIR/ansilust..."
  
  if ! cp "$binary" "$INSTALL_DIR/ansilust"; then
    print_error "Failed to copy binary to $INSTALL_DIR"
    print_error "Try running with: sudo bash -c 'curl -fsSL https://ansilust.com/install | bash'"
    return 1
  fi
  
  chmod +x "$INSTALL_DIR/ansilust"
  print_success "Binary installed to $INSTALL_DIR/ansilust"
}

# Update PATH if needed
update_path() {
  local shell_rc=""
  local path_not_set=false
  
  # Check if already in PATH
  if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    print_success "$INSTALL_DIR is already in your PATH"
    return 0
  fi
  
  path_not_set=true
  
  # Determine shell configuration file
  if [ -n "$ZSH_VERSION" ]; then
    shell_rc="${HOME}/.zshrc"
  elif [ -n "$BASH_VERSION" ]; then
    shell_rc="${HOME}/.bashrc"
  else
    shell_rc="${HOME}/.profile"
  fi
  
  print_warning "$INSTALL_DIR is not in your PATH"
  
  if [ -w "$shell_rc" ]; then
    print_info "Adding to $shell_rc..."
    echo "" >> "$shell_rc"
    echo "# ansilust" >> "$shell_rc"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_rc"
    print_success "Added to PATH in $shell_rc"
    print_info "Run 'source $shell_rc' or start a new terminal session"
  else
    print_error "Cannot write to $shell_rc"
    print_info "Please add manually: export PATH=\"$INSTALL_DIR:\$PATH\""
  fi
}

# Verify installation
verify_installation() {
  print_info "Verifying installation..."
  
  if [ ! -f "$INSTALL_DIR/ansilust" ]; then
    print_error "Binary not found at $INSTALL_DIR/ansilust"
    return 1
  fi
  
  if ! "$INSTALL_DIR/ansilust" --version &> /dev/null; then
    print_error "Binary exists but failed to execute"
    return 1
  fi
  
  local version
  version=$("$INSTALL_DIR/ansilust" --version 2>&1 || echo "unknown")
  print_success "Installation successful! Version: $version"
  
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    print_warning "Note: $INSTALL_DIR is not in your PATH"
    print_info "Either run: export PATH=\"$INSTALL_DIR:\$PATH\""
    print_info "Or restart your terminal"
  fi
}

# Main installation flow
main() {
  print_info "ansilust installer"
  print_info "Detecting platform..."
  
  local platform
  if ! platform=$(detect_platform); then
    print_error "Platform detection failed"
    return 1
  fi
  
  print_success "Detected platform: $platform"
  
  local tarball
  if ! tarball=$(download_binary "$platform"); then
    return 1
  fi
  
  if ! verify_checksum "$tarball" "$platform"; then
    return 1
  fi
  
  if ! install_binary "$tarball" "$platform"; then
    return 1
  fi
  
  update_path
  
  if ! verify_installation; then
    return 1
  fi
  
  echo ""
  print_success "Installation complete!"
  echo ""
  print_info "Get started:"
  echo "  ansilust --help"
  echo ""
}

# Run main function
main "$@"
