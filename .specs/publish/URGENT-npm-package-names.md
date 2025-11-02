# 🚨 URGENT: Reserve npm Package Names

**Priority**: CRITICAL  
**Estimated Time**: 15 minutes  
**Assignee**: [ASSIGN TO AVAILABLE PERSON]  
**Deadline**: ASAP (before names are taken)

---

## Objective

Immediately reserve the following npm package names by publishing placeholder packages:
- `ansilust`
- `16colors`
- `16c`

---

## Prerequisites

- npm account with publishing permissions
- Access to terminal/command line
- Node.js/npm installed

---

## Step-by-Step Instructions

### 1. Check Name Availability (30 seconds)

```bash
npm view ansilust
npm view 16colors
npm view 16c
```

**Expected**: "npm ERR! 404 Not Found" (means available)  
**If taken**: Document who owns it and when it was published

---

### 2. Create Placeholder Package for `ansilust` (2 minutes)

```bash
mkdir -p /tmp/ansilust-placeholder
cd /tmp/ansilust-placeholder

cat > package.json << 'EOF'
{
  "name": "ansilust",
  "version": "0.0.1",
  "description": "ANSI art rendering engine (placeholder - real package coming soon)",
  "main": "index.js",
  "repository": {
    "type": "git",
    "url": "https://github.com/OWNER/ansilust.git"
  },
  "keywords": ["ansi", "art", "text-art", "ascii", "bbs", "ansilove"],
  "author": "AUTHOR_NAME",
  "license": "MIT"
}
EOF

cat > index.js << 'EOF'
console.log("ansilust placeholder - real package coming soon!");
console.log("See: https://github.com/OWNER/ansilust");
EOF

cat > README.md << 'EOF'
# ansilust

⚠️ **This is a placeholder package.** The real ansilust package is under development.

## About

ansilust is a next-generation ANSI art rendering engine inspired by [ansilove](https://github.com/ansilove/ansilove).

**Status**: Coming soon

**Repository**: https://github.com/OWNER/ansilust

**Website**: https://ansilust.com

---

*Package reserved to prevent squatting. Real package will be published soon.*
EOF

npm publish
```

---

### 3. Create Placeholder Package for `16colors` (2 minutes)

```bash
mkdir -p /tmp/16colors-placeholder
cd /tmp/16colors-placeholder

cat > package.json << 'EOF'
{
  "name": "16colors",
  "version": "0.0.1",
  "description": "16colo.rs ANSI art archive utilities (placeholder - real package coming soon)",
  "main": "index.js",
  "repository": {
    "type": "git",
    "url": "https://github.com/OWNER/ansilust.git"
  },
  "keywords": ["16colors", "16colo.rs", "ansi", "art", "bbs", "archive"],
  "author": "AUTHOR_NAME",
  "license": "MIT"
}
EOF

cat > index.js << 'EOF'
console.log("16colors placeholder - real package coming soon!");
console.log("See: https://16colo.rs");
EOF

cat > README.md << 'EOF'
# 16colors

⚠️ **This is a placeholder package.** The real 16colors package is under development.

## About

Utilities for working with the [16colo.rs](https://16colo.rs) ANSI art archive.

**Status**: Coming soon

**Related Projects**:
- [ansilust](https://github.com/OWNER/ansilust) - ANSI art rendering engine
- [16colo.rs](https://16colo.rs) - ANSI art archive

---

*Package reserved to prevent squatting. Real package will be published soon.*
EOF

npm publish
```

---

### 4. Create Placeholder Package for `16c` (2 minutes)

```bash
mkdir -p /tmp/16c-placeholder
cd /tmp/16c-placeholder

cat > package.json << 'EOF'
{
  "name": "16c",
  "version": "0.0.1",
  "description": "16colo.rs CLI shorthand (placeholder - real package coming soon)",
  "main": "index.js",
  "repository": {
    "type": "git",
    "url": "https://github.com/OWNER/ansilust.git"
  },
  "keywords": ["16colors", "16c", "ansi", "cli"],
  "author": "AUTHOR_NAME",
  "license": "MIT"
}
EOF

cat > index.js << 'EOF'
console.log("16c placeholder - real package coming soon!");
console.log("See: https://16colo.rs");
EOF

cat > README.md << 'EOF'
# 16c

⚠️ **This is a placeholder package.** The real 16c package is under development.

## About

Shorthand CLI for 16colo.rs ANSI art archive.

**Status**: Coming soon

**Related Projects**:
- [16colors](https://www.npmjs.com/package/16colors) - 16colo.rs utilities
- [ansilust](https://www.npmjs.com/package/ansilust) - ANSI art rendering engine

---

*Package reserved to prevent squatting. Real package will be published soon.*
EOF

npm publish
```

---

### 5. Verify Publications (1 minute)

```bash
npm view ansilust
npm view 16colors
npm view 16c
```

**Expected**: Should show version 0.0.1 with your author name

---

### 6. Document Results (2 minutes)

Create a file with the results:

```bash
cat > /tmp/npm-package-reservation-results.txt << 'EOF'
NPM Package Name Reservation Results
=====================================

Date: $(date)

Packages Reserved:
- ansilust: [SUCCESS/FAILED - reason]
- 16colors: [SUCCESS/FAILED - reason]
- 16c: [SUCCESS/FAILED - reason]

Package URLs:
- https://www.npmjs.com/package/ansilust
- https://www.npmjs.com/package/16colors
- https://www.npmjs.com/package/16c

Notes:
[Any issues or observations]

Next Steps:
- Update .specs/publish with actual npm package owner
- Plan migration from placeholder to real package
EOF
```

---

## Troubleshooting

### If name is already taken:
1. Check `npm view <package>` to see who owns it
2. Look for "Repository" field - might be abandoned
3. Check last publish date - if >2 years, can request via npm support
4. Consider alternative names: `ansilust-cli`, `ansilust-core`, etc.

### If publish fails:
1. Ensure logged in: `npm whoami`
2. Login if needed: `npm login`
3. Check package name doesn't violate npm policies
4. Try with different package name variation

### If 2FA is enabled:
- Have authenticator app ready
- npm will prompt for OTP during `npm publish`

---

## Success Criteria

- [ ] All 3 package names published successfully
- [ ] Package URLs accessible on npmjs.com
- [ ] Placeholder README visible on npm
- [ ] Results documented
- [ ] Team notified

---

## Post-Task Actions

1. **Notify team** that names are secured
2. **Update `.specs/publish/instructions.md`** with actual npm account details
3. **Add to project notes** which npm account owns the packages
4. **Set calendar reminder** to publish real packages (placeholders expire if unused)

---

## Time Estimates

- Name availability check: 30 sec
- Package 1 (ansilust): 2 min
- Package 2 (16colors): 2 min  
- Package 3 (16c): 2 min
- Verification: 1 min
- Documentation: 2 min

**Total**: ~10 minutes (plus potential 2FA delays)

---

## Critical Notes

⚠️ **Do NOT wait** - these are good package names and could be taken at any moment  
⚠️ **Use MIT license** for maximum flexibility  
⚠️ **Point to real repository** in package.json for credibility  
⚠️ **Keep credentials secure** - do not commit npm tokens  

---

## Contact

If blocked or issues arise:
- Escalate immediately
- Do NOT abandon task
- Document blocker and reassign if needed
