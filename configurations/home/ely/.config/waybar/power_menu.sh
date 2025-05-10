#!/bin/bash

choice=$(printf "⏾ Suspender\n⏼ Hibernar\n⏻ Desligar\n↻ Reiniciar" | wofi --dmenu --width 200 --height 200 --prompt "Power Menu" --hide-scroll --no-actions)

case "$choice" in
*Suspender) systemctl suspend ;;
*Hibernar) systemctl hibernate ;;
*Desligar) ~/.config/waybar/shutdown_confirmation.sh ;;
*Reiniciar) ~/.config/waybar/reboot_confirmation.sh ;;
esac
