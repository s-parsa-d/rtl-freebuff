# Freebuff RTL

A small add-on patch that makes the **Freebuff Desktop** app usable in Persian:

1. **Persian font** — every Persian glyph is rendered with **Vazirmatn**
   (four weights, bundled inside the app, works offline).
2. **Right-to-left chat** — the composer and the message text are right-aligned
   and bidirectional order is correct (`unicode-bidi: plaintext`), so an English
   word or code snippet inside a Persian sentence no longer jumps around.
3. **Persian app strings** — short Persian UI strings (sidebar, menus, settings,
   thread titles) are detected and get `dir="rtl"`; Latin strings are left
   untouched.

**What does not change:** layout and sizes, the Latin UI font (the app's own
Google Sans), the monospace font for code/terminal/diff (DM Mono), the logo and
brand (Freebuff Outfit), and no `dir="rtl"` is applied to the whole page. The
patch only *adds* files (one CSS, one JS, four font files) and two `<link>` lines
to `index.html`; no file that belongs to the app is rewritten.

> **Why it is needed:** Freebuff ships its UI font in ~50 subsets (Latin,
> Cyrillic, Greek, Hebrew, Devanagari, …) but **none covers the Arabic/Persian
> range**, so Persian text fell back to a system font and looked bad. The patch
> adds a face with a Persian `unicode-range` to the same `Google Sans` family
> and puts the font on the stack, so only Persian glyphs use Vazirmatn.

See [`docs/TECHNICAL.md`](docs/TECHNICAL.md) for implementation details.

## Install

### Linux — AppImage (tested ✅)

```bash
git clone <repo> "freebuff RTL" && cd "freebuff RTL"
./tools/get-appimagetool.sh          # run once; fetches the packaging tool
./linux/apply-appimage.sh            # find and patch the AppImage (in place)
./linux/install-desktop.sh --command # menu entry + `freebuff-rtl` command
freebuff-rtl                         # run (auto-repatch on update, then start)
```

An AppImage is a read-only squashfs, so the patch is baked in: extract → copy the
patch → repack → verify. If the app is somewhere unusual, use
`./linux/apply-appimage.sh --app /path/Freebuff.AppImage` or `FREEBUFF_APPIMAGE=...`.

### Linux — directory install (deb / rpm / pacman / tar)

```bash
./linux/apply-dir.sh                 # finds /opt/Freebuff and ~/.local/opt/... itself
sudo ./linux/apply-dir.sh --root /opt/Freebuff   # if installed under /opt
```

### macOS

```bash
./macos/apply-macos.sh                       # patch the installed Freebuff.app
./macos/apply-macos.sh --install ~/Downloads/Freebuff-0.0.155.dmg   # install from dmg + patch
./macos/launch.command                       # run (auto-repatch on update, then start)
./macos/install-launchagent.sh               # (optional) auto-patch after every update/login
```

Touching a `.app` invalidates its code signature, so the script re-signs it
**ad-hoc** afterwards (`codesign --force --deep --sign -`) and clears the
quarantine flag. If Gatekeeper complains, open it once via right-click → Open.

### Windows

```powershell
# In PowerShell (Administrator if Freebuff is installed under Program Files)
.\windows\apply-windows.ps1
.\windows\install-shortcut.ps1        # "Freebuff RTL" Desktop + Start menu shortcut
```

From then on launch the app through the **Freebuff RTL** shortcut;
`launch-windows.ps1` runs hidden, re-applies the patch if an update removed it,
then starts the app. (The Windows scripts only need PowerShell — no Node.)

**Windows notes:**

