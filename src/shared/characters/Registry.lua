--[[
	Registry.lua
	Character registry and selection
	Location: ReplicatedStorage
]]

local Registry = {}
Registry.Characters = {}
Registry.DefaultCharacter = "Arthur"

function Registry.Register(characterData)
	if characterData and characterData.Name then
		Registry.Characters[characterData.Name] = characterData
		return true
	end
	return false
end

function Registry.Get(name)
	return Registry.Characters[name]
end

function Registry.GetAll()
	return Registry.Characters
end

function Registry.Exists(name)
	return Registry.Characters[name] ~= nil
end

function Registry.Init()
	-- Auto-register Arthur
	local Arthur = require(script.Parent.Arthur)
	Registry.Register(Arthur)
	print("[Registry] Loaded character:", Arthur.Name)
end

return Registry
