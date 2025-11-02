# NPM Package Publishing Guide

## Quick Commands to Publish All Placeholders

### 1. Check Name Availability (30 seconds)

```bash
npm view ansilust
npm view 16colors
npm view 16c
```

**Expected**: "npm ERR! 404 Not Found" (means available)

### 2. Publish All Packages (~5 minutes)

```bash
# Publish ansilust
cd packages/ansilust && npm publish && cd ../..

# Publish 16colors
cd packages/16colors && npm publish && cd ../..

# Publish 16c
cd packages/16c && npm publish && cd ../..
```

### 3. Verify Publications (1 minute)

```bash
npm view ansilust
npm view 16colors
npm view 16c
```

**Expected**: Should show version 0.0.1

## Troubleshooting

### If not logged in:
```bash
npm whoami  # Check if logged in
npm login   # Login if needed
```

### If 2FA is enabled:
- Have authenticator app ready
- npm will prompt for OTP during `npm publish`

### If name is already taken:
1. Check `npm view <package>` to see who owns it
2. Look for "Repository" field - might be abandoned
3. Check last publish date - if >2 years, can request via npm support
4. Consider alternative names if needed

## Package URLs

Once published, packages will be available at:
- https://www.npmjs.com/package/ansilust
- https://www.npmjs.com/package/16colors
- https://www.npmjs.com/package/16c

## Next Steps

After securing the names:
1. Update this file with actual publication results
2. Set calendar reminder to publish real packages
3. Plan migration from placeholder to real package

---

**Author**: Tom Aylott <oblivious@subtlegradient.com>  
**Repository**: https://github.com/subtleGradient/ansilust
