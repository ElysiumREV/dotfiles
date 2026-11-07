--------------------
-- KEYBINDINGS
--------------------

local terminal = "kitty"
local fileManager = "dolphin"
local browser = "firefox"
local mainMod = "SUPER"

-- Apps
hl.bind(
	mainMod .. " + D",
	hl.dsp.exec_cmd("qs ipc call shell toggleLauncher"),
	{ description = "Apps: Open launcher" }
)
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal), { description = "Apps: Open terminal" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("uwsm stop"), { description = "System: Exit Hyprland" })
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("qs ipc call shell toggleLogout"),
	{ description = "System: Open session menu" }
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Apps: Open file manager" })
hl.bind(
	mainMod .. " + V",
	hl.dsp.window.float({ action = "toggle" }),
	{ description = "Windows: Toggle floating window" }
)
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Windows: Toggle split" }) -- dwindle only
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(
	mainMod .. " + F",
	hl.dsp.window.fullscreen({ mode = "maximized" }),
	{ description = "Windows: Maximize window" }
)
hl.bind(
	mainMod .. " + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen" }),
	{ description = "Windows: Toggle fullscreen" }
)
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Windows: Toggle pseudo mode" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Apps: Open browser" })
hl.bind(
	mainMod .. " + SHIFT + B",
	hl.dsp.exec_cmd(browser .. " -p"),
	{ description = "Apps: Open profile manager" }
)
hl.bind(
	mainMod .. " + T",
	hl.dsp.exec_cmd(terminal .. " -e btop"),
	{ description = "System: Open resource monitor" }
)
hl.bind(
	mainMod .. " + SHIFT + V",
	hl.dsp.exec_cmd("qs ipc call shell toggleClipboardHistory"),
	{ description = "QuickShell: Open clipboard history" }
)
hl.bind(
	mainMod .. " + H",
	hl.dsp.exec_cmd("qs ipc call shell toggleKeybindCheatsheet"),
	{ description = "QuickShell: Open shortcut cheatsheet" }
)
hl.bind(
	mainMod .. " + O",
	hl.dsp.exec_cmd("qs ipc call shell toggleShortcutHub"),
	{ description = "QuickShell: Open shortcut hub" }
)
hl.bind(
	mainMod .. " + N",
	hl.dsp.exec_cmd("qs ipc call shell toggleDoNotDisturb"),
	{ description = "QuickShell: Toggle Do Not Disturb" }
)

-- Focus
hl.bind(
	mainMod .. " + left",
	hl.dsp.focus({ direction = "left" }),
	{ description = "Windows: Focus window to the left" }
)
hl.bind(
	mainMod .. " + right",
	hl.dsp.focus({ direction = "right" }),
	{ description = "Windows: Focus window to the right" }
)
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Windows: Focus window above" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Windows: Focus window below" })

-- Resize
hl.bind(
	"SUPER + SHIFT + RIGHT",
	hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
	{ repeating = true, description = "Windows: Increase width" }
)
hl.bind(
	"SUPER + SHIFT + LEFT",
	hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
	{ repeating = true, description = "Windows: Decrease width" }
)
hl.bind(
	"SUPER + SHIFT + DOWN",
	hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
	{ repeating = true, description = "Windows: Increase height" }
)
hl.bind(
	"SUPER + SHIFT + UP",
	hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
	{ repeating = true, description = "Windows: Decrease height" }
)

-- Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 → tecla 0
	hl.bind(
		mainMod .. " + " .. key,
		hl.dsp.focus({ workspace = i }),
		{ description = "Workspaces: Go to workspace " .. i }
	)
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Workspaces: Move window to workspace " .. i }
	)
end

-- Scroll entre workspaces
hl.bind(
	mainMod .. " + mouse_down",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Workspaces: Next workspace" }
)
hl.bind(
	mainMod .. " + mouse_up",
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Workspaces: Previous workspace" }
)

-- Mover/redimensionar com mouse
hl.bind(
	mainMod .. " + mouse:272",
	hl.dsp.window.drag(),
	{ mouse = true, description = "Windows: Move window with the mouse" }
)
hl.bind(
	mainMod .. " + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Windows: Resize window with the mouse" }
)

-- Teclas FN
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("quickshell ipc call shell increaseVolume"),
	{ locked = true, repeating = true, description = "Audio: Increase system volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("quickshell ipc call shell decreaseVolume"),
	{ locked = true, repeating = true, description = "Audio: Decrease system volume" }
)
hl.bind(
	"SHIFT + XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("playerctl volume 0.05+"),
	{ locked = true, repeating = true, description = "Media: Increase track volume" }
)
hl.bind(
	"SHIFT + XF86AudioLowerVolume",
	hl.dsp.exec_cmd("playerctl volume 0.05-"),
	{ locked = true, repeating = true, description = "Media: Decrease track volume" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("quickshell ipc call shell toggleMute"),
	{ locked = true, description = "Audio: Toggle system mute" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, description = "Audio: Mute or unmute microphone" }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("quickshell ipc call shell increaseBrightness"),
	{ locked = true, repeating = true, description = "Display: Increase brightness" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("quickshell ipc call shell decreaseBrightness"),
	{ locked = true, repeating = true, description = "Display: Decrease brightness" }
)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Media: Next track" })
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Media: Play or pause" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Media: Play or pause" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("playerctl previous"),
	{ locked = true, description = "Media: Previous track" }
)

-- Screenshots via QuickShell
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd("qs ipc call shell screenshotRegion"),
	{ description = "QuickShell: Capture screen region" }
)
hl.bind(
	mainMod .. " + S",
	hl.dsp.exec_cmd("qs ipc call shell screenshotWindow"),
	{ description = "QuickShell: Capture window" }
)

-- Lockscreen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"), { description = "System: Lock session" })

-- Wallpaper
hl.bind(
	mainMod .. " + W",
	hl.dsp.exec_cmd("qs ipc call shell toggleWallpaper"),
	{ description = "QuickShell: Choose wallpaper" }
)

hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.exec_cmd("qs ipc call shell toggleWallhaven"),
	{ description = "QuickShell: Search wallpapers online" }
)
