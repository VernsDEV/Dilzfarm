-- ===================================================
-- ui.lua  --  Dilz Farm Main Module
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
local Workspace = cloneref(game:GetService("Workspace"))
local Players   = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

local Config = {
    AutoFarm = {
        Marshmallow = {
            Enabled = false
        }
    }
}

-- ===================================================
-- 6. Custom teleport logic (X‑axis 9e9 method)
-- ===================================================
local function CustomTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return false end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local targetPos = targetCFrame.Position
    local maxAttempts = 5

    for attempt = 1, maxAttempts do
        -- Stop if farm was disabled mid‑attempt
        if not Config.AutoFarm.Marshmallow.Enabled then
            return false
        end

        -- Step 1: teleport to 9e9 on X axis
        rootPart.CFrame = CFrame.new(9e9, 0, 0)
        task.wait(0.5)  -- let engine process

        -- Step 2: teleport to final coordinates
        rootPart.CFrame = targetCFrame
        task.wait(0.5)  -- let physics settle

        -- Verify position
        local distance = (rootPart.Position - targetPos).Magnitude
        if distance < 3 then
            return true   -- success
        end
        -- otherwise retry
    end
    return false
end

-- ===================================================
-- 7. Marshmallow selling logic (no cooking)
-- ===================================================
local MarshmallowFarm_Thread = nil

local function StartMarshmallowFarm()
    if MarshmallowFarm_Thread then return end

    MarshmallowFarm_Thread = task.spawn(function()
        while Config.AutoFarm.Marshmallow.Enabled do
            -- Check inventory for marshmallow bags
            local hasMarshmallows = false
            local backpackItems = LocalPlayer.Backpack:GetChildren()
            for _, item in ipairs(backpackItems) do
                if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                    hasMarshmallows = true
                    break
                end
            end
            if not hasMarshmallows and LocalPlayer.Character then
                for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
                    if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                        hasMarshmallows = true
                        break
                    end
                end
            end

            if hasMarshmallows then
                -- NPC Lamont Bell coordinates
                local sellCFrame = CFrame.new(511.1, 3.6, 601.4)
                local success = CustomTeleport(sellCFrame)

                if success then
                    local npcFolder = Workspace:FindFirstChild("Folders") and Workspace.Folders:FindFirstChild("NPCs")
                    if npcFolder then
                        local lamont = npcFolder:FindFirstChild("Lamont Bell")
                        if lamont then
                            local prompt = lamont:FindFirstChild("UpperTorso") and lamont.UpperTorso:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                -- Tweak prompt properties
                                pcall(function()
                                    prompt.HoldDuration = 0
                                    prompt.RequiresLineOfSight = false
                                end)

                                -- Sell each marshmallow bag
                                for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                    if item:IsA("Tool") and item.Name:find("Marshmallow Bag") then
                                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                        if hum then
                                            hum:EquipTool(item)
                                            task.wait(0.2)
                                        end
                                        -- Trigger the prompt
                                        local fired = pcall(function()
                                            fireproximityprompt(prompt)
                                        end)
                                        if not fired then
                                            pcall(function()
                                                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                                            end)
                                        end
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            else
                -- No marshmallows → idle (cooking is disabled)
                Syde:Notify({
                    Title = "Out of Stock",
                    Content = "No marshmallows found. Cooking is disabled.",
                    Duration = 3
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
    Description = "Automatically teleport and sell marshmallows (cooking disabled).",
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
    Description = "Test the X‑axis 9e9 teleport to NPC coordinates (511, 3.6, 601.4).",
    CallBack = function()
        task.spawn(function()
            Syde:Notify({
                Title = "Teleport Test",
                Content = "Starting void sequence...",
                Duration = 2
            })
            local result = CustomTeleport(CFrame.new(511.1, 3.6, 601.4))
            if result then
                Syde:Notify({
                    Title = "Success",
                    Content = "Arrived at destination!",
                    Duration = 3
                })
            else
                Syde:Notify({
                    Title = "Failed",
                    Content = "Could not reach destination after 5 attempts.",
                    Duration = 3
                })
            end
        end)
    end
})