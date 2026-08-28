----------------------------------
-- Elysium's Hyprland config
----------------------------------

require("modules.autostart")
require("modules.env")
require("modules.input")
require("modules.keybinds")
require("modules.workspaces")
require("modules.looknfeel")

-- Debug
hl.config({
	debug = {
		disable_logs = false,
		damage_tracking = 2,
	},
})

--------------------
-- MONITORS
--------------------

-- Desktop/Home
hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
-- Notebook
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- Fallback
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
