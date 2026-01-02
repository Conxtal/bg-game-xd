--[[
	DamageService.lua
	Damage calculation with all modifiers
]]

local DamageService = {}

local StateService = nil

function DamageService.Init(dependencies)
	StateService = dependencies.StateService
	print("[DamageService] Initialized")
end

function DamageService.Calculate(attacker, victim, baseDamage, damageData)
	local attackerData = StateService.Get(attacker)
	local victimData = StateService.Get(victim)

	if not attackerData or not victimData then
		return baseDamage
	end

	local finalDamage = baseDamage

	-- Attacker modifiers
	if damageData then
		-- Character stat multiplier
		if damageData.statMultiplier then
			finalDamage = finalDamage * damageData.statMultiplier
		end

		-- Passive bonus
		if damageData.passiveBonus then
			finalDamage = finalDamage * damageData.passiveBonus
		end

		-- Awakening multiplier
		if attackerData.awakened and damageData.awakeningMultiplier then
			finalDamage = finalDamage * damageData.awakeningMultiplier
		end
	end

	-- Victim modifiers
	if victimData.blocking and damageData and damageData.blockReduction then
		finalDamage = finalDamage * (1 - damageData.blockReduction)
	end

	return math.floor(finalDamage + 0.5)
end

function DamageService.Apply(victim, damage, source)
	local char = victim.Character
	if not char then return false end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	humanoid:TakeDamage(damage)
	return true
end

return DamageService
