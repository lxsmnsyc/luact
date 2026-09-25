std = "max"
max_line_length = 100

-- Lua and LuaRocks installed into the checkout by CI
exclude_files = { ".lua/", ".luarocks/", ".install/" }

files["spec/"] = { std = "+busted" }
files["luact-love/"] = { globals = { "love" } }
files["examples/love/"] = { globals = { "love" } }
