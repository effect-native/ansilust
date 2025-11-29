# Manual Steps Required Before First Release

## 1. Add NPM_TOKEN Secret to GitHub

### Option A: Via GitHub Web UI
1. Go to https://github.com/effect-native/ansilust/settings/secrets/actions
2. Click "New repository secret"
3. Name: `NPM_TOKEN`
4. Value: Your npm access token (get from https://www.npmjs.com/settings/~/tokens)
5. Click "Add secret"

### Option B: Via gh CLI
```bash
# First, get an npm token from https://www.npmjs.com/settings/~/tokens
# Choose "Automation" token type for CI/CD
gh secret set NPM_TOKEN -R effect-native/ansilust
# Paste your token when prompted
```

## 2. (Optional) Add AUR_SSH_KEY Secret

This is only needed if you want automatic AUR package updates.
Can be deferred until after v1.0.0.

```bash
# Generate SSH key for AUR
ssh-keygen -t ed25519 -C "ansilust@github-actions" -f ~/.ssh/aur_ansilust
# Add public key to AUR account settings
# Then add private key as secret:
gh secret set AUR_SSH_KEY -R effect-native/ansilust < ~/.ssh/aur_ansilust
```

## 3. Push Feature Branch and Test Workflow

```bash
cd /home/tom/Work/ansilust
git push -u origin feat/publish-v1
```

Then check GitHub Actions to see if the workflow syntax is valid.

## 4. Create Test Release (Optional Dry Run)

```bash
git tag v0.0.2-test.1
git push origin v0.0.2-test.1
# Watch GitHub Actions
# Delete tag after testing:
git push origin :refs/tags/v0.0.2-test.1
git tag -d v0.0.2-test.1
```

## 5. Create Real v1.0.0 Release

```bash
# Create changeset
npx changeset add
# Select major, describe: "Initial public release"

# Commit and push
git add .changeset/*.md
git commit -m "chore: add changeset for v1.0.0"
git push

# Wait for Changesets bot to create version PR
# Merge the version PR
# Release workflow will run automatically
```

## Verification After Release

```bash
# Test npm
npx ansilust@1.0.0 --help

# Test GitHub release
curl -fsSL https://github.com/effect-native/ansilust/releases/latest/download/SHA256SUMS

# Test install script (once website is deployed)
curl -fsSL https://ansilust.com/install | bash
```
