#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Download appimagetool (used by linux/apply-appimage.sh to repack AppImages).
#
#      ./tools/get-appimagetool.sh
#
#  It lands in tools/appimagetool.AppImage and is intentionally NOT committed
#  (see .gitignore) — it is an upstream binary, ~8 MB, and only Linux needs it.
# ---------------------------------------------------------------------------
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
echo "دانلود $URL"
curl -fL --retry 3 --progress-bar -o "$DEST" "$URL"
chmod +x "$DEST"

# با --version تستش می‌کنیم (اگر FUSE نبود، حالت استخراج‌و‌اجرا)
if "$DEST" --version >/dev/null 2>&1 || "$DEST" --appimage-extract-and-run --version >/dev/null 2>&1; then
  echo "آماده است: $DEST"
else
  echo "دانلود شد ولی اجرا نشد — ممکن است FUSE نصب نباشد؛ apply-appimage.sh خودش حالت جایگزین را امتحان می‌کند." >&2
fi
