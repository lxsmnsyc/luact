-- Unique markers used to tag elements and special component types.
-- Each marker is a distinct table, so it can only be matched by identity.

local function symbol(name)
  return setmetatable({}, {
    __tostring = function ()
      return "luact." .. name
    end,
  })
end

return {
  ELEMENT = symbol("element"),
  PORTAL = symbol("portal"),
  FRAGMENT = symbol("Fragment"),
  CONTEXT = symbol("context"),
  CONSUMER = symbol("Consumer"),
  MEMO = symbol("memo"),
  ERROR_BOUNDARY = symbol("ErrorBoundary"),
}
