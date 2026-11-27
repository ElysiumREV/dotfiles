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

hl.window_rule({
	name = "float-share-picker",
	match = { class = "hyprland-share-picker" },
	float = true,
})

-- Disable blur for xwayland context menus
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })

-- Disable blur for every window
-- hl.window_rule({ match = { class = ".*" }, no_blur = true })

hl.layer_rule({
	match = { namespace = "^notifications$" },
	no_screen_share = true,
})

-- Discord / Vesktop / Telegram → workspace 4
hl.window_rule({
	name = "socials",
	match = { class = "^(vesktop|discord|com.discord.libdiscord|org.telegram.desktop|zapfast|salinha)$" },
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

hl.window_rule({
	name = "Spotifast",
	match = {
		class = "spotifast",
	},
	workspace = 5,
})

-- Steam → workspace 9
hl.window_rule({
	name = "steam",
	match = {
		class = "^(steam)$",
	},
	workspace = 9,
	center = true,
	-- float = false,
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { class = "^steam.*" },
	opacity = "1 override 1 override",
})
hl.window_rule({
	match = {
		class = "steam",
		title = "Friends List",
	},
	size = {
		460,
		800,
	},
	float = true,
})

-- EpicGamesLauncher
hl.window_rule({
	name = "Epic",
	match = {
		class = "EpicGamesLauncher",
	},
	workspace = 9,
})

-- Jogos → workspace 10, fullscreen, sem borda
hl.window_rule({
	name = "games",
	match = { class = "^(steam_app_[0-9]+|dota2|cs2|gamescope|bg3)$" },
	workspace = 10,
	fullscreen = true,
	border_size = 0,
	render_unfocused = true,
	idle_inhibit = "fullscreen",
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
	immediate = true,
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

-- Fix IntelliJ IDEA (foco inicial)
hl.window_rule({
	name = "fix-intellij",
	match = {
		title = "^(jetbrains-.*)$",
		class = "^(jetbrains-.*)$",
	},
	no_follow_mouse = true,
	no_initial_focus = true,
})

-- App desktop do Bitwarden
hl.window_rule({
	name = "bitwarden-desktop",
	match = {
		class = "^Bitwarden$",
	},
	no_screen_share = true,
	center = true,
	float = true,
})

hl.window_rule({
	name = "moonlight",
	match = {
		title = "com.moonlight_stream.Moonlight",
		class = "com.moonlight_stream.Moonlight",
	},
	fullscreen = true,
	idle_inhibit = "fullscreen",
})

-- Picture-in-Picture (top right)
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	float = true,
	pin = true,
	keep_aspect_ratio = true,
	size = { 600, 338 },
	border_size = 0,
	opacity = "1 override 1 override",
	move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Google Meet PiP uses the meeting title instead of "Picture-in-Picture".
hl.window_rule({
	match = {
		class = "chromium-based-browser|google-chrome|firefox",
		title = "^Meet - .+",
	},
	float = true,
	pin = true,
	size = { 600, 338 },
	border_size = 0,
	opacity = "1 override 1 override",
	move = {
		"(monitor_w-window_w-40)",
		"(monitor_h-window_h-40)",
	},
})

hl.layer_rule({
	match = { namespace = "selection" },
	no_anim = true,
	animation = "none",
})

-- Floating (centered)
local dialogs = {
	"^(Open File)(.*)$",
	"^(Select a File)(.*)$",
	"^(Open Folder)(.*)$",
	"^(Save As)(.*)$",
	"^(Library)(.*)$",
	"^(File Upload)(.*)$",
	"^(.*)(wants to save)$",
	"^(.*)(wants to open)$",
	"^(Firefox - Choose User Profile)",
}
for _, title in ipairs(dialogs) do
	hl.window_rule({ match = { title = title }, float = true, center = true })
end
hl.window_rule({ match = { class = "xdg-desktop-portal-gtk" }, float = true, center = true })
hl.window_rule({ match = { class = "^(ark|org[.]kde[.]ark)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(nemo)$", title = "^.+ Properties$" }, float = true, center = true })
hl.window_rule({
	match = { title = "^(Choose wallpaper)(.*)$" },
	float = true,
	center = true,
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})
hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor)$" },
	float = true,
	center = true,
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})

-- Floating
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(guifetch)$" }, float = true }) -- FlafyDev/guifetch
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = "^(.*)Welcome$" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })
hl.window_rule({
	match = { class = "org.freedesktop.impl.portal.desktop.kde" },
	float = true,
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})
hl.window_rule({
	match = { class = "^(Zotero)$" },
	float = true,
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})

-- Screen sharing
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	float = true,
	pin = true,
	move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- --- Tearing ---
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = false }, no_shadow = true })

hl.workspace_rule({
	workspace = "f[1]",
	gaps_out = 0,
	border_size = 0,
	no_rounding = true,
})
