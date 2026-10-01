#!/usr/bin/env node
/**
 * Freebuff RTL — cross-platform patcher (Node >= 18, no dependencies).
 *
 *   node tools/apply.mjs --root <dir>      patch the app found under <dir>
 *   node tools/apply.mjs --root <dir> --check    only report whether it is patched
 *   node tools/apply.mjs --root <dir> --list     print the resolved UI directory
 *
 * <dir> may be any of:
 *   macOS   : /Applications/Freebuff.app/Contents/Resources
 *   Windows : %LOCALAPPDATA%\Programs\Freebuff\resources
 *   Linux   : <squashfs-root>/resources   (extracted AppImage)
 *             /opt/Freebuff/resources     (deb/rpm/tar install)
 *   any     : the UI directory itself (.../orchestrator/ui)
 *
 * Everything the patch needs is copied *into* the app (fonts included), so the
 * patched app works offline. The patch is additive and idempotent: it never
 * rewrites a file that belongs to the app.
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = path.dirname(fileURLToPath(import.meta.url))
const PATCH = path.resolve(HERE, '..', 'patch')
const CSS_HREF = './freebuff-rtl.css'
const JS_SRC = './freebuff-rtl.js'

const argv = process.argv.slice(2)
const arg = (name) => {
  const i = argv.indexOf(name)
  return i >= 0 ? argv[i + 1] : undefined
}
const flag = (name) => argv.includes(name)

const root = arg('--root')
if (!root) {
  console.error('usage: node tools/apply.mjs --root <dir> [--check] [--list] [--quiet]')
  process.exit(2)
}
if (!fs.existsSync(PATCH)) {
  console.error(`patch files not found at ${PATCH}`)
  process.exit(1)
}

/** Locate the renderer UI directory (the one holding index.html). */
function findUiDir(base) {
  const candidates = [
    base,
    path.join(base, 'orchestrator', 'ui'),
    path.join(base, 'resources', 'orchestrator', 'ui'),
    path.join(base, 'Contents', 'Resources', 'orchestrator', 'ui'),
    path.join(base, 'ui'),
  ]
  return candidates.find((c) => fs.existsSync(path.join(c, 'index.html'))) || null
}

const uiDir = findUiDir(path.resolve(root))
if (!uiDir) {
  console.error(`no Freebuff UI found under ${root} (looked for index.html)`)
  process.exit(1)
}
if (flag('--list')) {
  console.log(uiDir)
  process.exit(0)
}

const indexPath = path.join(uiDir, 'index.html')
const readHtml = () => fs.readFileSync(indexPath, 'utf8')

function isPatched() {
  const html = readHtml()
  return (
    html.includes(CSS_HREF) &&
    html.includes(JS_SRC) &&
    fs.existsSync(path.join(uiDir, 'freebuff-rtl.css')) &&
    fs.existsSync(path.join(uiDir, 'freebuff-rtl.js')) &&
    fs.existsSync(path.join(uiDir, 'fonts', 'freebuff-rtl', 'Vazirmatn-Regular.woff2'))
  )
}

if (flag('--check')) {
  const ok = isPatched()
  if (!flag('--quiet')) console.log(ok ? `patched: ${uiDir}` : `not patched: ${uiDir}`)
  process.exit(ok ? 0 : 1)
}

// --- copy the patch into the app -------------------------------------------
fs.copyFileSync(path.join(PATCH, 'rtl.css'), path.join(uiDir, 'freebuff-rtl.css'))
fs.copyFileSync(path.join(PATCH, 'rtl.js'), path.join(uiDir, 'freebuff-rtl.js'))

const fontDir = path.join(uiDir, 'fonts', 'freebuff-rtl')
fs.mkdirSync(fontDir, { recursive: true })
for (const f of fs.readdirSync(path.join(PATCH, 'fonts'))) {
  if (f.endsWith('.woff2')) fs.copyFileSync(path.join(PATCH, 'fonts', f), path.join(fontDir, f))
}

// --- link them from index.html (idempotent) --------------------------------
let html = readHtml()
if (!/<\/head>/i.test(html)) {
  console.error('index.html has no </head> — the UI layout changed, patch aborted')
  process.exit(1)
}
const tags = []
if (!html.includes(CSS_HREF)) tags.push(`    <link rel="stylesheet" href="${CSS_HREF}" />`)
if (!html.includes(JS_SRC)) tags.push(`    <script defer src="${JS_SRC}"></script>`)
if (tags.length) {
  html = html.replace(/<\/head>/i, `${tags.join('\n')}\n  </head>`)
  fs.writeFileSync(indexPath, html)
}

if (!isPatched()) {
  console.error('verification failed: the patch is not active after writing it')
  process.exit(1)
}
if (!flag('--quiet')) {
  console.log(`patched: ${uiDir}`)
  if (tags.length === 0) console.log('  (index.html was already linked — files refreshed)')
}
