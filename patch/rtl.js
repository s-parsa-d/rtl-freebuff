/* ============================================================================
 *  Freebuff RTL — جهت خودکارِ ورودی چت
 *
 *  composer اپ یک contenteditable است و هیچ dir ای نمی‌گذارد؛ در نتیجه پرامپت
 *  فارسی چپ‌چین و به‌هم‌ریخته تایپ می‌شود. این اسکریپت کوچک فقط همین یک کار را
 *  می‌کند: بر اساس «اولین کاراکتر قویِ» متنِ ورودی، dir را rtl یا ltr می‌گذارد
 *  (خالی → rtl). بقیهٔ کارها را rtl.css انجام می‌دهد.
 *
 *  هیچ‌چیز بیرون از .composer را دست نمی‌زند و اگر خطا بدهد اپ بدون آن هم
 *  کار می‌کند (try/catch سراسری).
 * ========================================================================= */
;(() => {
  'use strict'
  try {
    if (window.__freebuffRtl) return
    window.__freebuffRtl = true

    // حروف راست‌به‌چپ: عبری، عربی، فارسی و شکل‌های نمایشی‌شان.
    const RTL_CHAR =
      /[\u0590-\u05FF\u0600-\u06FF\u0700-\u074F\u0750-\u077F\u0780-\u07BF\u08A0-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/
    // حروف چپ‌به‌راست: لاتین و سیریلیک/یونانی.
    const LTR_CHAR = /[A-Za-z\u00C0-\u02AF\u0370-\u052F\u1E00-\u1EFF\u2C60-\u2C7F\uA720-\uA7FF]/

    const SELECTOR =
      '.composer [data-composer-input], .composer [contenteditable="true"], .composer textarea'

    /** جهت متن از روی اولین کاراکتر قوی؛ نبود چنین کاراکتری → null. */
    function dirOf(text) {
      const sample = text.length > 400 ? text.slice(0, 400) : text
      for (const ch of sample) {
        // رقم، فاصله و نشانه‌ها خنثی‌اند و از آن‌ها رد می‌شویم.
        if (RTL_CHAR.test(ch)) return 'rtl'
        if (LTR_CHAR.test(ch)) return 'ltr'
      }
      return null
    }

    function textOf(el) {
      if (typeof el.value === 'string') return el.value
      return el.textContent || ''
    }

    /* ------------------------------------------------------------------ *
     * جهت متن‌های فارسیِ خود اپ: سایدبار، منو، تنظیمات، عنوان گفتگوها و هر
     * متن کوتاه دیگری. فقط «برگ‌های» DOM را نگاه می‌کنیم (عنصری که فرزند
     * عنصری ندارد) تا چیدمان هیچ لیست/فلکسی را به‌هم نزنیم، و چت/کد/ترمینال
     * را رد می‌کنیم چون خودشان در CSS حل شده‌اند.
     * فقط اگر متن فارسی بود dir="rtl" می‌گذاریم؛ متن لاتین دست‌نخورده می‌ماند.
     * ------------------------------------------------------------------ */
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
          /* بی‌صدا: هیچ‌وقت نباید تایپ کاربر را قطع کند */
        }
      })
    }

    document.addEventListener('input', schedule, true)
    document.addEventListener('compositionend', schedule, true)
    document.addEventListener('focusin', schedule, true)
    document.addEventListener('click', schedule, true)

    // React گره‌های تازه می‌سازد (پیام جدید، ادیت پیام، ترد جدید)؛ بدون این
    // ناظر، ورودی تازه‌ساخته‌شده تا اولین تایپ راست‌چین نمی‌شد.
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
    /* چیزی که ارزش شکستن اپ را داشته باشد اینجا نیست */
  }
})()
