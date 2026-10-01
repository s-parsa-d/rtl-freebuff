# Freebuff RTL — فارسی‌سازی اپ دسکتاپ Freebuff

پچ کوچکی که رابط **Freebuff Desktop** را برای فارسی قابل‌استفاده می‌کند:

1. **فونت فارسی:** هر متن فارسیِ نمایش‌داده‌شده با **وزیرمتن** رندر می‌شود (چهار وزن، داخل خود اپ، بدون نیاز به اینترنت).
2. **چت راست‌چین:** ورودی چت و متن پیام‌ها راست‌چین می‌شوند و ترتیب دوجهتهٔ فارسی/انگلیسی درست می‌شود (`unicode-bidi: plaintext`)، پس واژه یا کد انگلیسیِ وسط جملهٔ فارسی دیگر پرت نمی‌شود.
3. **متن‌های فارسی خود اپ** (سایدبار، منو، تنظیمات، عنوان گفتگوها) با تشخیص خودکار `dir="rtl"` می‌گیرند و راست‌چین می‌شوند؛ متن‌های انگلیسی دست‌نخورده می‌مانند.

**چیزی که عوض نمی‌شود:** چیدمان و اندازه‌ها، فونت لاتین (Google Sans خود اپ)، مونواسپیس کد/ترمینال/دیف (DM Mono)، لوگو و برند (Freebuff Outfit)، و هیچ `dir="rtl"` روی کل صفحه. پچ فقط *اضافه* می‌کند (یک CSS، یک JS و چهار فایل فونت) و دو خط لینک در `index.html`؛ هیچ فایلی از خود اپ بازنویسی نمی‌شود.

> **چرا لازم است:** فونت رابط Freebuff در ۵۰ زیرمجموعه بار می‌شود (لاتین، سیریلیک، یونانی، عبری، هندی، …) ولی **هیچ زیرمجموعهٔ عربی/فارسی ندارد**؛ پس متن فارسی به فونت جانشین سیستم می‌افتاد و زشت دیده می‌شد. پچ یک فیس اضافه با `unicode-range` فارسی روی همان خانوادهٔ `Google Sans` اعلام می‌کند و فونت را در ترتیب استک هم می‌آورد تا فقط گلیف‌های فارسی وزیرمتن شوند.

## نصب

### Linux — AppImage ‏(تست‌شده ✅)

```bash
git clone <repo> "freebuff RTL" && cd "freebuff RTL"
./tools/get-appimagetool.sh          # یک‌بار؛ ابزار بسته‌بندی را می‌گیرد
./linux/apply-appimage.sh            # AppImage را پیدا و پچ می‌کند (همان فایل، درجا)
./linux/install-desktop.sh --command # میانبر منو + دستور freebuff-rtl
freebuff-rtl                         # اجرا (پچ خودکار در صورت آپدیت + اجرا)
```

AppImage یک squashfs فقط‌خواندنی است، پس پچ داخلش «پخته» می‌شود: استخراج → کپی پچ → بسته‌بندی مجدد → بازبینی. اگر اپ جای غیرمعمول است: `./linux/apply-appimage.sh --app /path/Freebuff.AppImage` یا `FREEBUFF_APPIMAGE=...`.

### Linux — نصب دایرکتوری (deb / rpm / pacman / tar)

```bash
./linux/apply-dir.sh                 # خودش /opt/Freebuff و ~/.local/opt/... را پیدا می‌کند
sudo ./linux/apply-dir.sh --root /opt/Freebuff   # اگر در /opt نصب است
```

### macOS

```bash
./macos/apply-macos.sh                       # Freebuff.app نصب‌شده را پچ می‌کند
./macos/apply-macos.sh --install ~/Downloads/Freebuff-0.0.155.dmg   # نصب از dmg + پچ
./macos/launch.command                       # اجرا (پچ خودکار در صورت آپدیت + اجرا)
./macos/install-launchagent.sh               # (اختیاری) پچ خودکار بعد از هر آپدیت/ورود
```

