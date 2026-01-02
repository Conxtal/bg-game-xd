--[[
	GroundedState.lua
	Normal grounded movement and combat state
]]

local GroundedState = {}

function GroundedState.Enter(player, data, transitionData)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Restore normal movement
		humanoid.WalkSpeed = 16
		humanoid.AutoRotate = true
	end

	-- Reset air flags
	data.airJumps = 0
	data.isGrounded = true
end

function GroundedState.Update(player, data, dt)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Check if still grounded (simple raycast downward)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rayParams)

	if not ray then
		-- No longer grounded - transition to airborne
		local StateService = require(script.Parent.StateService)
		StateService.Transition(player, StateService.PRIMARY_STATES.AIRBORNE)
		return
	end

	-- Stamina regen (if not using)
	if tick() - data.lastStaminaUse > 0.8 then
		data.stamina = math.min(100, data.stamina + 20 * dt)
	end

	-- Posture regen (if not being hit)
	if tick() - data.lastPostureHit > 2.0 then
		data.posture = math.max(0, data.posture - 15 * dt)
	end

	-- Combo timeout
	if tick() - data.lastAttack > 0.5 then
		data.combo = 0
	end
end

function GroundedState.Exit(player, data)
	-- Clean up any grounded-specific state
end

-- Transition rules
GroundedState.CanTransitionTo = {
	Airborne = true, -- Can go airborne
	Stunned = true, -- Can be stunned
	Ragdoll = true, -- Can be ragdolled
}

return GroundedState
