#!/usr/bin/env bash
set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"

usage() {
  cat <<'USAGE'
./linux/launch.sh             patch if needed, then start the app
./linux/launch.sh --status    report patch state and running instance
./linux/launch.sh --restart   close the running app, start the patched one
./linux/launch.sh -- <args>   pass arguments through to the app
USAGE
}

find_appimage() {
  local c
  for c in "${FREEBUFF_APPIMAGE:-}" \
    "$HOME/.local/bin/Freebuff-RTL.AppImage" \
    "$HOME/.local/bin/"*[Ff]reebuff*.AppImage \
    "$HOME/Applications/"*[Ff]reebuff*.AppImage; do
    [[ -n "$c" && -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

find_dir_install() {
  local c
  for c in "${FREEBUFF_ROOT:-}" \
    "$HOME/.local/opt/Freebuff" "$HOME/.local/opt/freebuff" \
    /opt/Freebuff /opt/freebuff /usr/lib/freebuff; do
    [[ -n "$c" && -f "$c/resources/orchestrator/ui/index.html" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

APPIMAGE="$(find_appimage || true)"
TARGET=""
if [[ -z "$APPIMAGE" ]]; then
  TARGET="$(find_dir_install || true)"
fi

app_binary() {
  local d="$1" c
  for c in "$d/freebuff" "$d/freebuff-desktop" "$d/Freebuff"; do
    [[ -x "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  find "$d" -maxdepth 3 -type f -name '*reebuff*' -perm -u+x 2>/dev/null | head -1
}

patched() {
  if [[ -n "$APPIMAGE" ]]; then
    "$ROOT/linux/apply-appimage.sh" --check >/dev/null 2>&1
  elif [[ -n "$TARGET" ]]; then
    node "$ROOT/tools/apply.mjs" --root "$TARGET" --check --quiet >/dev/null 2>&1
  else
    return 1
  fi
}

running() { pgrep -f 'mount_Freebu[^/]*/@codebufffreebuff-desktop' 2>/dev/null || pgrep -f 'freebuff-desktop' 2>/dev/null || true; }

show_status() {
  if [[ -n "$APPIMAGE" ]]; then
    echo "Install    : AppImage — $APPIMAGE"
  elif [[ -n "$TARGET" ]]; then
    echo "Install    : directory — $TARGET"
  else
    echo "Install    : not found (set FREEBUFF_APPIMAGE or FREEBUFF_ROOT)"
    return
  fi
  if patched; then echo "RTL patch : applied ✅"; else echo "RTL patch : not applied — will build on next launch"; fi
  if [[ -n "$(running)" ]]; then echo "Running    : yes"; else echo "Running    : no"; fi
}

RESTART=0
case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  --status | -s) show_status; exit 0 ;;
  --restart | -r) RESTART=1; shift ;;
  --) shift ;;
  -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

if [[ -z "$APPIMAGE" && -z "$TARGET" ]]; then
  echo "Freebuff not found. Set FREEBUFF_APPIMAGE=/path/to/Freebuff.AppImage or FREEBUFF_ROOT=/opt/Freebuff." >&2
  exit 1
fi

if [[ $RESTART -eq 1 && -n "$(running)" ]]; then
  echo "Closing the running instance…"
  pkill -TERM -f 'mount_Freebu[^/]*/@codebufffreebuff-desktop' 2>/dev/null || true
  pkill -TERM -f 'freebuff-desktop' 2>/dev/null || true
  for _ in $(seq 1 30); do [[ -z "$(running)" ]] && break; sleep 0.5; done
  sleep 1
fi

if ! patched; then
  echo "RTL patch missing — building it…"
  if [[ -n "$APPIMAGE" ]]; then
    "$ROOT/linux/apply-appimage.sh" --app "$APPIMAGE" || {
      echo "Patching failed; starting the app without the patch." >&2
    }
  else
    node "$ROOT/tools/apply.mjs" --root "$TARGET" || echo "Patching failed; starting the app without the patch." >&2
  fi
fi

if [[ -n "$(running)" ]]; then
  echo "Freebuff is already open — bringing its window forward."
fi

if [[ -n "$APPIMAGE" ]]; then
  exec "$APPIMAGE" "$@"
fi

BIN="$(app_binary "$TARGET")"
if [[ -z "$BIN" ]]; then
  echo "App binary not found in $TARGET." >&2
  exit 1
fi
exec "$BIN" "$@"