- If you get `running scripts is disabled`, run once in the same window:
  `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, or invoke the
  script with `powershell -ExecutionPolicy Bypass -File ...`.
- The scripts must be saved as **UTF-8 with BOM** (they contain Persian text);
  otherwise PowerShell 5.1 mis-parses them.
- If the app is installed in a folder other than `Freebuff` (for example
  `@codebufffreebuff-desktop`), the scripts find it automatically; otherwise pass
  `-Root <path to resources>`.
- The shortcut name is Latin (`Freebuff RTL`) because `WScript.Shell` cannot
  create a `.lnk` with a Persian name on non-Persian codepages.

## After every update (important)

The Freebuff updater rewrites the app files and removes the patch. How to bring
it back on each system:

| System | What to do so the patch returns automatically |
|---|---|
| Linux | Always launch through `freebuff-rtl` (or the menu entry → Freebuff) |
| macOS | Always open `macos/launch.command` (or its Dock alias), or install `install-launchagent.sh` |
| Windows | Always launch the **Freebuff RTL** shortcut |

The logic is simple: the launcher notices the patch files are missing (i.e. a new
version arrived), rebuilds the patch, then starts the app.

## Repository layout

| Path | Purpose |
|---|---|
| `patch/rtl.css` | Main patch: Persian font + chat RTL rules |
| `patch/rtl.js` | Automatic direction detection (chat + short Persian app strings) |
| `patch/fonts/` | Vazirmatn (4 woff2 weights) + OFL license text |
| `tools/apply.mjs` | Cross-platform patcher for an install directory (Node) |
| `tools/inject.mjs` | Adds the two link lines to `index.html` (idempotent) |
| `tools/locate.mjs` | Finds Freebuff installs on this machine |
| `tools/get-appimagetool.sh` | Downloads appimagetool to repack AppImages |
| `linux/apply-appimage.sh` | Extract → patch → repack → verify |
| `linux/apply-dir.sh` | Patch a directory install |
| `linux/launch.sh` | Launch with auto-repatch; `--status`, `--restart` |
| `linux/install-desktop.sh` | Desktop entry and optional `freebuff-rtl` command |
| `macos/apply-macos.sh` | Patch + ad-hoc signing + install from dmg/zip |
| `macos/launch.command` | Launch with auto-repatch; `--status`, `--restart` |
| `macos/install-launchagent.sh` | LaunchAgent with `WatchPaths` (patch after every update) |
| `windows/apply-windows.ps1` | Patch a Windows install (pure PowerShell) |
| `windows/launch-windows.ps1` | Launch with auto-repatch; `-Status`, `-Restart` |
| `windows/install-shortcut.ps1` | Desktop / Start menu shortcut |
| `docs/TECHNICAL.md` | Design and implementation notes |

## Test status

| Platform | Status |
|---|---|
| Linux / AppImage (x86_64) | ✅ tested on Arch (patch, image verification, run, repatch after update) |
| Linux / directory install | ✅ shared logic `tools/apply.mjs` tested |
| macOS | ⚠️ scripts written but not tested on a Mac (paths and `codesign` are standard) |
| Windows | ✅ tested on Windows 10/11 (patch, Desktop/Start shortcuts, launcher) |

If you run it on a Mac or Windows and hit an error, please open an issue.

## Troubleshooting

- **The patch has no effect:** close the app completely and open it from the
  launcher. Freebuff is single-instance; if its window is open, running it again
  just brings that window forward.
- **How do I know the patch is on disk?** `./linux/apply-appimage.sh --check`,
  `./macos/apply-macos.sh --check`, `.\windows\apply-windows.ps1 -Check`, or on
  Linux `node tools/locate.mjs`.
- **Is it actually linked?** Inside the install, `orchestrator/ui/index.html`
  must contain `freebuff-rtl.css`, and the three patch files must be next to it.
- **Part of the sidebar/UI is not Persian:** that part may live in a shadow DOM.
  Open `patch/rtl.css`, add the same pattern, or file an issue naming the section.
- **AppImage build failed:** check `build.log`; if you lack FUSE,
  `./tools/get-appimagetool.sh` already tries the fallback
  (`--appimage-extract-and-run`).
- **Back to the stock build:** the patch is additive — just delete the three
  files `freebuff-rtl.css`, `freebuff-rtl.js`, and `fonts/freebuff-rtl/`, and
  remove the two lines
  `<link rel="stylesheet" href="./freebuff-rtl.css" />` and
  `<script defer src="./freebuff-rtl.js"></script>` from `index.html` — or
  reinstall the app from the vendor's site.

## License

Scripts and patch: MIT (see `LICENSE`). Vazirmatn font: SIL Open Font License
1.1 (`patch/fonts/LICENSE-Vazirmatn.md`).
