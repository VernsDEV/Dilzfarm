-- main.lua
local url = "https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/ui.lua"
local scriptContent = game:HttpGet(url)
local loadFunction = loadstring(scriptContent)
if loadFunction then
    loadFunction() -- Jalankan ui.lua
else
    warn("cant load ui, pls report this to VernsDEV or dilz on discord")
end