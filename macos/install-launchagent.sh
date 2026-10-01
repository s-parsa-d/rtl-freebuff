#!/bin/bash
# ---------------------------------------------------------------------------
#  macOS — keep the patch alive without you thinking about it (optional)
#
#      ./macos/install-launchagent.sh            install + load the agent
#      ./macos/install-launchagent.sh --remove   unload + delete it
#
#  It writes ~/Library/LaunchAgents/com.freebuff.rtl.plist with:
#    • RunAtLoad   — repatch at login
#    • WatchPaths  — repatch whenever Freebuff.app changes, which is exactly
#                    what an app update does (the new bundle drops the patch)
#  The agent calls apply-macos.sh --quiet, so it stays silent.
# ---------------------------------------------------------------------------
set -euo pipefail

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(cd "$(dirname "$SELF")" && pwd)/$(readlink "$SELF")"; done
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
LABEL="com.freebuff.rtl"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

APP="${FREEBUFF_APP:-}"
if [[ -z "$APP" ]]; then
  for c in "$HOME/Applications/Freebuff.app" /Applications/Freebuff.app /Applications/Freebuff*.app; do
    [[ -d "$c" ]] && { APP="$c"; break; }
  done
fi
[[ -n "$APP" && -d "$APP" ]] || { echo "Freebuff.app پیدا نشد — FREEBUFF_APP=/Applications/Freebuff.app بده." >&2; exit 1; }

if [[ "${1:-}" == "--remove" ]]; then
  launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || launchctl unload "$PLIST" >/dev/null 2>&1 || true
  rm -f "$PLIST"
  echo "حذف شد: $PLIST"
  exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents"
cat >"$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$ROOT/macos/apply-macos.sh</string>
    <string>--app</string>
    <string>$APP</string>
    <string>--quiet</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>WatchPaths</key>
  <array><string>$APP</string></array>
  <key>LowPriorityIO</key><true/>
</dict>
</plist>
PLIST_EOF

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
if ! launchctl bootstrap "gui/$(id -u)" "$PLIST" >/dev/null 2>&1; then
  launchctl load "$PLIST" >/dev/null 2>&1 || true
fi
echo "نصب شد: $PLIST"
echo "هر بار Freebuff آپدیت شود یا وارد سیستم شوی، پچ خودکار برمی‌گردد."
