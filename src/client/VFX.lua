--[[
	VFX.lua
	Handles visual effects
	Location: StarterPlayer/StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VFX = {}
local CharacterVFX = {}

function VFX.Init()
	-- Load character VFX modules
	local vfxFolder = ReplicatedStorage:WaitForChild("vfx")
	for _, module in pairs(vfxFolder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local success, vfxModule = pcall(require, module)
			if success then
				CharacterVFX[module.Name] = vfxModule
			end
		end
	end
end

function VFX.GetVFX(characterName)
	return CharacterVFX[characterName .. "VFX"]
end

function VFX.PlayHitEffect(data)
	local vfxModule = VFX.GetVFX(data.attackerCharacter or "Arthur")
	if vfxModule and vfxModule.OnHit then
		vfxModule.OnHit(data.position, data.combo, data.hitType, data.direction, data.victimCharacter)
	end
end

function VFX.PlayM1Effect(character, combo, data)
	local vfxModule = VFX.GetVFX("Arthur")
	if vfxModule and vfxModule.OnM1 then
		vfxModule.OnM1(character, combo, data)
	end
end

function VFX.PlayDashEffect(character, direction, data)
	local vfxModule = VFX.GetVFX("Arthur")
	if vfxModule and vfxModule.OnDash then
		vfxModule.OnDash(character, direction, data)
	end
end

function VFX.PlayBlockStart(character, data)
	local vfxModule = VFX.GetVFX("Arthur")
	if vfxModule and vfxModule.OnBlockStart then
		vfxModule.OnBlockStart(character, data)
	end
end

function VFX.PlayBlockEnd(character)
	local vfxModule = VFX.GetVFX("Arthur")
	if vfxModule and vfxModule.OnBlockEnd then
		vfxModule.OnBlockEnd(character)
	end
end

function VFX.PlayUptilt(character, data)
	local vfxModule = VFX.GetVFX("Arthur")
	if vfxModule and vfxModule.OnUptilt then
		vfxModule.OnUptilt(character, data)
	end
end

return VFX
