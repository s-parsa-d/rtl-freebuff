#!/usr/bin/env node
/**
 * Links the RTL patch into an extracted Freebuff renderer UI.
 *
 *   node inject.mjs <uiDir>
 *
 * <uiDir> is .../resources/orchestrator/ui inside a Freebuff AppImage. The tags
 * are appended at the end of <head>, so this stylesheet wins over the app's own
 * bundled CSS (same specificity, later in document order). Idempotent: running
 * it twice does not duplicate the tags.
 */
import fs from 'node:fs'
import path from 'node:path'

const CSS_HREF = './freebuff-rtl.css'
const JS_SRC = './freebuff-rtl.js'

const uiDir = process.argv[2]
if (!uiDir) {
  console.error('usage: inject.mjs <uiDir>')
  process.exit(2)
}

const indexPath = path.join(uiDir, 'index.html')
if (!fs.existsSync(indexPath)) {
  console.error(`index.html not found in ${uiDir}`)
  process.exit(1)
}

let html = fs.readFileSync(indexPath, 'utf8')
if (!/<\/head>/i.test(html)) {
  console.error('index.html has no </head> — the UI layout changed, patch aborted')
  process.exit(1)
}

const tags = []
if (!html.includes(CSS_HREF)) tags.push(`    <link rel="stylesheet" href="${CSS_HREF}" />`)
if (!html.includes(JS_SRC)) tags.push(`    <script defer src="${JS_SRC}"></script>`)

if (tags.length === 0) {
  console.log('index.html already patched')
} else {
  html = html.replace(/<\/head>/i, `${tags.join('\n')}\n  </head>`)
  fs.writeFileSync(indexPath, html)
  console.log(`index.html patched (${tags.length} tag${tags.length > 1 ? 's' : ''})`)
}

const patched = fs.readFileSync(indexPath, 'utf8')
if (!patched.includes(CSS_HREF) || !patched.includes(JS_SRC)) {
  console.error('verification failed: the patch tags are not in index.html')
  process.exit(1)
}
