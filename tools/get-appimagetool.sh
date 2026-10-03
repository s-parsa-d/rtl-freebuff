#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
DEST="$ROOT/tools/appimagetool.AppImage"

case "$(uname -m)" in
  aarch64 | arm64) ARCH="aarch64" ;;
  armv7l) ARCH="armhf" ;;
  *) ARCH="x86_64" ;;
esac

URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
echo "Downloading $URL"
curl -fL --retry 3 --progress-bar -o "$DEST" "$URL"
chmod +x "$DEST"

if "$DEST" --version >/dev/null 2>&1 || "$DEST" --appimage-extract-and-run --version >/dev/null 2>&1; then
  echo "Ready: $DEST"
else
  echo "Downloaded but could not run it — FUSE may be missing; apply-appimage.sh falls back to --appimage-extract-and-run automatically." >&2
fi
