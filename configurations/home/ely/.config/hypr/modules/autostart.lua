--------------------
-- AUTOSTART
--------------------

hl.on("hyprland.start", function()
	-- Session Environment
	-- Old fix i made, the new one is from omarchy config
	-- hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	-- hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
	-- hl.exec_cmd("dbus-update-activation-environment --systemd --all")

	-- check whether this is needed
	-- hl.exec_cmd("gnome-keyring-daemon --start")

	-- Panel / system tray / notifications
	-- QS_ICON_THEME pins the icon theme (read from kdeglobals at startup) so the
	-- KDE platform theme can't swap it at runtime; app icons used to vanish
	-- until quickshell was restarted.
	hl.exec_cmd(
		"uwsm app -- sh -c 'QS_ICON_THEME=$(kreadconfig6 --file kdeglobals --group Icons --key Theme --default breeze-plus-dark) QS_NO_RELOAD_POPUP=1 QML_DISABLE_DISK_CACHE=1 exec quickshell'"
	)

	-- Hyprland ecosystem
	hl.exec_cmd("uwsm app -- hyprsunset")
	hl.exec_cmd("uwsm app -- hypridle")
	-- Eco visuals on battery / power-saver (no-op on the desktop)
	hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/power-watch.sh")
	-- hl.exec_cmd("systemctl --user start hyprpolkitagent")

	-- Apps / services
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- udiskie")
end)
