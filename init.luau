local function loadFile(name)
	return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/x8lua/Staconf/main/" .. name .. ".luau"))()
end

return loadFile("staconf_demo")
