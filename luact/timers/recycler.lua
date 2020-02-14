return function ()
  local recycler = { [0] = 1 }

  local function alloc()
    local id = recycler[0]

    if (recycler[id] == nil) then
      recycler[0] = id + 1
    else
      recycler[0] = recycler[id]
    end

    recycler[id] = -1

    return id
  end

  local function free(id)
    if (recycler[id] == -1) then
      recycler[id] = recycler[0]
      recycler[0] = id

      return true
    end
    return false
  end

  return alloc, free
end