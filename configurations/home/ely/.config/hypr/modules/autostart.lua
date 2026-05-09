--------------------
-- AUTOSTART
--------------------

hl.on("hyprland.start", function()
	-- Panel / system tray / notifications
	hl.exec_cmd("qs")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("mako")

	-- Hyprland ecosystem
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("hyprlauncher -d")

	-- Apps / services
	hl.exec_cmd("awww-daemon")
	-- hl.exec_cmd("vesktop --start-minimized")
	-- hl.exec_cmd("discord --start-minimized")
	-- hl.exec_cmd("steam -silent")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("cliphist wipe")
	hl.exec_cmd("udiskie")
	hl.exec_cmd("easyeffects --gapplication-service")
	hl.exec_cmd("xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search")
	hl.exec_cmd("gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty")
end)
