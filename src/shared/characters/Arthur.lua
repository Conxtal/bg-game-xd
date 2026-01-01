--[[
	Arthur.lua
	Character data for Arthur Leywin
	Location: ReplicatedStorage
]]

local Arthur = {
	Name = "Arthur",
	DisplayName = "Arthur Leywin",
	Description = "A young swordsman channeling ether and asuran will.",
	ModelName = "Arthur",

	-- Base stats
	Stats = {
		Damage = 1.0,
		Knockback = 1.0,
		Speed = 1.0,
		Health = 100,
		WalkSpeed = 16,
		JumpPower = 50,
	},

	-- Passive ability
	Passive = {
		Name = "Ether Resonance",
		MaxStacks = 8,
		StacksPerHit = 1,
		StackDuration = 8,
		DecayDuration = 8,
		BuffDuration = 5,
		Cooldown = 30,
		BuffDamage = 1.2,
		BuffSpeed = 1.1,
		DamagePerStack = 0.03,
		AttackSpeedPerStack = 0.03,
	},

	-- M1 combo
	M1 = {
		MaxCombo = 4,
		ComboWindow = 0.50,
		Hitstun = 0.35,
		HitboxSize = Vector3.new(4, 4, 5),
		HitboxOffset = Vector3.new(0, 0, -3),
		AttackWalkSpeed = 3,

		Hits = {
			{ startup = 0.10, active = 0.12, recovery = 0.15, damage = 8, knockback = 65, postureDamage = 12 },
			{ startup = 0.08, active = 0.06, recovery = 0.08, damage = 8, knockback = 65, postureDamage = 12 },
			{ startup = 0.08, active = 0.08, recovery = 0.10, damage = 10, knockback = 65, postureDamage = 15 },
			{ startup = 0.08, active = 0.10, recovery = 0.14, damage = 14, knockback = 200, lift = 3, postureDamage = 20 },
		},
	},

	-- Uptilt attack
	Uptilt = {
		Startup = 0.05,
		Active = 0.10,
		Recovery = 0.14,
		RecoveryOnHit = 0.06,
		Damage = 12,
		LaunchVelocity = 22,
		ForwardPush = 4,
		Hitstun = 0.28,
		PostureDamage = 18,
		HitboxSize = Vector3.new(4, 6, 4),
		HitboxOffset = Vector3.new(0, 2, -3),
		MaxComboToUse = 2,
	},

	-- Dash
	Dash = {
		Distance = 16,
		Duration = 0.12,
		Cooldown = 0.30,
		IFrames = 0.07,
		StaminaCost = 15,
	},

	-- Block/Deflect
	Block = {
		DamageReduction = 0.75,
		KnockbackReduction = 0.3,
		StaminaDrain = 12,
		Pushback = 5,
		PerfectWindow = 0.18,
		PerfectStun = 0.35,
		BreakStun = 1.0,
		PostureDamageMultiplier = 0.6,
	},

	-- Awakening
	Awakening = {
		Name = "Asura Ascension",
		Duration = 25,
		Cooldown = 90,
		SpeedMultiplier = 1.20,
		DamageMultiplier = 1.20,
		M1RangeMultiplier = 1.25,
	},

	-- Animations
	Animations = {
		M1_1 = "rbxassetid://12845340632",
		M1_2 = "rbxassetid://12845369253",
		M1_3 = "rbxassetid://12845398367",
		M1_4 = "rbxassetid://12845456406",
		Uptilt = "rbxassetid://126734284253680",
		BlockIdle = "rbxassetid://12927194871",
		BlockHit = "rbxassetid://0",
		DashForward = "rbxassetid://11989948466",
		DashRight = "rbxassetid://11997368950",
		DashLeft = "rbxassetid://11997366704",
		DashBack = "rbxassetid://11997364353",
		HitLight = "rbxassetid://0",
		HitHeavy = "rbxassetid://0",
	},

	-- Animation speeds
	AnimationSpeeds = {
		M1_1 = 1.35, M1_2 = 1.35, M1_3 = 1.35, M1_4 = 1.35,
		DashForward = 1.5, DashLeft = 1.5, DashRight = 1.5, DashBack = 1.5,
		Uptilt = 1.20,
		BlockIdle = 1.0,
		HitLight = 0.3,
		HitHeavy = 1.10,
	},

	-- Abilities
	Abilities = { "DragonStep", "EtherSlash", "BurstNova", "StaticEdge" },
	AwakeningAbilities = { "AsuraStep", "EthericDivide", "DragonNova", "Realmbreaker" },

	-- Ability data
	AbilityData = {
		DragonStep = {
			Cooldown = 4, StaminaCost = 15, Distance = 20, Duration = 0.10,
			IFrameWindow = 0.06, Damage = 6, Knockback = 6, Stagger = 0.2,
			HitboxSize = Vector3.new(3, 4, 6), CancelFromM1 = true, CancelWindow = 0.15,
		},
		EtherSlash = {
			Cooldown = 6, StaminaCost = 20, Startup = 0.10, Active = 0.12, Recovery = 0.16,
			Damage = 12, Knockback = 8, HitboxSize = Vector3.new(8, 4, 6),
			HitboxOffset = Vector3.new(0, 0, -4), BlockDrain = 30,
		},
		BurstNova = {
			Cooldown = 8, StaminaCost = 25, Startup = 0.10, Active = 0.08, Recovery = 0.18,
			Damage = 8, PushDistance = 8, Radius = 8,
		},
		StaticEdge = {
			Cooldown = 5, StaminaCost = 10, CounterWindow = 0.35,
			CounterDamage = 16, CounterKnockback = 10,
		},
	},
}

return Arthur
