--[[
	UptiltHandler.lua
	Handles Uptilt (launcher) attacks
	Location: ServerScriptService/Combat/Handlers/UptiltHandler
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local Hitbox = require(CombatFolder.Modules.HitboxHandler)
local State = require(CombatFolder.Modules.StateManager)
local Cooldown = require(CombatFolder.Modules.CooldownManager)
local Config = require(CombatFolder.Config)

local UptiltHandler = {}

local Remotes = nil
local CharacterManager = nil
local PassiveHandler = nil
local BlockHandler = nil
local ActiveUptilts = {}
local LastRequest = {}

function UptiltHandler.Init(remotes, charManager)
	Remotes = remotes
	CharacterManager = charManager
	PassiveHandler = require(script.Parent.PassiveHandler)
	BlockHandler = require(script.Parent.BlockHandler)

	Remotes.Uptilt.OnServerEvent:Connect(function(player)
		UptiltHandler.OnUptilt(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ActiveUptilts[player] = nil
		LastRequest[player] = nil
	end)

	print("[UptiltHandler] Initialized")
	return UptiltHandler
end

function UptiltHandler.OnUptilt(player)
	-- Server-side request throttling
	local now = tick()
	local lastReq = LastRequest[player] or 0
	if now - lastReq < 0.05 then return end
	LastRequest[player] = now

	local data = State.Get(player)
	if not data then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	local charName = State.GetCharacter(player)
	local charData = CharacterManager.Get(charName)
	if not charData or not charData.Uptilt then return end

	local uptiltData = charData.Uptilt

	-- State checks
	if State.IsStunned(player) or State.IsBlocking(player) or State.IsDashing(player) or State.IsGuardBroken(player) then
		return
	end

	-- Combo limit check (can't uptilt after certain combo hits)
	local currentCombo = State.GetCombo(player)
	if uptiltData.MaxComboToUse and currentCombo > uptiltData.MaxComboToUse then
		return
	end

	-- Cooldown check
	if not Cooldown.IsReady(player, Cooldown.Actions.Uptilt) then
		return
	end

	-- Reset combo when using uptilt
	State.ResetCombo(player)

	-- Set cooldown
	local totalTime = uptiltData.Startup + uptiltData.Active + uptiltData.Recovery
	Cooldown.Set(player, Cooldown.Actions.Uptilt, totalTime)

	State.SetState(player, State.States.ATTACKING)

	-- Fire to clients
	Remotes.State:FireAllClients(player, "Uptilt", {
		character = charName,
	})

	local uptiltId = tick()
	ActiveUptilts[player] = uptiltId

	-- Calculate damage with passive bonus
	local damage = uptiltData.Damage * (charData.Stats.Damage or 1)
	local launchVelocity = uptiltData.LaunchVelocity
	local forwardPush = uptiltData.ForwardPush
	local postureDamage = uptiltData.PostureDamage or (damage * 0.8)

	-- Apply passive damage bonus
	if PassiveHandler then
		local passiveBonus = PassiveHandler.GetDamageMultiplier(player)
		damage = damage * passiveBonus
	end

	if data.awakened and charData.Awakening then
		damage = damage * (charData.Awakening.DamageMultiplier or 1)
	end

	-- Startup
	task.wait(uptiltData.Startup)
	if ActiveUptilts[player] ~= uptiltId then return end

	-- Hitbox
	local hitboxSize = uptiltData.HitboxSize or Vector3.new(4, 6, 4)
	local hitboxOffset = uptiltData.HitboxOffset or Vector3.new(0, 2, -3)

	local hasHit = {}
	local activeStart = tick()
	local hitOccurred = false

	while tick() - activeStart < uptiltData.Active do
		if ActiveUptilts[player] ~= uptiltId then return end

		local origin = hrp.CFrame * CFrame.new(hitboxOffset)

		Hitbox.Box(origin, hitboxSize, {char}, function(victimPlayer, victimChar, victimHum, victimHrp)
			if hasHit[victimChar] then return end
			hasHit[victimChar] = true
			hitOccurred = true

			UptiltHandler.ApplyHit(player, victimPlayer, victimChar, victimHum, victimHrp, {
				damage = damage,
				launchVelocity = launchVelocity,
				forwardPush = forwardPush,
				postureDamage = postureDamage,
				hitstun = uptiltData.Hitstun,
				charData = charData,
			})
		end)

		task.wait()
	end

	if ActiveUptilts[player] ~= uptiltId then return end

	-- Recovery (shorter if hit landed)
	local recoveryTime = hitOccurred and (uptiltData.RecoveryOnHit or uptiltData.Recovery) or uptiltData.Recovery
	State.SetState(player, State.States.RECOVERY)
	task.wait(recoveryTime)

	if ActiveUptilts[player] ~= uptiltId then return end

	if State.IsRecovery(player) then
		State.SetState(player, State.States.IDLE)
	end

	ActiveUptilts[player] = nil
end

function UptiltHandler.ApplyHit(attacker, victimPlayer, victimChar, victimHum, victimHrp, hitInfo)
	local attackerChar = attacker.Character
	local attackerHrp = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerHrp then return end

	local damage = hitInfo.damage
	local launchVelocity = hitInfo.launchVelocity
	local forwardPush = hitInfo.forwardPush
	local postureDamage = hitInfo.postureDamage
	local hitstun = hitInfo.hitstun
	local charData = hitInfo.charData

	local blocked = nil
	local actualDamage = damage

	-- Check for block/iframes
	if victimPlayer then
		local vd = State.Get(victimPlayer)

		if vd and State.HasIFrames(victimPlayer) then
			return
		end

		State.UpdatePressure(victimPlayer)

		if vd and State.IsBlockingActive(victimPlayer) then
			-- Process blocked uptilt
			blocked, actualDamage, _ = BlockHandler.ProcessBlockedHit(attacker, victimPlayer, {
				damage = damage,
				knockback = 0,
				postureDamage = postureDamage,
			})
		else
			State.DamagePosture(victimPlayer, postureDamage)
		end
	end

	-- Apply damage
	if actualDamage > 0 then
		victimHum:TakeDamage(actualDamage)
	end

	-- Apply launch (if not blocked or deflected)
	if not blocked or blocked == "Normal" then
		local launchDir = attackerHrp.CFrame.LookVector
		local launchVec = Vector3.new(launchDir.X * forwardPush, launchVelocity, launchDir.Z * forwardPush)
		victimHrp.AssemblyLinearVelocity = launchVec
	end

	-- Apply hitstun (player only)
	if not blocked and victimPlayer then
		local vd = State.Get(victimPlayer)
		if vd then
			State.SetState(victimPlayer, State.States.STUNNED)

			task.delay(hitstun, function()
				if victimPlayer and State.IsStunned(victimPlayer) then
					State.SetState(victimPlayer, State.States.IDLE)
				end
			end)
		end
	end

	-- Call PassiveHandler
	if PassiveHandler and not blocked then
		PassiveHandler.OnHit(attacker, victimPlayer, hitInfo)
	end

	-- Fire hit event to clients
	Remotes.Hit:FireAllClients({
		attacker = attacker,
		victim = victimPlayer,
		victimChar = victimChar,
		position = victimHrp.Position,
		damage = actualDamage,
		knockback = 0,
		combo = 0,
		hitType = "Uptilt",
		blocked = blocked,
		attackDir = attackerHrp.CFrame.LookVector,
	})
end

function UptiltHandler.CancelUptilt(player)
	ActiveUptilts[player] = nil
end

return UptiltHandler
