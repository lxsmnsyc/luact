local tasks = {}

local function schedule(func)
	tasks[#tasks + 1] = func
end

local function drain()
	for i = 1, #tasks do
		tasks[i]()
	end
	tasks = {}
end

return {
	schedule = schedule,
	drain = drain,
}