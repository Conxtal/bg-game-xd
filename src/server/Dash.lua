--[[
	Dash.lua
	Handles dashing with i-frames
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(ReplicatedStorage:WaitForChild("State"))
local Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))

local Dash = {}
local Remotes, Registry

function Dash.Init(remotes, registry)
	Remotes = remotes
	Registry = registry

	Remotes.Dash.OnServerEvent:Connect(Dash.OnDash)
end

function Dash.OnDash(player)
	local data = State.Get(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if not data or not hrp or not hum or hum.Health <= 0 then return end

	-- Check state
	local state = State.GetState(player)
	if state == State.STUNNED or state == State.DASHING then
		return
	end

	-- Check cooldown
	if not Cooldown.IsReady(player, "Dash") then return end

	-- Get character data
	local charData = Registry.Get(State.GetCharacter(player))
	if not charData or not charData.Dash then return end

	-- Check stamina
	if data.stamina < charData.Dash.StaminaCost then return end

	-- Consume stamina
	data.stamina = data.stamina - charData.Dash.StaminaCost
	data.lastStaminaUse = tick()

	-- Set state
	State.SetState(player, State.DASHING)
	Cooldown.Set(player, "Dash", charData.Dash.Cooldown)

	-- Calculate dash direction
	local moveDirection = hum.MoveDirection
	if moveDirection.Magnitude < 0.1 then
		moveDirection = hrp.CFrame.LookVector
	end

	-- Apply dash velocity
	local dashVelocity = moveDirection * (charData.Dash.Distance / charData.Dash.Duration)
	hrp.AssemblyLinearVelocity = Vector3.new(dashVelocity.X, hrp.AssemblyLinearVelocity.Y, dashVelocity.Z)

	-- I-frames
	local originalHealth = hum.Health
	local iframeConnection
	iframeConnection = hum.HealthChanged:Connect(function(health)
		if health < originalHealth then
			hum.Health = originalHealth
		end
	end)

	task.delay(charData.Dash.IFrames, function()
		if iframeConnection then
			iframeConnection:Disconnect()
		end
	end)

	-- End dash
	task.delay(charData.Dash.Duration, function()
		if State.GetState(player) == State.DASHING then
			State.SetState(player, State.IDLE)
		end
	end)
end

return Dash
