--[[
	Block.lua
	Handles blocking and deflects
	Location: ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(ReplicatedStorage:WaitForChild("State"))

local Block = {}
local Remotes, Registry

function Block.Init(remotes, registry)
	Remotes = remotes
	Registry = registry

	Remotes.Block.OnServerEvent:Connect(Block.OnBlock)
end

function Block.OnBlock(player, isBlocking)
	if isBlocking then
		Block.StartBlock(player)
	else
		Block.EndBlock(player)
	end
end

function Block.StartBlock(player)
	local data = State.Get(player)
	if not data then return end

	-- Check state
	local state = State.GetState(player)
	if state == State.STUNNED or state == State.DASHING or state == State.ATTACKING then
		return
	end

	-- Set blocking
	data.blocking = true
	data.canParry = true
	State.SetState(player, State.BLOCKING)

	-- Send state update
	Remotes.State:FireClient(player, { state = State.BLOCKING })

	-- Parry window ends after a short time
	task.delay(0.18, function()
		if data then
			data.canParry = false
		end
	end)
end

function Block.EndBlock(player)
	local data = State.Get(player)
	if not data then return end

	data.blocking = false
	data.canParry = false

	if State.GetState(player) == State.BLOCKING then
		State.SetState(player, State.IDLE)
		Remotes.State:FireClient(player, { state = State.IDLE })
	end
end

return Block
