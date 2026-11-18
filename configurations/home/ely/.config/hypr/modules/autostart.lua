--------------------
-- AUTOSTART
--------------------

hl.on("hyprland.start", function()
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

	-- Apps / services
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- udiskie")
end)
