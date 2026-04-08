import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(here, '..')
const websiteRoot = path.join(repoRoot, 'website')
const rootPackagePath = path.join(repoRoot, 'package.json')
const websitePackagePath = path.join(websiteRoot, 'package.json')

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'))
}

test('repo exposes a checked-in root website directory', () => {
  assert.ok(
    fs.existsSync(websiteRoot),
    'expected root website scaffold at ./website, but the directory does not exist',
  )

  assert.ok(
    fs.statSync(websiteRoot).isDirectory(),
    'expected ./website to be a directory',
  )
})

test('root workspace wiring includes the website app scaffold', () => {
  const rootPackage = readJson(rootPackagePath)

  assert.ok(Array.isArray(rootPackage.workspaces), 'expected root package.json to define workspaces')
  assert.ok(
    rootPackage.workspaces.includes('website'),
    'expected root package.json workspaces to include "website" so the website scaffold is part of repo reality',
  )
})

test('website scaffold declares the minimum build contract', () => {
  assert.ok(
    fs.existsSync(websitePackagePath),
    'expected ./website/package.json to exist for the checked-in build scaffold',
  )

  const websitePackage = readJson(websitePackagePath)

  assert.equal(websitePackage.private, true, 'expected website/package.json to mark the app private')
  assert.match(websitePackage.packageManager ?? '', /^bun@/i, 'expected website/package.json to declare Bun as package manager')
  assert.equal(typeof websitePackage.scripts?.dev, 'string', 'expected website/package.json to define a dev script')
  assert.equal(typeof websitePackage.scripts?.build, 'string', 'expected website/package.json to define a build script')

  const allDeps = {
    ...(websitePackage.dependencies ?? {}),
    ...(websitePackage.devDependencies ?? {}),
  }

  assert.ok(allDeps.react, 'expected website scaffold to declare React')
  assert.ok(allDeps.tailwindcss, 'expected website scaffold to declare Tailwind CSS')
})
