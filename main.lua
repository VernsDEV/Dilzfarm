-- // DILZ FARM | MAIN SCRIPT
-- // Compatible with Syde Library (Source Provided)

-- // 1. SERVICES (Cloneref for AC Evasion)
local Workspace           = cloneref(game:GetService("Workspace"))
local Players             = cloneref(game:GetService("Players"))
local CoreGui             = cloneref(game:GetService("CoreGui"))
local StarterGui          = cloneref(game:GetService("StarterGui"))
local Lighting            = cloneref(game:GetService("Lighting"))
local ReplicatedStorage   = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService    = cloneref(game:GetService("UserInputService"))
local RunService          = cloneref(game:GetService("RunService"))
local HttpService         = cloneref(game:GetService("HttpService"))
local TeleportService     = cloneref(game:GetService("TeleportService"))
local VirtualUser         = cloneref(game:GetService("VirtualUser"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local TweenService        = cloneref(game:GetService("TweenService"))

local LocalPlayer         = Players.LocalPlayer
local Mouse               = LocalPlayer:GetMouse()
local Camera              = Workspace.CurrentCamera

-- // 2. CONFIGURATION & STATE
local Config = {
    ["Functions"] = {};
    ["IsOwned_Bike"] = "...";
    ["AutoFarm"] = {
        ["Running"] = false;
        ["MovementType"] = "Teleport Mode"; 
        ["Marshmallow"] = {
            ["Enabled"] = false;
            ["BatchAmount"] = 1;
            ["Status"] = {
                ["Earned"] = 0;
                ["Total_Sold"] = 0;
                ["Sold_Type"] = {
                    ["Small Marshmallow Bag"] = 0;
                    ["Medium Marshmallow Bag"] = 0;
                    ["Large Marshmallow Bag"] = 0;
                };
            };
        };
    };
}

-- // 3. LOAD SYDE LIBRARY
-- NOTE: Since your repo is private, this URL will 404 unless authenticated.
-- If it fails, paste the raw source of ui.lua into a string and use: local Syde = loadstring(SOURCE_CODE)()
local LibSource = game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/ui.lua")
local Syde = loadstring(LibSource)()

-- Initialize Loader
Syde:Load({
    Name = "Dilz Farm",
    Logo = "14554547135", 
    ConfigFolder = "DilzFarm",
    Status = "Stable", 
    Accent = Color3.fromRGB(255, 151, 227),
    HitBox = Color3.fromRGB(255, 151, 227)
})

-- Initialize Window
local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = { Enabled = false } -- Skip home page, go straight to tabs
})

-- Create FARM Tab (Using correct Syde API: Tab)
local FarmTab = Window:Tab({
    Title = "FARM"
})

-- // 4. CUSTOM TELEPORT LOGIC (9e9 Void Check)
local function CustomTeleport(targetCFrame)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = targetCFrame.Position
    local maxAttempts = 5
    
    for i = 1, maxAttempts do
        -- Break if farm is disabled during test
        if not Config["AutoFarm"]["Marshmallow"]["Enabled"] and i > 1 then return false end
        
        -- STEP A: TP TO VOID (9e9)
        hrp.CFrame = CFrame.new(0, 9e9, 0)
        
        -- STEP B: WAIT 1-2 SECONDS (RANDOM)
        task.wait(math.random(1, 2))
        
        -- STEP C: TP TO EXACT COORDINATE
        hrp.CFrame = targetCFrame
        task.wait(0.5) -- Allow physics to settle
        
        -- STEP D: CHECK COORDINATES
        local currentPos = hrp.Position
        local distance = (currentPos - targetPos).Magnitude
        
        -- If almost exact (< 3 studs), SUCCESS - Don't try again
        if distance < 3 then
            return true
        end
        -- If not same, loop continues to try again
    end
    return false
end

-- // 5. MARSHMALLOW FARM LOGIC (SELLING ONLY - COOKING DISABLED)
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
            -- Check inventory for marshmallows to sell
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
                -- Execute Custom TP Logic to Sell NPC
                local sellCFrame = CFrame.new(511.1, 3.6, 601.4)
                local success = CustomTeleport(sellCFrame)
                
                if success then
                    local npc = Workspace.Folders.NPCs:FindFirstChild("Lamont Bell")
                    if npc then
                        local prompt = npc.UpperTorso:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                            
                            -- Equip and sell each bag
                            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(item)
                                    task.wait(0.2)
                                    fireproximityprompt(prompt)
                                    
                                    -- Update Stats
                                    local bagType = item.Name
                                    if Config["AutoFarm"]["Marshmallow"]["Status"]["Sold_Type"][bagType] then
                                        Config["AutoFarm"]["Marshmallow"]["Status"]["Total_Sold"] += 1
                                        Config["AutoFarm"]["Marshmallow"]["Status"]["Sold_Type"][bagType] += 1
                                        Config["AutoFarm"]["Marshmallow"]["Status"]["Earned"] += MarshmallowSellPrices[bagType] or 0
                                    end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            else
                -- ==========================================
                -- COOKING LOGIC DISABLED AS REQUESTED
                -- Previously: Buy ingredients -> Cook -> Collect
                -- Now: Just waits for manual restock or external cooking
                -- ==========================================
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

-- // 6. UI ELEMENTS (Strictly using Syde API from Pasted_Text)

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

-- Button: Test Teleport (FIXED: Now uses correct Syde Button API)
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