--[[
	Signal.lua
	Custom event system - better than BindableEvents

	Usage:
		local signal = Signal.new()
		local conn = signal:Connect(function(...) end)
		signal:Fire(...)
		conn:Disconnect()
		signal:Destroy()
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._connections = {}
	self._firing = false
	return self
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Callback must be a function")

	local connection = {
		Connected = true,
		_signal = self,
		_callback = callback
	}

	function connection:Disconnect()
		if not self.Connected then return end
		self.Connected = false

		local connections = self._signal._connections
		local index = table.find(connections, self)
		if index then
			table.remove(connections, index)
		end
	end

	table.insert(self._connections, connection)
	return connection
end

function Signal:Fire(...)
	if self._firing then
		warn("[Signal] Recursive fire detected")
		return
	end

	self._firing = true

	-- Copy connections to avoid issues if disconnected during fire
	local connections = table.clone(self._connections)

	for _, conn in ipairs(connections) do
		if conn.Connected then
			task.spawn(conn._callback, ...)
		end
	end

	self._firing = false
end

function Signal:Wait()
	local thread = coroutine.running()
	local conn

	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Signal:Destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

return Signal
