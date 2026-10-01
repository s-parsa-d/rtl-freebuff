;(() => {
  'use strict'
  try {
    if (window.__freebuffRtl) return
    window.__freebuffRtl = true

    const RTL_CHAR =
      /[\u0590-\u05FF\u0600-\u06FF\u0700-\u074F\u0750-\u077F\u0780-\u07BF\u08A0-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/
    const LTR_CHAR = /[A-Za-z\u00C0-\u02AF\u0370-\u052F\u1E00-\u1EFF\u2C60-\u2C7F\uA720-\uA7FF]/

    const SELECTOR =
      '.composer [data-composer-input], .composer [contenteditable="true"], .composer textarea'

    function dirOf(text) {
      const sample = text.length > 400 ? text.slice(0, 400) : text
      for (const ch of sample) {
        if (RTL_CHAR.test(ch)) return 'rtl'
        if (LTR_CHAR.test(ch)) return 'ltr'
      }
      return null
    }

    function textOf(el) {
      if (typeof el.value === 'string') return el.value
      return el.textContent || ''
    }

    const SKIP =
      '.composer, .messages, .xterm, .cm-editor, .monaco-editor, pre, code, ' +
      '[contenteditable="true"], .new-thread-logo, .loading-screen-logo, .splash-logo'
    const seen = new WeakSet()

    function markPersian() {
      for (const el of document.querySelectorAll('body *')) {
        if (seen.has(el) || el.children.length) continue
        seen.add(el)
        if (el.closest(SKIP)) continue
        const text = (el.textContent || '').trim()
        if (!text) continue
        if (dirOf(text) === 'rtl') el.setAttribute('dir', 'rtl')
      }
    }

    function refresh() {
      for (const el of document.querySelectorAll(SELECTOR)) {
        const dir = dirOf(textOf(el)) || 'rtl'
        if (el.getAttribute('dir') !== dir) el.setAttribute('dir', dir)
      }
      markPersian()
    }

    let queued = false
    function schedule() {
      if (queued) return
      queued = true
      requestAnimationFrame(() => {
        queued = false
        try {
          refresh()
        } catch {
        }
      })
    }

    document.addEventListener('input', schedule, true)
    document.addEventListener('compositionend', schedule, true)
    document.addEventListener('focusin', schedule, true)
    document.addEventListener('click', schedule, true)

    new MutationObserver(schedule).observe(document.documentElement, {
      childList: true,
      subtree: true,
    })

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', schedule, { once: true })
    } else {
      schedule()
    }
  } catch {
  }
})()
