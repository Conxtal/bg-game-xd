--[[
	Init.client.lua
	Client entry point
	Location: StarterPlayer/StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for remotes
local function WaitForRemotes()
	local maxWait = 10
	local waited = 0
	while not ReplicatedStorage:FindFirstChild("Remotes") and waited < maxWait do
		task.wait(0.1)
		waited = waited + 0.1
	end
	return ReplicatedStorage:FindFirstChild("Remotes") ~= nil
end

if not WaitForRemotes() then
	warn("[Combat] Remotes folder not found!")
	return
end

print("[Combat] Client starting...")

-- Initialize modules
local Client = require(script.Parent.Client)
local Lock = require(script.Parent.Lock)

Client.Init()
Lock.Init()

print("[Combat] Client initialized!")
