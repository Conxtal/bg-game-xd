--[[
	AirborneState.lua
	In-air state - reduced control, aerial attacks enabled
]]

local AirborneState = {}

function AirborneState.Enter(player, data, transitionData)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Reduced air control
		humanoid.WalkSpeed = 8
		humanoid.AutoRotate = false
	end

	-- Set air flags
	data.isGrounded = false
	data.launchSource = transitionData and transitionData.source

	-- If launched into air during combat, maintain combat sub-state
	if transitionData and transitionData.maintainCombat then
		local StateService = require(script.Parent.StateService)
		StateService.AddSubState(player, StateService.SUB_STATES.COMBAT)
	end
end

function AirborneState.Update(player, data, dt)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Check if landed (raycast downward)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rayParams)

	if ray and hrp.AssemblyLinearVelocity.Y <= 1 then
		-- Landed - transition to grounded
		local StateService = require(script.Parent.StateService)
		StateService.Transition(player, StateService.PRIMARY_STATES.GROUNDED)
		return
	end

	-- Apply modified gravity if in aerial combat
	local StateService = require(script.Parent.StateService)
	if StateService.HasSubState(player, StateService.SUB_STATES.COMBAT) then
		-- Reduced gravity during aerial combat
		local currentVel = hrp.AssemblyLinearVelocity
		if currentVel.Y < 0 then
			-- Slow down fall
			hrp.AssemblyLinearVelocity = Vector3.new(
				currentVel.X,
				currentVel.Y * 0.7, -- Reduce downward velocity
				currentVel.Z
			)
		end
	end

	-- Aerial combo timeout
	if tick() - data.lastAttack > 0.4 then
		data.combo = 0
	end
end

function AirborneState.Exit(player, data)
	-- Clear aerial flags
	data.launchSource = nil

	-- Clear combat sub-state if still active
	local StateService = require(script.Parent.StateService)
	StateService.RemoveSubState(player, StateService.SUB_STATES.COMBAT)
end

-- Transition rules
AirborneState.CanTransitionTo = {
	Grounded = true, -- Can land
	Stunned = true, -- Can be stunned in air
	Ragdoll = true, -- Can be ragdolled in air
}

return AirborneState
