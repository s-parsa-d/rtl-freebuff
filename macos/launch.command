#!/bin/bash
# ---------------------------------------------------------------------------
#  macOS — launch Freebuff with the Persian patch
#
#      ./macos/launch.command              patch if needed, then open the app
#      ./macos/launch.command --status     report the state
#      ./macos/launch.command --restart    quit the running app, then open it
#
#  Double-click this file (or put an alias of it in the Dock and use that
#  instead of the Freebuff icon) so an app update never leaves you unpatched.
#  The updater replaces Freebuff.app — the patch files vanish with it and this
#  wrapper simply rebuilds them.
# ---------------------------------------------------------------------------
set -uo pipefail

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(cd "$(dirname "$SELF")" && pwd)/$(readlink "$SELF")"; done
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
APPLY="$ROOT/macos/apply-macos.sh"

case "${1:-}" in
  -h | --help) sed -n '4,11p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

APP="${FREEBUFF_APP:-}"
if [[ -z "$APP" ]]; then
  for c in "$HOME/Applications/Freebuff.app" /Applications/Freebuff.app /Applications/Freebuff*.app; do
    [[ -d "$c" ]] && { APP="$c"; break; }
  done
fi
[[ -n "$APP" && -d "$APP" ]] || { echo "Freebuff.app پیدا نشد — FREEBUFF_APP=/path/to/Freebuff.app بده." >&2; exit 1; }

status() {
  echo "اپ      : $APP"
  if "$APPLY" --app "$APP" --check --quiet; then echo "پچ فارسی: اعمال‌شده ✅"; else echo "پچ فارسی: اعمال‌نشده"; fi
  if pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1; then echo "اجرا    : بله"; else echo "اجرا    : نه"; fi
}

case "${1:-}" in
  --status | -s) status; exit 0 ;;
  --restart | -r)
    if pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1; then
      NAME="$(basename "$APP" .app)"
      echo "بستن «$NAME»…"
      osascript -e "quit app \"$NAME\"" >/dev/null 2>&1 || pkill -f "$APP/Contents/MacOS" || true
      for _ in $(seq 1 20); do pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1 || break; sleep 0.5; done
    fi
    ;;
esac

# --- پچ در صورت آپدیت ---------------------------------------------------------
if ! "$APPLY" --app "$APP" --check --quiet; then
  echo "پچ فارسی ساخته نشده — ساخته می‌شود…"
  "$APPLY" --app "$APP" --quiet || echo "پچ نشد؛ اپ بدون پچ اجرا می‌شود." >&2
fi

set --
open "$APP" 2>/dev/null || open -a "$APP" 2>/dev/null || {
  echo "اجرای اپ نشد — یک‌بار خودش را باز کن و اجازهٔ Gatekeeper بده." >&2
  exit 1
}
