#!/usr/bin/env bash
# Reloads the Hyprland config when the power profile changes, so
# modules/power.lua can switch the eco visuals (eco unless "performance").
# Also makes apps with their own translucency opaque in eco, since without
# blur a see-through background is hard to read.
# Exits right away on machines without a battery (desktop).

ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || exit 0

epp=/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
state() { [[ $(<"$epp") == performance ]] && echo full || echo eco; }

kitty_override=~/.config/kitty/power-eco.conf

apply_apps() {
  if [[ $1 == eco ]]; then
    echo "background_opacity 1.0" >"$kitty_override"
  else
    rm -f "$kitty_override"
  fi
  # SIGUSR1 makes every kitty instance reload its config
  pkill -USR1 -x kitty
}

last=$(state)
apply_apps "$last"

gdbus monitor --system --dest net.hadess.PowerProfiles | while read -r _; do
  # coalesce bursts of signals and give ppd time to write EPP
  while read -r -t 1 _; do :; done
  now=$(state)
  if [[ $now != "$last" ]]; then
    last=$now
    hyprctl reload config-only >/dev/null
    apply_apps "$now"
  fi
done
