#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

menu() {
  find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

main() {
  choice=$(menu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n)
  selected_wallpaper=$(echo "$choice" | sed 's/^img://')

  cp -f "$selected_wallpaper" "$HOME/Pictures/.current-wallpaper.jpg"

  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5

  matugen image --mode dark "$selected_wallpaper"

  swaync-client --reload-css

  COLOR_JSON="$HOME/.cache/matugen/colors.json"
  if [ -f "$COLOR_JSON" ]; then
    color1=$(jq -r '.primary' "$COLOR_JSON")
    color2=$(jq -r '.secondary' "$COLOR_JSON")

    cava_config="$HOME/.config/cava/config"
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color1'/" $cava_config
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color2'/" $cava_config
    pkill -USR2 cava 2>/dev/null
  fi
}

main