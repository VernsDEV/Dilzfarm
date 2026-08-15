-- ===================================================
-- ui.lua  --  Dilz Farm Main Module (void teleport)
-- ===================================================

-- 1. Load Syde UI library
local Syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/library.lua"))()

-- 2. Show loading screen
Syde:Load({
    Name = "Dilz Farm",
    Logo = "14554547135",
    ConfigFolder = "DilzFarm",
    Status = "Stable",
    Accent = Color3.fromRGB(255, 151, 227),
    HitBox = Color3.fromRGB(255, 151, 227)
})

-- 3. Create main window
local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = { Enabled = false }
})

-- 4. Create "FARM" tab
local FarmTab = Window:InitTab({
    Title = "FARM"
})

-- ===================================================
-- 5. Services & state
-- ===================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Config = {
    AutoFarm = {
        Marshmallow = {
            Enabled = false
        }
    }
}

-- ===================================================
-- 6. Teleport with void (9e9 on X axis)
-- ===================================================
local function CustomTeleport(targetCFrame)
    -- Get character and root part
    local char = LocalPlayer.Character
    if not char then
        return false, "Character not found"
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false, "HumanoidRootPart not found"
    end

    local targetPos = targetCFrame.Position
    local maxAttempts = 5

    for attempt = 1, maxAttempts do
        -- Stop if farm disabled mid‑attempt
        if not Config.AutoFarm.Marshmallow.Enabled then
            return false, "Farm disabled during attempt"
        end

        -- Re‑fetch character/rootPart in case they changed
        char = LocalPlayer.Character
        if not char then
            return false, "Character lost during attempt"
        end
        rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return false, "RootPart lost during attempt"
        end

        -- Step 1: Teleport to void (X = 9e9)
        local voidCF = CFrame.new(9e9, 0, 0)
        local success, err = pcall(function()
            rootPart.CFrame = voidCF
        end)
        if not success then
            return false, "Void teleport failed: " .. tostring(err)
        end

        -- Step 2: Wait for engine to process
        task.wait(0.5)

        -- Step 3: Teleport to final target
        success, err = pcall(function()
            rootPart.CFrame = targetCFrame
        end)
        if not success then
            return false, "Target teleport failed: " .. tostring(err)
        end

        -- Step 4: Let physics settle
        task.wait(0.5)

        -- Verify position
        local distance = (rootPart.Position - targetPos).Magnitude
        if distance < 3 then
            return true, "Success on attempt " .. attempt
        end
        -- Otherwise, loop again
    end

    return false, "Failed after " .. maxAttempts .. " attempts"
end

-- ===================================================
-- 7. Marshmallow selling logic (no cooking)
-- ===================================================
local MarshmallowFarm_Thread = nil

local function StartMarshmallowFarm()
    if MarshmallowFarm_Thread then return end

    MarshmallowFarm_Thread = task.spawn(function()
        while Config.AutoFarm.Marshmallow.Enabled do
            -- Check backpack for marshmallow bags
            local hasMarshmallows = false
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                    hasMarshmallows = true
                    break
                end
            end

            if hasMarshmallows then
                local sellCFrame = CFrame.new(511.1, 3.6, 601.4)
                local success, msg = CustomTeleport(sellCFrame)
                if success then
                    -- Sell logic
                    local npcFolder = Workspace:FindFirstChild("Folders") and Workspace.Folders:FindFirstChild("NPCs")
                    if npcFolder then
                        local lamont = npcFolder:FindFirstChild("Lamont Bell")
                        if lamont then
                            local prompt = lamont:FindFirstChild("UpperTorso") and lamont.UpperTorso:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function()
                                    prompt.HoldDuration = 0
                                    prompt.RequiresLineOfSight = false
                                end)
                                for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                    if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                        if hum then hum:EquipTool(item) end
                                        task.wait(0.2)
                                        pcall(function() fireproximityprompt(prompt) end)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                else
                    Syde:Notify({
                        Title = "Teleport Error",
                        Content = msg or "Unknown",
                        Duration = 3
                    })
                    task.wait(3)
                end
            else
                Syde:Notify({
                    Title = "Out of Stock",
                    Content = "No marshmallows to sell.",
                    Duration = 2
                })
                task.wait(5)
            end
            task.wait(0.5)
        end
        MarshmallowFarm_Thread = nil
    end)
end

local function StopMarshmallowFarm()
    Config.AutoFarm.Marshmallow.Enabled = false
    if MarshmallowFarm_Thread then
        task.cancel(MarshmallowFarm_Thread)
        MarshmallowFarm_Thread = nil
    end
end

-- ===================================================
-- 8. UI elements
-- ===================================================

-- Toggle: Auto Farm
FarmTab:Toggle({
    Title = "Marshmallow Auto Farm",
    Description = "Automatically teleport (with void) and sell marshmallows.",
    Value = false,
    CallBack = function(state)
        Config.AutoFarm.Marshmallow.Enabled = state
        if state then
            StartMarshmallowFarm()
        else
            StopMarshmallowFarm()
        end
    end
})

-- Button: Test Teleport
FarmTab:Button({
    Title = "Test Teleport",
    Description = "Test void teleport to NPC (511, 3.6, 601.4).",
    CallBack = function()
        task.spawn(function()
            Syde:Notify({
                Title = "Teleport Test",
                Content = "Starting void sequence...",
                Duration = 2
            })
            local result, msg = CustomTeleport(CFrame.new(511.1, 3.6, 601.4))
            if result then
                Syde:Notify({
                    Title = "Success",
                    Content = "Arrived at destination!",
                    Duration = 3
                })
            else
                Syde:Notify({
                    Title = "Failed",
                    Content = msg or "Unknown error",
                    Duration = 5
                })
            end
        end)
    end
})