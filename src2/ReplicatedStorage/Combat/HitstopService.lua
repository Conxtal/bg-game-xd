--[[
	HitstopService.lua
	Brief freeze on hit for impact feel
]]

local HitstopService = {}

function HitstopService.Init()
	print("[HitstopService] Initialized")
end

function HitstopService.Apply(attacker, victim, duration)
	-- Freeze both attacker and victim briefly
	HitstopService.FreezeCharacter(attacker, duration)
	HitstopService.FreezeCharacter(victim, duration)
end

function HitstopService.FreezeCharacter(player, duration)
	if not player or not player.Character then return end

	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	if not hrp or not humanoid then return end

	-- Store velocity
	local storedVelocity = hrp.AssemblyLinearVelocity
	local storedWalkSpeed = humanoid.WalkSpeed

	-- Freeze
	hrp.Anchored = true
	humanoid.WalkSpeed = 0

	-- Unfreeze after duration
	task.delay(duration, function()
		if hrp and hrp.Parent then
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = storedVelocity
		end
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = storedWalkSpeed
		end
	end)
end

return HitstopService
