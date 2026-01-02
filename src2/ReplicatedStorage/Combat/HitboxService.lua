--[[
	HitboxService.lua
	Hitbox detection abstraction
]]

local HitboxService = {}

function HitboxService.Init()
	print("[HitboxService] Initialized")
end

local function GetCharacterFromPart(part)
	local current = part
	while current do
		local humanoid = current:FindFirstChildOfClass("Humanoid")
		local hrp = current:FindFirstChild("HumanoidRootPart")
		if humanoid and hrp then
			return current, humanoid, hrp
		end
		current = current.Parent
	end
	return nil, nil, nil
end

local function GetPlayerFromCharacter(character)
	local Players = game:GetService("Players")
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character == character then
			return player
		end
	end
	return nil
end

function HitboxService.CreateBox(origin, size, direction, distance, filter)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = filter or {}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local cframe = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -distance/2)
	return workspace:GetPartBoundsInBox(cframe, size, params)
end

function HitboxService.CreateSphere(origin, radius, filter)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = filter or {}
	params.FilterType = Enum.RaycastFilterType.Exclude

	return workspace:GetPartBoundsInRadius(origin, radius, params)
end

function HitboxService.ProcessHits(parts, attacker)
	local results = {}
	local seen = {}

	for _, part in pairs(parts) do
		local char, hum, hrp = GetCharacterFromPart(part)
		if char and hum and hum.Health > 0 then
			if not seen[char] then
				seen[char] = true

				local player = GetPlayerFromCharacter(char)

				-- Skip if hitting self
				if player ~= attacker then
					table.insert(results, {
						character = char,
						humanoid = hum,
						rootPart = hrp,
						player = player,
						part = part,
					})
				end
			end
		end
	end

	return results
end

-- Multi-frame detection for active hitbox windows
function HitboxService.DetectMultiFrame(hitboxFunc, duration)
	local hits = {}
	local seen = {}
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			local parts = hitboxFunc()
			for _, part in pairs(parts) do
				local char = GetCharacterFromPart(part)
				if char and not seen[char] then
					seen[char] = true
					table.insert(hits, part)
				end
			end
			task.wait()
		end
	end)

	return hits, seen
end

return HitboxService
