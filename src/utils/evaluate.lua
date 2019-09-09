local typeTable = require "luact.src.types.table"
local typeFunction = require "luact.src.types.func"

local function evaluate(tree, beforeCall, afterCall)
  
  if (typeTable(tree)) then
    if (typeFunction(beforeCall)) then
      beforeCall(tree)
    end

    local nodes = tree.nodes

    if (typeTable(nodes)) then
      for i = 1, #nodes do
        evaluate(nodes[i], beforeCall, afterCall)
      end
    end
    
    if (typeFunction(afterCall)) then
      afterCall(tree)
    end
  end
end

return evaluate
