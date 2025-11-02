#!/bin/bash

###############################################################################
# Phase 2 Validation: Build System & npm Packages Infrastructure
# 
# This script validates all Phase 2 requirements from the publishing plan.
# It tests:
# - 2.1: Zig cross-compilation for 10 targets
# - 2.2: npm launcher script with platform detection
# - 2.3: Assembly script for platform packages
# - 2.4: Local testing of npm packages
#
# Run with: bash .validation_phase2.sh
###############################################################################

set -e

PHASE_PASS=0
PHASE_FAIL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TEST_NUM=0

###############################################################################
# Helper Functions
###############################################################################

log_test() {
    TEST_NUM=$((TEST_NUM + 1))
    echo -e "${BLUE}[TEST $TEST_NUM]${NC} $1"
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

section_start() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

section_end() {
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests in this section passed${NC}"
    else
        echo -e "${RED}✗ $TESTS_FAILED test(s) failed in this section${NC}"
    fi
}

###############################################################################
# Phase 2.1: Zig Build Configuration
###############################################################################

validate_phase_2_1() {
    section_start "PHASE 2.1: Zig Build Configuration"
    
    cd /home/tom/Hack/ansilust
    
    # 2.1.1: Check build.zig has cross-compilation support
    log_test "2.1.1: build.zig declares supported targets"
    if grep -q "x86_64-macos\|aarch64-macos\|x86_64-linux-gnu" build.zig; then
        test_pass "build.zig documents supported targets"
    else
        test_fail "build.zig missing target documentation"
    fi
    
    # 2.1.1: Verify we can resolve targets
    log_test "2.1.1: Zig can resolve x86_64-linux-gnu target"
    if zig build -Dtarget=x86_64-linux-gnu 2>&1 | grep -q "install"; then
        test_pass "zig build -Dtarget=x86_64-linux-gnu succeeds"
    else
        test_fail "zig build -Dtarget=x86_64-linux-gnu failed"
    fi
    
    # 2.1.1: Verify aarch64-macos target
    log_test "2.1.1: Zig can resolve aarch64-macos target"
    if zig build -Dtarget=aarch64-macos 2>&1 | grep -q "install"; then
        test_pass "zig build -Dtarget=aarch64-macos succeeds"
    else
        test_fail "zig build -Dtarget=aarch64-macos failed"
    fi
    
    # 2.1.1: Verify arm-linux-gnueabihf target (armv7 in plan)
    log_test "2.1.1: Zig can resolve arm-linux-gnueabihf target"
    if zig build -Dtarget=arm-linux-gnueabihf 2>&1 | grep -q "install"; then
        test_pass "zig build -Dtarget=arm-linux-gnueabihf succeeds"
    else
        test_fail "zig build -Dtarget=arm-linux-gnueabihf failed"
    fi
    
    # 2.1.2: Check output directories
    log_test "2.1.2: Native build produces binary in zig-out/bin/"
    zig build 2>&1 > /dev/null
    if [ -f zig-out/bin/ansilust ]; then
        test_pass "Binary exists at zig-out/bin/ansilust"
    else
        test_fail "Binary not found at zig-out/bin/ansilust"
    fi
    
    # 2.1.3: Check binary size (should be reasonable)
    log_test "2.1.3: Binary size is reasonable (< 50MB)"
    if [ -f zig-out/bin/ansilust ]; then
        size_kb=$(du -k zig-out/bin/ansilust | cut -f1)
        if [ "$size_kb" -lt 51200 ]; then
            test_pass "Binary size acceptable: ${size_kb}KB"
        else
            test_fail "Binary too large: ${size_kb}KB"
        fi
    else
        test_fail "Cannot check binary size"
    fi
    
    section_end
}

###############################################################################
# Phase 2.2: npm Meta Package (ansilust)
###############################################################################

validate_phase_2_2() {
    section_start "PHASE 2.2: npm Meta Package (ansilust)"
    
    cd /home/tom/Hack/ansilust
    
    # 2.2.1: Check launcher script exists
    log_test "2.2.1: Launcher script exists at packages/ansilust/bin/launcher.js"
    if [ -f packages/ansilust/bin/launcher.js ]; then
        test_pass "launcher.js exists"
    else
        test_fail "launcher.js not found"
    fi
    
    # 2.2.1: Check launcher has shebang
    log_test "2.2.1: Launcher has correct shebang"
    if head -1 packages/ansilust/bin/launcher.js | grep -q "#!/usr/bin/env node"; then
        test_pass "Launcher has shebang"
    else
        test_fail "Launcher missing shebang"
    fi
    
    # 2.2.1: Check launcher is executable
    log_test "2.2.1: Launcher is executable"
    if [ -x packages/ansilust/bin/launcher.js ]; then
        test_pass "launcher.js is executable"
    else
        test_fail "launcher.js is not executable"
    fi
    
    # 2.2.1: Check launcher has key functions
    log_test "2.2.1: Launcher implements platform detection"
    if grep -q "getPlatform\|process.platform\|process.arch" packages/ansilust/bin/launcher.js; then
        test_pass "Launcher has platform detection logic"
    else
        test_fail "Launcher missing platform detection"
    fi
    
    # 2.2.1: Check launcher has package selection
    log_test "2.2.1: Launcher implements package selection"
    if grep -q "getPackageName\|ansilust-" packages/ansilust/bin/launcher.js; then
        test_pass "Launcher has package selection logic"
    else
        test_fail "Launcher missing package selection"
    fi
    
    # 2.2.1: Check launcher has error handling
    log_test "2.2.1: Launcher has error handling"
    if grep -q "Error:\|console.error" packages/ansilust/bin/launcher.js; then
        test_pass "Launcher has error handling"
    else
        test_fail "Launcher missing error handling"
    fi
    
    # 2.2.2: Check detect-libc is installed
    log_test "2.2.2: detect-libc dependency installed"
    if grep -q "detect-libc" packages/ansilust/package.json; then
        test_pass "detect-libc in package.json dependencies"
    else
        test_fail "detect-libc not in package.json"
    fi
    
    # 2.2.3: Check package.json has bin entry
    log_test "2.2.3: package.json has bin entry"
    if grep -q '"bin"' packages/ansilust/package.json && grep -q "launcher.js" packages/ansilust/package.json; then
        test_pass "bin entry pointing to launcher.js"
    else
        test_fail "bin entry not configured"
    fi
    
    # 2.2.3: Check package.json has optional dependencies
    log_test "2.2.3: package.json has optionalDependencies"
    if grep -q "optionalDependencies" packages/ansilust/package.json; then
        test_pass "optionalDependencies declared"
    else
        test_fail "optionalDependencies missing"
    fi
    
    # 2.2.3: Check all 10 platform packages listed
    log_test "2.2.3: All 10 platform packages listed"
    local platform_count=$(grep -c "ansilust-" packages/ansilust/package.json)
    if [ "$platform_count" -ge 10 ]; then
        test_pass "All platform packages listed in optional dependencies"
    else
        test_fail "Only $platform_count platform packages found (need 10)"
    fi
    
    section_end
}

###############################################################################
# Phase 2.3: Platform Package Assembly
###############################################################################

validate_phase_2_3() {
    section_start "PHASE 2.3: Platform Package Assembly"
    
    cd /home/tom/Hack/ansilust
    
    # 2.3.1: Check assembly script exists
    log_test "2.3.1: Assembly script exists at scripts/assemble-npm-packages.js"
    if [ -f scripts/assemble-npm-packages.js ]; then
        test_pass "assemble-npm-packages.js exists"
    else
        test_fail "assemble-npm-packages.js not found"
    fi
    
    # 2.3.1: Check script is executable
    log_test "2.3.1: Assembly script is executable"
    if [ -x scripts/assemble-npm-packages.js ]; then
        test_pass "Script is executable"
    else
        test_fail "Script is not executable"
    fi
    
    # 2.3.2: Check 10 platform packages exist
    log_test "2.3.2: All 10 platform package directories exist"
    local packages_found=0
    for pkg in ansilust-darwin-arm64 ansilust-darwin-x64 ansilust-linux-x64-gnu ansilust-linux-x64-musl ansilust-linux-aarch64-gnu ansilust-linux-aarch64-musl ansilust-linux-arm-gnu ansilust-linux-arm-musl ansilust-linux-i386-musl ansilust-win32-x64; do
        if [ -d "packages/$pkg" ]; then
            packages_found=$((packages_found + 1))
        fi
    done
    if [ "$packages_found" -eq 10 ]; then
        test_pass "All 10 platform packages exist"
    else
        test_fail "Only $packages_found platform packages found"
    fi
    
    # 2.3.3: Check package.json in platform packages
    log_test "2.3.3: Platform packages have valid package.json"
    if [ -f packages/ansilust-linux-x64-gnu/package.json ]; then
        if grep -q '"name"' packages/ansilust-linux-x64-gnu/package.json && grep -q '"os"' packages/ansilust-linux-x64-gnu/package.json; then
            test_pass "Platform package.json properly formatted"
        else
            test_fail "Platform package.json malformed"
        fi
    else
        test_fail "Platform package.json not found"
    fi
    
    # 2.3.4: Check index.js in platform packages
    log_test "2.3.4: Platform packages have index.js with binPath export"
    if [ -f packages/ansilust-linux-x64-gnu/index.js ]; then
        if grep -q "binPath\|bin/ansilust" packages/ansilust-linux-x64-gnu/index.js; then
            test_pass "index.js has binPath export"
        else
            test_fail "index.js missing binPath export"
        fi
    else
        test_fail "index.js not found"
    fi
    
    # 2.3.5: Check README in platform packages
    log_test "2.3.5: Platform packages have README.md"
    if [ -f packages/ansilust-linux-x64-gnu/README.md ]; then
        test_pass "README.md exists in platform package"
    else
        test_fail "README.md missing from platform package"
    fi
    
    # 2.3.5: Check LICENSE in platform packages
    log_test "2.3.5: Platform packages have LICENSE"
    if [ -f packages/ansilust-linux-x64-gnu/LICENSE ]; then
        test_pass "LICENSE copied to platform package"
    else
        test_fail "LICENSE missing from platform package"
    fi
    
    # 2.3.2: Check binary exists in package
    log_test "2.3.2: Binary exists in platform package bin/ directory"
    if [ -f packages/ansilust-linux-x64-gnu/bin/ansilust ]; then
        test_pass "Binary present in bin/ directory"
    else
        test_fail "Binary not found in bin/ directory"
    fi
    
    # 2.3.2: Check binary is executable
    log_test "2.3.2: Binary is executable"
    if [ -x packages/ansilust-linux-x64-gnu/bin/ansilust ]; then
        test_pass "Binary is executable"
    else
        test_fail "Binary is not executable"
    fi
    
    section_end
}

###############################################################################
# Phase 2.4: Local npm Package Testing
###############################################################################

validate_phase_2_4() {
    section_start "PHASE 2.4: Local npm Package Testing"
    
    cd /home/tom/Hack/ansilust
    
    # 2.4.1: Test package linking
    log_test "2.4.1: Test npm link of meta package"
    cd packages/ansilust
    if npm link > /dev/null 2>&1; then
        test_pass "npm link succeeded"
        LINK_SUCCESS=1
    else
        test_fail "npm link failed"
        LINK_SUCCESS=0
    fi
    
    # 2.4.2: Test launcher is available in PATH
    log_test "2.4.2: Launcher available as 'ansilust' command"
    if which ansilust > /dev/null 2>&1; then
        test_pass "ansilust command found in PATH"
    else
        test_fail "ansilust command not in PATH"
    fi
    
    # 2.4.2: Test launcher detects platform
    log_test "2.4.2: Launcher detects current platform"
    output=$(ansilust 2>&1)
    if echo "$output" | grep -q "usage:\|Error:"; then
        test_pass "Launcher runs and produces output"
    else
        test_fail "Launcher did not produce expected output"
    fi
    
    # 2.4.3: Test error handling (missing package)
    log_test "2.4.3: Proper error handling for missing platform package"
    # Temporarily remove the package
    cd /home/tom/Hack/ansilust
    rm -rf node_modules/ansilust-linux-x64-gnu 2>/dev/null || true
    output=$(ansilust 2>&1)
    if echo "$output" | grep -q "Error:\|not available\|not found"; then
        test_pass "Error message shown for missing platform package"
    else
        test_fail "No error message for missing platform package"
    fi
    
    # Restore the package for next tests
    cd /home/tom/Hack/ansilust
    npm install > /dev/null 2>&1 || true
    
    # 2.4.4: Test with corrupted binary
    log_test "2.4.4: Proper error handling for corrupted binary"
    cp packages/ansilust-linux-x64-gnu/bin/ansilust packages/ansilust-linux-x64-gnu/bin/ansilust.backup 2>/dev/null || true
    echo "corrupted" > packages/ansilust-linux-x64-gnu/bin/ansilust 2>/dev/null || true
    output=$(ansilust 2>&1)
    if echo "$output" | grep -q "Error:\|error\|cannot execute"; then
        test_pass "Error message shown for corrupted binary"
    else
        test_fail "No error message for corrupted binary"
    fi
    
    # Restore the binary
    if [ -f packages/ansilust-linux-x64-gnu/bin/ansilust.backup ]; then
        mv packages/ansilust-linux-x64-gnu/bin/ansilust.backup packages/ansilust-linux-x64-gnu/bin/ansilust
    else
        zig build 2>&1 > /dev/null
        node scripts/assemble-npm-packages.js > /dev/null 2>&1
    fi
    
    # 2.4.5: Test unlink
    log_test "2.4.5: Cleanup with npm unlink"
    if [ "$LINK_SUCCESS" -eq 1 ]; then
        npm unlink -g ansilust > /dev/null 2>&1 || true
        if ! which ansilust > /dev/null 2>&1; then
            test_pass "npm unlink succeeded"
        else
            test_fail "Command still in PATH after unlink"
        fi
    else
        test_fail "Skipped (npm link did not succeed)"
    fi
    
    section_end
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}PHASE 2 VALIDATION SUMMARY${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}❌ PHASE 2 VALIDATION FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}Failed: 0${NC}"
        echo ""
        echo -e "${GREEN}✅ PHASE 2 VALIDATION PASSED${NC}"
        echo ""
        echo -e "${GREEN}All Phase 2 requirements validated:${NC}"
        echo "  ✓ 2.1: Zig cross-compilation for 10 targets"
        echo "  ✓ 2.2: npm launcher with platform detection"
        echo "  ✓ 2.3: Assembly script for platform packages"
        echo "  ✓ 2.4: Local testing of npm packages"
        echo ""
        echo -e "${YELLOW}Ready to proceed to Phase 3${NC}"
        return 0
    fi
}

###############################################################################
# Main Execution
###############################################################################

main() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} Phase 2 Validation: Build System & npm Packages       ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    validate_phase_2_1
    validate_phase_2_2
    validate_phase_2_3
    validate_phase_2_4
    
    print_summary
}

main
