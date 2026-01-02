--[[
	InputTracker.lua
	Handles input buffering for responsive combat feel
	Location: ReplicatedStorage/Combat/Modules/InputTracker

	USAGE:
	- Client buffers inputs when actions aren't immediately available
	- Server can check if buffered input exists when state allows
	- Provides forgiving input windows for combo chains
]]

local RunService = game:GetService("RunService")

local InputTracker = {}

-- Configuration
local BUFFER_WINDOW = 0.20 -- seconds (configurable)
local MAX_BUFFER_SIZE = 5 -- max buffered inputs per player

-- Data structure
-- PlayerBuffers[player] = { [inputType] = {timestamp, data}, ... }
local PlayerBuffers = {}

-- Cleanup connection
local cleanupConnection = nil

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InputTracker.Init(bufferWindow)
	BUFFER_WINDOW = bufferWindow or 0.20

	-- Periodic cleanup of expired inputs (every 0.1s)
	if not cleanupConnection then
		cleanupConnection = RunService.Heartbeat:Connect(function()
			InputTracker.CleanupExpired()
		end)
	end

	print("[InputTracker] Initialized (buffer window:", BUFFER_WINDOW, "s)")
	return InputTracker
end

function InputTracker.Shutdown()
	if cleanupConnection then
		cleanupConnection:Disconnect()
		cleanupConnection = nil
	end

	PlayerBuffers = {}
end

--------------------------------------------------------------------------------
-- BUFFER MANAGEMENT
--------------------------------------------------------------------------------

function InputTracker.BufferInput(player, inputType, data)
	-- Create player buffer if doesn't exist
	if not PlayerBuffers[player] then
		PlayerBuffers[player] = {}
	end

	local buffer = PlayerBuffers[player]

	-- Count current buffered inputs
	local count = 0
	for _ in pairs(buffer) do
		count = count + 1
	end

	-- Don't buffer if already at max
	if count >= MAX_BUFFER_SIZE then
		return false
	end

	-- Store input with timestamp
	buffer[inputType] = {
		timestamp = tick(),
		data = data or {},
	}

	return true
end

function InputTracker.HasBufferedInput(player, inputType)
	if not PlayerBuffers[player] then return false end

	local buffered = PlayerBuffers[player][inputType]
	if not buffered then return false end

	-- Check if still within window
	local age = tick() - buffered.timestamp
	if age > BUFFER_WINDOW then
		-- Expired
		PlayerBuffers[player][inputType] = nil
		return false
	end

	return true
end

function InputTracker.ConsumeInput(player, inputType)
	if not PlayerBuffers[player] then return nil end

	local buffered = PlayerBuffers[player][inputType]
	if not buffered then return nil end

	-- Check if still valid
	local age = tick() - buffered.timestamp
	if age > BUFFER_WINDOW then
		PlayerBuffers[player][inputType] = nil
		return nil
	end

	-- Consume (remove from buffer)
	local data = buffered.data
	PlayerBuffers[player][inputType] = nil

	return data
end

function InputTracker.ClearBuffer(player)
	PlayerBuffers[player] = {}
end

function InputTracker.ClearInput(player, inputType)
	if PlayerBuffers[player] then
		PlayerBuffers[player][inputType] = nil
	end
end

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------

function InputTracker.CleanupExpired()
	local now = tick()

	for player, buffer in pairs(PlayerBuffers) do
		for inputType, buffered in pairs(buffer) do
			local age = now - buffered.timestamp
			if age > BUFFER_WINDOW then
				buffer[inputType] = nil
			end
		end

		-- Clean up empty player buffers
		local isEmpty = true
		for _ in pairs(buffer) do
			isEmpty = false
			break
		end

		if isEmpty then
			PlayerBuffers[player] = nil
		end
	end
end

function InputTracker.CleanupPlayer(player)
	PlayerBuffers[player] = nil
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function InputTracker.GetBufferedInputs(player)
	return PlayerBuffers[player] or {}
end

function InputTracker.GetBufferWindow()
	return BUFFER_WINDOW
end

function InputTracker.SetBufferWindow(window)
	BUFFER_WINDOW = window
end

--------------------------------------------------------------------------------
-- ADVANCED: COMBO BUFFERING
--------------------------------------------------------------------------------

-- Check if next combo input is buffered
function InputTracker.HasBufferedCombo(player)
	return InputTracker.HasBufferedInput(player, "M1")
end

-- Consume combo buffer
function InputTracker.ConsumeCombo(player)
	return InputTracker.ConsumeInput(player, "M1")
end

-- Buffer M1 for combo continuation
function InputTracker.BufferCombo(player)
	return InputTracker.BufferInput(player, "M1", {})
end

return InputTracker
