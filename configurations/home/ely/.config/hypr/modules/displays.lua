--------------------
-- EXTERNAL DISPLAYS (notebook)
--------------------
-- On the notebook, anything plugged into HDMI/DP is usually a projector, so it
-- mirrors the built-in panel right away, at the LOWEST refresh rate the
-- projector advertises (some classroom projectors show nothing at 60 Hz).
--
-- The computer can't tell whether the projector actually shows an image, so
-- stepping down is manual:
--   SUPER + CTRL + P          next resolution (1080p -> 1366x768 -> 720p -> ...),
--                             only modes the projector advertises, then wraps
--   SUPER + CTRL + SHIFT + P  toggle mirror / extend (extend = preferred mode)
-- The last mode picked is remembered per projector (by its EDID description)
-- in ~/.local/state/hypr-display-modes, so next time it starts with that one.
-- The desktop keeps the plain fallback rule from hyprland.lua.

local power = require("modules.power")

if not power.has_battery then
	return
end

local INTERNAL = "eDP-1"
local MIN_REFRESH = 23 -- ignore odd modes below this
local NOTIFY_ID = 47011 -- replace the previous notification instead of stacking

local saved_file = (os.getenv("HOME") or "") .. "/.local/state/hypr-display-modes"
-- Kept in $XDG_RUNTIME_DIR because every config reload (power-watch.sh does one
-- on profile changes) re-runs this file.
local layout_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-display-layout"

-- "key<TAB>value" files
local function load(path)
	local t = {}
	local f = io.open(path, "r")
	if f then
		for line in f:lines() do
			local k, v = line:match("^(.-)\t(.+)$")
			if k then
				t[k] = v
			end
		end
		f:close()
	end
	return t
end

local function store(path, t)
	local f = io.open(path, "w")
	if not f then
		return
	end
	for k, v in pairs(t) do
		f:write(k, "\t", v, "\n")
	end
	f:close()
end

local saved = load(saved_file) -- description -> "WxH@Hz"
local layout = load(layout_file) -- output name -> "mirror" | "extend"

local function mode_string(m)
	return string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate)
end

-- One mode per advertised resolution, largest first, each at its lowest
-- usable refresh rate. The preferred resolution goes first.
local function ladder(monitor)
	local modes = monitor.available_modes
	if type(modes) ~= "table" then
		return {}
	end
	local by_res, pref_key = {}, nil
	for _, m in pairs(modes) do
		if m.refresh_rate >= MIN_REFRESH then
			local key = m.width .. "x" .. m.height
			local cur = by_res[key]
			if not cur or m.refresh_rate < cur.refresh_rate then
				by_res[key] = m
			end
			if m.preferred then
				pref_key = key
			end
		end
	end
	local list = {}
	for key, m in pairs(by_res) do
		if key ~= pref_key then
			list[#list + 1] = m
		end
	end
	table.sort(list, function(a, b)
		if a.width * a.height ~= b.width * b.height then
			return a.width * a.height > b.width * b.height
		end
		return a.width > b.width
	end)
	if pref_key then
		table.insert(list, 1, by_res[pref_key])
	end
	local out = {}
	for i, m in ipairs(list) do
		out[i] = mode_string(m)
	end
	return out
end

local function index_of(list, value)
	for i, v in ipairs(list) do
		if v == value then
			return i
		end
	end
	return nil
end

local function key_of(monitor)
	local d = monitor.description
	return (d and d ~= "") and d or monitor.name
end

local function notify(text)
	text = text:gsub("'", "")
	hl.exec_cmd("notify-send -a Hyprland -i video-display -r " .. NOTIFY_ID .. " 'External display' '" .. text .. "'")
end

-- Mode to use for a mirrored output: the remembered one if still advertised,
-- else the top of the ladder.
local function current_mode(monitor)
	local list = ladder(monitor)
	if #list == 0 then
		return "preferred", 0, 0
	end
	local i = index_of(list, saved[key_of(monitor)]) or 1
	return list[i], i, #list
end

local function apply(monitor, silent)
	local name = monitor.name
	if (layout[name] or "mirror") == "mirror" then
		local mode, i, n = current_mode(monitor)
		hl.monitor({ output = name, mode = mode, position = "auto", scale = 1, mirror = INTERNAL })
		if not silent then
			notify(string.format(
				"Mirroring at %s (%d/%d)\nNo image? SUPER+CTRL+P tries the next resolution.\nSUPER+CTRL+SHIFT+P extends instead.",
				mode, i, n))
		end
	else
		hl.monitor({ output = name, mode = "preferred", position = "auto-right", scale = 1, cm = "auto" })
		if not silent then
			notify("Extending to " .. name .. "\nSUPER+CTRL+SHIFT+P mirrors again.")
		end
	end
end

-- Any output without its own rule mirrors the panel from the moment it appears.
-- With an extend fallback, Hyprland first gave the projector a new empty
-- workspace, which then moved to the panel and stayed active there.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = INTERNAL })

-- Last workspace with windows shown on the panel, to go back to it if a
-- hotplug still leaves the panel on an empty workspace.
local last_ws = nil

local function panel_workspace()
	local panel = hl.get_monitor(INTERNAL)
	return panel and panel.active_workspace or nil
end

do
	local ws = panel_workspace()
	if ws and not ws.is_empty then
		last_ws = ws.id
	end
end

hl.on("workspace.active", function()
	local ws = panel_workspace()
	if ws and not ws.is_empty then
		last_ws = ws.id
	end
end)

local function restore_workspace()
	local ws = panel_workspace()
	if last_ws and ws and ws.is_empty and ws.id ~= last_ws then
		hl.dispatch(hl.dsp.focus({ workspace = last_ws }))
	end
end

local function externals()
	local list = {}
	for _, m in ipairs(hl.get_monitors({ all = true }) or {}) do
		if m.name ~= INTERNAL and m.enabled ~= false then
			list[#list + 1] = m
		end
	end
	return list
end

hl.on("monitor.added", function(monitor)
	if monitor and monitor.name ~= INTERNAL then
		apply(monitor, false)
		hl.timer(restore_workspace, { timeout = 500, type = "oneshot" })
	end
end)

hl.on("monitor.removed", function(monitor)
	if monitor then
		layout[monitor.name] = nil
		store(layout_file, layout)
	end
end)

-- Re-apply on every config load; reloads reset runtime monitor rules.
for _, m in ipairs(externals()) do
	apply(m, true)
end

hl.bind("SUPER + CTRL + P", function()
	for _, m in ipairs(externals()) do
		local was_mirror = (layout[m.name] or "mirror") == "mirror"
		layout[m.name] = "mirror"
		local list = ladder(m)
		if was_mirror and #list > 0 then
			local _, i = current_mode(m)
			saved[key_of(m)] = list[i % #list + 1]
		end
		apply(m, false)
	end
	store(layout_file, layout)
	store(saved_file, saved)
end, { description = "Monitors: Try next resolution on external display (projector)" })

hl.bind("SUPER + CTRL + SHIFT + P", function()
	for _, m in ipairs(externals()) do
		layout[m.name] = (layout[m.name] or "mirror") == "mirror" and "extend" or "mirror"
		apply(m, false)
	end
	store(layout_file, layout)
end, { description = "Monitors: Toggle mirror / extend on external display" })
