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
	hl.exec_cmd("mako")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("blueman-applet")

	-- Hyprland ecosystem
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("hyprlauncher -d")

	-- Apps / services
	hl.exec_cmd("awww-daemon")
	-- hl.exec_cmd("discord --start-minimized")
	-- hl.exec_cmd("vesktop --start-minimized")
	-- hl.exec_cmd("steam -silent")
	hl.exec_cmd("vicinae server")

	hl.exec_cmd("udiskie")
	-- hl.exec_cmd("easyeffects --gapplication-service")
	hl.exec_cmd("xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search")
	hl.exec_cmd("gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty")
	hl.exec_cmd("gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings '<Ctrl><Alt>t'")
	hl.exec_cmd("gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true")
	hl.exec_cmd("gsettings set com.github.stunkymonkey.nautilus-open-any-terminal flatpak system")
end)
