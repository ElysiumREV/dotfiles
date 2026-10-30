#!/bin/sh

# GTK applications load their CSS when they start. Updating the preference
# makes newly started GTK/libadwaita applications use the selected variant.
mode="${1:-dark}"
case "$mode" in
    light|dark) ;;
    *) mode=dark ;;
esac

if command -v gsettings >/dev/null 2>&1; then
    # GTK3 (adw-gtk3) and GTK4/libadwaita share this preference. Clearing
    # first also forces already-running GTK3 settings daemons to notice it.
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-${mode}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-${mode}" 2>/dev/null || true
fi
