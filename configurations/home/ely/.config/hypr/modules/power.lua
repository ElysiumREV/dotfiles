--------------------
-- POWER STATE
--------------------
-- Decides whether the session should run in "eco" mode (no blur, shadows,
-- dim, transparency or animations). Only applies to machines with a battery,
-- so the desktop always keeps the full visuals.
--
-- Eco is on unless the power profile is "performance" (balanced and
-- power-saver both use eco). scripts/power-watch.sh reloads the config when
-- the profile changes.

local M = {}

local function read(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local value = f:read("l")
	f:close()
	return value
end

local function first_supply(prefix)
	-- BAT0/BAT1, ADP0/ADP1/AC... are the usual names
	for _, name in ipairs({ prefix .. "0", prefix .. "1", prefix }) do
		local value = read("/sys/class/power_supply/" .. name .. "/type")
		if value then
			return "/sys/class/power_supply/" .. name
		end
	end
	return nil
end

M.has_battery = first_supply("BAT") ~= nil

local function performance()
	-- power-profiles-daemon sets EPP to "performance" only in the performance profile
	return read("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference") == "performance"
end

M.eco = M.has_battery and not performance()

return M
