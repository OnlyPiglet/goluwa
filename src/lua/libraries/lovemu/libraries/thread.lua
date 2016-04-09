local love = ... or love

love.thread = {}

local threads = {}
local threads2 = {}
local running

local Thread = {}
Thread.Type = "Thread"

function Thread:start(...) self.args = {...} self.thread:Start() if self.thread.co then threads2[self.thread.co] = self else running = self end end
function Thread:wait() end
function Thread:set(key, val) self.vars[key] = val end
function Thread:send() end
function Thread:receive() end
function Thread:peek() end
function Thread:kill() end
function Thread:getName() return self.name end
function Thread:getKeys() return {} end
function Thread:get() return end
function Thread:demand(name) return self.vars[name] end
function Thread:getError(name) end

function love.thread.newThread(name, script_path)
	local self = lovemu.CreateObject(Thread)

	self.vars = {}

	local env = getfenv(2)
	local func = love.filesystem.load(script_path or name)
	local thread = tasks.CreateTask()
	function thread.OnStart()
		setfenv(func, env)
		thread:Wait()
		func(unpack(self.args))
		thread:Wait()
	end

	function thread:OnFinish()
		logn("[lovemu] thread ", name ," finished")
	end

	self.thread = thread
	threads[name] = self

	self.name = name

	logn("[lovemu] creating thread ", name)

	return self
end

function love.thread.getThread(name)
	if not name then
		return threads2[coroutine.running()] or running
	end
	return threads[name]
end

function love.thread.getThreads()
	return threads
end

local channels = {}

local Channel = {}
Channel.Type = "Channel"

function Channel:clear() table.clear(self.queue) end
function Channel:demand() repeat until #self.queue ~= 0 return self:pop() end -- supposedly blocking
function Channel:getCount() return #self.queue end
function Channel:peek() return self.queue[1] end
function Channel:pop() return table.remove(self.queue, 1) end
function Channel:push(value) return table.insert(self.queue, value) end
function Channel:supply(value) return self:push(value) end -- supposedly blocking


function love.thread.newChannel()
	local self = lovemu.CreateObject(Channel)

	self.queue = {}

	return self
end

function love.thread.getChannel(name)
	return channels[name]
end