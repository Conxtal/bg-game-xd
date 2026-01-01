--[[
	Passive.lua
	Handles passive abilities
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage:WaitForChild("State"))

local Passive = {}
local Remotes, Registry
local PassiveData = {}

function Passive.Init(remotes, registry)
	Remotes = remotes
	Registry = registry
end

function Passive.SetupPlayer(player)
	PassiveData[player] = {
		-- Arthur - Ether Resonance
		stacks = 0,
		lastStackTime = 0,
		buffActive = false,
		buffEndTime = 0,
		lastBuffTrigger = 0,
	}
end

function Passive.OnHit(attacker, victim)
	local data = PassiveData[attacker]
	if not data then return end

	local charData = Registry.Get(State.GetCharacter(attacker))
	if not charData or not charData.Passive then return end

	local passive = charData.Passive

	-- Add stacks
	data.stacks = math.min(passive.MaxStacks, data.stacks + passive.StacksPerHit)
	data.lastStackTime = tick()

	-- Trigger buff at max stacks
	if data.stacks >= passive.MaxStacks then
		local canTrigger = tick() - data.lastBuffTrigger > passive.Cooldown
		if canTrigger and not data.buffActive then
			data.buffActive = true
			data.buffEndTime = tick() + passive.BuffDuration
			data.lastBuffTrigger = tick()

			Remotes.Passive:FireClient(attacker, "BuffActivated")

			task.delay(passive.BuffDuration, function()
				data.buffActive = false
				data.stacks = 0
			end)
		end
	end

	-- Stack decay
	task.delay(passive.StackDuration, function()
		if data and data.lastStackTime and tick() - data.lastStackTime >= passive.StackDuration then
			data.stacks = 0
		end
	end)
end

return Passive
