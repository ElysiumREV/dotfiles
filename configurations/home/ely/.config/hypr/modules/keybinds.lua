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
	{ description = "Apps: Abrir launcher" }
)
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal), { description = "Apps: Abrir terminal" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close(), { description = "Janelas: Fechar janela" })
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exit(), { description = "Sistema: Sair do Hyprland" })
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("qs ipc call shell toggleLogout"),
	{ description = "Sistema: Abrir menu de sessão" }
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Apps: Abrir gerenciador de arquivos" })
hl.bind(
	mainMod .. " + V",
	hl.dsp.window.float({ action = "toggle" }),
	{ description = "Janelas: Alternar janela flutuante" }
)
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Janelas: Alternar divisão" }) -- dwindle only
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(
	mainMod .. " + F",
	hl.dsp.window.fullscreen({ mode = "maximized" }),
	{ description = "Janelas: Maximizar janela" }
)
hl.bind(
	mainMod .. " + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen" }),
	{ description = "Janelas: Alternar tela cheia" }
)
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Janelas: Alternar modo pseudo" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Apps: Abrir navegador" })
hl.bind(
	mainMod .. " + SHIFT + B",
	hl.dsp.exec_cmd(browser .. " -p"),
	{ description = "Apps: Abrir gerenciador de perfis" }
)
hl.bind(
	mainMod .. " + T",
	hl.dsp.exec_cmd(terminal .. " -e btop"),
	{ description = "Sistema: Abrir monitor de recursos" }
)
hl.bind(
	mainMod .. " + SHIFT + V",
	hl.dsp.exec_cmd("qs ipc call shell toggleClipboardHistory"),
	{ description = "QuickShell: Abrir histórico da área de transferência" }
)
hl.bind(
	mainMod .. " + H",
	hl.dsp.exec_cmd("qs ipc call shell toggleKeybindCheatsheet"),
	{ description = "QuickShell: Abrir cheatsheet de atalhos" }
)
hl.bind(
	mainMod .. " + O",
	hl.dsp.exec_cmd("qs ipc call shell toggleShortcutHub"),
	{ description = "QuickShell: Abrir central de atalhos" }
)
hl.bind(
	mainMod .. " + N",
	hl.dsp.exec_cmd("qs ipc call shell toggleDoNotDisturb"),
	{ description = "QuickShell: Alternar Não Perturbe" }
)

-- Focus
hl.bind(
	mainMod .. " + left",
	hl.dsp.focus({ direction = "left" }),
	{ description = "Janelas: Focar janela à esquerda" }
)
hl.bind(
	mainMod .. " + right",
	hl.dsp.focus({ direction = "right" }),
	{ description = "Janelas: Focar janela à direita" }
)
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Janelas: Focar janela acima" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Janelas: Focar janela abaixo" })

-- Resize
hl.bind(
	"SUPER + SHIFT + RIGHT",
	hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
	{ repeating = true, description = "Janelas: Aumentar largura" }
)
hl.bind(
	"SUPER + SHIFT + LEFT",
	hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
	{ repeating = true, description = "Janelas: Diminuir largura" }
)
hl.bind(
	"SUPER + SHIFT + DOWN",
	hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
	{ repeating = true, description = "Janelas: Aumentar altura" }
)
hl.bind(
	"SUPER + SHIFT + UP",
	hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
	{ repeating = true, description = "Janelas: Diminuir altura" }
)

-- Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 → tecla 0
	hl.bind(
		mainMod .. " + " .. key,
		hl.dsp.focus({ workspace = i }),
		{ description = "Workspaces: Ir para workspace " .. i }
	)
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Workspaces: Mover janela para workspace " .. i }
	)
end

-- Scroll entre workspaces
hl.bind(
	mainMod .. " + mouse_down",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Workspaces: Próximo workspace" }
)
hl.bind(
	mainMod .. " + mouse_up",
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Workspaces: Workspace anterior" }
)

-- Mover/redimensionar com mouse
hl.bind(
	mainMod .. " + mouse:272",
	hl.dsp.window.drag(),
	{ mouse = true, description = "Janelas: Mover janela com o mouse" }
)
hl.bind(
	mainMod .. " + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Janelas: Redimensionar janela com o mouse" }
)

-- Teclas FN
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("quickshell ipc call shell increaseVolume"),
	{ locked = true, repeating = true, description = "Áudio: Aumentar volume do sistema" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("quickshell ipc call shell decreaseVolume"),
	{ locked = true, repeating = true, description = "Áudio: Diminuir volume do sistema" }
)
hl.bind(
	"SHIFT + XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("playerctl volume 0.05+"),
	{ locked = true, repeating = true, description = "Mídia: Aumentar volume da faixa" }
)
hl.bind(
	"SHIFT + XF86AudioLowerVolume",
	hl.dsp.exec_cmd("playerctl volume 0.05-"),
	{ locked = true, repeating = true, description = "Mídia: Diminuir volume da faixa" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("quickshell ipc call shell toggleMute"),
	{ locked = true, description = "Áudio: Alternar mute do sistema" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, description = "Áudio: Silenciar ou ativar microfone" }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("quickshell ipc call shell increaseBrightness"),
	{ locked = true, repeating = true, description = "Tela: Aumentar brilho" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("quickshell ipc call shell decreaseBrightness"),
	{ locked = true, repeating = true, description = "Tela: Diminuir brilho" }
)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Mídia: Próxima faixa" })
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Mídia: Reproduzir ou pausar" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Mídia: Reproduzir ou pausar" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("playerctl previous"),
	{ locked = true, description = "Mídia: Faixa anterior" }
)

-- Screenshots via QuickShell
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd("qs ipc call shell screenshotRegion"),
	{ description = "QuickShell: Capturar região da tela" }
)
hl.bind(
	mainMod .. " + S",
	hl.dsp.exec_cmd("qs ipc call shell screenshotWindow"),
	{ description = "QuickShell: Capturar janela" }
)

-- Lockscreen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"), { description = "Sistema: Bloquear sessão" })

-- Wallpaper
hl.bind(
	mainMod .. " + W",
	hl.dsp.exec_cmd("qs ipc call shell toggleWallpaper"),
	{ description = "QuickShell: Escolher wallpaper" }
)

hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.exec_cmd("qs ipc call shell toggleWallhaven"),
	{ description = "QuickShell: Buscar wallpapers online" }
)
