#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"

usage() {
  cat <<'USAGE'
Linux — install a menu entry (and optionally a terminal command)

    ./linux/install-desktop.sh              menu entry only
    ./linux/install-desktop.sh --command    + symlink ~/.local/bin/freebuff-rtl
    ./linux/install-desktop.sh --remove     undo both
USAGE
}

APPS="$HOME/.local/share/applications"
DESKTOP="$APPS/freebuff.desktop"
BIN="$HOME/.local/bin/freebuff-rtl"
# Icon: the user may drop their own icon here (see README); otherwise it is
# extracted from the AppImage once and stored next to it.
ICON_USER="$HOME/.local/icons/freebuff.png"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON="$ICON_DIR/freebuff-rtl.png"

COMMAND=0
REMOVE=0
while (($#)); do
  case "$1" in
    --command) COMMAND=1; shift ;;
    --remove) REMOVE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ $REMOVE -eq 1 ]]; then
  rm -f "$DESKTOP" "$BIN" "$ICON"
  # never delete the user's own icon
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true
  echo "Removed: $DESKTOP and $BIN"
  exit 0
fi

mkdir -p "$APPS" "$ICON_DIR"
if [[ -f "$ICON_USER" ]]; then
  ICON="$ICON_USER"            # user-provided icon wins, used by absolute path
fi
find_appimage() {
  local c
  for c in "${FREEBUFF_APPIMAGE:-}" \
    "$HOME/.local/bin/Freebuff-RTL.AppImage" \
    "$HOME/.local/bin/"*[Ff]reebuff*.AppImage; do
    [[ -n "$c" && -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}
APP="$(find_appimage || true)"
if [[ -n "$APP" && ! -f "$ICON" ]]; then
  TMP="$(mktemp -d /tmp/fbrtl-icon.XXXXXX)"
  if (cd "$TMP" && "$APP" --appimage-extract >/dev/null 2>&1); then
    SRC="$(find "$TMP/squashfs-root" -maxdepth 4 \( -name '.DirIcon' -o -iname '*.png' \) -size +1k 2>/dev/null | head -1 || true)"
    [[ -n "$SRC" ]] && cp -Lf "$SRC" "$ICON" || true
  fi
  rm -rf "$TMP"
fi

{
  echo '[Desktop Entry]'
  echo 'Type=Application'
  echo 'Name=Freebuff RTL'
  echo 'Comment=Freebuff with Persian font and RTL chat'
  echo "Exec=\"$ROOT/linux/launch.sh\" %U"
  echo 'Terminal=false'
  echo 'Categories=Development;'
  echo 'StartupWMClass=Freebuff'
  if [[ -f "$ICON" ]]; then
    if [[ "$ICON" == "$ICON_USER" ]]; then
      echo "Icon=$ICON"      # absolute path for the user's own file
    else
      echo 'Icon=freebuff-rtl'
    fi
  fi
} >"$DESKTOP"
chmod 644 "$DESKTOP"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true
echo "Desktop entry created: $DESKTOP"

if [[ $COMMAND -eq 1 ]]; then
  mkdir -p "$(dirname "$BIN")"
  ln -sfn "$ROOT/linux/launch.sh" "$BIN"
  echo "Command created: $BIN"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "Note: ~/.local/bin is not in PATH — add it to your PATH." ;;
  esac
fi
