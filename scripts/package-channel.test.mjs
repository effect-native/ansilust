import test from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync, spawn } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const here = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(here, '..')
const require = createRequire(import.meta.url)

const assembly = require(path.join(repoRoot, 'scripts', 'assemble-npm-packages.js'))
const launcher = require(path.join(repoRoot, 'packages', '16c', 'bin', 'launcher.js'))

function makeTempRoot() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ansilust-package-channel-'))
}

function writeFile(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true })
  fs.writeFileSync(filePath, content)
}

function ensureBuiltSixteencBinary() {
  execFileSync('zig', ['build'], { cwd: repoRoot, stdio: 'inherit' })
  const binaryPath = path.join(repoRoot, 'zig-out', 'bin', '16c')
  assert.ok(fs.existsSync(binaryPath), 'expected zig build to produce zig-out/bin/16c')
  return binaryPath
}

async function waitFor(predicate, timeoutMs, intervalMs = 50) {
  const startedAt = Date.now()

  while (Date.now() - startedAt < timeoutMs) {
    if (predicate()) {
      return
    }

    await new Promise((resolve) => setTimeout(resolve, intervalMs))
  }

  throw new Error(`Condition not met within ${timeoutMs}ms`)
}

test('assembly uses arm64 package names and emits 16c platform payloads', () => {
  const rootDir = makeTempRoot()

  writeFile(path.join(rootDir, 'LICENSE'), 'MIT\n')
  writeFile(path.join(rootDir, 'packages', 'ansilust', 'package.json'), JSON.stringify({ version: '9.9.9' }))
  writeFile(path.join(rootDir, 'artifacts', 'linux-x64-gnu', 'ansilust'), '#!/bin/sh\n')
  writeFile(path.join(rootDir, 'artifacts', 'linux-x64-gnu', '16c'), '#!/bin/sh\n')
  writeFile(path.join(rootDir, 'artifacts', 'linux-arm64-gnu', 'ansilust'), '#!/bin/sh\n')
  writeFile(path.join(rootDir, 'artifacts', 'linux-arm64-gnu', '16c'), '#!/bin/sh\n')

  const count = assembly.assemble({ rootDir, isCI: true, versionOverride: '1.2.3' })
  assert.equal(count, 4)

  const arm64Pkg = JSON.parse(
    fs.readFileSync(path.join(rootDir, 'packages', 'ansilust-linux-arm64-gnu', 'package.json'), 'utf8'),
  )
  assert.equal(arm64Pkg.name, 'ansilust-linux-arm64-gnu')

  const sixteencPkg = JSON.parse(
    fs.readFileSync(path.join(rootDir, 'packages', '16c-linux-arm64-gnu', 'package.json'), 'utf8'),
  )
  assert.equal(sixteencPkg.name, '16c-linux-arm64-gnu')
  assert.ok(fs.existsSync(path.join(rootDir, 'packages', '16c-linux-arm64-gnu', 'bin', '16c')))
})

test('16c launcher resolves the same platform naming convention used by release assembly', () => {
  assert.equal(
    launcher.getPackageName({ platform: 'linux', arch: 'arm64', libcFamily: 'glibc' }),
    '16c-linux-arm64-gnu',
  )

  assert.equal(
    launcher.getPackageName({ platform: 'linux', arch: 'x64', libcFamily: 'musl' }),
    '16c-linux-x64-musl',
  )

  assert.equal(
    launcher.getPackageName({ platform: 'darwin', arch: 'arm64' }),
    '16c-darwin-arm64',
  )
})

test('16c package launcher seeds starter art and reaches looping screensaver playback on a clean temp home', async (t) => {
  if (process.platform === 'win32') {
    t.skip('16c package launcher smoke coverage only supports POSIX platforms')
  }

  const installRoot = makeTempRoot()
  const binaryPath = ensureBuiltSixteencBinary()
  const packageName = launcher.getPackageName({
    platform: process.platform,
    arch: process.arch,
    libcFamily: process.platform === 'linux' ? 'glibc' : undefined,
  })
  const nodeModules = path.join(installRoot, 'node_modules')

  writeFile(
    path.join(nodeModules, packageName, 'package.json'),
    JSON.stringify({ name: packageName, version: '0.0.0-test', main: 'index.js' }),
  )
  writeFile(
    path.join(nodeModules, packageName, 'index.js'),
    `module.exports = { binPath: ${JSON.stringify(binaryPath)} }\n`,
  )

  const homeDir = path.join(installRoot, 'home')
  const xdgDataHome = path.join(installRoot, 'xdg-data')
  const starterPath = path.join(xdgDataHome, '16colors', 'local', 'ansilust-starter.ans')
  const launcherPath = path.join(repoRoot, 'packages', '16c', 'bin', 'launcher.js')
  const nodePath = [nodeModules, process.env.NODE_PATH].filter(Boolean).join(path.delimiter)

  const child = spawn(process.execPath, [launcherPath, 'screensaver', '--instant'], {
    cwd: installRoot,
    detached: true,
    env: {
      ...process.env,
      HOME: homeDir,
      XDG_DATA_HOME: xdgDataHome,
      NODE_PATH: nodePath,
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  })

  let stdout = ''
  let stderr = ''
  child.stdout.setEncoding('utf8')
  child.stderr.setEncoding('utf8')
  child.stdout.on('data', (chunk) => {
    stdout += chunk
  })
  child.stderr.on('data', (chunk) => {
    stderr += chunk
  })

  const closePromise = new Promise((resolve) => {
    child.once('close', (code, signal) => resolve({ code, signal }))
  })

  const stopChild = () => {
    if (!child.killed) {
      try {
        process.kill(-child.pid, 'SIGTERM')
      } catch {}
    }
  }

  t.after(async () => {
    stopChild()
    await closePromise
  })

  await waitFor(() => {
    const frameCount = (stdout.match(/ANSILUST STARTER ART/g) || []).length
    return fs.existsSync(starterPath) && frameCount >= 2 && stderr.includes('Provisioned 1 repo-owned starter artwork file(s) into local/.')
  }, 5000)

  stopChild()
  await closePromise

  assert.ok(fs.existsSync(starterPath), `expected starter art at ${starterPath}`)
  assert.match(fs.readFileSync(starterPath, 'utf8'), /ANSILUST STARTER ART/)
  assert.match(stdout, /ANSILUST STARTER ART/)
  assert.match(stdout, /Local first-use pool ready\./)
  assert.match(stderr, /Selected local artwork:/)
})
