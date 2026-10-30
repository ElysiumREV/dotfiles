local colors = require("modules.colors")

--------------------
-- LOOK AND FEEL
--------------------

hl.gesture({
	fingers = 3,
	direction = "swipe",
	action = "move",
})
hl.gesture({
	fingers = 3,
	direction = "pinch",
	action = "fullscreen",
})
hl.gesture({
	fingers = 4,
	direction = "horizontal",
	action = "workspace",
})

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		gaps_workspaces = 50,

		border_size = 1,

		resize_on_border = false,
		col = {
			active_border = colors.primary,
			inactive_border = colors.surface_variant,
		},
		allow_tearing = true,
		layout = "dwindle",
	},

	render = {
		cm_auto_hdr = false,
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,
		active_opacity = 1,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1,
		blur = {
			enabled = true,
      size = 5,
      passes = 3,
      popups = true,
      input_methods = true,
		},
		shadow = {
			enabled = true,
      range = 25,
      render_power = 3,
			color = "rgba(00000020)",
		},
		-- Dim
		dim_inactive = true,
		dim_strength = 0.05,
		dim_special = 0.2,
	},

	dwindle = {
		preserve_split = true,
		smart_split = false,
		smart_resizing = false,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 1,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		swallow_regex = "(foot|kitty|allacritty|Alacritty)",
		on_focus_under_fullscreen = 2,
		allow_session_lock_restore = true,
		session_lock_xray = true,
		initial_workspace_tracking = 0,
		focus_on_activate = false,
		render_unfocused_fps = 60,
		middle_click_paste = false,
	},
})

--------------------
-- ANIMATIONS
--------------------

-- Curves
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })