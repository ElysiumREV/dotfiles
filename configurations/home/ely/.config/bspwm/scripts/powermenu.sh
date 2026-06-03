#!/usr/bin/env bash

choice="$(
  printf '%s\n' \
    "Lock" \
    "Logout" \
    "Reboot" \
    "Shutdown" \
    | rofi -dmenu -i -p "Power" -theme "$HOME/.config/rofi/config.rasi"
)"

case "$choice" in
  Lock) "$HOME/.config/bspwm/scripts/lock.sh" ;;
  Logout) bspc quit ;;
  Reboot) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
