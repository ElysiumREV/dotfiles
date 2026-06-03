# bspwm config based on the Hyprland setup

Required for the core session:

- `bspwm`
- `sxhkd`
- `polybar`
- `rofi`

Recommended for feature parity with the Hyprland config:

- `picom`: opacity, shadows, rounded corners and blur
- `feh` or `nitrogen`: wallpaper restore/selection
- `maim` and `xclip`: area screenshots copied to clipboard
- `betterlockscreen`, `i3lock-color` or `i3lock`: lockscreen
- `redshift`: night color temperature
- `clipmenu` or `greenclip`: clipboard history
- `dunst`: X11 notifications

Main translations:

- Hyprland keybinds -> `~/.config/sxhkd/sxhkdrc`
- Hyprland workspaces/window rules -> `~/.config/bspwm/bspwmrc`
- Hyprland gaps/borders/colors -> `bspc config` in `bspwmrc`
- Hyprland blur/rounding/shadows -> `~/.config/picom/picom.conf`
- Hyprland wallpaper script -> `~/.config/bspwm/scripts/wallpaper.sh`

Known differences:

- Hyprland animations are not available in bspwm.
- Workspace 4's `master` layout has no native bspwm equivalent.
- Hyprlock/hypridle/hyprsunset were replaced with X11-oriented fallbacks.
