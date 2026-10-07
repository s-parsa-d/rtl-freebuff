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

## Quick start

```bash
git clone https://github.com/s-parsa-d/rtl-freebuff.git
cd rtl-freebuff
```

Then run **one patch command**, and from then on start the app through the
project's launcher:

| System | Patch the app | Then start it with |
|---|---|---|
| Linux — AppImage | `./tools/get-appimagetool.sh` then `./linux/apply-appimage.sh` | `./linux/install-desktop.sh --command`, then `freebuff-rtl` |
| Linux — deb / rpm / pacman / tar | `./linux/apply-dir.sh` (add `--root /opt/Freebuff` if needed) | `./linux/launch.sh` |
| macOS | `./macos/apply-macos.sh` | `./macos/launch.command` |
| Windows (PowerShell) | `.\windows\apply-windows.ps1` | `.\windows\install-shortcut.ps1`, then the **Freebuff RTL** shortcut |

Confirm it worked:

```bash
./linux/apply-appimage.sh --check      # or: ./macos/apply-macos.sh --check
```

That is the whole flow. The launcher is not optional: Freebuff's updater deletes
the patch on every update, and the launcher puts it back before starting the app
(see [After every update](#after-every-update-important)).

**Requirements:** a POSIX shell with `git` and `curl` for Linux/macOS — plus
**Node.js** for the Linux directory install (`apply-dir.sh`) — or **PowerShell
5.1+** on Windows. The Persian fonts are bundled, so nothing else is downloaded
after the clone. If macOS asks for permission on the first run, see
[macOS permissions](#macos-permissions-one-time).

## Install

### Linux — AppImage 

```bash
cd rtl-freebuff                                         # from the Quick start clone
./tools/get-appimagetool.sh                 # run once; fetches the packaging tool
./linux/apply-appimage.sh                    # find and patch the AppImage (in place)
./linux/install-desktop.sh --command # menu entry + `freebuff-rtl` command
freebuff-rtl                                              # run (auto-repatch on update, then start)
```

**Menu icon:** put your own icon at
`~/.local/icons/freebuff.png` **before** running `install-desktop.sh` and the
menu entry will use exactly that file. If the file is not there, the script
extracts the app's own icon from the AppImage once and installs it into
`~/.local/share/icons/hicolor/256x256/apps/freebuff-rtl.png`. If the app is not
visible in the launcher menu right away, log out and back in (or `Alt+F2` → `r`
on X11).

An AppImage is a read-only squashfs, so the patch is baked in: extract → copy the
patch → repack → verify. If the app is somewhere unusual, use
`./linux/apply-appimage.sh --app /path/Freebuff.AppImage` or `FREEBUFF_APPIMAGE=...`.

### Linux — directory install (deb / rpm / pacman / tar)

```bash
./linux/apply-dir.sh                 # finds /opt/Freebuff and ~/.local/opt/... itself
sudo ./linux/apply-dir.sh --root /opt/Freebuff   # if installed under /opt
```

### macOS — Apple Silicon and Intel 

```bash
./macos/apply-macos.sh                       # patch the installed Freebuff.app
./macos/apply-macos.sh --install ~/Downloads/Freebuff-0.0.155.dmg   # install from dmg + patch
./macos/launch.command                       # run (auto-repatch on update, then start)
./macos/install-launchagent.sh               # (optional) auto-patch after every update/login
```

The patch writes *inside* the `Freebuff.app` bundle, which invalidates the
vendor's code signature, so the script re-signs the bundle **ad-hoc** afterwards
(`codesign --force --deep --sign -`) and clears the quarantine flag. Because the
app is therefore no longer signed by an identified developer, macOS asks you to
allow it **once** — the exact prompts and the one-line fixes are in
[macOS permissions](#macos-permissions-one-time) below.

#### macOS permissions (one-time)

macOS protects application bundles, so the first run asks for permission. Grant
it once and `launch.command` (or the LaunchAgent) works silently afterwards.

| What macOS shows | When | How to allow it |
|---|---|---|
| *“… would like to administer applications on your Mac”*, or the patch fails with `Operation not permitted` | while patching, when the app lives in `/Applications` | **System Settings → Privacy & Security → App Management** → turn on your terminal app (Terminal / iTerm / VS Code), then re-run the script |
| *“Apple could not verify ‘Freebuff’ is free of malware”* or *“Freebuff is damaged and can't be opened”* | first launch after patching (the ad-hoc signature is not from an identified developer) | **Finder → right-click the app → Open → Open** (once), or **System Settings → Privacy & Security → Open Anyway** |
| *“Terminal wants access to control Freebuff”* | `./macos/launch.command --restart` (it uses `osascript` to quit the app first) | click **OK**, or allow your terminal under **Privacy & Security → Automation** |

If the script still cannot write into the bundle, give your terminal **Full Disk
Access** (Privacy & Security → Full Disk Access) and run it again. These are all
one-time prompts tied to your terminal app, not to Freebuff.

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

## Troubleshooting

- **The patch has no effect:** close the app completely and open it from the
  launcher. Freebuff is single-instance; if its window is open, running it again
  just brings that window forward.
- **macOS: “Operation not permitted” while patching, or macOS refuses to write
  into the `.app`:** your terminal lacks **App Management** permission — allow it
  in System Settings → Privacy & Security (see
  [macOS permissions](#macos-permissions-one-time)) and re-run the script.
- **macOS: the app is blocked on first launch:** this is expected after the
  ad-hoc re-sign. Right-click the app → **Open** once, or use Privacy & Security →
  **Open Anyway**. Re-running `./macos/apply-macos.sh` clears the quarantine flag
  again if it comes back after an update.
- **macOS: the UI lost the Persian patch after an update:** the updater
  replaced the bundle, so the patch went with it. Re-run `./macos/apply-macos.sh`
  (or just `./macos/launch.command`, which patches on demand) and confirm with
  `./macos/apply-macos.sh --check`.
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

## Getting help

If you hit an error on any platform, please open an issue. 

## License

Scripts and patch: MIT (see `LICENSE`). Vazirmatn font: SIL Open Font License
1.1 (`patch/fonts/LICENSE-Vazirmatn.md`).
