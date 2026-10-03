#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
UI_REL="resources/orchestrator/ui"

usage() {
  cat <<'USAGE'
Linux — patch a Freebuff AppImage

    ./linux/apply-appimage.sh                 auto-detect + patch in place
    ./linux/apply-appimage.sh --check         only report (exit 1 if stock)
    ./linux/apply-appimage.sh --app <file>    explicit AppImage
    ./linux/apply-appimage.sh --out <file>    write the patched copy elsewhere
USAGE
}

APP="${FREEBUFF_APPIMAGE:-}"
OUT=""
CHECK=0
while (($#)); do
  case "$1" in
    --app) APP="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --check) CHECK=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

find_appimage() {
  local c
  for c in "$HOME/.local/bin/Freebuff-RTL.AppImage" \
    "$HOME/.local/bin/"*[Ff]reebuff*.AppImage \
    "$HOME/Applications/"*[Ff]reebuff*.AppImage \
    "$HOME/Downloads/"*[Ff]reebuff*.AppImage; do
    [[ -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

[[ -n "$APP" ]] || APP="$(find_appimage || true)"
if [[ -z "$APP" || ! -f "$APP" ]]; then
  echo "AppImage not found. Pass --app <file> or set FREEBUFF_APPIMAGE=..." >&2
  exit 1
fi
[[ -x "$APP" ]] || chmod +x "$APP"
OUT="${OUT:-$APP}"

check_patched() {
  local tmp
  tmp="$(mktemp -d /tmp/fbrtl-check.XXXXXX)"
  local rc=1
  if (cd "$tmp" && "$1" --appimage-extract "$UI_REL/index.html" >/dev/null 2>&1) &&
    grep -q 'freebuff-rtl.css' "$tmp/squashfs-root/$UI_REL/index.html" 2>/dev/null; then
    rc=0
  fi
  rm -rf "$tmp"
  return $rc
}

if [[ $CHECK -eq 1 ]]; then
  if check_patched "$APP"; then
    echo "patched:     $APP"
    exit 0
  fi
  echo "not patched: $APP"
  exit 1
fi

TOOL="${APPIMAGETOOL:-}"
if [[ -z "$TOOL" ]]; then
  for c in "$ROOT/tools/appimagetool.AppImage" "$(command -v appimagetool || true)"; do
    [[ -n "$c" && -e "$c" ]] && { TOOL="$c"; break; }
  done
fi
if [[ -z "$TOOL" ]]; then
  echo "appimagetool not found — run 'tools/get-appimagetool.sh' first, or set APPIMAGETOOL=/path/to/appimagetool." >&2
  exit 1
fi

ARCH_APPIMAGE="$(uname -m)"
case "$ARCH_APPIMAGE" in
  aarch64 | arm64) ARCH_APPIMAGE="aarch64" ;;
  armv7l) ARCH_APPIMAGE="armhf" ;;
  *) ARCH_APPIMAGE="x86_64" ;;
esac

WORK="$(mktemp -d /tmp/fbrtl-build.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

echo "[1/4] Extracting $(basename "$APP")"
(cd "$WORK" && "$APP" --appimage-extract >/dev/null)

APPDIR="$WORK/squashfs-root"
UI="$APPDIR/$UI_REL"
if [[ ! -d "$UI" ]]; then
  echo "AppImage layout changed — '$UI_REL' not found." >&2
  exit 1
fi

echo "[2/4] Copying patch into the UI"
install -m 644 "$ROOT/patch/rtl.css" "$UI/freebuff-rtl.css"
install -m 644 "$ROOT/patch/rtl.js" "$UI/freebuff-rtl.js"
mkdir -p "$UI/fonts/freebuff-rtl"
cp -f "$ROOT/patch/fonts/"*.woff2 "$UI/fonts/freebuff-rtl/"

IDX="$UI/index.html"
if grep -q 'freebuff-rtl.css' "$IDX" && grep -q 'freebuff-rtl.js' "$IDX"; then
  echo "        index.html already linked"
elif command -v node >/dev/null 2>&1; then
  node "$ROOT/tools/inject.mjs" "$UI"
else
  grep -v 'freebuff-rtl\.\(css\|js\)' "$IDX" >"$IDX.tmp" && mv "$IDX.tmp" "$IDX"
  sed -i '0,/<\/head>/s|</head>|    <link rel="stylesheet" href="./freebuff-rtl.css" />\n    <script defer src="./freebuff-rtl.js"></script>\n  </head>|' "$IDX"
  echo "        index.html linked (without Node)"
fi
grep -q 'freebuff-rtl.css' "$IDX" || { echo "Failed to link the patch." >&2; exit 1; }

echo "[3/4] Repacking"
TMPOUT="${OUT}.building"
rm -f "$TMPOUT"
if ! ARCH="$ARCH_APPIMAGE" "$TOOL" --no-appstream "$APPDIR" "$TMPOUT" >>"$ROOT/build.log" 2>&1; then
  if [[ "$TOOL" == *.AppImage ]]; then
    ARCH="$ARCH_APPIMAGE" "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$TMPOUT" >>"$ROOT/build.log" 2>&1 || true
  fi
fi
if [[ ! -s "$TMPOUT" ]]; then
  echo "Repacking failed — details: $ROOT/build.log" >&2
  exit 1
fi
chmod +x "$TMPOUT"

echo "[4/4] Verifying the output"
if ! check_patched "$TMPOUT"; then
  echo "Verification failed: the patch is not active inside the built AppImage." >&2
  rm -f "$TMPOUT"
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
mv -f "$TMPOUT" "$OUT"
echo "Done: $OUT ($(du -h "$OUT" | cut -f1))"
