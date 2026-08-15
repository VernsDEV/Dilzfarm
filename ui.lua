-- ==========================================
-- DILZ FARM UI SCRIPT (FIXED API + LOGIC)
-- ==========================================

-- 1. Load the Syde Library
-- NOTE: Since your repo is private, game:HttpGet will 404.
-- PASTE THE RAW SOURCE OF library.lua INTO A STRING IF IT FAILS:
-- local Syde = loadstring(LIBRARY_SOURCE_STRING)()
local Syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/library.lua"))()

-- 2. Show the Loading Screen
Syde:Load({
    Name = "Dilz Farm",
    Logo = "14554547135",
    ConfigFolder = "DilzFarm",
    Status = "Stable",
    Accent = Color3.fromRGB(255, 151, 227),
    HitBox = Color3.fromRGB(255, 151, 227)
})

-- 3. Initialize the Main Window
local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = { Enabled = false }
})

-- 4. Create the "FARM" Tab
-- FIXED: Uses Window:InitTab() as defined in tbdata:InitTab within your source
local FarmTab = Window:InitTab({
    Title = "FARM"
})

-- // SERVICES & CONFIG FOR FARM LOGIC
local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

local Config = {
    ["AutoFarm"] = {
        ["Marshmallow"] = {
            ["Enabled"] = false;
        };
    };
}

-- // CUSTOM TELEPORT LOGIC (9e9 Void Check)
local function CustomTeleport(targetCFrame)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = targetCFrame.Position
    local maxAttempts = 5
    
    for i = 1, maxAttempts do
        if not Config["AutoFarm"]["Marshmallow"]["Enabled"] and i > 1 then return false end
        
        -- STEP A: TP TO VOID (9e9)
        hrp.CFrame = CFrame.new(0, 9e9, 0)
        
        -- STEP B: WAIT 1-2 SECONDS (RANDOM)
        task.wait(math.random(1, 2))
        
        -- STEP C: TP TO EXACT COORDINATE
        hrp.CFrame = targetCFrame
        task.wait(0.5)
        
        -- STEP D: CHECK COORDINATES
        local currentPos = hrp.Position
        local distance = (currentPos - targetPos).Magnitude
        
        -- If almost exact (< 3 studs), SUCCESS
        if distance < 3 then
            return true
        end
    end
    return false
end

-- // MARSHMALLOW FARM LOGIC (SELLING ONLY - COOKING DISABLED)
local MarshmallowFarm_Thread = nil
local MarshmallowSellPrices = {
    ["Small Marshmallow Bag"]  = 1470;
    ["Medium Marshmallow Bag"] = 2840;
    ["Large Marshmallow Bag"]  = 4050;
}

local function StartMarshmallowFarm()
    if MarshmallowFarm_Thread then return end
    
    MarshmallowFarm_Thread = task.spawn(function()
        while Config["AutoFarm"]["Marshmallow"]["Enabled"] do
            local hasMarshmallows = false
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item.Name:find("Marshmallow Bag") then hasMarshmallows = true break end
            end
            if not hasMarshmallows and LocalPlayer.Character then
                for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
                    if item.Name:find("Marshmallow Bag") then hasMarshmallows = true break end
                end
            end

            if hasMarshmallows then
                local sellCFrame = CFrame.new(511.1, 3.6, 601.4)
                local success = CustomTeleport(sellCFrame)
                
                if success then
                    local npc = Workspace.Folders.NPCs:FindFirstChild("Lamont Bell")
                    if npc then
                        local prompt = npc.UpperTorso:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                            
                            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(item)
                                    task.wait(0.2)
                                    fireproximityprompt(prompt)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            else
                -- COOKING DISABLED AS REQUESTED
                Syde:Notify({Title = "Farm Idle", Content = "No marshmallows found. Cooking disabled.", Duration = 3})
                task.wait(5)
            end
            
            task.wait(0.5)
        end
        MarshmallowFarm_Thread = nil
    end)
end

local function StopMarshmallowFarm()
    Config["AutoFarm"]["Marshmallow"]["Enabled"] = false
    if MarshmallowFarm_Thread then
        task.cancel(MarshmallowFarm_Thread)
        MarshmallowFarm_Thread = nil
    end
end

-- // 6. UI ELEMENTS (Strictly matching Syde API signatures)

-- Toggle: Auto Farm
FarmTab:Toggle({
    Title = "Marshmallow Auto Farm",
    Description = "Automatically teleports and sells marshmallows. (Cooking Disabled)",
    Value = false,
    CallBack = function(State)
        Config["AutoFarm"]["Marshmallow"]["Enabled"] = State
        if State then
            StartMarshmallowFarm()
        else
            StopMarshmallowFarm()
        end
    end
})

-- Button: Test Teleport
FarmTab:Button({
    Title = "Test Teleport",
    Description = "Manually test the custom 9e9 TP logic to 511.1, 3.6, 601.4",
    CallBack = function()
        task.spawn(function()
            Syde:Notify({Title = "TP Testing", Content = "Starting 9e9 void check sequence...", Duration = 2})
            local result = CustomTeleport(CFrame.new(511.1, 3.6, 601.4))
            if result then
                Syde:Notify({Title = "TP Success", Content = "Arrived at destination!", Duration = 3})
            else
                Syde:Notify({Title = "TP Failed", Content = "Could not reach destination after 5 attempts.", Duration = 3})
            end
        end)
    end
})