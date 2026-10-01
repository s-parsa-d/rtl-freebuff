# Freebuff RTL — Technical notes

Design and implementation details for the Persian (RTL) patch of the Freebuff
desktop app. The per-file comments were moved here so the source stays clean.

## 1. Overview

The patch does three things and nothing else:

1. Persian text is rendered with **Vazirmatn** (bundled, works offline).
2. The chat transcript and the composer are right-aligned, with correct
   bidirectional ordering (`unicode-bidi: plaintext`).
3. Short Persian UI strings (sidebar, menus, settings, thread titles) get
   `dir="rtl"` and are right-aligned; Latin strings are left untouched.

Everything is **additive**. The patch never rewrites a file that belongs to the
app. It adds exactly:

```
resources/orchestrator/ui/freebuff-rtl.css
resources/orchestrator/ui/freebuff-rtl.js
resources/orchestrator/ui/fonts/freebuff-rtl/*.woff2
```

and links the first two from `index.html`.

## 2. Font strategy

The app loads its UI font (`Google Sans`) as ~50 `@font-face` subsets — Latin,
Cyrillic, Greek, Hebrew, Devanagari, Bengali, … — but **none covers the
Arabic/Persian range**. Persian text therefore fell back to a system font and
looked bad.

The patch declares extra `@font-face` rules for the *same* family name
(`Google Sans`) that are limited to the Arabic/Persian `unicode-range`
(`U+0600-06FF`, `U+0750-077F`, `U+0870-08E1`, `U+08E3-08FF`, `U+FB50-FDFF`,
`U+FE70-FEFF`). Because no bundled subset claims that range, font matching
selects the patched face only for Persian glyphs:

- Latin characters → the app's own font (visual layer unchanged).
- Persian characters → Vazirmatn.

This is exactly the subsetting mechanism the app already uses, so no global
`font-family`, no `!important` override of the app's CSS, and no `dir="rtl"` on
`<html>` are needed for the font layer. Four weights (400/500/600/700) are
declared, plus italic faces so Persian italic text is not synthetically
slanted.

A `--fb-fa-font` custom property lists the app font first (so Latin stays
identical) followed by `"Freebuff Vazir"`, and is applied under `.messages` and
`.composer`.

## 3. Chat RTL (CSS)

`freebuff-rtl.css` right-aligns the message text and forces direction on:

- `.messages .msg.user .user-message-text`
- `.messages .msg.assistant .prose` block elements

with `direction: rtl; unicode-bidi: plaintext`. `plaintext` lets each paragraph
derive its base direction from its own first strong character, so an English
sentence inside Persian prose neither jumps position nor throws its punctuation
to the wrong side.

Code, terminal and diff "islands" inside chat stay left-aligned, monospace and
isolated:

```
pre, code, kbd, samp, .md-code, .md-code *, .md-inline,
.xterm, .xterm *, .tool-row-details, .tool-row-details *
```

Lists and blockquotes get their padding/border mirrored to the right edge.

The composer is a `contenteditable` (class `composer-input`), not a `textarea`.
Until `rtl.js` sets a direction it defaults to RTL; when the first strong
character is Latin, `rtl.js` sets `dir="ltr"` so an English prompt reads
naturally. The empty state stays LTR so the app's English placeholder is
untouched.

Global monospace exclusions (`.xterm`, `.cm-editor`, `.monaco-editor`, the
logos) preserve the app's DM Mono and the Freebuff logo.

## 4. Auto direction (`freebuff-rtl.js`)

A small observer that:

- On input/composition/focus/click and on DOM mutation, computes the direction
  of the composer text from its **first strong character**
  (`RTL_CHAR`/`LTR_CHAR` regexes; digits, spaces and punctuation are neutral).
  Empty → `rtl`.
- Walks leaf elements of `body` and gives `dir="rtl"` to any whose trimmed text
  is Persian, skipping `.composer`, `.messages`, terminals, editors, `pre`/`code`
  and the logos.

Directions only are set; nothing outside the composer and short UI leaves is
touched, and the whole script is wrapped in `try/catch` so a failure can never
break the app.

## 5. `index.html` injection

`tools/inject.mjs` (Node) appends, once, before `</head>`:

```html
    <link rel="stylesheet" href="./freebuff-rtl.css" />
    <script defer src="./freebuff-rtl.js"></script>
```

It is idempotent: it strips any previous copy of those tags first, and aborts if
`index.html` has no `</head>` (UI layout changed). The `windows/*.ps1` patcher
does the same with `[regex]::Replace`.

## 6. Platform installers

All platform patchers ultimately write the three patch artifacts into the UI
directory and link them from `index.html`; the shared Node implementation is
`tools/apply.mjs`.

| Platform | Entry point | Mechanism |
|---|---|---|
| Linux / AppImage | `linux/apply-appimage.sh` | AppImage is read-only squashfs → extract, copy patch, repack with `appimagetool`, re-verify. |
| Linux / directory | `linux/apply-dir.sh` | deb/rpm/pacman/tar layout → patch plain files in place via `tools/apply.mjs`. |
| macOS | `macos/apply-macos.sh` | patch `Freebuff.app/Contents/Resources/orchestrator/ui`, then **ad-hoc re-sign** (`codesign --force --deep --sign -`) because editing a bundle invalidates its signature; clears the quarantine flag. Can install from `.dmg`/`.zip` first. |
| Windows | `windows/apply-windows.ps1` | pure PowerShell, no Node: locate the install (incl. `@codebufffreebuff-desktop`), copy the patch, inject the tags. |

Known Windows install layouts:

- electron-builder / NSIS: `%LOCALAPPDATA%\Programs\<name>\resources\orchestrator\ui`
- Squirrel: `%LOCALAPPDATA%\Freebuff\app-<version>\resources\...`
- Program Files: `%ProgramFiles%\<name>\resources\...`

The real electron-builder folder name is `@codebufffreebuff-desktop`, so every
Windows script must probe it.

## 7. Update resilience

Freebuff's updater rewrites the installed files, which deletes the patch. Each
platform therefore ships a launcher that runs the patcher when the artifacts are
missing, then starts the app:

- Linux: `linux/launch.sh` (+ menu entry / `freebuff-rtl` command via
  `linux/install-desktop.sh`).
- macOS: `macos/launch.command`; optionally `macos/install-launchagent.sh`
  registers a LaunchAgent with `RunAtLoad` and `WatchPaths` on the app bundle.
- Windows: `windows/launch-windows.ps1`; `windows/install-shortcut.ps1` creates
  the Desktop/Start-menu shortcut that runs it hidden.

The launcher's check is simple: if the patch artifacts are gone, the app was
updated, so rebuild the patch before starting.

## 8. Limitations

- UI inside a shadow DOM is not reached by the CSS; extend `freebuff-rtl.css`
  or file an issue naming the section.
- The Windows `-Install` path unpacks an electron-builder setup with 7-Zip and
  patches the extracted tree, but a normal install afterwards overwrites it;
  the launcher re-patches the real install anyway, so that path is only useful
  for inspection.
- The macOS scripts were written to standard paths but have not been tested on
  real hardware.
