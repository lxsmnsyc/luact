local function is(t)
  return function (value)
    return type(value) == t
  end
end

return {
  ['number'] = is('number'),
  ['boolean'] = is('boolean'),
  ['string'] = is('string'),
  ['function'] = is('function'),
  ['table'] = is('table'),
}