--[[
	Lock.lua
	Target lock and combat lock system
	Location: StarterPlayer/StarterPlayerScripts
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Lock = {}

-- Target lock state
local TargetLocked = false
local CurrentTarget = nil
local LockConnection = nil

-- Combat lock state
local CombatLocked = false
local CombatTarget = nil
local CombatConnection = nil

-- Settings
local MAX_LOCK_DISTANCE = 50
local CAMERA_OFFSET = Vector3.new(0, 2, 0)
local STANDOFF_DISTANCE = 5
local FOLLOW_SPEED = 80
local ORIENT_SPEED = 70

function Lock.Init()
	-- Toggle target lock on Tab
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Tab then
			Lock.ToggleTargetLock()
		end
	end)
end

function Lock.FindNearestTarget()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local nearest = nil
	local nearestDist = MAX_LOCK_DISTANCE

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= Player and player.Character then
			local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
			local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
			if targetHRP and targetHum and targetHum.Health > 0 then
				local dist = (hrp.Position - targetHRP.Position).Magnitude
				if dist < nearestDist then
					nearest = player.Character
					nearestDist = dist
				end
			end
		end
	end

	return nearest
end

function Lock.ToggleTargetLock()
	if TargetLocked then
		Lock.EndTargetLock()
	else
		local target = Lock.FindNearestTarget()
		if target then
			Lock.StartTargetLock(target)
		end
	end
end

function Lock.StartTargetLock(target)
	if TargetLocked then Lock.EndTargetLock() end

	CurrentTarget = target
	TargetLocked = true

	LockConnection = RunService.RenderStepped:Connect(function()
		if not CurrentTarget or not CurrentTarget.Parent then
			Lock.EndTargetLock()
			return
		end

		local targetHRP = CurrentTarget:FindFirstChild("HumanoidRootPart")
		if not targetHRP then
			Lock.EndTargetLock()
			return
		end

		-- Point camera at target
		local targetPos = targetHRP.Position + CAMERA_OFFSET
		Camera.CFrame = Camera.CFrame:Lerp(
			CFrame.new(Camera.CFrame.Position, targetPos),
			0.3
		)
	end)
end

function Lock.EndTargetLock()
	if LockConnection then
		LockConnection:Disconnect()
		LockConnection = nil
	end
	CurrentTarget = nil
	TargetLocked = false
end

function Lock.StartCombatLock(target, duration)
	if CombatLocked then Lock.EndCombatLock() end

	CombatTarget = target
	CombatLocked = true

	local endTime = tick() + (duration or 999)

	CombatConnection = RunService.Heartbeat:Connect(function(dt)
		if tick() >= endTime or not CombatTarget or not CombatTarget.Parent then
			Lock.EndCombatLock()
			return
		end

		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local targetHRP = CombatTarget:FindFirstChild("HumanoidRootPart")

		if not hrp or not targetHRP then
			Lock.EndCombatLock()
			return
		end

		-- Orient towards target
		local direction = (targetHRP.Position - hrp.Position) * Vector3.new(1, 0, 1)
		if direction.Magnitude > 0.1 then
			local targetCFrame = CFrame.new(hrp.Position, hrp.Position + direction)
			hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, ORIENT_SPEED * dt)
		end

		-- Follow at standoff distance
		local distance = (targetHRP.Position - hrp.Position).Magnitude
		if distance > STANDOFF_DISTANCE then
			local velocity = direction.Unit * FOLLOW_SPEED
			hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(velocity, dt * 5)
		end
	end)
end

function Lock.EndCombatLock()
	if CombatConnection then
		CombatConnection:Disconnect()
		CombatConnection = nil
	end
	CombatTarget = nil
	CombatLocked = false
end

return Lock
