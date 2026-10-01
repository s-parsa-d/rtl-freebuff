#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'

const home = os.homedir()
const env = process.env
const roots = []

function add(p) {
  if (p && fs.existsSync(p) && !roots.includes(p)) roots.push(p)
}

function scanForResourcesDirs(dir, depth = 3) {
  if (depth < 0) return
  let entries = []
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true })
  } catch {
    return
  }
  for (const e of entries) {
    if (!e.isDirectory()) continue
    const full = path.join(dir, e.name)
    if (fs.existsSync(path.join(full, 'orchestrator', 'ui', 'index.html'))) add(full)
    else scanForResourcesDirs(full, depth - 1)
  }
}

if (process.platform === 'darwin') {
  for (const base of ['/Applications', path.join(home, 'Applications')]) {
    for (const name of ['Freebuff.app', 'Freebuff Desktop.app']) {
      add(path.join(base, name, 'Contents', 'Resources'))
    }
    try {
      for (const e of fs.readdirSync(base)) {
        if (/^freebuff.*\.app$/i.test(e)) add(path.join(base, e, 'Contents', 'Resources'))
      }
    } catch {}
  }
} else if (process.platform === 'win32') {
  const local = env.LOCALAPPDATA || path.join(home, 'AppData', 'Local')
  const prog = env.ProgramFiles || 'C:\\Program Files'
  const prog86 = env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)'
  scanForResourcesDirs(path.join(local, 'Programs'), 2)
  scanForResourcesDirs(path.join(local, 'Freebuff'), 2)
  for (const base of ['Freebuff', 'Freebuff Desktop']) {
    add(path.join(prog, base, 'resources'))
    add(path.join(prog86, base, 'resources'))
  }
} else {
  for (const base of ['/opt', path.join(home, '.local', 'opt')]) {
    for (const name of ['Freebuff', 'freebuff', 'Freebuff Desktop']) {
      add(path.join(base, name, 'resources'))
      add(path.join(base, name))
    }
  }
  add('/usr/lib/freebuff/resources')
  for (const base of ['/tmp', home]) {
    try {
      for (const e of fs.readdirSync(base)) {
        if (/^squashfs-root|^Freebuff.*AppDir$/i.test(e)) add(path.join(base, e, 'resources'))
      }
    } catch {}
  }
}

const appImages = []
for (const dir of [path.join(home, '.local', 'bin'), path.join(home, 'Applications'), home]) {
  try {
    for (const e of fs.readdirSync(dir)) {
      if (/^freebuff.*\.appimage$/i.test(e)) appImages.push(path.join(dir, e))
    }
  } catch {}
}

const patched = (root) => {
  const ui = path.join(root, 'orchestrator', 'ui')
  try {
    const html = fs.readFileSync(path.join(ui, 'index.html'), 'utf8')
    return html.includes('./freebuff-rtl.css') && html.includes('./freebuff-rtl.js')
  } catch {
    return false
  }
}

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({ roots: roots.map((r) => ({ path: r, patched: patched(r) })), appImages }, null, 2))
} else {
  if (!roots.length && !appImages.length) console.log('Freebuff نصب‌شده‌ای پیدا نشد.')
  for (const r of roots) console.log(`${patched(r) ? '✅ patched ' : '⚠  stock  '} ${r}`)
  for (const a of appImages) console.log(`   appimage  ${a}`)
  if (roots.length) console.log(`\nبرای پچ‌کردن: node tools/apply.mjs --root "${roots[0]}"`)
}
