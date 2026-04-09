#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const TARGETS = {
  'x86_64-macos': 'darwin-x64',
  'aarch64-macos': 'darwin-arm64',
  'x86_64-linux-gnu': 'linux-x64-gnu',
  'x86_64-linux-musl': 'linux-x64-musl',
  'aarch64-linux-gnu': 'linux-arm64-gnu',
  'aarch64-linux-musl': 'linux-arm64-musl',
  'arm-linux-gnueabihf': 'linux-arm-gnu',
  'arm-linux-musleabihf': 'linux-arm-musl',
};

const PLATFORM_META = {
  'darwin-x64': { os: ['darwin'], cpu: ['x64'] },
  'darwin-arm64': { os: ['darwin'], cpu: ['arm64'] },
  'linux-x64-gnu': { os: ['linux'], cpu: ['x64'], libc: ['glibc'] },
  'linux-x64-musl': { os: ['linux'], cpu: ['x64'], libc: ['musl'] },
  'linux-arm64-gnu': { os: ['linux'], cpu: ['arm64'], libc: ['glibc'] },
  'linux-arm64-musl': { os: ['linux'], cpu: ['arm64'], libc: ['musl'] },
  'linux-arm-gnu': { os: ['linux'], cpu: ['arm'], libc: ['glibc'] },
  'linux-arm-musl': { os: ['linux'], cpu: ['arm'], libc: ['musl'] },
};

const PACKAGE_FAMILIES = {
  ansilust: {
    metaPackageName: 'ansilust',
    metaPackageDir: 'ansilust',
    binaryName: 'ansilust',
    description: 'Next-generation text art processing system - convert, render, and animate ANSI art',
  },
  '16c': {
    metaPackageName: '16c',
    metaPackageDir: '16c',
    binaryName: '16c',
    description: 'Native launcher package for the 16c CLI',
  },
};

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function copyFile(src, dest) {
  fs.copyFileSync(src, dest);
}

function getBinaryFilename(binaryName, platformId) {
  return platformId.startsWith('win32-') ? `${binaryName}.exe` : binaryName;
}

function getPlatformPackageName(familyName, platformId) {
  return `${familyName}-${platformId}`;
}

function generatePackageJson(familyName, platformId, version) {
  const meta = PLATFORM_META[platformId];
  const packageName = getPlatformPackageName(familyName, platformId);
  const family = PACKAGE_FAMILIES[familyName];

  const pkg = {
    name: packageName,
    version,
    description: `${family.metaPackageName} binaries for ${platformId}`,
    main: 'index.js',
    files: ['bin/', 'index.js', 'README.md', 'LICENSE'],
    repository: {
      type: 'git',
      url: 'https://github.com/effect-native/ansilust.git',
    },
    keywords: ['ansi', 'art', 'text-art', 'ascii', 'bbs', 'ansilove', family.metaPackageName],
    author: 'Tom Aylott <oblivious@subtlegradient.com>',
    license: 'MIT',
  };

  if (meta.os) pkg.os = meta.os;
  if (meta.cpu) pkg.cpu = meta.cpu;
  if (meta.libc) pkg.libc = meta.libc;

  return pkg;
}

function generateIndexJs(binaryName) {
  return 'const path = require(\'path\');\n' +
    '\n' +
    `const binName = process.platform === 'win32' ? '${binaryName}.exe' : '${binaryName}';\n` +
    'const binPath = path.join(__dirname, \'bin\', binName);\n' +
    '\n' +
    'module.exports = {\n' +
    '  binPath: binPath,\n' +
    '};\n';
}

function generateReadme(familyName, platformId) {
  const packageName = getPlatformPackageName(familyName, platformId);
  return '# ' + packageName + '\n' +
    '\n' +
    `Platform-specific binary for ${familyName}.\n` +
    '\n' +
    `This package contains the native ${familyName} binary for ${platformId}.\n` +
    '\n' +
    `This package is meant to be used as an optional dependency of the main \`${familyName}\` package.\n` +
    '\n' +
    '## Usage\n' +
    '\n' +
    '```javascript\n' +
    `const cli = require('${packageName}');\n` +
    'console.log(cli.binPath);\n' +
    '```\n' +
    '\n' +
    '## License\n' +
    '\n' +
    'MIT\n';
}

