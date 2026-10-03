#!/bin/bash
set -uo pipefail

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(cd "$(dirname "$SELF")" && pwd)/$(readlink "$SELF")"; done
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
APPLY="$ROOT/macos/apply-macos.sh"

usage() {
  cat <<'USAGE'
macOS — launch Freebuff with the Persian patch

    ./macos/launch.command              patch if needed, then open the app
    ./macos/launch.command --status     report the state
    ./macos/launch.command --restart    quit the running app, then open it
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
esac

APP="${FREEBUFF_APP:-}"
if [[ -z "$APP" ]]; then
  for c in "$HOME/Applications/Freebuff.app" /Applications/Freebuff.app /Applications/Freebuff*.app; do
    [[ -d "$c" ]] && { APP="$c"; break; }
  done
fi
[[ -n "$APP" && -d "$APP" ]] || { echo "Freebuff.app not found — set FREEBUFF_APP=/path/to/Freebuff.app." >&2; exit 1; }

status() {
  echo "App      : $APP"
  if "$APPLY" --app "$APP" --check --quiet; then echo "RTL patch: applied ✅"; else echo "RTL patch: not applied"; fi
  if pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1; then echo "Running  : yes"; else echo "Running  : no"; fi
}

case "${1:-}" in
  --status | -s) status; exit 0 ;;
  --restart | -r)
    if pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1; then
      NAME="$(basename "$APP" .app)"
      echo "Quitting $NAME…"
      osascript -e "quit app \"$NAME\"" >/dev/null 2>&1 || pkill -f "$APP/Contents/MacOS" || true
      for _ in $(seq 1 20); do pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1 || break; sleep 0.5; done
    fi
    ;;
esac

if ! "$APPLY" --app "$APP" --check --quiet; then
  echo "RTL patch missing — building it…"
  "$APPLY" --app "$APP" --quiet || echo "Patching failed; starting the app without the patch." >&2
fi

set --
open "$APP" 2>/dev/null || open -a "$APP" 2>/dev/null || {
  echo "Could not open the app — open it once manually and grant the Gatekeeper permission." >&2
  exit 1
}
