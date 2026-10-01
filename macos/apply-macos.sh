#!/usr/bin/env bash
set -euo pipefail

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(cd "$(dirname "$SELF")" && pwd)/$(readlink "$SELF")"; done
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
UI_REL="Contents/Resources/orchestrator/ui"

usage() {
  cat <<'USAGE'
macOS — patch Freebuff.app (and optionally install it from a .dmg / .zip)

    ./macos/apply-macos.sh                       patch the installed app
    ./macos/apply-macos.sh --check               only report
    ./macos/apply-macos.sh --app ~/Applications/Freebuff.app
    ./macos/apply-macos.sh --install ~/Downloads/Freebuff-0.0.155.dmg
USAGE
}

APP="${FREEBUFF_APP:-}"
INSTALL_FROM=""
CHECK=0
QUIET=0
while (($#)); do
  case "$1" in
    --app) APP="${2:-}"; shift 2 ;;
    --install) INSTALL_FROM="${2:-}"; shift 2 ;;
    --check) CHECK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

say() { [[ $QUIET -eq 1 ]] || echo "$@"; }

find_app() {
  local c
  for c in "$HOME/Applications/Freebuff.app" "$HOME/Applications/Freebuff Desktop.app" \
    "/Applications/Freebuff.app" "/Applications/Freebuff Desktop.app" /Applications/Freebuff*.app; do
    [[ -d "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

if [[ -n "$INSTALL_FROM" ]]; then
  [[ -f "$INSTALL_FROM" ]] || { echo "file not found: $INSTALL_FROM" >&2; exit 1; }
  TMP="$(mktemp -d /tmp/fbrtl-install.XXXXXX)"
  trap 'hdiutil detach "$TMP/mnt" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
  case "$INSTALL_FROM" in
    *.dmg)
      mkdir -p "$TMP/mnt"
      hdiutil attach -nobrowse -quiet -mountpoint "$TMP/mnt" "$INSTALL_FROM"
      SRC="$(find "$TMP/mnt" -maxdepth 1 -name '*.app' | head -1)"
      ;;
    *.zip)
      ditto -x -k "$INSTALL_FROM" "$TMP/zip"
      SRC="$(find "$TMP/zip" -maxdepth 2 -name '*.app' | head -1)"
      ;;
    *) SRC="$INSTALL_FROM" ;;
  esac
  [[ -n "${SRC:-}" && -d "$SRC" ]] || { echo "no .app inside $INSTALL_FROM" >&2; exit 1; }
  DEST_DIR="$HOME/Applications"
  [[ -w /Applications ]] && DEST_DIR="/Applications"
  mkdir -p "$DEST_DIR"
  DEST="$DEST_DIR/$(basename "$SRC")"
  say "installing $(basename "$SRC") → $DEST"
  rm -rf "$DEST"
  ditto "$SRC" "$DEST"
  APP="$DEST"
fi

[[ -n "$APP" ]] || APP="$(find_app || true)"
[[ -n "$APP" && -d "$APP" ]] || { echo "Freebuff.app not found — pass --app /path/to/Freebuff.app" >&2; exit 1; }

UI="$APP/$UI_REL"
[[ -f "$UI/index.html" ]] || { echo "not a Freebuff app: $UI/index.html missing" >&2; exit 1; }

is_patched() {
  [[ -f "$UI/freebuff-rtl.css" && -f "$UI/freebuff-rtl.js" ]] &&
    grep -q 'freebuff-rtl.css' "$UI/index.html" &&
    grep -q 'freebuff-rtl.js' "$UI/index.html"
}

if [[ $CHECK -eq 1 ]]; then
  if is_patched; then say "patched:     $APP"; exit 0; else say "not patched: $APP"; exit 1; fi
fi

if ! is_patched; then
  say "patching $APP"
  install -m 644 "$ROOT/patch/rtl.css" "$UI/freebuff-rtl.css"
  install -m 644 "$ROOT/patch/rtl.js" "$UI/freebuff-rtl.js"
  mkdir -p "$UI/fonts/freebuff-rtl"
  cp -f "$ROOT/patch/fonts/"*.woff2 "$UI/fonts/freebuff-rtl/"

  if command -v node >/dev/null 2>&1; then
    node "$ROOT/tools/inject.mjs" "$UI" >/dev/null
  else
    IDX="$UI/index.html"
    grep -v 'freebuff-rtl\.\(css\|js\)' "$IDX" >"$IDX.tmp" && mv "$IDX.tmp" "$IDX"
    sed -i '' 's|</head>|    <link rel="stylesheet" href="./freebuff-rtl.css" />\
    <script defer src="./freebuff-rtl.js"></script>\
  </head>|' "$IDX"
  fi
fi
is_patched || { echo "patch verification failed" >&2; exit 1; }

if command -v codesign >/dev/null 2>&1; then
  say "re-signing (ad-hoc)…"
  codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || say "  (codesign warned — app usually still runs)"
fi
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

say "done: $APP"
