--[[
	Hitbox.lua
	Hitbox detection utilities
	Location: ReplicatedStorage
]]

local Hitbox = {}
Hitbox.Debug = false

local function GetCharacter(part)
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

local function GetPlayer(character)
	local Players = game:GetService("Players")
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character == character then
			return player
		end
	end
	return nil
end

function Hitbox.BoxCast(origin, size, direction, maxDistance, filterList)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = filterList or {}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local cframe = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -maxDistance/2)
	local hits = workspace:GetPartBoundsInBox(cframe, size, params)

	local results = {}
	for _, hit in pairs(hits) do
		local char, hum, hrp = GetCharacter(hit)
		if char and hum then
			local player = GetPlayer(char)
			table.insert(results, {
				character = char,
				humanoid = hum,
				rootPart = hrp,
				player = player,
				part = hit,
			})
		end
	end

	return results
end

function Hitbox.Sphere(origin, radius, filterList)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = filterList or {}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local hits = workspace:GetPartBoundsInRadius(origin, radius, params)

	local results = {}
	for _, hit in pairs(hits) do
		local char, hum, hrp = GetCharacter(hit)
		if char and hum then
			local player = GetPlayer(char)
			table.insert(results, {
				character = char,
				humanoid = hum,
				rootPart = hrp,
				player = player,
				part = hit,
			})
		end
	end

	return results
end

return Hitbox
