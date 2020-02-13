
local commit_root = require "luact.fiber.commit_root"
local perform_unit_of_work = require "luact.fiber.perform_unit_of_work"

return function (reconciler)
  local function work_loop(deadline)
    local should_yield = false

    while (reconciler.next_unit_of_work and not should_yield) do
      reconciler.next_unit_of_work = perform_unit_of_work(
        reconciler.next_unit_of_work.alternate,
        reconciler.next_unit_of_work
      )

      should_yield = deadline() < 1
    end

    if ((not reconciler.next_unit_of_work) and reconciler.wip_root) then
      commit_root(reconciler)
    end

    reconciler:schedule(work_loop)
  end

  reconciler:schedule(work_loop)
end