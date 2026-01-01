--[[
	Input.lua
	Handles player input
	Location: StarterPlayer/StarterPlayerScripts
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Input = {}

local Remotes
local Blocking = false

-- Keybinds
local Keys = {
	Attack = Enum.UserInputType.MouseButton1,
	Block = Enum.KeyCode.F,
	Dash = Enum.KeyCode.Q,
	Uptilt = Enum.KeyCode.Space,
	Ability1 = Enum.KeyCode.One,
	Ability2 = Enum.KeyCode.Two,
	Ability3 = Enum.KeyCode.Three,
	Ability4 = Enum.KeyCode.Four,
}

function Input.Init(remotes)
	Remotes = remotes

	UserInputService.InputBegan:Connect(Input.OnInputBegan)
	UserInputService.InputEnded:Connect(Input.OnInputEnded)
end

function Input.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- Attack
	if input.UserInputType == Keys.Attack then
		Remotes.Attack:FireServer()

	-- Dash
	elseif input.KeyCode == Keys.Dash then
		Remotes.Dash:FireServer()

	-- Uptilt
	elseif input.KeyCode == Keys.Uptilt then
		Remotes.Uptilt:FireServer()

	-- Block start
	elseif input.KeyCode == Keys.Block then
		Blocking = true
		Remotes.Block:FireServer(true)

	-- Abilities
	elseif input.KeyCode == Keys.Ability1 then
		Remotes.Ability:FireServer(1)
	elseif input.KeyCode == Keys.Ability2 then
		Remotes.Ability:FireServer(2)
	elseif input.KeyCode == Keys.Ability3 then
		Remotes.Ability:FireServer(3)
	elseif input.KeyCode == Keys.Ability4 then
		Remotes.Ability:FireServer(4)
	end
end

function Input.OnInputEnded(input, gameProcessed)
	-- Block end
	if input.KeyCode == Keys.Block and Blocking then
		Blocking = false
		Remotes.Block:FireServer(false)
	end
end

return Input
