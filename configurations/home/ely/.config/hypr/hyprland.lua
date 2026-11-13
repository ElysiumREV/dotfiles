----------------------------------
-- Elysium's Hyprland config
----------------------------------

require("modules.autostart")
require("modules.env")
require("modules.input")
require("modules.keybinds")
require("modules.workspaces")
require("modules.looknfeel")
-- require("modules.colors")

--------------------
-- MONITORS
--------------------

-- Desktop/Home
hl.monitor({
	output = "DP-1",
	mode = "1920x1080@144",
	position = "auto-right",
	scale = 1,
	cm = "auto",
	icc = "/home/ely/.config/hypr/icc/lg-24gl600f-rtings.icm", -- LG 24GL600F, RTINGS calibration
})
-- hl.monitor({ output = "DP-2", mode = "1920x1080@144", position = "auto-right", scale = 1, cm = "auto" })
-- Notebook
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "auto-right", scale = 1, cm = "auto" })
-- Fallback: extend on the desktop. On the notebook modules/displays.lua sets
-- a mirror fallback instead, so a projector never gets its own workspace.
if not require("modules.power").has_battery then
	hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1, cm = "auto" })
end

require("modules.displays")
