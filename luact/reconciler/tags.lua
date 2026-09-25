-- Fiber tags, effect flags and hook effect flags.
--
-- Flags are powers of two stored in a number. Lua 5.1 has no bitwise
-- operators, so `has`, `add` and `remove` do the bit math with arithmetic.

local M = {}

M.work = {
  FUNCTION_COMPONENT = 0,
  HOST_ROOT = 1,
  HOST_PORTAL = 2,
  HOST_COMPONENT = 3,
  HOST_TEXT = 4,
  FRAGMENT = 5,
  CONTEXT_PROVIDER = 6,
  CONTEXT_CONSUMER = 7,
  MEMO_COMPONENT = 8,
  ERROR_BOUNDARY = 9,
}

-- Effect flags of a fiber.
M.effect = {
  NO_EFFECT = 0,
  PERFORMED_WORK = 1,
  PLACEMENT = 2,
  UPDATE = 4,
  DELETION = 8,
  CALLBACK = 16,
  REF = 32,
  PASSIVE = 64,
  DID_CAPTURE = 128,
  INCOMPLETE = 256,
  SHOULD_CAPTURE = 512,
}

-- Flags of an effect created by an effect hook.
M.hook = {
  HAS_EFFECT = 1,
  INSERTION = 2,
  LAYOUT = 4,
  PASSIVE = 8,
}

function M.has(flags, flag)
  return flags % (flag + flag) >= flag
end

function M.add(flags, flag)
  if flags % (flag + flag) >= flag then
    return flags
  end
  return flags + flag
end

function M.remove(flags, flag)
  if flags % (flag + flag) >= flag then
    return flags - flag
  end
  return flags
end

return M
