--[[
	Client.lua
	Main client combat controller
	Location: StarterPlayer/StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Client = {}

local State, Cooldown, Registry
local Remotes, Input, Animation, VFX

function Client.Init()
	-- Get shared modules
	State = require(ReplicatedStorage:WaitForChild("State"))
	Cooldown = require(ReplicatedStorage:WaitForChild("Cooldown"))
	Registry = require(ReplicatedStorage:WaitForChild("characters"):WaitForChild("Registry"))

	-- Setup local state
	State.Setup(Player)

	-- Get remotes
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	Remotes = {
		Attack = folder:WaitForChild("Attack"),
		Uptilt = folder:WaitForChild("Uptilt"),
		Block = folder:WaitForChild("Block"),
		Dash = folder:WaitForChild("Dash"),
		Hit = folder:WaitForChild("Hit"),
		State = folder:WaitForChild("State"),
		Ability = folder:WaitForChild("Ability"),
		Notification = folder:WaitForChild("Notification"),
		CombatLock = folder:WaitForChild("CombatLock"),
	}

	-- Load handlers
	Input = require(script.Parent.Input)
	Animation = require(script.Parent.Animation)
	VFX = require(script.Parent.VFX)

	Input.Init(Remotes)
	Animation.Init()
	VFX.Init()

	-- Listen for events
	Remotes.State.OnClientEvent:Connect(Client.OnState)
	Remotes.Hit.OnClientEvent:Connect(Client.OnHit)
	Remotes.Notification.OnClientEvent:Connect(Client.OnNotification)
end

function Client.OnState(data)
	if data.state then
		State.SetState(Player, data.state)
	end
	if data.character then
		State.SetCharacter(Player, data.character)
	end
end

function Client.OnHit(data)
	VFX.PlayHitEffect(data)
	if data.victimPlayer == Player then
		-- Play hit reaction animation
		Animation.PlayHit(data.hitType)
	end
end

function Client.OnNotification(message, messageType)
	print("[Combat]", message)
end

return Client