دست‌زدن به `.app` امضای کد را باطل می‌کند، پس اسکریپت بعد از پچ **امضای ad-hoc** می‌زند (`codesign --force --deep --sign -`) و پرچم quarantine را برمی‌دارد. اگر Gatekeeper گیر داد، یک‌بار از منوی راست‌کلیک → Open استفاده کن.

### Windows

```powershell
# در PowerShell (برای نصب در Program Files با دسترسی Administrator)
.\windows\apply-windows.ps1
.\windows\install-shortcut.ps1        # میانبر «Freebuff RTL» روی دسکتاپ + منوی استارت
```

از این به بعد اپ را از همان میانبر «Freebuff RTL» اجرا کن؛ `launch-windows.ps1` مخفی اجرا می‌شود، اگر آپدیت پچ را پاک کرده باشد دوباره می‌سازد و بعد اپ را بالا می‌آورد. (اسکریپت‌های ویندوز فقط PowerShell لازم دارند، به Node نیازی نیست.)

**نکته‌های ویندوز:**

- اگر `running scripts is disabled` گرفتی، یک بار در همان پنجره `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` بزن یا اسکریپت را با `powershell -ExecutionPolicy Bypass -File ...` اجرا کن.
- اسکریپت‌ها حتماً باید **UTF-8 با BOM** ذخیره شوند (متن فارسی داخلشان است)؛ در غیر این صورت PowerShell 5.1 پارس را خراب می‌کند.
- اگر نصب اپ پوشه‌ای غیر از `Freebuff` دارد (مثلاً `@codebufffreebuff-desktop`)، اسکریپت خودش پیدایش می‌کند؛ وگرنه با `-Root <مسیر resources>` بده.
- اسم میانبر لاتین است (`Freebuff RTL`) چون `WScript.Shell` در ویندوزهای با کدپیج غیرفارسی نمی‌تواند فایل `.lnk` با اسم فارسی بسازد.

## بعد از هر آپدیت (مهم)

آپدیتر Freebuff فایل‌های اپ را بازنویسی می‌کند و پچ از بین می‌رود. راه‌حل در هر سیستم:

| سیستم | چه کار کن که پچ خودکار برگردد |
|---|---|
| Linux | همیشه از `freebuff-rtl` (یا میانبر منو → Freebuff) اپ را باز کن |
| macOS | همیشه `macos/launch.command` (یا alias آن در Dock) را باز کن، یا `install-launchagent.sh` را نصب کن |
| Windows | همیشه میانبر «Freebuff RTL» را اجرا کن |

منطق ساده است: لانچر می‌بیند فایل‌های پچ وجود ندارند (یعنی نسخهٔ تازه آمده)، پچ را از نو می‌سازد و بعد اپ را اجرا می‌کند.

## ساختار ریپو

| مسیر | کار |
|---|---|
| `patch/rtl.css` | پچ اصلی: فونت فارسی + قواعد راست‌چینِ چت |
| `patch/rtl.js` | تشخیص خودکار جهت (چت + متن‌های کوتاه فارسی خود اپ) |
| `patch/fonts/` | وزیرمتن (۴ وزن woff2) + متن مجوز OFL |
| `tools/apply.mjs` | پچ‌کنندهٔ کراس‌پلتفرم روی یک دایرکتوری نصب (Node) |
| `tools/inject.mjs` | افزودن دو خط لینک به `index.html` (تکرارپذیر) |
| `tools/locate.mjs` | پیدا کردن نصب‌های Freebuff روی همین سیستم |
| `tools/get-appimagetool.sh` | دانلود appimagetool برای بازبسته‌بندی AppImage |
| `linux/apply-appimage.sh` | استخراج → پچ → بسته‌بندی مجدد → بازبینی |
| `linux/apply-dir.sh` | پچ روی نصب دایرکتوری |
| `linux/launch.sh` | اجرا با پچ خودکار؛ `--status`, `--restart` |
| `linux/install-desktop.sh` | دسکتاپ‌آیتم و اختیاری دستور `freebuff-rtl` |
| `macos/apply-macos.sh` | پچ + امضای ad-hoc + نصب از dmg/zip |
| `macos/launch.command` | اجرا با پچ خودکار؛ `--status`, `--restart` |
| `macos/install-launchagent.sh` | LaunchAgent با `WatchPaths` (پچ بعد از هر آپدیت) |
| `windows/apply-windows.ps1` | پچ روی نصب ویندوز (خالص PowerShell) |
| `windows/launch-windows.ps1` | اجرا با پچ خودکار؛ `-Status`, `-Restart` |
| `windows/install-shortcut.ps1` | میانبر دسکتاپ/منوی استارت |

