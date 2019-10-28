local Timeout = {}
Timeout.__index = Timeout

local life = 0

local timeouts = {}
local tindex = 0

local epochProvider

function Timeout.new(func, duration, ...)
  
  local instance = setmetatable({}, Timeout)

  tindex = tindex + 1
  timeouts[tindex] = instance
  
  instance.index = tindex
  instance.epoch = epochProvider()

  local args = {...}
  instance.call = function ()
    func(unpack(args))
  end
  
  return instance
end

function Timeout:cancel()
  table.remove(timeouts, self.index)
  tindex = tindex - 1
end

function Timeout.update(dt)
  life = life + dt
  local i = 1
  
  while i <= tindex do
    local instance = timeouts[i]
    
    if (life >= instance.epoch) then
      instance.call()
      
      table.remove(timeouts, i)
      tindex = tindex - 1
    else
      i = i + 1
    end
  end
end

function Timeout.setProvider(provider)
  epochProvider = provider
end

return Timeout