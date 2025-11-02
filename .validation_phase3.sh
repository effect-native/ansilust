#!/bin/bash
# Comprehensive Phase 3 validation suite
# Tests: Install scripts, checksum generation, GitHub Actions workflows

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_check() { echo -e "${GREEN}✓${NC} $*"; }
print_error() { echo -e "${RED}✗${NC} $*" >&2; }
print_info() { echo -e "${YELLOW}ℹ${NC} $*"; }
print_header() { echo -e "\n${YELLOW}━━━${NC} $* ${YELLOW}━━━${NC}"; }

passed=0
failed=0

test_item() {
  local name="$1"
  local cmd="$2"
  
  if eval "$cmd" &>/dev/null; then
    print_check "$name"
    ((passed++))
  else
    print_error "$name"
    ((failed++))
  fi
}

print_header "Phase 3 Validation Suite"
echo "Tests for install scripts, checksums, and GitHub Actions workflows"

print_header "Bash Installer Tests"
test_item "install.sh syntax valid" "bash -n scripts/install.sh"
test_item "install.sh is executable" "test -x scripts/install.sh"
test_item "install.sh has header" "grep -q 'ansilust installer script' scripts/install.sh"
test_item "install.sh has service URL" "grep -q 'ansilust.com/install' scripts/install.sh"
test_item "install.sh has GitHub link" "grep -qi 'github' scripts/install.sh"
test_item "install.sh has detect_platform" "grep -q '^detect_platform()' scripts/install.sh"
test_item "install.sh has download_binary" "grep -q '^download_binary()' scripts/install.sh"
test_item "install.sh has verify_checksum" "grep -q '^verify_checksum()' scripts/install.sh"
test_item "install.sh has install_binary" "grep -q '^install_binary()' scripts/install.sh"

print_header "PowerShell Installer Tests"
test_item "install.ps1 exists" "test -f scripts/install.ps1"
test_item "install.ps1 has PowerShell structure" "grep -q 'param(\|function\|Write-' scripts/install.ps1"
test_item "install.ps1 has header" "grep -q 'ansilust installer script' scripts/install.ps1"
test_item "install.ps1 has Detect-Platform" "grep -q 'function Detect-Platform' scripts/install.ps1"
test_item "install.ps1 has Download-Binary" "grep -q 'function Download-Binary' scripts/install.ps1"
test_item "install.ps1 has Verify-Checksum" "grep -q 'function Verify-Checksum' scripts/install.ps1"
test_item "install.ps1 has Install-Binary" "grep -q 'function Install-Binary' scripts/install.ps1"

print_header "Checksum Script Tests"
test_item "generate-checksums.sh syntax valid" "bash -n scripts/generate-checksums.sh"
test_item "generate-checksums.sh is executable" "test -x scripts/generate-checksums.sh"
test_item "generate-checksums.sh has header" "grep -q 'SHA256 checksums' scripts/generate-checksums.sh"
test_item "generate-checksums.sh uses sha256sum" "grep -q 'sha256sum' scripts/generate-checksums.sh"
test_item "generate-checksums.sh sorts output" "grep -q 'sort' scripts/generate-checksums.sh"

print_header "GitHub Actions Workflow Tests"
test_item "release.yml exists" "test -f .github/workflows/release.yml"
test_item "release.yml has name" "grep -q 'name: Release' .github/workflows/release.yml"
test_item "release.yml has trigger" "grep -q 'on:' .github/workflows/release.yml"
test_item "release.yml has jobs" "grep -q 'jobs:' .github/workflows/release.yml"
test_item "release.yml has build job" "grep -q '^  build:' .github/workflows/release.yml"
test_item "release.yml has assemble-npm job" "grep -q '^  assemble-npm:' .github/workflows/release.yml"
test_item "release.yml has publish-npm job" "grep -q '^  publish-npm:' .github/workflows/release.yml"
test_item "release.yml has create-release job" "grep -q '^  create-release:' .github/workflows/release.yml"
test_item "release.yml has multi-target matrix" "grep -q 'x86_64-linux-gnu\|aarch64-linux-gnu\|x86_64-windows' .github/workflows/release.yml"

print_header "Changeset Version Workflow Tests"
test_item "changeset-version.yml exists" "test -f .github/workflows/changeset-version.yml"
test_item "changeset-version.yml has name" "grep -q 'name: Changeset Version' .github/workflows/changeset-version.yml"
test_item "changeset-version.yml has trigger" "grep -q 'on:' .github/workflows/changeset-version.yml"
test_item "changeset-version.yml uses changesets" "grep -q 'changesets/action' .github/workflows/changeset-version.yml"

print_header "Summary"
total=$((passed + failed))
echo "Tests passed: $passed / $total"

if [ $failed -eq 0 ]; then
  print_check "All Phase 3 validation tests passed!"
  exit 0
else
  print_error "Some tests failed!"
  exit 1
fi
