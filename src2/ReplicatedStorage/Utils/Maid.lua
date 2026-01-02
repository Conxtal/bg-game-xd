--[[
	Maid.lua
	Resource cleanup manager

	Usage:
		local maid = Maid.new()
		maid:Add(connection)
		maid:Add(instance)
		maid:Add(function() ... end)
		maid:Cleanup()
]]

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {}
	}, Maid)
end

function Maid:Add(task)
	assert(task ~= nil, "Task cannot be nil")
	table.insert(self._tasks, task)
	return task
end

function Maid:Remove(task)
	local index = table.find(self._tasks, task)
	if index then
		table.remove(self._tasks, index)
	end
end

function Maid:Cleanup()
	for _, task in ipairs(self._tasks) do
		if type(task) == "function" then
			task()
		elseif typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "Instance" then
			task:Destroy()
		elseif type(task) == "table" and task.Destroy then
			task:Destroy()
		elseif type(task) == "table" and task.Disconnect then
			task:Disconnect()
		end
	end
	table.clear(self._tasks)
end

function Maid:Destroy()
	self:Cleanup()
end

return Maid
