------------------------------
-- WINDOWS AND WORKSPACES
------------------------------

-- Fix XWayland dragging issues
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Workspace 4 usa master layout
hl.workspace_rule({ workspace = "4", layout = "master" })

-- Discord / Vesktop / Telegram → workspace 4
hl.window_rule({
	name = "socials",
	match = { class = "^(vesktop|discord|org%.telegram%.desktop)$" },
	workspace = 4,
})

-- YouTube Music → workspace 5
hl.window_rule({
	name = "Youtube Music",
	match = {
		class = "^com.github.th_ch.youtube_music$",
	},
	workspace = 5,
})

hl.window_rule({
	name = "Spotify",
	match = {
		class = "Spotify",
	},
	workspace = 5,
})

-- Steam → workspace 9
hl.window_rule({
	name = "steam",
	match = { class = "^(steam)$" },
	workspace = 9,
})

-- Jogos → workspace 10, fullscreen, sem borda
hl.window_rule({
	name = "games",
	match = { class = "^(steam_app_[0-9]+|dota2|cs2|lutris|heroic|gamescope|bg3)$" },
	workspace = 10,
	fullscreen = true,
	border_size = 0,
	render_unfocused = true,
})

-- Workspace 10: sem gaps/rounding/blur/anim/sombra
hl.window_rule({
	name = "gaming-workspace",
	match = { workspace = "10" },
	rounding = 0,
	opacity = "1.0 override",
	no_blur = true,
	no_anim = true,
	no_shadow = true,
	decorate = false,
})

-- Workspace 10: sem gaps
hl.workspace_rule({ workspace = "10", gaps_in = 0, gaps_out = 0 })

-- Unity / Unreal → workspace 6, sem efeitos
hl.window_rule({
	name = "fix-unity",
	match = { class = "^(Unity|unityhub|unreal)$" },
	workspace = 6,
	rounding = 0,
	opacity = "1.0 override",
	no_blur = true,
	no_anim = true,
	no_shadow = true,
	decorate = false,
})

-- Blur na waybar
hl.layer_rule({
	name = "waybar-blur",
	match = { namespace = "waybar" },
	blur = true,
})

-- Fix IntelliJ IDEA (foco inicial)
hl.window_rule({
	name = "fix-intellij",
	match = { class = "jetbrains-idea" },
	no_initial_focus = true,
})
