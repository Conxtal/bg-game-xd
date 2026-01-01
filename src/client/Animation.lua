--[[
	Animation.lua
	Handles character animations
	Location: StarterPlayer/StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Animation = {}

local LoadedTracks = {}
local Animators = {}
local Registry

function Animation.Init()
	Registry = require(ReplicatedStorage:WaitForChild("characters"):WaitForChild("Registry"))
	Registry.Init()
end

function Animation.GetAnimator(character)
	if not Animators[character] then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end
			Animators[character] = animator
		end
	end
	return Animators[character]
end

function Animation.Load(character, animName)
	local charData = Registry.Get("Arthur") -- TODO: Get from state
	if not charData or not charData.Animations[animName] then
		return nil
	end

	local key = character.Name .. "_" .. animName
	if not LoadedTracks[key] then
		local animator = Animation.GetAnimator(character)
		if animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = charData.Animations[animName]
			LoadedTracks[key] = animator:LoadAnimation(anim)
		end
	end
	return LoadedTracks[key]
end

function Animation.Play(character, animName, speed)
	local track = Animation.Load(character, animName)
	if track then
		local charData = Registry.Get("Arthur")
		local animSpeed = speed or (charData.AnimationSpeeds and charData.AnimationSpeeds[animName]) or 1
		track:Play()
		track:AdjustSpeed(animSpeed)
		return track
	end
end

function Animation.Stop(character, animName)
	local key = character.Name .. "_" .. animName
	local track = LoadedTracks[key]
	if track then
		track:Stop()
	end
end

function Animation.PlayHit(hitType)
	local char = Player.Character
	if char then
		if hitType == "Heavy" then
			Animation.Play(char, "HitHeavy")
		else
			Animation.Play(char, "HitLight")
		end
	end
end

return Animation
