--[[
	StateService.lua
	Core state machine - enforces exclusive states with proper enter/update/exit

	Primary States (EXCLUSIVE - only ONE active):
	- Grounded, Airborne, Stunned, Ragdoll

	Sub-States (MODIFIERS - can have multiple):
	- Combat, Blocking, Dashing
]]

local RunService = game:GetService("RunService")

local StateService = {}

-- Player data storage
local PlayerData = {}
local UpdateConnection = nil

-- State references (injected during Init)
local States = {}

-- Constants
StateService.PRIMARY_STATES = {
	GROUNDED = "Grounded",
	AIRBORNE = "Airborne",
	STUNNED = "Stunned",
	RAGDOLL = "Ragdoll",
}

StateService.SUB_STATES = {
	COMBAT = "Combat",
	BLOCKING = "Blocking",
	DASHING = "Dashing",
}

function StateService.Init(stateModules)
	States = stateModules

	-- Start update loop
	if not UpdateConnection then
		UpdateConnection = RunService.Heartbeat:Connect(function(dt)
			StateService.Update(dt)
		end)
	end

	print("[StateService] Initialized")
end

function StateService.Setup(player)
	if PlayerData[player] then
		warn("[StateService] Player already setup:", player.Name)
		return
	end

	PlayerData[player] = {
		-- State
		currentState = nil,
		subStates = {},

		-- Character
		character = "Arthur",

		-- Combat
		combo = 0,
		lastAttack = 0,

		-- Resources
		stamina = 100,
		lastStaminaUse = 0,
		posture = 0,
		lastPostureHit = 0,

		-- Flags
		blocking = false,
		awakened = false,

		-- Timestamps
		stateEnterTime = 0,
	}

	-- Start in Grounded state
	StateService.Transition(player, StateService.PRIMARY_STATES.GROUNDED)

	print("[StateService] Setup player:", player.Name)
end

function StateService.Cleanup(player)
	if not PlayerData[player] then return end

	-- Exit current state
	local data = PlayerData[player]
	if data.currentState and States[data.currentState] then
		local state = States[data.currentState]
		if state.Exit then
			state.Exit(player, data)
		end
	end

	PlayerData[player] = nil
	print("[StateService] Cleaned up player:", player.Name)
end

function StateService.Get(player)
	return PlayerData[player]
end

function StateService.GetAll()
	return PlayerData
end

-- Transition to new primary state
function StateService.Transition(player, newStateName, transitionData)
	local data = PlayerData[player]
	if not data then
		warn("[StateService] No data for player:", player.Name)
		return false
	end

	local newState = States[newStateName]
	if not newState then
		warn("[StateService] State not found:", newStateName)
		return false
	end

	local currentStateName = data.currentState
	local currentState = currentStateName and States[currentStateName]

	-- Check if transition is allowed
	if currentState and currentState.CanTransitionTo then
		local canTransition = currentState.CanTransitionTo[newStateName]
		if canTransition ~= nil then
			if type(canTransition) == "function" then
				if not canTransition(player, data) then
					return false
				end
			elseif not canTransition then
				return false
			end
		end
	end

	-- Exit current state
	if currentState and currentState.Exit then
		currentState.Exit(player, data)
	end

	-- Change state
	data.currentState = newStateName
	data.stateEnterTime = tick()

	-- Enter new state
	if newState.Enter then
		newState.Enter(player, data, transitionData)
	end

	return true
end

-- Get current primary state name
function StateService.GetState(player)
	local data = PlayerData[player]
	return data and data.currentState or nil
end

-- Check if in specific state
function StateService.IsInState(player, stateName)
	local data = PlayerData[player]
	return data and data.currentState == stateName
end

-- Sub-state management
function StateService.AddSubState(player, subState)
	local data = PlayerData[player]
	if not data then return end

	if not table.find(data.subStates, subState) then
		table.insert(data.subStates, subState)
	end
end

function StateService.RemoveSubState(player, subState)
	local data = PlayerData[player]
	if not data then return end

	local index = table.find(data.subStates, subState)
	if index then
		table.remove(data.subStates, index)
	end
end

function StateService.HasSubState(player, subState)
	local data = PlayerData[player]
	if not data then return false end

	return table.find(data.subStates, subState) ~= nil
end

function StateService.ClearSubStates(player)
	local data = PlayerData[player]
	if not data then return end

	table.clear(data.subStates)
end

-- Update loop - calls Update on current state
function StateService.Update(dt)
	for player, data in pairs(PlayerData) do
		if data.currentState then
			local state = States[data.currentState]
			if state and state.Update then
				state.Update(player, data, dt)
			end
		end
	end
end

return StateService
