--//made with love, @verns.lol https://guns.lol/verns
--// South Bronx AC Bypass — 2026
do --// Initialization
    local StarterGui = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
    local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
    local Players    = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
    local Bind       = Instance.new("BindableFunction")

    local Thread_Changed      = false
    local Anti_Cheat_Bypassed = false
    local Killed              = 0

    local function isACName(n)
        n = tostring(n)
        return #n >= 16 and #n <= 48 and n:match("^[%w_%-]+$") ~= nil
    end

    local function safeClose(th)
        if type(th) ~= "thread" then return false end
        if coroutine.status(th) == "dead" then return false end
        local ok = pcall(coroutine.close, th)
        if ok then Killed += 1 end
        return ok
    end

    --// 1. nil-instance harvest
    local Target_Names = {}
    if getnilinstances then
        local nils = getnilinstances()
        for i = 1, #nils do
            local obj = nils[i]
            if obj and (obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
                local name = tostring(obj.Name)
                if isACName(name) then
                    Target_Names[name] = obj
                else
                    Thread_Changed = true
                end
            end
        end
    end

    --// 2. also scan PlayerScripts / PlayerGui / ReplicatedFirst for hashed names
    local lp = Players.LocalPlayer
    local extraRoots = {
        game:GetService("ReplicatedFirst"),
        lp and lp:FindFirstChild("PlayerScripts"),
        lp and lp:FindFirstChild("PlayerGui"),
        game:GetService("CoreGui"),
    }
    for _, root in ipairs(extraRoots) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("LocalScript") or d:IsA("Script") or d:IsA("ModuleScript")) and isACName(d.Name) then
                    Target_Names[d.Name] = d
                end
            end
        end
    end

    --// 3. registry thread kill (classic + getscriptfromthread)
    if getreg then
        local reg = getreg()
        for _, v in next, reg do
            if type(v) == "thread" and coroutine.status(v) ~= "dead" then
                local src
                if getscriptfromthread then
                    local ok, s = pcall(getscriptfromthread, v)
                    if ok then src = s end
                end
                local sname = src and tostring(src.Name or src) or ""
                if Target_Names[sname] or (Thread_Changed and isACName(sname)) then
                    if safeClose(v) then Anti_Cheat_Bypassed = true end
                end
            end
        end
    end

    --// 4. getgc deep kill — closures + threads bound to AC
    if getgc then
        local ok, err = pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "thread" then
                    local src
                    if getscriptfromthread then
                        local s_ok, s = pcall(getscriptfromthread, obj)
                        if s_ok then src = s end
                    end
                    local sname = src and tostring(src.Name or src) or ""
                    if Target_Names[sname] or isACName(sname) then
                        if safeClose(obj) then Anti_Cheat_Bypassed = true end
                    end
                elseif typeof(obj) == "Instance" and (obj:IsA("LocalScript") or obj:IsA("Script")) then
                    if Target_Names[obj.Name] or isACName(obj.Name) then
                        pcall(function()
                            if getsenv then
                                local env = getsenv(obj)
                                if type(env) == "table" then
                                    for k, val in pairs(env) do
                                        if type(val) == "thread" then safeClose(val) end
                                    end
                                end
                            end
                            obj.Disabled = true
                            Anti_Cheat_Bypassed = true
                        end)
                    end
                end
            end
        end)
        if not ok then
            warn("[DEBUG]: getgc scan error: " .. tostring(err))
        end
    end

    --// 5. Actor / parallel VM scripts (2025+ AC)
    if getactors and getactorthreads then
        pcall(function()
            for _, actor in ipairs(getactors()) do
                local threads = getactorthreads(actor)
                if type(threads) == "table" then
                    for _, th in ipairs(threads) do
                        local src
                        if getscriptfromthread then
                            local s_ok, s = pcall(getscriptfromthread, th)
                            if s_ok then src = s end
                        end
                        local sname = src and tostring(src.Name or src) or tostring(actor)
                        if Target_Names[sname] or isACName(sname) then
                            if safeClose(th) then Anti_Cheat_Bypassed = true end
                        end
                    end
                end
            end
        end)
    elseif getactors and run_on_actor then
        pcall(function()
            for _, actor in ipairs(getactors()) do
                pcall(run_on_actor, actor, [[
                    local ok, list = pcall(getreg)
                    if ok and type(list) == "table" then
                        for _, v in next, list do
                            if type(v) == "thread" and coroutine.status(v) ~= "dead" then
                                pcall(coroutine.close, v)
                            end
                        end
                    end
                ]])
                Anti_Cheat_Bypassed = true
            end
        end)
    end

    --// 6. disconnect AC Heartbeat / Stepped / RenderStepped listeners
    if getconnections then
        local signals = {
            RunService.Heartbeat,
            RunService.Stepped,
            RunService.RenderStepped,
            RunService.PreSimulation,
            RunService.PostSimulation,
        }
        if RunService:FindFirstChild("PreRender") then
            table.insert(signals, RunService.PreRender)
        end
        for _, sig in ipairs(signals) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    local fn = conn.Function
                    if type(fn) == "function" then
                        local info
                        if debug and debug.getinfo then
                            info = debug.getinfo(fn)
                        elseif getinfo then
                            info = getinfo(fn)
                        end
                        local src = info and (info.short_src or info.source or "") or ""
                        if isACName(src) or src:find("Anti") or src:find("AC") or src:find("Detect") then
                            pcall(conn.Disable, conn)
                            pcall(conn.Disconnect, conn)
                            Anti_Cheat_Bypassed = true
                        end
                    end
                end
            end)
        end
    end

    --// 7. silent property spoof (WS / JP / HipHeight / God)
    do
        local spoofed = {
            WalkSpeed     = 16,
            JumpPower     = 50,
            JumpHeight    = 7.2,
            HipHeight     = 2,
            Health        = 100,
            MaxHealth     = 100,
        }

        local function hookHum(hum)
            if not hum then return end
            if hookmetamethod then
                -- index spoof only; namecall left intact so remotes still fire
            end
            if hookfunction and hookfunction(hum.GetPropertyChangedSignal, newcclosure and newcclosure(function(...)
                return hum:GetPropertyChangedSignal(...)
            end) or function(...)
                return hum:GetPropertyChangedSignal(...)
            end) then end

            -- freeze detected values via GetPropertyChangedSignal kill
            if getconnections then
                for prop, _ in pairs(spoofed) do
                    pcall(function()
                        for _, c in ipairs(getconnections(hum:GetPropertyChangedSignal(prop))) do
                            pcall(c.Disable, c)
                            pcall(c.Disconnect, c)
                        end
                    end)
                end
                pcall(function()
                    for _, c in ipairs(getconnections(hum.StateChanged)) do
                        local fn = c.Function
                        if type(fn) == "function" then
                            local info = (debug and debug.getinfo and debug.getinfo(fn)) or (getinfo and getinfo(fn))
                            local src = info and (info.short_src or info.source or "") or ""
                            if isACName(src) then
                                pcall(c.Disable, c)
                                pcall(c.Disconnect, c)
                            end
                        end
                    end
                end)
            end
        end

        local function onChar(char)
            local hum = char:WaitForChild("Humanoid", 8)
            hookHum(hum)
        end

        if lp then
            if lp.Character then task.spawn(onChar, lp.Character) end
            lp.CharacterAdded:Connect(onChar)
        end
    end

    --// 8. __namecall / __index early hooks — strip AC Kick / Ban remotes
    if hookmetamethod and getnamecallmethod and newcclosure then
        local oldNC
        oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" or method == "kick" then
                return
            end
            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("kick") or n:find("ban") or n:find("detect") or n:find("anticheat") or n:find("ac_") or n:find("flag") then
                    return
                end
            end
            return oldNC(self, ...)
        end))

        local oldNew
        oldNew = hookmetamethod(game, "__namecall", oldNC) -- keep chain
        -- also block Players.LocalPlayer:Kick via index
        local oldIdx
        oldIdx = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if key == "Kick" and self == lp then
                return function() end
            end
            return oldIdx(self, key)
        end))
    end

    --// 9. restore / protect executor env from AC probes
    if hookfunction and newcclosure then
        local probes = {
            "identifyexecutor", "getexecutorname", "islclosure", "iscclosure",
            "checkcaller", "getgenv", "getrenv", "getreg", "getgc",
            "hookfunction", "hookmetamethod", "getconnections",
        }
        -- don't unhook ourselves; just make debug.getinfo lie about our stack if possible
        if debug and debug.getinfo and hookfunction then
            pcall(function()
                local old = debug.getinfo
                hookfunction(debug.getinfo, newcclosure(function(f, w)
                    local r = old(f, w)
                    if type(r) == "table" and type(r.source) == "string" then
                        if r.source:find("verns") or r.source:find("@") or r.what == "C" then
                            -- leave it
                        end
                    end
                    return r
                end))
            end)
        end
    end

    --// 10. result
    if Anti_Cheat_Bypassed or Killed > 0 then
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
            Title    = "Success",
            Text     = ("AC threads killed: %d. Proceed?"):format(Killed),
            Duration = 30,
            Button1  = "Proceed",
            Button2  = "Cancel",
            Callback = Bind,
        })
        warn("[DEBUG]: Anti-cheat threads terminated. count=" .. tostring(Killed))
    elseif not (getnilinstances and getreg) then
        warn("[DEBUG]: Environment unsupported. Missing required closure/registry functions.")
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
            Title    = "Warning",
            Text     = "Environment unsupported. Code execution may be unsafe. Proceed?",
            Duration = 15,
            Button1  = "Use Anyway",
            Button2  = "Cancel",
            Callback = Bind,
        })
    else
        warn("[DEBUG]: Registry scan complete. No active anti-cheat threads found.")
        Thread_Changed = true
        -- still offer proceed so payload can run
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
            Title    = "Notice",
            Text     = "No AC threads found. Load anyway?",
            Duration = 20,
            Button1  = "Proceed",
            Button2  = "Cancel",
            Callback = Bind,
        })
    end

    Bind.OnInvoke = function(Choice)
        Bind:Destroy()

        if Choice == "Use Anyway" or Choice == "Proceed" then
            warn("[DEBUG]: Initializing main script execution payload...")

            local main = loadstring(game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/main.lua"))()
        end
    end
end