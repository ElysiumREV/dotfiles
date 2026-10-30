#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"
current="$wallpaper_dir/.current-wallpaper.png"

set_wallpaper() {
  local image="$1"

  if command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$image"
  elif command -v nitrogen >/dev/null 2>&1; then
    nitrogen --set-zoom-fill "$image"
  fi
}

if [ "${1:-}" = "--restore" ]; then
  [ -e "$current" ] && set_wallpaper "$current"
  exit 0
fi

selected="$(
  find "$wallpaper_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -not -name ".*" \
    | while read -r img; do
        printf '%s\0icon\x1f%s\n' "$img" "$img"
      done \
    | rofi -dmenu -show-icons -i -p "Wallpaper" -theme "$HOME/.config/rofi/wallpaper.rasi"
)"

if [ -n "$selected" ]; then
  set_wallpaper "$selected"
  ln -sf "$selected" "$current"
fi
