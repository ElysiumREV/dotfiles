#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

menu() {
  find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

main() {
  # Use rofi instead of wofi
  choice=$(menu | rofi -dmenu -p "Select Wallpaper:" -theme ~/.config/rofi/wallpaper.rasi)
  selected_wallpaper=$(echo "$choice" | sed 's/^img://')

  # Set wallpaper
  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5

  # Generate colors with matugen
  matugen image --mode dark "$selected_wallpaper"

  # Reload swaync with new CSS
  swaync-client --reload-css

  # If you added a JSON template, extract colors for cava
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
