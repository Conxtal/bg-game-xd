--[[
	States loader
]]

local States = {
	StateService = require(script.StateService),
	Grounded = require(script.GroundedState),
	Airborne = require(script.AirborneState),
	Stunned = require(script.StunnedState),
}

return States
