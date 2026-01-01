--[[
	ArthurVFX.lua
	VFX for Arthur character
	Location: ReplicatedStorage
]]

local TweenService = game:GetService("TweenService")

local ArthurVFX = {}

ArthurVFX.Colors = {
	Primary = Color3.fromRGB(100, 180, 255),
	PrimaryBright = Color3.fromRGB(150, 220, 255),
	Awakening = Color3.fromRGB(255, 100, 50),
	Electric = Color3.fromRGB(255, 255, 100),
}

-- Helper: Create a part
local function CreatePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = props.Material or Enum.Material.Neon
	part.Color = props.Color or Color3.new(1, 1, 1)
	part.Size = props.Size or Vector3.new(1, 1, 1)
	part.Transparency = props.Transparency or 0
	if props.CFrame then part.CFrame = props.CFrame end
	part.Parent = props.Parent or workspace
	return part
end

-- Helper: Tween and destroy
local function TweenDestroy(part, duration, properties)
	TweenService:Create(part, TweenInfo.new(duration), properties):Play()
	task.delay(duration, function()
		if part then part:Destroy() end
	end)
end

-- M1 VFX
function ArthurVFX.OnM1(character, combo, data)
	-- Placeholder - can add slash effects here
end

-- Hit VFX
function ArthurVFX.OnHit(position, combo, hitType, attackDir, victimChar)
	if hitType == "Final" then
		-- Heavy hit effect
		local impact = CreatePart({
			Size = Vector3.new(3, 3, 3),
			CFrame = CFrame.new(position),
			Color = ArthurVFX.Colors.PrimaryBright,
			Transparency = 0.5,
			Shape = Enum.PartType.Ball,
		})
		TweenDestroy(impact, 0.3, {
			Size = Vector3.new(6, 6, 6),
			Transparency = 1,
		})
	else
		-- Light hit effect
		local impact = CreatePart({
			Size = Vector3.new(1.5, 1.5, 1.5),
			CFrame = CFrame.new(position),
			Color = ArthurVFX.Colors.Primary,
			Transparency = 0.6,
			Shape = Enum.PartType.Ball,
		})
		TweenDestroy(impact, 0.2, {
			Size = Vector3.new(3, 3, 3),
			Transparency = 1,
		})
	end
end

-- Uptilt VFX
function ArthurVFX.OnUptilt(character, data)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local slash = CreatePart({
		Size = Vector3.new(0.3, 4, 0.1),
		CFrame = hrp.CFrame * CFrame.new(0, 2, -2),
		Color = ArthurVFX.Colors.PrimaryBright,
		Transparency = 0.3,
	})

	TweenDestroy(slash, 0.15, {
		Size = Vector3.new(0.5, 6, 0.1),
		Transparency = 1,
	})
end

-- Dash VFX
function ArthurVFX.OnDash(character, direction, data)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Afterimage effect
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local clone = part:Clone()
			clone:ClearAllChildren()
			clone.Anchored = true
			clone.CanCollide = false
			clone.CastShadow = false
			clone.Material = Enum.Material.Neon
			clone.Color = ArthurVFX.Colors.Primary
			clone.Transparency = 0.6
			clone.Parent = workspace
			TweenDestroy(clone, 0.25, { Transparency = 1 })
		end
	end
end

-- Block start VFX
function ArthurVFX.OnBlockStart(character, data)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local shield = CreatePart({
		Size = Vector3.new(4, 5, 0.2),
		CFrame = hrp.CFrame * CFrame.new(0, 0, -2),
		Color = ArthurVFX.Colors.Primary,
		Transparency = 0.7,
	})
	shield.Name = "BlockShield"

	-- Attach to character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = shield
	weld.Parent = shield

	shield.Parent = character
end

-- Block end VFX
function ArthurVFX.OnBlockEnd(character)
	local shield = character:FindFirstChild("BlockShield")
	if shield then
		shield:Destroy()
	end
end

return ArthurVFX
