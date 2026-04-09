import test from 'node:test'
import assert from 'node:assert/strict'
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