function resolveVersion(rootDir, versionOverride) {
  if (versionOverride) {
    return versionOverride;
  }

  const fallback = '0.0.1';
  try {
    const metaPkg = JSON.parse(fs.readFileSync(path.join(rootDir, 'packages', 'ansilust', 'package.json'), 'utf-8'));
    return metaPkg.version || fallback;
  } catch {
    return fallback;
  }
}

function resolveBinaryPath({ rootDir, isCI, platformId, binaryName }) {
  if (isCI) {
    return path.join(rootDir, 'artifacts', platformId, getBinaryFilename(binaryName, platformId));
  }

  return path.join(rootDir, 'zig-out', 'bin', getBinaryFilename(binaryName, platformId));
}

function assembleFamily(familyName, options = {}) {
  const rootDir = options.rootDir || path.join(__dirname, '..');
  const isCI = options.isCI ?? fs.existsSync(path.join(rootDir, 'artifacts'));
  const version = resolveVersion(rootDir, options.versionOverride || process.env.PACKAGE_VERSION);
  const packagesDir = path.join(rootDir, 'packages');
  const licenseFile = path.join(rootDir, 'LICENSE');
  const family = PACKAGE_FAMILIES[familyName];

  let successCount = 0;

  for (const platformId of Object.values(TARGETS)) {
    const binaryPath = resolveBinaryPath({ rootDir, isCI, platformId, binaryName: family.binaryName });
    if (!fs.existsSync(binaryPath)) {
      continue;
    }

    const packageName = getPlatformPackageName(familyName, platformId);
    const packageDir = path.join(packagesDir, packageName);
    const binDir = path.join(packageDir, 'bin');
    const destBinary = path.join(binDir, getBinaryFilename(family.binaryName, platformId));

    ensureDir(binDir);
    copyFile(binaryPath, destBinary);
    if (!platformId.startsWith('win32-')) {
      fs.chmodSync(destBinary, 0o755);
    }

    fs.writeFileSync(
      path.join(packageDir, 'package.json'),
      JSON.stringify(generatePackageJson(familyName, platformId, version), null, 2) + '\n',
    );
    fs.writeFileSync(path.join(packageDir, 'index.js'), generateIndexJs(family.binaryName));
    fs.writeFileSync(path.join(packageDir, 'README.md'), generateReadme(familyName, platformId));

    if (fs.existsSync(licenseFile)) {
      copyFile(licenseFile, path.join(packageDir, 'LICENSE'));
    }

    console.log(`✓ ${packageName}`);
    successCount += 1;
  }

  return successCount;
}

function assemble(options = {}) {
  const rootDir = options.rootDir || path.join(__dirname, '..');
  const isCI = options.isCI ?? fs.existsSync(path.join(rootDir, 'artifacts'));
  const version = resolveVersion(rootDir, options.versionOverride || process.env.PACKAGE_VERSION);

  console.log(`Mode: ${isCI ? 'CI (artifacts/)' : 'Local (zig-out/bin)'}`);
  console.log(`Assembling npm packages (v${version})`);
  console.log('');

  let total = 0;
  for (const familyName of Object.keys(PACKAGE_FAMILIES)) {
    total += assembleFamily(familyName, { rootDir, isCI, versionOverride: version });
  }

  console.log('');
  console.log(`Complete: ${total} packages assembled`);
  return total;
}

module.exports = {
  PACKAGE_FAMILIES,
  PLATFORM_META,
  TARGETS,
  assemble,
  assembleFamily,
  generateIndexJs,
  generatePackageJson,
  generateReadme,
  getBinaryFilename,
  getPlatformPackageName,
};

if (require.main === module) {
  assemble();
}
