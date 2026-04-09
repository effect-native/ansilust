#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

function resolveLibcFamily(runtime = {}) {
  if (runtime.platform !== 'linux') {
    return '';
  }

  if (runtime.libcFamily) {
    return runtime.libcFamily === 'musl' ? 'musl' : 'gnu';
  }

  try {
    const detectLibc = require('detect-libc');
    const family = detectLibc.familySync || detectLibc.family;
    const libc = typeof family === 'function' ? family() : family;
    return libc === 'musl' ? 'musl' : 'gnu';
  } catch {
    return 'gnu';
  }
}

function resolvePlatform(runtime = {}) {
  const platform = runtime.platform || process.platform;
  const arch = runtime.arch || process.arch;

  if (platform === 'win32') {
    throw new Error('Windows artifacts are not published in the current release workflow');
  }

  if (!['x64', 'arm64', 'arm'].includes(arch)) {
    throw new Error(`Unsupported architecture: ${arch}`);
  }

  const libcFamily = resolveLibcFamily({ ...runtime, platform });
  return libcFamily ? `${platform}-${arch}-${libcFamily}` : `${platform}-${arch}`;
}

function getPackageName(runtime = {}) {
  return `16c-${resolvePlatform(runtime)}`;
}

function getBinaryPath(runtime = {}) {
  const packageName = getPackageName(runtime);

  try {
    const binPackage = require(packageName);
    return binPackage.binPath;
  } catch {
    const platform = (() => {
      try {
        return resolvePlatform(runtime);
      } catch (platformError) {
        return platformError.message;
      }
    })();

    console.error(`Error: 16c is not available for your platform (${platform})`);
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
    console.error('  npm install --force');
    process.exit(1);
  }
}

function verifyBinary(binaryPath) {
  try {
    const stats = fs.statSync(binaryPath);
    if (!stats.isFile()) {
      throw new Error('Not a file');
    }

    if (process.platform !== 'win32' && !(stats.mode & 0o111)) {
      fs.chmodSync(binaryPath, stats.mode | 0o111);
    }
  } catch {
    console.error(`Error: Binary not found at ${binaryPath}`);
    console.error('');
    console.error('The 16c binary is missing or corrupted.');
    console.error('');
    console.error('To fix this:');
    console.error('  npm install --force');
    console.error('');
    console.error('Or to reinstall the package:');
    console.error('  npm uninstall 16c && npm install 16c@latest');
    process.exit(1);
  }
}

function runBinary(binaryPath, args) {
  try {
    verifyBinary(binaryPath);
    execFileSync(binaryPath, args, {
      stdio: 'inherit',
      encoding: 'utf-8',
    });
    process.exit(0);
  } catch (error) {
    if (error.signal) {
      process.exit(128 + error.signal);
    }

    process.exit(error.status || 1);
  }
}

module.exports = {
  getBinaryPath,
  getPackageName,
  resolveLibcFamily,
  resolvePlatform,
  runBinary,
  verifyBinary,
};

if (require.main === module) {
  runBinary(getBinaryPath(), process.argv.slice(2));
}
