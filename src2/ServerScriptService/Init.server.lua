--[[
	Init.server.lua
	Server initialization with dependency injection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Server] Initializing combat system...")

-- Load all modules
local Utils = require(ReplicatedStorage.Utils)
local States = require(ReplicatedStorage.States)
local Combat = require(ReplicatedStorage.Combat)
local Character = require(ReplicatedStorage.Character)
local Config = require(ReplicatedStorage.Config)

-- Initialize in correct order with dependencies

-- 1. Utils (no dependencies)
-- Already loaded

-- 2. Character system
Character.CharacterService.Init()

-- 3. State system
States.StateService.Init({
	Grounded = States.Grounded,
	Airborne = States.Airborne,
	Stunned = States.Stunned,
})

-- 4. Combat services
Combat.IFrameService.Init()
Combat.HitstopService.Init()
Combat.HitboxService.Init()

Combat.StunService.Init({
	StateService = States.StateService,
})

Combat.DamageService.Init({
	StateService = States.StateService,
})

Combat.CombatService.Init({
	StateService = States.StateService,
	HitboxService = Combat.HitboxService,
	DamageService = Combat.DamageService,
	StunService = Combat.StunService,
	IFrameService = Combat.IFrameService,
	HitstopService = Combat.HitstopService,
	CharacterService = Character.CharacterService,
	CombatLockService = nil, -- TODO: implement
})

-- Create remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local REMOTE_NAMES = {
	"Attack", "Uptilt", "Block", "Dash", "Hit",
	"State", "Ability", "Notification"
}

local RemoteEvents = {}
for _, name in ipairs(REMOTE_NAMES) do
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = Remotes
	end
	RemoteEvents[name] = remote
end

-- Wire up remotes
RemoteEvents.Attack.OnServerEvent:Connect(function(player)
	Combat.CombatService.ProcessM1(player)
end)

-- Player setup
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Setup state
		States.StateService.Setup(player)

		-- Setup character defaults
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = Config.Player.WalkSpeed
		humanoid.JumpPower = Config.Player.JumpPower

		print("[Server] Setup player:", player.Name)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	States.StateService.Cleanup(player)
	Combat.CombatService.Cleanup(player)
	Combat.IFrameService.Cleanup(player)
end)

print("[Server] Combat system initialized!")
