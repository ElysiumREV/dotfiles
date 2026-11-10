#!/usr/bin/env bash
# Helper for hypridle.conf so the laptop can use shorter timeouts on battery.
#
#   idle.sh <when> <action>
#     when:   battery  -> only runs on a laptop that is unplugged
#             default  -> runs on the desktop, or on the laptop while plugged in
#             always   -> no check (used by the resume actions)
#     action: dim | undim | kbd-off | kbd-on | lock | screen-off | screen-on | suspend
#
# dim/kbd-off write a state file, and undim/kbd-on only restore when it exists,
# so resuming never restores a stale brightness saved by an earlier cycle.

when=$1
action=$2
state=${XDG_RUNTIME_DIR:-/tmp}/hypridle

on_battery() {
  local f
  for f in /sys/class/power_supply/{ADP,AC}*/online; do
    [[ -r $f ]] && { [[ $(<"$f") == 0 ]]; return; }
  done
  return 1 # no adapter: desktop
}

case $when in
battery) on_battery || exit 0 ;;
default) on_battery && exit 0 ;;
always) ;;
*) echo "idle.sh: unknown condition '$when'" >&2; exit 2 ;;
esac

mkdir -p "$state"

case $action in
dim)
  [[ -e $state/dimmed ]] && exit 0
  brightnessctl -s set 10 >/dev/null && touch "$state/dimmed"
  ;;
undim)
  [[ -e $state/dimmed ]] && brightnessctl -r >/dev/null
  rm -f "$state/dimmed"
  ;;
kbd-off)
  brightnessctl -d rgb:kbd_backlight info >/dev/null 2>&1 || exit 0
  brightnessctl -sd rgb:kbd_backlight set 0 >/dev/null && touch "$state/kbd"
  ;;
kbd-on)
  [[ -e $state/kbd ]] && brightnessctl -rd rgb:kbd_backlight >/dev/null
  rm -f "$state/kbd"
  ;;
lock) pidof hyprlock >/dev/null || loginctl lock-session ;;
screen-off) hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })' >/dev/null ;;
screen-on) hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null ;;
suspend) systemctl suspend ;;
*) echo "idle.sh: unknown action '$action'" >&2; exit 2 ;;
esac
