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
-- Fallback (on the notebook, modules/displays.lua mirrors externals instead)
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1, cm = "auto" })

require("modules.displays")
