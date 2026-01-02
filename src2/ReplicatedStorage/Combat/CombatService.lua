--[[
	CombatService.lua
	Main combat orchestrator - handles M1, Uptilt, aerial combat

	SERVER AUTHORITY ONLY
]]

local CombatService = {}

-- Dependencies (injected)
local StateService, HitboxService, DamageService, StunService, IFrameService, HitstopService
local CharacterService, CombatLockService

-- State
local ActiveAttacks = {}
local CooldownService = {} -- Simple internal cooldowns

function CombatService.Init(dependencies)
	StateService = dependencies.StateService
	HitboxService = dependencies.HitboxService
	DamageService = dependencies.DamageService
	StunService = dependencies.StunService
	IFrameService = dependencies.IFrameService
	HitstopService = dependencies.HitstopService
	CharacterService = dependencies.CharacterService
	CombatLockService = dependencies.CombatLockService

	print("[CombatService] Initialized")
end

-- M1 Attack
function CombatService.ProcessM1(player)
	local data = StateService.Get(player)
	if not data then return false end

	-- Must be grounded or airborne (not stunned)
	local state = StateService.GetState(player)
	if state ~= StateService.PRIMARY_STATES.GROUNDED and state ~= StateService.PRIMARY_STATES.AIRBORNE then
		return false
	end

	-- Check blocking
	if StateService.HasSubState(player, StateService.SUB_STATES.BLOCKING) then
		return false
	end

	-- Check cooldown
	if not CombatService.IsReady(player, "M1") then
		return false
	end

	-- Get character data
	local charData = CharacterService.Get(player)
	if not charData or not charData.M1 then return false end

	-- Combo logic
	local timeSinceAttack = tick() - data.lastAttack
	if timeSinceAttack > charData.M1.ComboWindow then
		data.combo = 0
	end

	-- Check max combo
	if data.combo >= charData.M1.MaxCombo then
		return false
	end

	-- Increment combo
	data.combo = data.combo + 1
	data.lastAttack = tick()

	local hitData = charData.M1.Hits[data.combo]
	if not hitData then
		data.combo = 0
		return false
	end

	-- Set cooldown
	local totalTime = hitData.startup + hitData.active + hitData.recovery
	CombatService.SetCooldown(player, "M1", totalTime)

	-- Add combat sub-state
	StateService.AddSubState(player, StateService.SUB_STATES.COMBAT)

	-- Execute attack
	task.spawn(function()
		CombatService.ExecuteM1(player, data.combo, hitData, charData)
	end)

	return true
end

function CombatService.ExecuteM1(player, combo, hitData, charData)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Startup
	task.wait(hitData.startup)

	-- Active hitbox window
	local direction = hrp.CFrame.LookVector
	local hits = {}
	local activeStart = tick()

	while tick() - activeStart < hitData.active do
		local parts = HitboxService.CreateBox(
			hrp.Position,
			charData.M1.HitboxSize or Vector3.new(4, 4, 5),
			direction,
			10,
			{char}
		)

		local results = HitboxService.ProcessHits(parts, player)
		for _, hit in ipairs(results) do
			if not hits[hit.character] and hit.player then
				hits[hit.character] = true
				CombatService.ProcessHit(player, hit.player, hitData, charData, direction)
			end
		end

		task.wait()
	end

	-- Recovery
	task.wait(hitData.recovery)

	-- Remove combat sub-state if combo ended
	local data = StateService.Get(player)
	if data and tick() - data.lastAttack > 0.3 then
		StateService.RemoveSubState(player, StateService.SUB_STATES.COMBAT)
		data.combo = 0
	end
end

function CombatService.ProcessHit(attacker, victim, hitData, charData, direction)
	-- Check i-frames
	if IFrameService.Has(victim) then return end

	local victimChar = victim.Character
	if not victimChar then return end

	local victimHRP = victimChar:FindFirstChild("HumanoidRootPart")
	if not victimHRP then return end

	-- Calculate damage
	local damage = DamageService.Calculate(attacker, victim, hitData.damage, {
		statMultiplier = charData.Stats.Damage or 1,
	})

	-- Apply damage
	DamageService.Apply(victim, damage, attacker)

	-- Apply knockback
	local knockbackVel = direction * (hitData.knockback or 50)
	if hitData.lift then
		knockbackVel = knockbackVel + Vector3.new(0, hitData.lift, 0)
	end
	victimHRP.AssemblyLinearVelocity = knockbackVel

	-- Apply hitstun
	StunService.ApplyHitstun(victim, charData.M1.Hitstun or 0.35, StunService.TYPES.HIT)

	-- Hitstop for impact feel
	HitstopService.Apply(attacker, victim, 0.05)

	-- Combat lock (lock to first hit)
	if CombatLockService then
		CombatLockService.LockToTarget(attacker, victim, 1.0)
	end
end

-- Simple cooldown system
function CombatService.SetCooldown(player, action, duration)
	CooldownService[player] = CooldownService[player] or {}
	CooldownService[player][action] = tick() + duration
end

function CombatService.IsReady(player, action)
	if not CooldownService[player] then return true end
	local endTime = CooldownService[player][action]
	return not endTime or tick() >= endTime
end

function CombatService.Cleanup(player)
	CooldownService[player] = nil
	ActiveAttacks[player] = nil
end

return CombatService
