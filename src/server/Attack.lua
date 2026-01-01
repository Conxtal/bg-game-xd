--[[
	Attack.lua
	Handles M1 combo attacks
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(ReplicatedStorage:WaitForChild("State"))
local Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))
local Hitbox = require(ReplicatedStorage:WaitForChild("Hitbox"))

local Attack = {}
local Remotes, Registry
local ActiveAttacks = {}

function Attack.Init(remotes, registry)
	Remotes = remotes
	Registry = registry

	Remotes.Attack.OnServerEvent:Connect(Attack.OnAttack)
end

function Attack.OnAttack(player)
	local data = State.Get(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if not data or not hrp or not hum or hum.Health <= 0 then return end

	-- Check state
	local state = State.GetState(player)
	if state == State.STUNNED or state == State.BLOCKING or state == State.DASHING then
		return
	end

	-- Check cooldown
	if not Cooldown.IsReady(player, "M1") then return end

	-- Get character data
	local charData = Registry.Get(State.GetCharacter(player))
	if not charData or not charData.M1 then return end

	-- Determine combo number
	local combo = (data.combo or 0) + 1
	if combo > charData.M1.MaxCombo then
		combo = 1
	end
	data.combo = combo

	-- Get hit data
	local hitData = charData.M1.Hits[combo]
	if not hitData then return end

	-- Set state
	State.SetState(player, State.ATTACKING)
	Cooldown.Set(player, "M1", Config.Combat.M1Cooldown)

	-- Slow movement during attack
	hum.WalkSpeed = charData.M1.AttackWalkSpeed or 3

	-- Startup delay
	task.wait(hitData.startup)

	-- Create hitbox
	local direction = hrp.CFrame.LookVector
	local hits = Hitbox.BoxCast(
		hrp.Position,
		charData.M1.HitboxSize,
		direction,
		10,
		{char}
	)

	-- Process hits
	for _, hit in pairs(hits) do
		if hit.player and hit.player ~= player then
			Attack.ProcessHit(player, hit.player, combo, hitData, direction)
		end
	end

	-- Recovery
	task.wait(hitData.active + hitData.recovery)

	-- Reset state
	State.SetState(player, State.IDLE)
	hum.WalkSpeed = Config.Player.WalkSpeed

	-- Reset combo after window
	task.delay(charData.M1.ComboWindow, function()
		if data.combo == combo then
			data.combo = 0
		end
	end)
end

function Attack.ProcessHit(attacker, victim, combo, hitData, direction)
	local victimChar = victim.Character
	local victimHRP = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
	local victimHum = victimChar and victimChar:FindFirstChild("Humanoid")

	if not victimHRP or not victimHum or victimHum.Health <= 0 then return end

	local victimData = State.Get(victim)
	if not victimData then return end

	-- Check if blocking
	local isBlocking = victimData.blocking
	local damage = hitData.damage

	if isBlocking then
		-- Reduced damage
		local charData = Registry.Get(State.GetCharacter(victim))
		damage = damage * (1 - (charData.Block.DamageReduction or 0.75))

		-- Posture damage
		victimData.posture = (victimData.posture or 0) + hitData.postureDamage
		victimData.lastPostureHit = tick()

		-- Guard break check
		if victimData.posture >= Config.Combat.Posture.GuardBreakThreshold then
			State.SetState(victim, State.GUARD_BROKEN)
			victimData.blocking = false
			Remotes.State:FireClient(victim, { state = State.GUARD_BROKEN })
			task.delay(charData.Block.BreakStun or 1, function()
				State.SetState(victim, State.IDLE)
			end)
		end
	else
		-- Full damage
		victimHum:TakeDamage(damage)

		-- Knockback
		local knockbackVelocity = direction * (hitData.knockback or 50)
		if hitData.lift then
			knockbackVelocity = knockbackVelocity + Vector3.new(0, hitData.lift, 0)
		end

		victimHRP.AssemblyLinearVelocity = knockbackVelocity

		-- Hitstun
		local charData = Registry.Get(State.GetCharacter(attacker))
		State.SetState(victim, State.STUNNED)
		Remotes.State:FireClient(victim, { state = State.STUNNED })
		task.delay(charData.M1.Hitstun or 0.35, function()
			State.SetState(victim, State.IDLE)
		end)
	end

	-- Send hit event
	Remotes.Hit:FireAllClients({
		attackerPlayer = attacker,
		victimPlayer = victim,
		position = victimHRP.Position,
		combo = combo,
		hitType = combo == 4 and "Final" or "Light",
		direction = direction,
	})
end

return Attack
