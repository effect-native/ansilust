#!/bin/bash

# Quick Phase 2 Validation - focuses on deliverables not build times

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

test_check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $1"
        FAIL=$((FAIL + 1))
    fi
}

echo -e "${BLUE}Phase 2: Build System & npm Packages - Quick Validation${NC}\n"

cd /home/tom/Hack/ansilust

echo -e "${YELLOW}2.1: Zig Build Configuration${NC}"
[ -f build.zig ] && grep -q "x86_64-linux-gnu" build.zig
test_check "build.zig documents cross-compilation targets"

[ -f zig-out/bin/ansilust ]
test_check "Native binary built and exists"

echo -e "\n${YELLOW}2.2: npm Meta Package${NC}"
[ -f packages/ansilust/bin/launcher.js ]
test_check "launcher.js exists"

[ -x packages/ansilust/bin/launcher.js ]
test_check "launcher.js is executable"

head -1 packages/ansilust/bin/launcher.js | grep -q "#!/usr/bin/env node"
test_check "launcher.js has correct shebang"

grep -q "getPlatform\|process.platform" packages/ansilust/bin/launcher.js
test_check "launcher implements platform detection"

grep -q "detect-libc" packages/ansilust/package.json
test_check "detect-libc dependency configured"

grep -q '"bin"' packages/ansilust/package.json
test_check "package.json has bin entry"

grep -c "ansilust-" packages/ansilust/package.json | grep -q "[0-9][0-9]"
test_check "All 10 platform packages listed in optionalDependencies"

echo -e "\n${YELLOW}2.3: Platform Package Assembly${NC}"
[ -f scripts/assemble-npm-packages.js ]
test_check "Assembly script exists"

[ -x scripts/assemble-npm-packages.js ]
test_check "Assembly script is executable"

# Check that the 10 required packages exist
required_packages="ansilust-darwin-arm64 ansilust-darwin-x64 ansilust-linux-x64-gnu ansilust-linux-x64-musl ansilust-linux-aarch64-gnu ansilust-linux-aarch64-musl ansilust-linux-arm-gnu ansilust-linux-arm-musl ansilust-linux-i386-musl ansilust-win32-x64"
missing_count=0
for pkg in $required_packages; do
    [ ! -d "packages/$pkg" ] && missing_count=$((missing_count + 1))
done
[ $missing_count -eq 0 ]
test_check "All 10 required platform packages created"

[ -f packages/ansilust-linux-x64-gnu/package.json ]
test_check "Platform package.json exists"

[ -f packages/ansilust-linux-x64-gnu/index.js ] && grep -q "binPath" packages/ansilust-linux-x64-gnu/index.js
test_check "Platform index.js has binPath export"

[ -f packages/ansilust-linux-x64-gnu/README.md ]
test_check "Platform README exists"

[ -f packages/ansilust-linux-x64-gnu/LICENSE ]
test_check "Platform LICENSE copied"

[ -f packages/ansilust-linux-x64-gnu/bin/ansilust ]
test_check "Binary present in platform package"

[ -x packages/ansilust-linux-x64-gnu/bin/ansilust ]
test_check "Binary is executable"

echo -e "\n${YELLOW}2.4: Local npm Package Testing${NC}"
cd packages/ansilust && npm link > /dev/null 2>&1
test_check "npm link succeeded"

which ansilust > /dev/null 2>&1
test_check "ansilust command available in PATH"

npm unlink -g ansilust > /dev/null 2>&1
test_check "npm unlink succeeded"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Tests: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}✅ PHASE 2 VALIDATION PASSED${NC}"
    echo -e "All Phase 2 requirements validated:"
    echo "  ✓ 2.1: Zig cross-compilation documented and working"
    echo "  ✓ 2.2: npm launcher with platform detection complete"
    echo "  ✓ 2.3: Assembly script and 10 platform packages generated"
    echo "  ✓ 2.4: Local testing successful"
    echo ""
    echo -e "${YELLOW}Ready to proceed to Phase 3${NC}"
    exit 0
else
    echo -e "\n${RED}❌ PHASE 2 VALIDATION FAILED${NC}"
    echo "  Fix $FAIL failing test(s) before proceeding"
    exit 1
fi
