#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Linux — patch a *directory* install of Freebuff
#  (deb / rpm / pacman / tar.gz layout, or an AppImage you extracted yourself)
#
#      ./linux/apply-dir.sh                  auto-detect
#      ./linux/apply-dir.sh --root <dir>     explicit (e.g. /opt/Freebuff)
#      ./linux/apply-dir.sh --check          only report
#      ./linux/apply-dir.sh --list           show what was found
#
#  In this layout the files are plain files on disk, so the patch is applied in
#  place: patch/rtl.css + rtl.js + fonts are copied into
#  <app>/resources/orchestrator/ui and linked from index.html. No repack needed.
#  Needs: bash, node (tools/apply.mjs).
# ---------------------------------------------------------------------------
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"

TARGET="${FREEBUFF_ROOT:-}"
MODE="apply"
while (($#)); do
  case "$1" in
    --root) TARGET="${2:-}"; shift 2 ;;
    --check) MODE="check"; shift ;;
    --list) MODE="list"; shift ;;
    -h | --help) sed -n '3,15p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "گزینهٔ ناشناخته: $1" >&2; exit 2 ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "node لازم است (برای tools/apply.mjs)." >&2; exit 1; }

# --- پیدا کردن نصب‌های دایرکتوری -------------------------------------------------
candidates() {
  local c
  for c in \
    "$HOME/.local/opt/Freebuff" "$HOME/.local/opt/freebuff" \
    /opt/Freebuff /opt/freebuff /opt/Freebuff-Desktop /opt/freebuff-desktop \
    /usr/lib/freebuff /usr/share/freebuff; do
    [[ -f "$c/resources/orchestrator/ui/index.html" ]] && printf '%s\n' "$c"
  done
  # هر AppDir استخراج‌شده‌ای که کاربر ساخته باشد
  local d
  for d in "$HOME" /tmp; do
    for c in "$d"/squashfs-root "$d"/*.AppDir; do
      [[ -f "$c/resources/orchestrator/ui/index.html" ]] && printf '%s\n' "$c"
    done
  done
}

if [[ -z "$TARGET" ]]; then
  TARGET="$(candidates | head -1 || true)"
fi
if [[ -z "$TARGET" || ! -f "$TARGET/resources/orchestrator/ui/index.html" ]]; then
  echo "نصب دایرکتوری Freebuff پیدا نشد. با --root مسیر بده (مثلاً /opt/Freebuff)." >&2
  echo "اگر AppImage داری از linux/apply-appimage.sh استفاده کن." >&2
  exit 1
fi

case "$MODE" in
  list)
    echo "نصب‌های پیدا‌شده:"
    candidates | sed 's/^/  /'
    exit 0
    ;;
  check)
    if node "$ROOT/tools/apply.mjs" --root "$TARGET" --check; then exit 0; else exit 1; fi
    ;;
esac

if ! node "$ROOT/tools/apply.mjs" --root "$TARGET"; then
  echo "پچ نشد." >&2
  exit 1
fi
echo "انجام شد. Freebuff را از نو باز کن (اگر در /opt است و اجازه نداشتی، با sudo اجرا کن)."
