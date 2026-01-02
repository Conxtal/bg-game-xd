--[[
	IFrameService.lua
	Invulnerability frame management
]]

local IFrameService = {}

local ActiveIFrames = {}

function IFrameService.Init()
	print("[IFrameService] Initialized")
end

function IFrameService.Grant(player, duration)
	if not player or not player.Character then return end

	local endTime = tick() + duration
	ActiveIFrames[player] = endTime

	-- Auto-cleanup after duration
	task.delay(duration, function()
		if ActiveIFrames[player] == endTime then
			ActiveIFrames[player] = nil
		end
	end)
end

function IFrameService.Has(player)
	if not ActiveIFrames[player] then return false end

	if tick() >= ActiveIFrames[player] then
		ActiveIFrames[player] = nil
		return false
	end

	return true
end

function IFrameService.GetRemaining(player)
	if not ActiveIFrames[player] then return 0 end

	local remaining = ActiveIFrames[player] - tick()
	if remaining <= 0 then
		ActiveIFrames[player] = nil
		return 0
	end

	return remaining
end

function IFrameService.Remove(player)
	ActiveIFrames[player] = nil
end

function IFrameService.Cleanup(player)
	ActiveIFrames[player] = nil
end

return IFrameService
