#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/"
CURRENT_WALLPAPER="${WALLPAPER_DIR}.current-wallpaper.png"

menu() {
	find "${WALLPAPER_DIR}" \
		-type f \
		\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
		! -path "$CURRENT_WALLPAPER" \
		-not -path '*/.*' | awk '{print "img:"$0}'
}

main() {
	choice=$(menu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n)
	if [ -z "$choice" ]; then
		exit 0
	fi

	selected_wallpaper=$(echo "$choice" | sed 's/^img://')
	if [ ! -f "$selected_wallpaper" ]; then
		echo "Error: Wallpaper file not found: $selected_wallpaper"
		exit 1
	fi

	cp "$selected_wallpaper" "$CURRENT_WALLPAPER"
	echo "Setting wallpaper: $selected_wallpaper"
	hyprctl hyprpaper preload "$selected_wallpaper"

	monitors=$(hyprctl monitors | grep -oP 'Monitor \K[^ ]+')
	for monitor in $monitors; do
		hyprctl hyprpaper wallpaper "$monitor,$selected_wallpaper"
		echo "Set wallpaper on monitor: $monitor"
	done
}

main
