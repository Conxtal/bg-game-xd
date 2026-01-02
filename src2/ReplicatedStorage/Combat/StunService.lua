--[[
	StunService.lua
	Hitstun management
]]

local StunService = {}

local StateService = nil

function StunService.Init(dependencies)
	StateService = dependencies.StateService
	print("[StunService] Initialized")
end

-- Stun types
StunService.TYPES = {
	HIT = "Hit",
	BLOCK = "Block",
	COUNTER = "Counter",
	LAUNCH = "Launch",
}

function StunService.ApplyHitstun(victim, duration, stunType, customData)
	local data = StateService.Get(victim)
	if not data then return false end

	-- Determine if victim was airborne
	local wasAirborne = StateService.IsInState(victim, StateService.PRIMARY_STATES.AIRBORNE)

	-- Transition to stunned state
	return StateService.Transition(victim, StateService.PRIMARY_STATES.STUNNED, {
		duration = duration,
		stunType = stunType,
		wasAirborne = wasAirborne,
		customData = customData,
	})
end

function StunService.IsStunned(player)
	return StateService.IsInState(player, StateService.PRIMARY_STATES.STUNNED)
end

function StunService.GetStunRemaining(player)
	local data = StateService.Get(player)
	if not data or not data.stunEndTime then return 0 end

	return math.max(0, data.stunEndTime - tick())
end

return StunService
