--[[
	MathUtil.lua
	Math utility functions
]]

local MathUtil = {}

function MathUtil.Lerp(a, b, t)
	return a + (b - a) * t
end

function MathUtil.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function MathUtil.Round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

function MathUtil.Sign(value)
	return value > 0 and 1 or value < 0 and -1 or 0
end

function MathUtil.Map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

function MathUtil.InverseLerp(a, b, value)
	return (value - a) / (b - a)
end

function MathUtil.SmoothStep(edge0, edge1, x)
	local t = MathUtil.Clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

return MathUtil
