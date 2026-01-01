--[[
	Uptilt.lua
	Handles uptilt/launcher attacks
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(ReplicatedStorage:WaitForChild("State"))
local Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))
local Hitbox = require(ReplicatedStorage:WaitForChild("Hitbox"))

local Uptilt = {}
local Remotes, Registry

function Uptilt.Init(remotes, registry)
	Remotes = remotes
	Registry = registry

	Remotes.Uptilt.OnServerEvent:Connect(Uptilt.OnUptilt)
end

function Uptilt.OnUptilt(player)
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
	if not Cooldown.IsReady(player, "Uptilt") then return end

	-- Get character data
	local charData = Registry.Get(State.GetCharacter(player))
	if not charData or not charData.Uptilt then return end

	-- Check combo restriction
	if charData.Uptilt.MaxComboToUse and data.combo > charData.Uptilt.MaxComboToUse then
		return
	end

	-- Set state
	State.SetState(player, State.ATTACKING)
	Cooldown.Set(player, "Uptilt", Config.Combat.UptiltCooldown)

	-- Reset combo
	data.combo = 0

	-- Slow movement
	hum.WalkSpeed = 3

	-- Startup delay
	task.wait(charData.Uptilt.Startup)

	-- Create hitbox
	local direction = hrp.CFrame.LookVector
	local offset = charData.Uptilt.HitboxOffset or Vector3.new(0, 2, -3)
	local size = charData.Uptilt.HitboxSize or Vector3.new(4, 6, 4)

	local hits = Hitbox.BoxCast(
		hrp.Position + Vector3.new(0, offset.Y, 0),
		size,
		direction,
		10,
		{char}
	)

	-- Process hits
	for _, hit in pairs(hits) do
		if hit.player and hit.player ~= player then
			Uptilt.ProcessHit(player, hit.player, charData.Uptilt, direction)
		end
	end

	-- Recovery
	task.wait(charData.Uptilt.Active + charData.Uptilt.Recovery)

	-- Reset state
	State.SetState(player, State.IDLE)
	hum.WalkSpeed = Config.Player.WalkSpeed
end

function Uptilt.ProcessHit(attacker, victim, uptiltData, direction)
	local victimChar = victim.Character
	local victimHRP = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
	local victimHum = victimChar and victimChar:FindFirstChild("Humanoid")

	if not victimHRP or not victimHum or victimHum.Health <= 0 then return end

	local victimData = State.Get(victim)
	if not victimData then return end

	-- Check if blocking
	local isBlocking = victimData.blocking
	local damage = uptiltData.Damage

	if isBlocking then
		-- Reduced damage and posture
		damage = damage * 0.25
		victimData.posture = (victimData.posture or 0) + uptiltData.PostureDamage
		victimData.lastPostureHit = tick()
	else
		-- Full damage
		victimHum:TakeDamage(damage)

		-- Launch upward
		local launchVelocity = Vector3.new(
			direction.X * (uptiltData.ForwardPush or 4),
			uptiltData.LaunchVelocity or 22,
			direction.Z * (uptiltData.ForwardPush or 4)
		)

		victimHRP.AssemblyLinearVelocity = launchVelocity

		-- Hitstun (airborne state)
		State.SetState(victim, State.AIRBORNE)
		Remotes.State:FireClient(victim, { state = State.AIRBORNE })

		task.delay(uptiltData.Hitstun or 0.28, function()
			if State.GetState(victim) == State.AIRBORNE then
				State.SetState(victim, State.IDLE)
			end
		end)
	end

	-- Send hit event
	Remotes.Hit:FireAllClients({
		attackerPlayer = attacker,
		victimPlayer = victim,
		position = victimHRP.Position,
		hitType = "Uptilt",
		direction = direction,
	})
end

return Uptilt
