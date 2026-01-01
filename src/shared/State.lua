--[[
	State.lua
	Player combat state + posture management
	Location: ReplicatedStorage
]]

local Config = require(script.Parent.Config)

local State = {}
State.Data = {}

-- State constants
State.IDLE = "Idle"
State.ATTACKING = "Attacking"
State.BLOCKING = "Blocking"
State.STUNNED = "Stunned"
State.DASHING = "Dashing"
State.RECOVERY = "Recovery"
State.AIRBORNE = "Airborne"
State.GUARD_BROKEN = "GuardBroken"

function State.Setup(player)
	State.Data[player] = {
		state = State.IDLE,
		character = "Arthur",
		combo = 0,
		awakened = false,

		-- Stamina
		stamina = Config.Stamina.Max,
		lastStaminaUse = 0,

		-- Posture
		posture = 0,
		lastPostureHit = 0,

		-- Combat
		blocking = false,
		canParry = false,
	}
end

function State.Get(player)
	return State.Data[player]
end

function State.SetState(player, newState)
	local data = State.Get(player)
	if data then
		data.state = newState
	end
end

function State.GetState(player)
	local data = State.Get(player)
	return data and data.state or State.IDLE
end

function State.SetCharacter(player, character)
	local data = State.Get(player)
	if data then
		data.character = character
	end
end

function State.GetCharacter(player)
	local data = State.Get(player)
	return data and data.character or "Arthur"
end

function State.Cleanup(player)
	State.Data[player] = nil
end

return State
