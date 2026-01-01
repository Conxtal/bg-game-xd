--[[
	Cooldown.lua
	Centralized cooldown tracking
	Location: ReplicatedStorage
]]

local Cooldown = {}
local Data = {}

function Cooldown.Set(player, action, duration)
	Data[player] = Data[player] or {}
	Data[player][action] = tick() + duration
end

function Cooldown.Get(player, action)
	Data[player] = Data[player] or {}
	return Data[player][action] or 0
end

function Cooldown.IsReady(player, action)
	return tick() >= Cooldown.Get(player, action)
end

function Cooldown.GetRemaining(player, action)
	return math.max(0, Cooldown.Get(player, action) - tick())
end

function Cooldown.Clear(player, action)
	if Data[player] then
		Data[player][action] = nil
	end
end

function Cooldown.Cleanup(player)
	Data[player] = nil
end

return Cooldown
