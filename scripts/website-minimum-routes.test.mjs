import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(here, '..')
const websiteRoot = path.join(repoRoot, 'website')

const routePatterns = {
  '/': [
    'app/page',
    'src/app/page',
    'pages/index',
    'src/pages/index',
    'src/routes/index',
  ],
  '/install': [
    'app/install/page',
    'src/app/install/page',
    'pages/install',
    'src/pages/install',
    'src/routes/install',
    'src/routes/install/index',
  ],
  '/docs': [
    'app/docs/page',
    'src/app/docs/page',
    'pages/docs',
    'src/pages/docs',
    'src/routes/docs',
    'src/routes/docs/index',
  ],
}

const extensions = ['js', 'jsx', 'ts', 'tsx', 'mdx']

function routeCandidates(routePath) {
  return routePatterns[routePath].flatMap((pattern) =>
    extensions.map((extension) => path.join(websiteRoot, `${pattern}.${extension}`)),
  )
}

function assertRouteArtifact(routePath) {
  const candidates = routeCandidates(routePath)
  const existing = candidates.filter((candidate) => fs.existsSync(candidate))

  assert.ok(
    existing.length > 0,
    [
      `expected the website scaffold to evidence a checked-in route for ${routePath}`,
      'accepted route file locations:',
      ...candidates.map((candidate) => `- ${path.relative(repoRoot, candidate)}`),
    ].join('\n'),
  )
}

test('website scaffold owns the minimum homepage, install, and docs route set', () => {
  assert.ok(fs.existsSync(websiteRoot), 'expected ./website scaffold to exist before route checks run')

  assertRouteArtifact('/')
  assertRouteArtifact('/install')
  assertRouteArtifact('/docs')
})
