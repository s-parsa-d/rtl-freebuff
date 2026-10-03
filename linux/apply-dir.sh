#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"

usage() {
  cat <<'USAGE'
Linux — patch a directory install of Freebuff

    ./linux/apply-dir.sh                  auto-detect
    ./linux/apply-dir.sh --root <dir>     explicit (e.g. /opt/Freebuff)
    ./linux/apply-dir.sh --check          only report
    ./linux/apply-dir.sh --list           show what was found
USAGE
}

TARGET="${FREEBUFF_ROOT:-}"
MODE="apply"
while (($#)); do
  case "$1" in
    --root) TARGET="${2:-}"; shift 2 ;;
    --check) MODE="check"; shift ;;
    --list) MODE="list"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "node is required (for tools/apply.mjs)." >&2; exit 1; }

candidates() {
  local c
  for c in \
    "$HOME/.local/opt/Freebuff" "$HOME/.local/opt/freebuff" \
    /opt/Freebuff /opt/freebuff /opt/Freebuff-Desktop /opt/freebuff-desktop \
    /usr/lib/freebuff /usr/share/freebuff; do
    [[ -f "$c/resources/orchestrator/ui/index.html" ]] && printf '%s\n' "$c"
  done
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
  echo "Freebuff directory install not found. Pass --root <dir> (e.g. /opt/Freebuff)." >&2
  echo "If you have the AppImage, use linux/apply-appimage.sh instead." >&2
  exit 1
fi

case "$MODE" in
  list)
    echo "Found installs:"
    candidates | sed 's/^/  /'
    exit 0
    ;;
  check)
    if node "$ROOT/tools/apply.mjs" --root "$TARGET" --check; then exit 0; else exit 1; fi
    ;;
esac

if ! node "$ROOT/tools/apply.mjs" --root "$TARGET"; then
  echo "Patching failed." >&2
  exit 1
fi
echo "Done. Restart Freebuff (if it lives in /opt and you lack permission, rerun with sudo)."
