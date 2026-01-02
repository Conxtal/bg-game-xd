--[[
	MovementHandler.lua
	Handles player movement restrictions during combat states
	Location: StarterPlayer/StarterPlayerScripts/Combat/Handlers/MovementHandler
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local Config = require(CombatFolder.Config)

local MovementHandler = {}

-- State
local currentState = "Idle"
local isInCombatLock = false
local customWalkSpeed = nil
local customJumpPower = nil
local defaultWalkSpeed = Config.Player.WalkSpeed
local defaultJumpPower = Config.Player.JumpPower

-- Character references
local character = nil
local humanoid = nil

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function MovementHandler.Init()
	-- Wait for character
	if Player.Character then
		MovementHandler.SetupCharacter(Player.Character)
	end

	Player.CharacterAdded:Connect(MovementHandler.SetupCharacter)

	print("[MovementHandler] Initialized")
	return MovementHandler
end

function MovementHandler.SetupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 5)

	if humanoid then
		-- Reset to defaults
		humanoid.WalkSpeed = defaultWalkSpeed
		humanoid.JumpPower = defaultJumpPower

		-- Reset state
		currentState = "Idle"
		isInCombatLock = false
		customWalkSpeed = nil
		customJumpPower = nil
	end

	-- Listen for character death
	if humanoid then
		humanoid.Died:Connect(function()
			MovementHandler.Reset()
		end)
	end
end

function MovementHandler.Reset()
	currentState = "Idle"
	isInCombatLock = false
	customWalkSpeed = nil
	customJumpPower = nil
end

--------------------------------------------------------------------------------
-- STATE MANAGEMENT
--------------------------------------------------------------------------------

function MovementHandler.SetState(state, options)
	currentState = state
	options = options or {}

	if not humanoid then return end

	-- Reset to custom or defaults first
	local baseWalkSpeed = customWalkSpeed or defaultWalkSpeed
	local baseJumpPower = customJumpPower or defaultJumpPower

	if state == "Idle" then
		-- Full movement
		humanoid.WalkSpeed = baseWalkSpeed
		humanoid.JumpPower = baseJumpPower

	elseif state == "Attacking" then
		-- Restricted movement during attacks
		local attackSpeed = options.walkSpeed or (baseWalkSpeed * 0.2)
		humanoid.WalkSpeed = attackSpeed
		humanoid.JumpPower = 0 -- No jumping during attacks

	elseif state == "Recovery" then
		-- Slightly more movement during recovery
		local recoverySpeed = options.walkSpeed or (baseWalkSpeed * 0.4)
		humanoid.WalkSpeed = recoverySpeed
		humanoid.JumpPower = 0

	elseif state == "Blocking" then
		-- Slow movement while blocking
		local blockSpeed = options.walkSpeed or (baseWalkSpeed * 0.5)
		humanoid.WalkSpeed = blockSpeed
		humanoid.JumpPower = baseJumpPower * 0.5

	elseif state == "Stunned" then
		-- No movement while stunned
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0

	elseif state == "Dashing" then
		-- Movement handled by dash system
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0

	elseif state == "GuardBroken" then
		-- No movement when guard broken
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0

	elseif state == "Airborne" then
		-- Reduced air control
		humanoid.WalkSpeed = baseWalkSpeed * 0.7
		humanoid.JumpPower = 0 -- Can't double jump
	end
end

--------------------------------------------------------------------------------
-- COMBAT LOCK INTEGRATION
--------------------------------------------------------------------------------

function MovementHandler.OnCombatLockEngaged()
	isInCombatLock = true

	-- Combat lock uses AlignPosition constraints
	-- We don't want to fight against those, so disable normal movement
	if humanoid and currentState == "Attacking" then
		humanoid.WalkSpeed = 0
	end
end

function MovementHandler.OnCombatLockReleased()
	isInCombatLock = false

	-- Restore state-based movement
	MovementHandler.SetState(currentState)
end

--------------------------------------------------------------------------------
-- DASH HANDLING
--------------------------------------------------------------------------------

function MovementHandler.Dash(direction, distance, duration)
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Set state to dashing
	MovementHandler.SetState("Dashing")

	-- Calculate velocity
	local velocity = (direction * distance) / duration

	-- Apply using BodyVelocity (server should already do this, but client can predict)
	-- For client-side prediction:
	local bodyVel = hrp:FindFirstChild("DashVelocity")
	if not bodyVel then
		bodyVel = Instance.new("BodyVelocity")
		bodyVel.Name = "DashVelocity"
		bodyVel.MaxForce = Vector3.new(100000, 0, 100000)
		bodyVel.P = 5000
		bodyVel.Parent = hrp
	end

	bodyVel.Velocity = velocity

	-- Remove after duration
	task.delay(duration, function()
		if bodyVel and bodyVel.Parent then
			bodyVel:Destroy()
		end

		-- Restore movement
		if currentState == "Dashing" then
			MovementHandler.SetState("Idle")
		end
	end)
end

--------------------------------------------------------------------------------
-- ATTACK MOVEMENT (subtle forward momentum during attacks)
--------------------------------------------------------------------------------

function MovementHandler.ApplyAttackMovement(attackType, combo)
	if not character or isInCombatLock then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Slight forward movement during M1 attacks (SIFU feel)
	if attackType == "M1" then
		local forwardDistance = 0.5 -- studs per attack
		local moveDir = hrp.CFrame.LookVector

		-- Apply small forward velocity
		hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (moveDir * forwardDistance)
	end
end

--------------------------------------------------------------------------------
-- CUSTOM SPEED SETTERS (for character-specific stats)
--------------------------------------------------------------------------------

function MovementHandler.SetCustomSpeed(walkSpeed, jumpPower)
	customWalkSpeed = walkSpeed
	customJumpPower = jumpPower

	-- Apply if in idle state
	if currentState == "Idle" and humanoid then
		humanoid.WalkSpeed = walkSpeed
		humanoid.JumpPower = jumpPower
	end
end

function MovementHandler.ResetCustomSpeed()
	customWalkSpeed = nil
	customJumpPower = nil

	-- Apply defaults
	if currentState == "Idle" and humanoid then
		humanoid.WalkSpeed = defaultWalkSpeed
		humanoid.JumpPower = defaultJumpPower
	end
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function MovementHandler.GetState()
	return currentState
end

function MovementHandler.IsInCombatLock()
	return isInCombatLock
end

return MovementHandler
