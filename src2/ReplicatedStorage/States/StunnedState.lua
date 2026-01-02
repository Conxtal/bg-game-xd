--[[
	StunnedState.lua
	Hitstun - frozen, no input
]]

local StunnedState = {}

function StunnedState.Enter(player, data, transitionData)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Disable movement during stun
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
	end

	-- Set stun duration
	data.stunDuration = transitionData and transitionData.duration or 0.35
	data.stunEndTime = tick() + data.stunDuration
	data.wasAirborne = transitionData and transitionData.wasAirborne or false
end

function StunnedState.Update(player, data, dt)
	-- Wait for stun to end
	if tick() >= data.stunEndTime then
		-- Stun over - transition back
		local StateService = require(script.Parent.StateService)

		-- If was in air, go back to airborne, else grounded
		if data.wasAirborne then
			StateService.Transition(player, StateService.PRIMARY_STATES.AIRBORNE)
		else
			StateService.Transition(player, StateService.PRIMARY_STATES.GROUNDED)
		end
	end
end

function StunnedState.Exit(player, data)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Restore movement
		humanoid.WalkSpeed = 16
		humanoid.AutoRotate = true
	end

	-- Clear stun data
	data.stunDuration = nil
	data.stunEndTime = nil
	data.wasAirborne = nil
end

-- Transition rules
StunnedState.CanTransitionTo = {
	Grounded = true, -- After stun
	Airborne = true, -- After stun in air
	Ragdoll = true, -- Can be launched hard during stun
}

return StunnedState
