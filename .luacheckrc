std = "max"
max_line_length = 100

files["spec/"] = { std = "+busted" }
files["luact-love/"] = { globals = { "love" } }
files["examples/love/"] = { globals = { "love" } }
