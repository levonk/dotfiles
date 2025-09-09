#!/usr/bin/env sh
# Portable keyboard setup for X11 and Wayland sessions (user-scope, home-only)
# - X11: applies ~/.Xmodmap if present
# - Wayland: apply per-DE/compositor settings using user config from
#   ~/.config/keyboard/options.conf (layout, options). No /etc writes.
#   Many Xmodmap remaps are not portable to Wayland. Prefer DE/compositor-native config.
#
# This script is idempotent per-process via env flag and safe to call from:
# - ~/.xprofile, ~/.xinitrc
# - ~/.config/autostart/*.desktop
# - Shared shell rc (with guards)

set -eu

# Avoid repeated application in the same process chain
if [ "${KEYBOARD_SETUP_RAN:-0}" = "1" ]; then
  exit 0
fi
export KEYBOARD_SETUP_RAN=1

is_cmd() { command -v "$1" >/dev/null 2>&1; }

SESSION_TYPE="${XDG_SESSION_TYPE:-}"
CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}"

# Read user options (layout, options) from ~/.config/keyboard/options.conf
CONF_FILE="$HOME/.config/keyboard/options.conf"
KB_LAYOUT=""
KB_OPTIONS=""
if [ -r "$CONF_FILE" ]; then
  # shellcheck disable=SC2162
  while IFS='=' read key val; do
    case "${key%%#*}" in
      layout) KB_LAYOUT="${val%%#*}" ;;
      options) KB_OPTIONS="${val%%#*}" ;;
    esac
  done < "$CONF_FILE"
  KB_LAYOUT="$(printf %s "$KB_LAYOUT" | tr -d ' \t\r' | tr -s ',')"
  KB_OPTIONS="$(printf %s "$KB_OPTIONS" | tr -d ' \t\r' | tr -s ',')"
fi

apply_x11() {
  # Use the existing guarded env var to avoid double-loading across launchpoints
  if [ -z "${XMODMAP_LOADED:-}" ] && [ -r "$HOME/.Xmodmap" ] && is_cmd xmodmap; then
    xmodmap "$HOME/.Xmodmap" || true
    export XMODMAP_LOADED=1
  fi
}

# Wayland per-DE/compositor application using home-only mechanisms
apply_wayland() {
  # Hyprland: write ~/.config/hypr/conf.d/keyboard.conf
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || pgrep -x hyprland >/dev/null 2>&1; then
    if [ -n "$KB_LAYOUT$KB_OPTIONS" ]; then
      mkdir -p "$HOME/.config/hypr/conf.d"
      {
        echo "input {"
        [ -n "$KB_LAYOUT" ] && echo "  kb_layout = $KB_LAYOUT"
        [ -n "$KB_OPTIONS" ] && echo "  kb_options = $KB_OPTIONS"
        echo "}"
      } > "$HOME/.config/hypr/conf.d/keyboard.conf"
    fi
  fi

  # Sway: write ~/.config/sway/config.d/10-keyboard.conf
  if [ -n "${WAYLAND_DISPLAY:-}" ] && pgrep -x sway >/dev/null 2>&1; then
    if [ -n "$KB_LAYOUT$KB_OPTIONS" ]; then
      mkdir -p "$HOME/.config/sway/config.d"
      {
        echo "input \"*\" {"
        [ -n "$KB_LAYOUT" ] && echo "    xkb_layout $KB_LAYOUT"
        [ -n "$KB_OPTIONS" ] && echo "    xkb_options $KB_OPTIONS"
        echo "}"
      } > "$HOME/.config/sway/config.d/10-keyboard.conf"
    fi
  fi

  # GNOME: set user dconf keys via gsettings
  case "$CURRENT_DESKTOP" in
    *GNOME*)
      if is_cmd gsettings; then
        if [ -n "$KB_OPTIONS" ]; then
          # Convert comma-list to Python-like list syntax expected by gsettings
          OPTS_STR="['$(printf %s "$KB_OPTIONS" | sed "s/,/','/g")']"
          gsettings set org.gnome.desktop.input-sources xkb-options "$OPTS_STR" || true
        fi
        if [ -n "$KB_LAYOUT" ]; then
          SRC_STR="[(\"xkb\", \"$KB_LAYOUT\")]"
          gsettings set org.gnome.desktop.input-sources sources "$SRC_STR" || true
        fi
      fi
      ;;
  esac

  # KDE Plasma: write to ~/.config/kxkbrc via kwriteconfig5 and reconfigure
  case "$CURRENT_DESKTOP" in
    *KDE*|*PLASMA*|*Plasma*)
      if is_cmd kwriteconfig5; then
        [ -n "$KB_OPTIONS" ] && kwriteconfig5 --file kxkbrc --group Layout --key Options "$KB_OPTIONS" || true
        [ -n "$KB_LAYOUT" ] && kwriteconfig5 --file kxkbrc --group Layout --key LayoutList "$KB_LAYOUT" || true
        # Try to reconfigure if possible
        if is_cmd qdbus; then
          qdbus org.kde.keyboard /Layouts reconfigure >/dev/null 2>&1 || true
        fi
      fi
      ;;
  esac

  return 0
}

case "$SESSION_TYPE" in
  x11|X11)
    apply_x11
    ;;
  wayland|Wayland)
    apply_wayland
    ;;
  *)
    # Unknown session type; attempt X11 as safest no-op if not applicable
    apply_x11
    ;;
 esac

exit 0
