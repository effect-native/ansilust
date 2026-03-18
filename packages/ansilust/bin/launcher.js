#!/usr/bin/env node

/**
 * ansilust launcher
 * 
 * This script detects the current platform and loads the appropriate
 * native binary from the platform-specific package.
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

/**
 * Get the platform identifier
 * Returns a platform string like "linux-x64-gnu" or "darwin-arm64"
 */
function getPlatform() {
  const platform = process.platform;
  const arch = process.arch;

  if (platform === 'win32') {
    throw new Error('Windows artifacts are not published in the current release workflow');
  }
  
  let libcType = '';
  
  // Determine libc type for Linux
  if (platform === 'linux') {
    try {
      // Try to use detect-libc if available
      const detectLibc = require('detect-libc');
      const family = detectLibc.familySync || detectLibc.family;
      const libc = typeof family === 'function' ? family() : family;
      libcType = libc === 'musl' ? 'musl' : 'gnu';
    } catch (e) {
      // Fall back to glibc by default
      libcType = 'gnu';
    }
  }
  
  // Map Node.js arch names to npm package arch names
  // Package names match the release workflow platform IDs.
  let pkgArch = arch;
  if (arch === 'x64') pkgArch = 'x64';
  else if (arch === 'arm64') pkgArch = 'arm64';
  else if (arch === 'arm') pkgArch = 'arm';
  else throw new Error(`Unsupported architecture: ${arch}`);
  
  // Build package name
  // Format: {os}-{arch}[-{libc}]
  // Examples: darwin-arm64, linux-x64-gnu, linux-arm64-musl
  if (libcType) {
    return `${platform}-${pkgArch}-${libcType}`;
  } else {
    return `${platform}-${pkgArch}`;
  }
}

/**
 * Get the package name for the current platform
 */
function getPackageName() {
  const platformId = getPlatform();
  return `ansilust-${platformId}`;
}

/**
 * Find the binary path
 */
function getBinaryPath() {
  const packageName = getPackageName();
  
  try {
    // Try to require the platform-specific package
    const binPackage = require(packageName);
    return binPackage.binPath;
  } catch (e) {
    // Package not found
    const platform = (() => {
      try {
        return getPlatform();
      } catch (platformError) {
        return platformError.message;
      }
    })();
    console.error(`Error: ansilust is not available for your platform (${platform})`);
    console.error('');
    console.error(`The package "${packageName}" was not found.`);
    console.error('');
    console.error('Supported platforms:');
    console.error('  - darwin-arm64 (Apple Silicon)');
    console.error('  - darwin-x64 (Intel Mac)');
    console.error('  - linux-x64-gnu (Linux glibc)');
    console.error('  - linux-x64-musl (Linux musl)');
    console.error('  - linux-arm64-gnu (ARM64 Linux glibc)');
    console.error('  - linux-arm64-musl (ARM64 Linux musl)');
    console.error('  - linux-arm-gnu (ARMv7 glibc)');
    console.error('  - linux-arm-musl (ARMv7 musl)');
    console.error('');
    console.error('To reinstall with your platform binary:');
    console.error(`  npm install --force`);
    process.exit(1);
  }
}

/**
 * Check if binary exists and is executable
 */
function verifyBinary(binaryPath) {
  try {
    const stats = fs.statSync(binaryPath);
    if (!stats.isFile()) {
      throw new Error('Not a file');
    }
    // Check if executable (on Unix-like systems)
    if (process.platform !== 'win32' && !(stats.mode & 0o111)) {
      // Try to make it executable
      fs.chmodSync(binaryPath, stats.mode | 0o111);
    }
    return true;
  } catch (e) {
    const packageName = getPackageName();
    console.error(`Error: Binary not found at ${binaryPath}`);
    console.error('');
    console.error('The ansilust binary is missing or corrupted.');
    console.error('');
    console.error('To fix this:');
    console.error(`  npm install --force`);
    console.error('');
    console.error('Or to reinstall the package:');
    console.error(`  npm uninstall ansilust && npm install ansilust@latest`);
    process.exit(1);
  }
}

/**
 * Run the binary with arguments
 */
function runBinary(binaryPath, args) {
  try {
    // Make sure binary is executable
    verifyBinary(binaryPath);
    
    // Execute the binary with all arguments
    const result = execFileSync(binaryPath, args, {
      stdio: 'inherit',
      encoding: 'utf-8',
    });
    
    process.exit(0);
  } catch (e) {
    if (e.signal) {
      // Killed by signal
      process.exit(128 + e.signal);
    }
    process.exit(e.status || 1);
  }
}

// Main entry point
const binaryPath = getBinaryPath();
const args = process.argv.slice(2);
runBinary(binaryPath, args);
