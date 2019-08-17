local ELEMENT = {}

local function el(renderer, props, children)
	return {
		typeof = ELEMENT,
		renderer = renderer,
		props = props or {},
		children = children or {},
	}
end

local function unmount(node, parent, key)
	--[[
		Call all cleanup functions
	--]]
	local cleanup = node.cleanup
	for i = 1, #cleanup do
		cleanup[i]()
	end
	--[[
		Unmount each children
	--]]
	for i = 1, #children do
		unmount(children[i], node)
	end
	
	parent.nodes[key] = {}
end

local parentNode
local currentNode

local function render(node, parent, index, forceRender)
	--[[
		Deconstruct node
	--]]
	local renderer = node.renderer
	local props = node.props or {}
	local children = node.children or {}
	
	--[[
		Determine node indentifier
	--]]
	local key = props.key or index or 1
	props.key = key
	--[[
		Check if parent has nodes
	--]]
	local nodes = parent.nodes
	
	--[[
		Preparation for element rendering
	--]]
	local function requestRender()
		local prevNode = currentNode
		local prevParent = parentNode
		
		local effects = node.effects or {}
		node.stateIndex = 0
		
		currentNode = node
		parentNode = parent
		
		local childNode = renderer(props, children)
		
		if (type(childNode) == "table" and childNode.typeof == ELEMENT) then
			render(childNode, node, 1)
		else
			node.nodes = { childNode }
		end
		
		--[[
			Execute effects
		--]]
		for i = 1, #effects do
			effects[i]()
		end
		
		--[[
			Remove all effects
		--]]
		node.effects = {}

		currentNode = prevNode
		parentNode = prevParent
	end
	
	if (forceRender) then
		return requestRender()
	end
	
	--[[
		Check if parent has nodes already
	--]]
	if nodes then
		--[[
			Get the corresponding rendered node
		--]]
		local renderedNode = nodes[key]
		
		--[[
			Check if node has the same renderer
		--]]
		if (renderedNode.renderer == renderer) then
			--[[
				Get properties
			--]]
			local renderedProps = renderedNode.props
			local renderedChildren = renderedNode.children
			
			--[[
				Compare new properties to old one
			--]]
			for k, v in pairs(props) do
				--[[
					check if attribute does not exist from old props
				--]]
				if (renderedProps[k] ~= v) then
					--[[
						Request a re-render
					--]]
					return requestRender()
				end
			end
			
			--[[
				Compare children
			--]]
			for i = 1, #children do
				local new = children[i]
				local old = renderedChildren[i]
				--[[
					Check if left is a new child
				--]]
				if (old == nil) then
					return requestRender()
				end
				--[[
					Check if both child has different renderer
				--]]
				if (new.renderer ~= old.renderer) then
					return requestRender()
				end
				--[[
					Check if both child has different keys
				--]]
				if (new.props.key ~= old.props.key) then
					return requestRender()
				end
			end
		else
			--[[
				Unmount rendered node
			--]]
			unmount(renderedNode, parent, key)
			--[[
				Request a re-render
			--]]
			return requestRender()
		end
	else
		--[[
			Initialize nodes
		--]]
		parent.nodes = { [key] = node }
		--[[
			Initialize state
		--]]
		node.states = {}
		return requestRender()
	end
end

local function useState(initialValue)
	if currentNode then
		local states = currentNode.states
		local index = currentNode.stateIndex + 1
		if (states[index] == nil) then
			states[index] = initialValue
		end
		
		local node = currentNode
		local parent = parentNode
		return states[index], function (newValue)
			if (states[index] ~= newValue) then
				states[index] = newValue
				render(node, parent, node.props.key, true)
			end
		end
	end
	return nil, function ()
		error("Invalid useState usage")
	end
end

local function div(props, children)
	return {
		element = "div",
		props = props,
		children = children,
	}
end

local function App(props, children)
	local counter, setCounter = useState(0)
	setCounter(1)
	return el(div, {}, "Counter: "..counter)
end

local container = {}
render(el(App, {}, {}), container)

local function logTable(tbl, lvl)
	local s = "{"
	for k, v in pairs(tbl) do
		local result
		if (type(v) == "table") then
			result = logTable(v, lvl + 1)
		else
			result = tostring(v)
		end
		s = s.."\n"..string.rep("  ", lvl + 1)..k..": "..result..","
	end
	s = s.."\n"..string.rep("  ", lvl).."}"
	return s
end

print(logTable(container, 0))