## وضعیت تست

| پلتفرم | وضعیت |
|---|---|
| Linux / AppImage ‏(x86_64) | ✅ روی Arch تست شد (پچ، بازبینی ایمیج، اجرا، بازگردانی پچ بعد از آپدیت) |
| Linux / نصب دایرکتوری | ✅ منطق مشترک `tools/apply.mjs` تست شده |
| macOS | ⚠️ اسکریپت نوشته شده ولی روی مک تست نشده (Pathها و `codesign` استانداردند) |
| Windows | ✅ روی Windows 10/11 تست شد (پچ، میانبر دسکتاپ/استارت، لانچر) |

اگر روی مک/ویندوز اجرا کردی و جایی خطا داد، خطا را در Issue بگذار.

## عیب‌یابی

- **پچ اثر نمی‌کند:** اول اپ را کامل ببند و از لانچر باز کن. Freebuff تک‌نسخه‌ای است؛ اگر پنجره‌اش باز باشد، اجرای دوباره فقط همان را جلو می‌آورد.
- **از کجا بفهمم پچ روی فایل است؟** `./linux/apply-appimage.sh --check` یا `./macos/apply-macos.sh --check` یا `.\windows\apply-windows.ps1 -Check` و در لینوکس `node tools/locate.mjs`.
- **آیا واقعاً لینک شده؟** داخل نصب اپ باید `orchestrator/ui/index.html` شامل `freebuff-rtl.css` باشد و سه فایل پچ کنارش باشند.
- **سایدبار/بخشی از UI فارسی نشد:** ممکن است آن بخش در shadow DOM باشد. `patch/rtl.css` را باز کن و همان الگو را اضافه کن، یا Issue بگذار با نام آن بخش.
- **ساخت AppImage شکست خورد:** `build.log` را ببین؛ اگر FUSE نداری، `./tools/get-appimagetool.sh` خودش حالت جایگزین (`--appimage-extract-and-run`) را هم امتحان می‌کند.
- **بازگشت به نسخهٔ دست‌نخورده:** پچ اضافه‌کردنی است؛ کافی است سه فایل `freebuff-rtl.css`, `freebuff-rtl.js`, `fonts/freebuff-rtl/` را پاک کنی و دو خط `<link rel="stylesheet" href="./freebuff-rtl.css" />` و `<script defer src="./freebuff-rtl.js"></script>` را از `index.html` بردار، یا اپ را از سایت سازنده دوباره نصب کن.

## مجوز

اسکریپت‌ها و پچ: MIT (فایل `LICENSE`). فونت وزیرمتن: SIL Open Font License 1.1 (`patch/fonts/LICENSE-Vazirmatn.md`).

## English (short)

Small cross-platform patch that makes Freebuff Desktop usable in Persian: every
Persian glyph falls back to **Vazirmatn** (bundled, works offline), chat messages
and the composer are right-aligned with correct bidirectional text, and short
Persian UI strings (sidebar, menus, thread titles) get `dir="rtl"`. Nothing else
changes: layout, Latin font, monospace code/terminal and the logo stay exactly as
shipped. Install with `linux/apply-appimage.sh`, `linux/apply-dir.sh`,
`macos/apply-macos.sh`, or `windows/apply-windows.ps1`; launch through the
included launcher so an app update can never leave you unpatched. Upstream
font license: SIL OFL 1.1.
