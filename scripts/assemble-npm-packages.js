#!/usr/bin/env node

/**
 * Assemble npm platform packages from Zig binaries
 * 
 * This script:
 * 1. Takes compiled Zig binaries from zig-out/bin/ansilust
 * 2. Creates complete npm package directories for each platform
 * 3. Generates package.json, index.js, and README for each
 * 4. Copies LICENSE from root
 */

const fs = require('fs');
const path = require('path');

// Target mapping: zig-target -> npm-package-name
const TARGETS = {
  'x86_64-macos': 'ansilust-darwin-x64',
  'aarch64-macos': 'ansilust-darwin-arm64',
  'x86_64-linux-gnu': 'ansilust-linux-x64-gnu',
  'x86_64-linux-musl': 'ansilust-linux-x64-musl',
  'aarch64-linux-gnu': 'ansilust-linux-aarch64-gnu',
  'aarch64-linux-musl': 'ansilust-linux-aarch64-musl',
  'arm-linux-gnueabihf': 'ansilust-linux-arm-gnu',
  'arm-linux-musleabihf': 'ansilust-linux-arm-musl',
  'i386-linux-musl': 'ansilust-linux-i386-musl',
  'x86_64-windows': 'ansilust-win32-x64',
};

// Platform metadata for package.json
const PLATFORM_META = {
  'ansilust-darwin-x64': { os: ['darwin'], cpu: ['x64'] },
  'ansilust-darwin-arm64': { os: ['darwin'], cpu: ['arm64'] },
  'ansilust-linux-x64-gnu': { os: ['linux'], cpu: ['x64'], libc: ['glibc'] },
  'ansilust-linux-x64-musl': { os: ['linux'], cpu: ['x64'], libc: ['musl'] },
  'ansilust-linux-aarch64-gnu': { os: ['linux'], cpu: ['arm64'], libc: ['glibc'] },
  'ansilust-linux-aarch64-musl': { os: ['linux'], cpu: ['arm64'], libc: ['musl'] },
  'ansilust-linux-arm-gnu': { os: ['linux'], cpu: ['arm'], libc: ['glibc'] },
  'ansilust-linux-arm-musl': { os: ['linux'], cpu: ['arm'], libc: ['musl'] },
  'ansilust-linux-i386-musl': { os: ['linux'], cpu: ['ia32'], libc: ['musl'] },
  'ansilust-win32-x64': { os: ['win32'], cpu: ['x64'] },
};

// Helper: Ensure directory exists
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// Helper: Copy file
function copyFile(src, dest) {
  fs.copyFileSync(src, dest);
}

// Generate package.json for platform package
function generatePackageJson(packageName, version) {
  const meta = PLATFORM_META[packageName];
  const pkg = {
    name: packageName,
    version: version,
    description: `ansilust binaries for ${packageName.replace('ansilust-', '')}`,
    main: 'index.js',
    files: ['bin/', 'index.js', 'README.md', 'LICENSE'],
    repository: {
      type: 'git',
      url: 'https://github.com/effect-native/ansilust.git',
    },
    keywords: ['ansi', 'art', 'text-art', 'ascii', 'bbs', 'ansilove', 'ansilust'],
    author: 'Tom Aylott <oblivious@subtlegradient.com>',
    license: 'MIT',
  };

  // Add os and cpu restrictions
  if (meta.os) pkg.os = meta.os;
  if (meta.cpu) pkg.cpu = meta.cpu;

  return pkg;
}

// Generate index.js for platform package
function generateIndexJs() {
  return 'const path = require(\'path\');\n' +
    '\n' +
    'const binName = process.platform === \'win32\' ? \'ansilust.exe\' : \'ansilust\';\n' +
    'const binPath = path.join(__dirname, \'bin\', binName);\n' +
    '\n' +
    'module.exports = {\n' +
    '  binPath: binPath,\n' +
    '};\n';
}

// Generate README for platform package
function generateReadme(packageName) {
  const platform = packageName.replace('ansilust-', '');
  return '# ' + packageName + '\n' +
    '\n' +
    'Platform-specific binary for ansilust.\n' +
    '\n' +
    'This package contains the native ansilust binary for ' + platform + '.\n' +
    '\n' +
    'This is a private package meant to be used as an optional dependency of the main `ansilust` package.\n' +
    '\n' +
    '## Usage\n' +
    '\n' +
    '```javascript\n' +
    'const ansilust = require(\'' + packageName + '\');\n' +
    'console.log(ansilust.binPath);\n' +
    '```\n' +
    '\n' +
    'See the main ansilust package for CLI usage.\n' +
    '\n' +
    '## License\n' +
    '\n' +
    'MIT\n';
}

// Main assembly function
function assemble() {
  const rootDir = path.join(__dirname, '..');
  const zigOutDir = path.join(rootDir, 'zig-out', 'bin');
  const packagesDir = path.join(rootDir, 'packages');
  const licenseFile = path.join(rootDir, 'LICENSE');

  // Get version from root package.json
  let version = '0.0.1';
  try {
    const rootPkg = JSON.parse(fs.readFileSync(path.join(rootDir, 'package.json'), 'utf-8'));
    version = rootPkg.version || version;
  } catch (e) {
    console.warn('Warning: Could not read root package.json, using version 0.0.1');
  }

  console.log(`📦 Assembling ansilust npm packages (v${version})`);
  console.log('');

  let successCount = 0;
  let failureCount = 0;

  for (const [zigTarget, packageName] of Object.entries(TARGETS)) {
    const binaryPath = path.join(zigOutDir, 'ansilust');
    const packageDir = path.join(packagesDir, packageName);
    const binDir = path.join(packageDir, 'bin');

    try {
      // Check if binary exists
      if (!fs.existsSync(binaryPath)) {
        // For cross-compilation targets, the binary might not exist if not built
        console.log(`⏭️  Skipping ${packageName} (binary not found for ${zigTarget})`);
        continue;
      }

      // Create package directory structure
      ensureDir(binDir);

      // Copy binary
      const destBinary = path.join(binDir, 'ansilust');
      copyFile(binaryPath, destBinary);
      // Make executable on Unix-like systems
      if (process.platform !== 'win32') {
        fs.chmodSync(destBinary, 0o755);
      }

      // Generate package.json
      const packageJson = generatePackageJson(packageName, version);
      fs.writeFileSync(
        path.join(packageDir, 'package.json'),
        JSON.stringify(packageJson, null, 2) + '\n'
      );

      // Generate index.js
      const indexJs = generateIndexJs();
      fs.writeFileSync(path.join(packageDir, 'index.js'), indexJs);

      // Generate README
      const readme = generateReadme(packageName);
      fs.writeFileSync(path.join(packageDir, 'README.md'), readme);

      // Copy LICENSE
      if (fs.existsSync(licenseFile)) {
        copyFile(licenseFile, path.join(packageDir, 'LICENSE'));
      }

      console.log(`✓ ${packageName}`);
      successCount++;
    } catch (e) {
      console.error(`✗ ${packageName}: ${e.message}`);
      failureCount++;
    }
  }

  console.log('');
  console.log(`Complete: ${successCount} packages assembled`);
  if (failureCount > 0) {
    console.log(`Failed: ${failureCount} packages`);
    process.exit(1);
  }
}

// Run assembly
assemble();
