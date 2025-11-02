#!/bin/bash

echo "=== PHASE 1 VALIDATION ==="
echo ""

FAILED=0

echo "1.2.4 CHECK: Initial changeset created?"
CHANGESETS=$(ls .changeset/*.md 2>/dev/null | grep -v README.md | wc -l)
if [ "$CHANGESETS" -gt 0 ]; then
  echo "  ✓ Has $CHANGESETS changeset file(s)"
else
  echo "  ✗ ISSUE: No initial changeset created yet (Plan requires this)"
  FAILED=1
fi

echo ""
echo "1.3.1 CHECK: GitHub Actions secrets configured"
echo "  ⚠ Cannot verify without GitHub access"
echo "    Required per plan: NPM_TOKEN secret"

echo ""
echo "1.3.2 CHECK: AUR repository setup"
if test -d ../aur-ansilust; then
  echo "  ✓ Found ../aur-ansilust"
else
  echo "  ✗ ISSUE: AUR repo not cloned (plan requires this)"
  FAILED=1
fi

echo ""
echo "Checking plan requirements in detail:"
echo ""
echo "From section 1.2.4 (line 122-125):"
grep -A 3 "1.2.4" .specs/publish/plan.md | head -4

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✅ Core structure complete, but some tasks still pending"
  exit 0
else
  echo "❌ There are incomplete requirements"
  exit 1
fi
