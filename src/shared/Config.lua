--[[
	Config.lua
	Central combat configuration
	Location: ReplicatedStorage
]]

local Config = {}

-- Stamina
Config.Stamina = {
	Max = 100,
	RegenRate = 20,
	RegenDelay = 0.8,
}

-- Player defaults
Config.Player = {
	WalkSpeed = 16,
	JumpPower = 50,
}

-- Combat
Config.Combat = {
	M1Cooldown = 0.4,
	DashCooldown = 1.0,
	BlockCooldown = 0.3,
	UptiltCooldown = 0.6,

	-- Posture system
	Posture = {
		Max = 100,
		RegenRate = 15,
		RegenDelay = 2.0,
		DecayWhenBlocking = 10,
		GuardBreakThreshold = 100,
	},
}

-- Hitbox
Config.Hitbox = {
	MaxDistance = 10,
	DebugVisualization = false,
}

return Config
