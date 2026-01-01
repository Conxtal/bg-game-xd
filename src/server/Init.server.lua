--[[
	Init.server.lua
	Server entry point
	Location: ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[Combat] Server starting...")

-- Load shared modules
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(ReplicatedStorage:WaitForChild("State"))
local Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))
local Registry = require(ReplicatedStorage:WaitForChild("characters"):WaitForChild("Registry"))

-- Initialize registry
Registry.Init()

-- Create remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local REMOTE_NAMES = {
	"Attack", "Uptilt", "Block", "Dash", "Hit",
	"State", "Ability", "Notification", "Passive", "CombatLock"
}

local Remotes = {}
for _, name in ipairs(REMOTE_NAMES) do
	local remote = RemotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = RemotesFolder
	end
	Remotes[name] = remote
end

-- Load handlers
local Attack = require(script.Parent.Attack)
local Uptilt = require(script.Parent.Uptilt)
local Block = require(script.Parent.Block)
local Dash = require(script.Parent.Dash)
local Ability = require(script.Parent.Ability)
local Passive = require(script.Parent.Passive)

Attack.Init(Remotes, Registry)
Uptilt.Init(Remotes, Registry)
Block.Init(Remotes, Registry)
Dash.Init(Remotes, Registry)
Ability.Init(Remotes, Registry)
Passive.Init(Remotes, Registry)

-- Player setup
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		State.Setup(player)
		Passive.SetupPlayer(player)

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = Config.Player.WalkSpeed
		humanoid.JumpPower = Config.Player.JumpPower
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	State.Cleanup(player)
	Cooldown.Cleanup(player)
end)

-- Posture & stamina regen loop
RunService.Heartbeat:Connect(function(dt)
	for _, player in pairs(Players:GetPlayers()) do
		local data = State.Get(player)
		if data then
			-- Stamina regen
			if tick() - data.lastStaminaUse > Config.Stamina.RegenDelay then
				data.stamina = math.min(Config.Stamina.Max, data.stamina + Config.Stamina.RegenRate * dt)
			end

			-- Posture regen
			if tick() - data.lastPostureHit > Config.Combat.Posture.RegenDelay then
				data.posture = math.max(0, data.posture - Config.Combat.Posture.RegenRate * dt)
			end
		end
	end
end)

print("[Combat] Server initialized!")
