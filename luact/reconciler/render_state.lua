-- State shared by the modules of the render phase while one fiber renders.

return {
  -- False when the fiber being rendered got the same props, state and
  -- context as last time, so its output can be reused.
  did_receive_update = false,
}
