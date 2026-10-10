--------------------
-- AUTOSTART
--------------------

hl.on("hyprland.start", function()
	-- Session Environment
	-- Old fix i made, the new one is from omarchy config
	-- hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")

	hl.exec_cmd("gnome-keyring-daemon --start")

	-- Panel / system tray / notifications
	hl.exec_cmd("qs")

	-- Hyprland ecosystem
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")

	-- Apps / services
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("udiskie")
end)
