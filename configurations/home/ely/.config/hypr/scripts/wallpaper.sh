#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"

selected=$(find "$wallpaper_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -not -name ".*" \
  | while read -r img; do
      echo -en "$img\0icon\x1f$img\n"
    done \
  | rofi -dmenu -show-icons -i -p "Wallpaper" -theme ~/.config/rofi/wallpaper.rasi)

if [ -n "$selected" ]; then
  awww img --transition-fps 60 --transition-type random "$selected"
  ln -sf "$selected" "$HOME/Pictures/Wallpapers/.current-wallpaper.png"
fi
