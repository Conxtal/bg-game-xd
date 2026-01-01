--[[
	Ability.lua
	Handles ability slot activation (1-4)
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage:WaitForChild("State"))
local Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))
local Hitbox = require(ReplicatedStorage:WaitForChild("Hitbox"))

local Ability = {}
local Remotes, Registry

function Ability.Init(remotes, registry)
	Remotes = remotes
	Registry = registry

	Remotes.Ability.OnServerEvent:Connect(Ability.OnAbility)
end

function Ability.OnAbility(player, slot)
	local data = State.Get(player)
	if not data then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if not hrp or not hum or hum.Health <= 0 then return end

	-- Get character data
	local charData = Registry.Get(State.GetCharacter(player))
	if not charData then return end

	-- Get ability list
	local abilities = data.awakened and charData.AwakeningAbilities or charData.Abilities
	if not abilities or not abilities[slot] then return end

	local abilityName = abilities[slot]
	local abilityData = charData.AbilityData and charData.AbilityData[abilityName]

	if not abilityData then return end

	-- Check cooldown
	if not Cooldown.IsReady(player, "Ability" .. slot) then return end

	-- Check stamina
	if abilityData.StaminaCost and data.stamina < abilityData.StaminaCost then
		return
	end

	-- Execute ability (simplified - just basic hitbox)
	Cooldown.Set(player, "Ability" .. slot, abilityData.Cooldown or 5)

	if abilityData.StaminaCost then
		data.stamina = data.stamina - abilityData.StaminaCost
		data.lastStaminaUse = tick()
	end

	-- Notify clients
	Remotes.Notification:FireClient(player, "Used " .. abilityName, "Ability")

	-- Simple hitbox for abilities
	if abilityData.HitboxSize then
		task.wait(abilityData.Startup or 0)
		local direction = hrp.CFrame.LookVector
		local hits = Hitbox.BoxCast(
			hrp.Position,
			abilityData.HitboxSize,
			direction,
			10,
			{char}
		)

		for _, hit in pairs(hits) do
			if hit.player and hit.player ~= player and hit.humanoid then
				hit.humanoid:TakeDamage(abilityData.Damage or 10)
			end
		end
	end
end

return Ability
