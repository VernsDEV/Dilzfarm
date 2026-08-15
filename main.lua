-- ==========================================
-- DILZ FARM | MARSHMALLOW AUTO FARM SCRIPT
-- ==========================================

-- // 1. Services (Using cloneref for anti-cheat evasion)
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

-- // 2. Configuration Table
local Config = {
    ["Functions"] = {};
    ["IsOwned_Bike"] = "...";
    ["AutoFarm"] = {
        ["Running"] = false;
        ["MovementType"] = "...";
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

-- // 3. UI Initialization (Syde Library)
-- NOTE: Since your repo is private, game:HttpGet will return a 404 error. 
-- To fix this, either authenticate your executor, or paste the raw ui.lua source 
-- code directly into a string and use: local Syde = loadstring(SOURCE_CODE)()
local Syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/ui.lua"))()

Syde:Load({
    Name = "Dilz Farm",
    Logo = "14554547135", 
    ConfigFolder = "DilzFarm",
    Status = "Stable", 
    Accent = Color3.fromRGB(255, 151, 227),
    HitBox = Color3.fromRGB(255, 151, 227)
})

local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = { Enabled = false }
})

local FarmTab = Window:InitTab({
    Title = "FARM"
})

-- // 4. Custom Teleport Logic
local function CustomTeleport(targetCFrame)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = targetCFrame.Position
    local maxAttempts = 5
    
    for i = 1, maxAttempts do
        -- Break if farm is disabled
        if not Config["AutoFarm"]["Marshmallow"]["Enabled"] then return false end
        
        -- Step A: TP to 9e9 (Void)
        hrp.CFrame = CFrame.new(0, 9e9, 0)
        task.wait(math.random(1, 2)) -- Wait 1-2 seconds randomly
        
        -- Step B: TP to exact target coordinate
        hrp.CFrame = targetCFrame
        task.wait(0.5) -- Let physics/engine settle
        
        -- Step C: Check coordinate
        local currentPos = hrp.Position
        local distance = (currentPos - targetPos).Magnitude
        
        -- If almost exact (within 3 studs), don't try again
        if distance < 20 then
            return true
        end
        -- If not same, loop continues and tries again
    end
    return false
end

-- // 5. Marshmallow Farm Logic
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
            -- Check if we have marshmallows in inventory to sell
            local hasMarshmallows = false
            local backpackItems = LocalPlayer.Backpack:GetChildren()
            local charItems = LocalPlayer.Character and LocalPlayer.Character:GetChildren() or {}
            
            for _, item in ipairs(backpackItems) do
                if item.Name:find("Marshmallow Bag") then hasMarshmallows = true break end
            end
            if not hasMarshmallows then
                for _, item in ipairs(charItems) do
                    if item.Name:find("Marshmallow Bag") then hasMarshmallows = true break end
                end
            end

            if hasMarshmallows then
                -- Teleport to exact sell coordinate using custom logic
                local sellCFrame = CFrame.new(511.1, 3.6, 601.4)
                local success = CustomTeleport(sellCFrame)
                
                if success then
                    -- Interact with Sell NPC (Lamont Bell)
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
                                    
                                    -- Update Config Stats
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
                -- INSERT FULL COOKING/BUYING LOGIC HERE
                -- (Paste the internal cooking loop from your Main.lua here 
                -- if you want it to automatically buy ingredients and cook 
                -- when the backpack is empty)
                -- ==========================================
                task.wait(1)
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

-- // 6. UI Elements
FarmTab:Toggle({
    Title = "Marshmallow Auto Farm",
    Description = "Automatically teleports and sells marshmallows using void TP.",
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

FarmTab:Button({
    Title = "Test Teleport",
    Description = "Manually test the custom TP logic to 511.1, 3.6, 601.4",
    CallBack = function()
        CustomTeleport(CFrame.new(511.1, 3.6, 601.4))
    end
})