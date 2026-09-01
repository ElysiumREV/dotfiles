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

-- Disable blur for xwayland context menus
hl.window_rule({match = {class = "^()$", title = "^()$" }, no_blur = true })

-- Disable blur for every window
hl.window_rule({match = {class = ".*" }, no_blur = true })

hl.layer_rule({
	match = { namespace = "^dunst$" },
	no_screen_share = true,
})

hl.layer_rule({
	match = { namespace = "^notifications$" },
	no_screen_share = true,
})

-- Workspace 4 usa master layout
hl.workspace_rule({ workspace = "4", layout = "master" })

-- Discord / Vesktop / Telegram → workspace 4
hl.window_rule({
	name = "socials",
	match = { class = "^(vesktop|discord|org.telegram.desktop)$" },
	workspace = 4,
})

hl.window_rule({
	name = "telegram",
	match = { class = "^org%.telegram%.desktop$" },
	focus_on_activate = false,
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
	match = {
		class = "^(steam)$",
	},
	workspace = 9,
	center = true,
	size = {
		1100,
		700,
	},
	-- float = false,
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { "steam.*" },
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

-- Jogos → workspace 10, fullscreen, sem borda
hl.window_rule({
	name = "games",
	match = { class = "^(steam_app_[0-9]+|dota2|cs2|gamescope|bg3)$" },
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
	match = {
		title = "^(jetbrains-.*)$",
		class = "^(jetbrains-.*)$",
	},
	no_follow_mouse = true,
	no_initial_focus = true,
})

hl.window_rule({
	name = "monster-hunter-fix",
	match = { class = "HunterPie" },
})

hl.on("window.open", function(w)
	if w.class ~= "firefox" then
		return
	end
	if w.initial_title ~= "Mozilla Firefox" then
		return
	end

	local sub
	sub = hl.on("window.title", function(tw)
		if tw.address ~= w.address then
			return
		end

		if tw.title:match("^Extension: %(Bitwarden Password Manager%)") then
			hl.dispatch(hl.dsp.window.float({
				action = "set",
				window = tw,
			}))

			sub:remove()
		end
	end)
end)

hl.window_rule({
	name = "Bitwarden",
	match = {
		title = "^(Bitwarden)$&^Extension: %(Bitwarden Password Manager%)",
		class = "^(Bitwarden)$&^Extension: %(Bitwarden Password Manager%)",
	},
	no_screen_share = true,
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

-- Picture-in-Picture
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = {"(monitor_w*0.73)", "(monitor_h*0.72)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = {"(monitor_w*0.25)", "(monitor_h*0.25)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true})

hl.window_rule({
	match = {
		title = "(Picture.?[Pp]icture)|Picture-in-Picture",
	},
	tag = "+pip",
})

hl.window_rule({
	match = {
		tag = "pip",
	},
	float = true,
	pin = true,
	size = { 600, 338 },
	border_size = 0,
	opacity = "1 override 1 override",
	move = {
		"(monitor_w-window_w-40)",
		"(monitor_h*0.04)",
	},
})

-- Google Meet PiP uses the meeting title instead of "Picture-in-Picture".
hl.window_rule({
	match = {
		class = "chromium-based-browser|firefox",
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

-- Floating
hl.window_rule({match = {class = "xdg-desktop-portal-gtk"},                  float = true})
hl.window_rule({match = {class = "xdg-desktop-portal-gtk"},                  center = true})
hl.window_rule({match = {title = "^(Open File)(.*)$" },                      center = true})
hl.window_rule({match = {title = "^(Open File)(.*)$" },                      float = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                  center = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                  float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               center = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                    center = true})
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                    float = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                        center = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                        float = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                        center = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                        float = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                    center = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                    float = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                  center = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                  float = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                  center = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                  float = true})
hl.window_rule({match = {class = "^(blueberry\\.py)$" },                     float = true})
hl.window_rule({match = {class = "^(guifetch)$" },                           float = true}) -- FlafyDev/guifetch
hl.window_rule({match = {class = "^(pavucontrol)$" },                        float = true})
hl.window_rule({match = {class = "^(pavucontrol)$" },                        size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(pavucontrol)$" },                        center = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         float = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         center = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               float = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               center = true})
hl.window_rule({match = {class = ".*plasmawindowed.*" },                     float = true})
hl.window_rule({match = {class = "kcm_.*" },                                  float = true})
hl.window_rule({match = {class = ".*bluedevilwizard" },                      float = true})
hl.window_rule({match = {title = ".*Welcome" },                              float = true})
hl.window_rule({match = {title = "^(illogical-impulse Settings)$" },         float = true})
hl.window_rule({match = {title = ".*Shell conflicts.*" },                    float = true})
hl.window_rule({match = {class = "org.freedesktop.impl.portal.desktop.kde" }, float = true})
hl.window_rule({match = {class = "org.freedesktop.impl.portal.desktop.kde" }, size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {class = "^(Zotero)$" },                             float = true})
hl.window_rule({match = {class = "^(Zotero)$" },                             size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })

-- Screen sharing
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, float = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, pin = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"} })

-- --- Tearing ---
hl.window_rule({match = {title = ".*\\.exe" }, immediate = true})
hl.window_rule({match = {title = ".*minecraft.*" }, immediate = true})
hl.window_rule({match = {class = "^(steam_app).*" }, immediate = true})

-- No shadow for tiled windows
hl.window_rule({match = {float = 0 }, no_shadow = true})
