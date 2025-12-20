#!/usr/bin/env bash
# release.sh - Prepare and trigger a release
#
# Usage: ./scripts/release.sh <version>
#
# Examples:
#   ./scripts/release.sh 0.2.1
#   ./scripts/release.sh 1.0.0

set -euo pipefail

VERSION="${1:?Usage: ./scripts/release.sh <version>}"
TAG="v$VERSION"

# Ensure we're in the repo root
cd "$(dirname "$0")/.."

# Check if version already exists on npm
echo "Checking if ansilust@$VERSION exists on npm..."
if npm view "ansilust@$VERSION" --json &>/dev/null; then
  echo "Error: ansilust@$VERSION already exists on npm"
  exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: You have uncommitted changes. Please commit or stash them first."
  exit 1
fi

# Delete existing tag if present (local and remote)
if git tag -l "$TAG" | grep -q "$TAG"; then
  echo "Deleting existing local tag $TAG..."
  git tag -d "$TAG"
fi

if git ls-remote --tags origin | grep -q "refs/tags/$TAG"; then
  echo "Deleting existing remote tag $TAG..."
  git push origin ":refs/tags/$TAG"
fi

# Update version in packages/ansilust/package.json
echo "Updating packages/ansilust/package.json to version $VERSION..."
MAIN_PKG="packages/ansilust/package.json"
sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$MAIN_PKG"

# Update optionalDependencies versions
sed -i "s/\"ansilust-\([^\"]*\)\": \"[^\"]*\"/\"ansilust-\1\": \"$VERSION\"/g" "$MAIN_PKG"

# Commit the version bump
echo "Committing version bump..."
git add "$MAIN_PKG"
git commit -m "chore: release v$VERSION"

# Create and push tag
echo "Creating tag $TAG..."
git tag "$TAG"

echo "Pushing changes and tag..."
git push
git push origin "$TAG"

echo ""
echo "Release $TAG triggered!"
echo "Watch the workflow at: https://github.com/effect-native/ansilust/actions"
