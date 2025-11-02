#!/bin/bash
set -e

# Change to the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Publishing npm placeholder packages..."
echo ""

# Check if logged in
echo "Checking npm login status..."
if ! npm whoami > /dev/null 2>&1; then
  echo "❌ Not logged in to npm. Please run: npm login"
  exit 1
fi

echo "✅ Logged in as: $(npm whoami)"
echo ""

# Publish ansilust
echo "📦 Publishing ansilust..."
cd ansilust
npm publish
cd ..
echo "✅ ansilust published"
echo ""

# Publish 16colors
echo "📦 Publishing 16colors..."
cd 16colors
npm publish
cd ..
echo "✅ 16colors published"
echo ""

# Publish 16c
echo "📦 Publishing 16c..."
cd 16c
npm publish
cd ..
echo "✅ 16c published"
echo ""

echo "🎉 All packages published successfully!"
echo ""
echo "Verify at:"
echo "  - https://www.npmjs.com/package/ansilust"
echo "  - https://www.npmjs.com/package/16colors"
echo "  - https://www.npmjs.com/package/16c"
