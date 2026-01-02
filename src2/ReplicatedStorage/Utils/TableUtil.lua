--[[
	TableUtil.lua
	Table utility functions
]]

local TableUtil = {}

function TableUtil.DeepCopy(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end

	local copy = {}
	for key, value in pairs(tbl) do
		copy[TableUtil.DeepCopy(key)] = TableUtil.DeepCopy(value)
	end

	return setmetatable(copy, getmetatable(tbl))
end

function TableUtil.Merge(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			TableUtil.Merge(target[key], value)
		else
			target[key] = value
		end
	end
	return target
end

function TableUtil.Count(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function TableUtil.Clear(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

function TableUtil.Find(tbl, value)
	for key, val in pairs(tbl) do
		if val == value then
			return key
		end
	end
	return nil
end

function TableUtil.Map(tbl, func)
	local result = {}
	for key, value in pairs(tbl) do
		result[key] = func(value, key)
	end
	return result
end

function TableUtil.Filter(tbl, predicate)
	local result = {}
	for key, value in pairs(tbl) do
		if predicate(value, key) then
			result[key] = value
		end
	end
	return result
end

return TableUtil
