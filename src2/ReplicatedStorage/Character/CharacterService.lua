--[[
	CharacterService.lua
	Character data management
]]

local CharacterService = {}
local Characters = {}
local PlayerCharacters = {}

function CharacterService.Init()
	-- Load Arthur data
	local Arthur = require(script.Parent.Data.Arthur)
	Characters[Arthur.Name] = Arthur
	print("[CharacterService] Initialized")
end

function CharacterService.Get(player)
	local charName = PlayerCharacters[player] or "Arthur"
	return Characters[charName]
end

function CharacterService.SetCharacter(player, charName)
	if Characters[charName] then
		PlayerCharacters[player] = charName
		return true
	end
	return false
end

return CharacterService
