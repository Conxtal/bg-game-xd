--[[
	Init.client.lua
	Client initialization
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

print("[Client] Initializing...")

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then
	warn("[Client] Remotes not found!")
	return
end

-- Load modules
local States = require(ReplicatedStorage.States)

-- Setup local state
States.StateService.Setup(Player)

-- Input handling
local function OnInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- M1 Attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remotes.Attack:FireServer()
	end
end

UserInputService.InputBegan:Connect(OnInputBegan)

print("[Client] Initialized!")
