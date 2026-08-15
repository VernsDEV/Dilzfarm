-- ===================================================
-- ui.lua  --  Dilz Farm (All Farm Logic + Syde UI)
-- ===================================================

-- 1. Load Syde library
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

-- 3. Services
local Workspace           = cloneref(game:GetService("Workspace"))
local Players             = cloneref(game:GetService("Players"))
local ReplicatedStorage   = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService    = cloneref(game:GetService("UserInputService"))
local RunService          = cloneref(game:GetService("RunService"))
local VirtualUser         = cloneref(game:GetService("VirtualUser"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local TweenService        = cloneref(game:GetService("TweenService"))
local LocalPlayer         = Players.LocalPlayer
local Camera              = Workspace.CurrentCamera

-- 4. Config state
local Config = {
    AutoFarm = {
        Running = false,
        MovementType = "Safe Mode",
        Marshmallow = {
            Enabled = false,
            BatchAmount = 1,
            Status = {
                Earned = 0,
                Total_Sold = 0,
                Sold_Type = {
                    ["Small Marshmallow Bag"] = 0,
                    ["Medium Marshmallow Bag"] = 0,
                    ["Large Marshmallow Bag"] = 0,
                }
            }
        },
        Chips = {
            Enabled = false,
            Status = { Earned = 0, Delivered = 0 }
        },
        Card = {
            Enabled = false,
            Status = { Earned = 0, Swipes = 0 }
        }
    }
}

-- 5. Helper functions
local function pressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function safeFirePrompt(pp)
    if not pp then return false end
    pcall(function()
        pp.MaxActivationDistance = 50
        pp.Enabled = true
        pp.HoldDuration = 0
        pp.RequiresLineOfSight = false
        if pp.Parent and pp.Parent:IsA("BasePart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, pp.Parent.Position)
        end
        pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
    end)
    return true
end

local function safeEquip(toolName)
    local c = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local tool = LocalPlayer.Backpack:FindFirstChild(toolName) or c:FindFirstChild(toolName)
    if not tool then return false end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.3)
    return true
end

local function getItemCount(name)
    local n = 0
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do if v.Name == name then n += 1 end end
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetChildren()) do if v.Name == name then n += 1 end end
    end
    return n
end

local function Find_Bike()
    for _, Value in Workspace:GetChildren() do
        if Value:FindFirstChild("Owner") and string.match(tostring(Value), LocalPlayer.Name .. "'s Car") and Value:FindFirstChild("Body") and Value.Body:FindFirstChild("Passenger") then
            return Value
        end
    end
    return nil
end

-- 6. Teleport system (Safe Mode, Bike, Teleport Mode)
local RoadSidewalkFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Roads/Sidewalks")
local NoclipParts = {}
local SetHiddenProperty = function(instance, property, value)
    pcall(function() sethiddenproperty(instance, property, value) end)
end

local ExclusionsSideWalk_Folder = function(Part)
    return (RoadSidewalkFolder and Part:IsDescendantOf(RoadSidewalkFolder))
        or (Part.Name == "default")
        or (Part.Name == "Sidewalk")
        or (Part.Name == "Floor")
        or (Part.Name == "Collision")
        or Part:IsDescendantOf(LocalPlayer.Character)
        or (Part.Parent and Part.Parent:IsA("Model") and Players:GetPlayerFromCharacter(Part.Parent) ~= nil)
        or (Part:IsA("VehicleSeat") or Part:IsA("Vehicle"))
        or (Part.Name == "AntiFall_Platform1" or Part.Name == "AntiFall_Platform2")
end

local Reset_Noclip = function()
    for part, props in pairs(NoclipParts) do
        if part:IsA("BasePart") then
            SetHiddenProperty(part, "CanCollide", props.CanCollide)
        end
    end
    NoclipParts = {}
end

local Noclip = function()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    local Pos = Root.Position
    local radius = 15
    local region = Region3.new(Pos - Vector3.new(radius, radius, radius), Pos + Vector3.new(radius, radius, radius))
    local parts = Workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and not ExclusionsSideWalk_Folder(part) and not Workspace:FindFirstChild("Do not touch") then
            if not NoclipParts[part] then
                NoclipParts[part] = { CanCollide = part.CanCollide }
                SetHiddenProperty(part, "CanCollide", false)
            end
        end
    end
end

local LookDownConnection
local function LookDown(Zoom, Front)
    if LookDownConnection then return end
    LookDownConnection = RunService.RenderStepped:Connect(function()
        local Character = LocalPlayer.Character
        if not Character then return end
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        if not HumanoidRootPart then return end
        local characterPos = HumanoidRootPart.Position
        local lookDirection = HumanoidRootPart.CFrame.LookVector
        local flatLook = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
        local targetCFrame = CFrame.lookAt(characterPos, characterPos + flatLook)
        if Front then
            targetCFrame = targetCFrame * CFrame.Angles(0, 0, 0)
        else
            targetCFrame = targetCFrame * CFrame.Angles(math.rad(-80), 0, 0)
        end
        local cameraPosition = characterPos - (targetCFrame.LookVector * Zoom)
        Camera.CFrame = CFrame.lookAt(cameraPosition, characterPos)
    end)
end

local SafeModeRunning = false
local _SM_HeartbeatConnection = nil
local _SM_MeshPart = nil
local _SM_MeshPart2 = nil
local _SM_Root = nil

local function SafeModeCleanup()
    SafeModeRunning = false
    if _SM_HeartbeatConnection then
        _SM_HeartbeatConnection:Disconnect()
        _SM_HeartbeatConnection = nil
    end
    if _SM_Root then _SM_Root.Anchored = false end
    if _SM_MeshPart and _SM_MeshPart.Parent then _SM_MeshPart:Destroy() end
    if _SM_MeshPart2 and _SM_MeshPart2.Parent then _SM_MeshPart2:Destroy() end
    Reset_Noclip()
end

local chipFarmActive = false
local function anyFarmRunning()
    return getgenv().CardFarm == true or chipFarmActive == true or Config.AutoFarm.Marshmallow.Enabled
end

local function Teleport(Destination)
    if Config.AutoFarm.MovementType == "Teleport Mode" then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 9e9, 0)
        task.wait(1)
        LocalPlayer.Character.HumanoidRootPart.CFrame = Destination
        return (LocalPlayer.Character.HumanoidRootPart.Position - Destination.Position).Magnitude < 20 and "Success" or "Failed"

    elseif Config.AutoFarm.MovementType == "Safe Mode" then
        if LocalPlayer.Character.Humanoid.SeatPart and LocalPlayer.Character.Humanoid.SeatPart.Name == "DriveSeat" then
            Syde:Notify({Title = "Safe Teleport", Content = "Bike seat detected! (Unmount/Unsit)", Duration = 3})
            return
        end

        local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not Root then return "Failed" end

        _SM_Root = Root

        _SM_MeshPart = Instance.new("Part")
        _SM_MeshPart.Name = "AntiFall_Platform1"
        _SM_MeshPart.Size = Vector3.new(2048, 2, 2048)
        _SM_MeshPart.CFrame = CFrame.new(0, -6.5, 0)
        _SM_MeshPart.Transparency = 0.3
        _SM_MeshPart.Anchored = true
        _SM_MeshPart.CanCollide = true
        _SM_MeshPart.Parent = Workspace

        _SM_MeshPart2 = Instance.new("Part")
        _SM_MeshPart2.Name = "AntiFall_Platform2"
        _SM_MeshPart2.Size = Vector3.new(2048, 2, 2048)
        _SM_MeshPart2.CFrame = CFrame.new(935, -6.5, 65)
        _SM_MeshPart2.Transparency = 0.3
        _SM_MeshPart2.Anchored = true
        _SM_MeshPart2.CanCollide = true
        _SM_MeshPart2.Parent = Workspace

        _SM_HeartbeatConnection = RunService.Stepped:Connect(function()
            if Root and Root.Parent then Noclip() end
        end)

        SafeModeRunning = true

        local UndergroundPos = Vector3.new(Root.Position.X, -1, Root.Position.Z)
        local Tween_Root = TweenService:Create(Root,
            TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { CFrame = CFrame.new(UndergroundPos) * CFrame.Angles(0, math.atan2(Root.CFrame.LookVector.X, Root.CFrame.LookVector.Z), 0) }
        )
        Tween_Root:Play(); Tween_Root.Completed:Wait()
        task.wait(0.2)

        local GoalPos = Vector3.new(Destination.X, -2.1378674507141113, Destination.Z)
        LookDown(15, false)

        while anyFarmRunning() and Root and Root.Parent and (Vector3.new(Root.Position.X, 0, Root.Position.Z) - Vector3.new(GoalPos.X, 0, GoalPos.Z)).Magnitude > (1.7 + math.random() * 0.1) do
            local Direction = (GoalPos - Root.Position).Unit
            local LookTarget = Vector3.new(GoalPos.X, -2.1378674507141113, GoalPos.Z)
            local NextPosition = Root.Position + Direction
            Noclip()
            Root.CFrame = CFrame.new(Vector3.new(NextPosition.X, -2.1378674507141113, NextPosition.Z), LookTarget)
            task.wait(0.05)
        end

        if LookDownConnection then
            LookDownConnection:Disconnect(); LookDownConnection = nil
        end

        if not anyFarmRunning() then
            SafeModeCleanup()
            if Root and Root.Parent then
                local surfacePos = Vector3.new(Root.Position.X, 3, Root.Position.Z)
                local Tween_Up = TweenService:Create(Root,
                    TweenInfo.new(1, Enum.EasingStyle.Linear),
                    { CFrame = CFrame.new(surfacePos) * CFrame.Angles(0, math.atan2(Root.CFrame.LookVector.X, Root.CFrame.LookVector.Z), 0) }
                )
                Tween_Up:Play(); Tween_Up.Completed:Wait()
            end
            return "Stopped"
        end

        Root.CFrame = Destination
        task.wait(0.1)
        SafeModeCleanup()
        return "Success"

    elseif Config.AutoFarm.MovementType == "Bike" then
        local Bike = Find_Bike()
        if Bike == nil then
            Syde:Notify({Title = "Bike Teleport", Content = "Your bike was not found!", Duration = 3})
            return "Failed"
        end
        if LocalPlayer.Character.Humanoid.SeatPart and LocalPlayer.Character.Humanoid.SeatPart.Name == "DriveSeat" then
            for _ = 1, 50 do Bike:SetPrimaryPartCFrame(Destination + Vector3.new(0, 1.5, 0)) end
            task.wait(1)
            for _ = 1, 10 do Bike:SetPrimaryPartCFrame(Destination + Vector3.new(0, 1.5, 0)) end
            for _, Value in Bike:GetDescendants() do
                pcall(function() Value.Velocity = CFrame.new(0, 0, 0) end)
                pcall(function() Value.RotVelocity = CFrame.new(0, 0, 0) end)
            end
            Syde:Notify({Title = "Bike Teleport", Content = "Success!", Duration = 3})
        else
            Syde:Notify({Title = "Bike Teleport", Content = "Please sit on your bike first.", Duration = 3})
        end
        return "Success"
    end
    return "No method selected"
end

-- 7. Apartment functions
local Apartments_Lists = {"BH1", "BH2", "BH3", "BH4", "Home 1", "Home 2", "Home 3", "Home 4", "LT1", "WH1"}

function BuyApartment()
    task.spawn(function()
        local function Owns_Apartment(Apartment)
            local Board = Apartment:FindFirstChild("Board")
            local Label = Board and Board:FindFirstChild("name") and Board.name:FindFirstChild("SurfaceGui") and Board.name.SurfaceGui:FindFirstChild("TextLabel")
            return Label and Label.Text == LocalPlayer.Name
        end

        local function Is_Vacant(Apartment)
            local Board = Apartment:FindFirstChild("Board")
            local Label = Board and Board:FindFirstChild("name") and Board.name:FindFirstChild("SurfaceGui") and Board.name.SurfaceGui:FindFirstChild("TextLabel")
            return Label and Label.Text == "VACANT"
        end

        local Apartments = Workspace.Map:FindFirstChild("APTS")
        local Houses = Workspace.Map:FindFirstChild("Houses")
        if not Apartments or not Houses then return false end

        local SelectedApartment = nil
        for _, ApartmentName in ipairs(Apartments_Lists) do
            local APT = Apartments:FindFirstChild(ApartmentName)
            if APT and APT:IsA("Model") then
                if Owns_Apartment(APT) then
                    SelectedApartment = APT; break
                elseif not SelectedApartment and Is_Vacant(APT) then
                    SelectedApartment = APT
                end
            end
        end

        if Owns_Apartment(SelectedApartment) then
            Syde:Notify({Title = "AutoFarm", Content = "Apartment " .. SelectedApartment.Name .. " is already bought!", Duration = 3})
            return
        end

        if not SelectedApartment then return false end

        local Board = SelectedApartment:FindFirstChild("Board")
        if Board then
            Syde:Notify({Title = "AutoFarm", Content = "Teleporting to apartment...", Duration = 3})
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 9e9, 0)
            task.wait(1)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Board:GetPivot().Position)
        end

        if Is_Vacant(SelectedApartment) then
            local prompt = Board and Board:FindFirstChild("backboard") and Board.backboard:FindFirstChild("ProximityPrompt")
            if prompt then
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                task.wait(0.5)
                fireproximityprompt(prompt)
            else
                return false
            end
        end
    end)
end

function GetUnclaimedApartment()
    local Apartment = nil
    for _, Value in Workspace.Map.APTS:GetChildren() do
        if Value:FindFirstChild("name", true) and Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true) then
            if Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true).Text == "VACANT" then
                Apartment = Value; break
            end
        end
    end
    return Apartment
end

function GetPersonalApartment()
    local Apartment = nil
    for _, Value in Workspace.Map.APTS:GetChildren() do
        if Value:FindFirstChild("name", true) and Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true) then
            if Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true).Text == LocalPlayer.Name then
                Apartment = Value; break
            end
        end
    end
    return Apartment
end

function Get_House()
    for _, Value in Workspace.Map.APTS:GetChildren() do
        if Value:FindFirstChild("Board") then
            local Name = Value:FindFirstChild("Board").name.SurfaceGui.TextLabel.Text
            if Name == LocalPlayer.Name then
                return Workspace.Map.Houses:FindFirstChild(Value.Name) or Workspace.Map.Locations.Apartments:FindFirstChild(Value.Name)
            end
        end
    end
    return nil
end

-- 8. Marshmallow Farm
local MarshmallowFarm_Thread = nil
local MarshMallowStep = "Water"
local Task_Text = ""

task.spawn(function()
    while task.wait(0.1) do
        local Main = LocalPlayer.PlayerGui:FindFirstChild("Main")
        if Main then
            local TaskUpdate = Main:FindFirstChild("TaskUpdate")
            if TaskUpdate and TaskUpdate:FindFirstChild("TextLabel") then
                Task_Text = TaskUpdate:FindFirstChild("TextLabel").Text
            end
        end
    end
end)

local MarshmallowSellPrice = {
    ["Small Marshmallow Bag"] = 1470,
    ["Medium Marshmallow Bag"] = 2840,
    ["Large Marshmallow Bag"] = 4050,
}
local MarshmallowItems = {"Small Marshmallow Bag", "Medium Marshmallow Bag", "Large Marshmallow Bag"}

local function GetMarshmallowItem(name)
    for _, itemName in ipairs(MarshmallowItems) do
        if name == itemName then return itemName end
    end
    return nil
end

function Start_MarshmallowFarm()
    if MarshmallowFarm_Thread then return end

    MarshmallowFarm_Thread = task.spawn(function()
        while task.wait(1) do
            if not Config.AutoFarm.Marshmallow.Enabled then continue end

            local Marshmellow_Increment = Config.AutoFarm.Marshmallow.BatchAmount
            local Items = {"Gelatin", "Sugar Block Bag", "Water"}
            local Items_Price = { Gelatin = 70, ["Sugar Block Bag"] = 100, Water = 20 }

            Teleport(CFrame.new(510, 4, 602))

            for _, Value in ipairs(Items) do
                local CurrentAmount = getItemCount(Value)

                local CraftedAmount = 0
                for _, marshItem in ipairs(MarshmallowItems) do
                    CraftedAmount += getItemCount(marshItem)
                end

                local NeededAmount = math.max(Marshmellow_Increment - CraftedAmount, 0)
                local MissingAmount = math.max(NeededAmount - CurrentAmount, 0)
                if MissingAmount > 0 then
                    for _ = 1, MissingAmount do
                        local Added = false
                        local Child_Added
                        Child_Added = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                            if Child.Name == Value then
                                Config.AutoFarm.Marshmallow.Status.Earned = Config.AutoFarm.Marshmallow.Status.Earned - Items_Price[Value]
                                Added = true
                                if Child_Added then Child_Added:Disconnect() end
                            end
                        end)
                        local StartTime = os.clock()
                        repeat
                            task.wait(0.1)
                            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase"):FireServer(Value)
                        until Added == true or (os.clock() - StartTime) > 1
                        if not Added and Child_Added then Child_Added:Disconnect() end
                    end
                end
            end

            task.wait(2.5)

            local House = Get_House()
            if not House then
                local HouseToBuy = GetUnclaimedApartment()
                if not HouseToBuy then
                    repeat
                        task.wait(1)
                        Syde:Notify({Title = "Apartment", Content = "No House owned! Buying one...", Duration = 5})
                        HouseToBuy = GetUnclaimedApartment()
                    until HouseToBuy
                end
                Teleport(HouseToBuy.Board.backboard.CFrame)
                LookDown(10, true)
                task.wait(1)
                fireproximityprompt(HouseToBuy.Board:FindFirstChildWhichIsA("ProximityPrompt", true))
                if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
                task.wait(1)
                House = Get_House()
            end

            local Personal_Apartment = GetPersonalApartment()

            if Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0, 90, 0)
                and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0, -90, 0)
                and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(180, 0, 180) then
                Personal_Apartment.Door.Interact.Attachment.ProximityPrompt.HoldDuration = 0
                Personal_Apartment.Door.Interact.Attachment.ProximityPrompt.RequiresLineOfSight = false
                local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                    TweenInfo.new(2, Enum.EasingStyle.Linear),
                    { CFrame = Personal_Apartment.Door.Interact.CFrame }
                )
                Tween:Play(); Tween.Completed:Wait(); Tween = nil
                task.wait(0.5)
                fireproximityprompt(Personal_Apartment.Door.Interact.Attachment.ProximityPrompt)
                task.wait(1)
            end

            if Personal_Apartment.Door.DoorLock.Part.Rotation ~= Vector3.new(90, 0, 0) then
                Personal_Apartment.Door.DoorLock.Part.ProximityPrompt.HoldDuration = 0
                Personal_Apartment.Door.DoorLock.Part.ProximityPrompt.RequiresLineOfSight = false
                local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                    TweenInfo.new(2, Enum.EasingStyle.Linear),
                    { CFrame = Personal_Apartment.Door.Interact.CFrame }
                )
                Tween:Play(); Tween.Completed:Wait(); Tween = nil
                task.wait(0.5)
                fireproximityprompt(Personal_Apartment.Door.DoorLock.Part.ProximityPrompt)
                task.wait(0.5)
            end

            local Interior = House:FindFirstChild("Interior") or House
            for _, Value in Interior:GetChildren() do
                if Value.Name == "Floor" or Value.Name == "Cooking Pot" or Value.Name == "Stove" then
                    Value.CanCollide = false
                end
            end

            local Pot = Interior["Cooking Pot"]
            Teleport(Pot.CFrame)

            local function tween_and_prompt(Prompt)
                if House.Parent.Name == "Apartments" then
                    Prompt.HoldDuration = 0
                    Prompt.MaxActivationDistance = 50
                    Prompt.RequiresLineOfSight = false
                    local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                        TweenInfo.new(1, Enum.EasingStyle.Linear),
                        { CFrame = Pot.CFrame + Vector3.new(0, 7, 0) }
                    )
                    Tween:Play(); Tween.Completed:Wait(); Tween = nil
                    LookDown(10, true)
                    task.wait(0.5)
                    fireproximityprompt(Prompt)
                    if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
                    task.wait(2.5)
                    Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                        TweenInfo.new(1, Enum.EasingStyle.Linear),
                        { CFrame = Pot.CFrame + Vector3.new(0, 16, 0) }
                    )
                    Tween:Play(); Tween.Completed:Wait(); Tween = nil
                else
                    Prompt.HoldDuration = 0
                    Prompt.MaxActivationDistance = 50
                    Prompt.RequiresLineOfSight = false
                    LookDown(8, false)
                    fireproximityprompt(Prompt)
                    if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
                end
            end

            if not (House.Parent.Name == "Apartments") then
                local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                    TweenInfo.new(1, Enum.EasingStyle.Linear),
                    { CFrame = Pot.CFrame - Vector3.new(0, 7, 0) }
                )
                Tween:Play(); Tween.Completed:Wait(); Tween = nil
            end

            -- Step loop
            local Water, Gel, Sug = {}, {}, {}
            for _, Value in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if Value.Name == "Sugar Block Bag" then table.insert(Sug, Value)
                elseif Value.Name == "Gelatin" then table.insert(Gel, Value)
                elseif Value.Name == "Water" then table.insert(Water, Value) end
            end

            local highestCommon = math.min(#Water, #Gel, #Sug)

            for i = 1, highestCommon do
                if MarshMallowStep == "Water" then
                    if not LocalPlayer.Character:FindFirstChild("Water") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Water"))
                    end
                    Syde:Notify({Title = "Steps", Content = "Water", Duration = 5})
                    repeat task.wait(1) tween_and_prompt(Pot.Attachment.ProximityPrompt) until Task_Text == "Wait 20 seconds for your water to boil."
                    task.wait(2.5)
                    MarshMallowStep = "Sugar Block Bag"
                end

                if MarshMallowStep == "Sugar Block Bag" then
                    repeat task.wait() until Pot.Timer.TextLabel.Text == "0"
                    if not LocalPlayer.Character:FindFirstChild("Sugar Block Bag") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Sugar Block Bag"))
                    end
                    Syde:Notify({Title = "Steps", Content = "Sugar Block Bag", Duration = 5})
                    repeat task.wait(1) tween_and_prompt(Pot.Attachment.ProximityPrompt) until Task_Text == "Pour gelatin into the pot."
                    task.wait(2.5)
                    LocalPlayer.Character.Humanoid:UnequipTools()
                    MarshMallowStep = "Gelatin"
                end

                if MarshMallowStep == "Gelatin" then
                    repeat task.wait() until Pot.Timer.TextLabel.Text == "0"
                    local HumanoidConnection
                    HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                        MarshMallowStep = "Water"
                        HumanoidConnection:Disconnect()
                    end)
                    LocalPlayer.Character.Humanoid:UnequipTools()
                    if not LocalPlayer.Character:FindFirstChild("Gelatin") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gelatin"))
                    end
                    Syde:Notify({Title = "Steps", Content = "Gelatin", Duration = 5})
                    repeat task.wait(1) tween_and_prompt(Pot.Attachment.ProximityPrompt) until Task_Text == "Let the solution cook for 45 seconds."
                    task.wait(2.5)
                    MarshMallowStep = "Collect"
                    HumanoidConnection:Disconnect()
                end

                if MarshMallowStep == "Collect" then
                    repeat task.wait() until Pot.Timer.TextLabel.Text == "0"
                    local HumanoidConnection
                    HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                        MarshMallowStep = "Water"
                        HumanoidConnection:Disconnect()
                    end)
                    if not LocalPlayer.Character:FindFirstChild("Empty Bag") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Empty Bag"))
                    end
                    Syde:Notify({Title = "Steps", Content = "Collect", Duration = 5})
                    repeat task.wait(1) tween_and_prompt(Pot.Attachment.ProximityPrompt) until LocalPlayer.Character:FindFirstChild("Empty Bag") == nil
                    task.wait(1)
                    LocalPlayer.Character.Humanoid:UnequipTools()
                    if i == Marshmellow_Increment then
                        MarshMallowStep = "Sell"
                    else
                        MarshMallowStep = "Water"
                    end
                    HumanoidConnection:Disconnect()
                end
            end

            if MarshMallowStep == "Sell" then
                Syde:Notify({Title = "AutoFarm", Content = "Selling Marshmallows...", Duration = 5})
                Teleport(CFrame.new(510, 4, 602))
                repeat task.wait() until Workspace.Folders.NPCs:FindFirstChild("Lamont Bell")
                task.wait(0.5)
                local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
                    TweenInfo.new(2.5, Enum.EasingStyle.Linear),
                    { CFrame = CFrame.new(511, 4, 598) }
                )
                Tween:Play(); Tween.Completed:Wait(); Tween = nil
                LookDown(15, true)
                if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
                Workspace.Folders.NPCs["Lamont Bell"].UpperTorso.ProximityPrompt.HoldDuration = 0
                Workspace.Folders.NPCs["Lamont Bell"].UpperTorso.ProximityPrompt.RequiresLineOfSight = false
                for _, Value in LocalPlayer.Backpack:GetChildren() do
                    if Value:IsA("Tool") then
                        local MarshmallowItem = GetMarshmallowItem(Value.Name)
                        if MarshmallowItem then
                            LocalPlayer.Character.Humanoid:EquipTool(Value)
                            fireproximityprompt(Workspace.Folders.NPCs["Lamont Bell"].UpperTorso.ProximityPrompt)
                            Config.AutoFarm.Marshmallow.Status.Earned = Config.AutoFarm.Marshmallow.Status.Earned + MarshmallowSellPrice[MarshmallowItem]
                            Config.AutoFarm.Marshmallow.Status.Total_Sold = Config.AutoFarm.Marshmallow.Status.Total_Sold + 1
                            Config.AutoFarm.Marshmallow.Status.Sold_Type[MarshmallowItem] = Config.AutoFarm.Marshmallow.Status.Sold_Type[MarshmallowItem] + 1
                            task.wait(0.2)
                        end
                    end
                end
                MarshMallowStep = "Water"
            end
        end
    end)
end

function Stop_MarshmallowFarm()
    if not MarshmallowFarm_Thread then return end
    local status = coroutine.status(MarshmallowFarm_Thread)
    if status ~= "dead" then
        SafeModeRunning = false
        local HumanoidRootPart = _SM_Root or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        pcall(task.cancel, MarshmallowFarm_Thread)
        MarshmallowFarm_Thread = nil
        SafeModeCleanup()
        if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
        if HumanoidRootPart and HumanoidRootPart.Parent then
            local surfacePos = Vector3.new(HumanoidRootPart.Position.X, 3, HumanoidRootPart.Position.Z)
            local Tween_Root = TweenService:Create(HumanoidRootPart,
                TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                { CFrame = CFrame.new(surfacePos) * CFrame.Angles(0, math.atan2(HumanoidRootPart.CFrame.LookVector.X, HumanoidRootPart.CFrame.LookVector.Z), 0) }
            )
            Tween_Root:Play(); Tween_Root.Completed:Wait()
        end
    end
end

-- 9. Card Farm
local CardFarmRunning = false
local immCard = {false}

local function pointCamAt(target)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not target then return end
    local targetPos = (typeof(target) == "Instance" and target:IsA("BasePart")) and target.Position or target
    Camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 1.5, 0), targetPos)
end

local function cardMove(pos)
    Teleport(CFrame.new(pos))
end

local function waitForAlive()
    repeat task.wait(0.5)
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if c and c:FindFirstChild("HumanoidRootPart") and h and h.Health > 0 then return end
    until false
end

local function AutoPressCardfarmKeys()
    while getgenv().CardFarm do
        if not immCard[1] then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game); task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game); task.wait(0.3)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game); task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game); task.wait(0.3)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game); task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game); task.wait(0.3)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game); task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game); task.wait(0.5)
        else task.wait(1) end
    end
end

local function startCardFarming()
    if CardFarmRunning then return end
    CardFarmRunning = true
    task.spawn(AutoPressCardfarmKeys)
    task.spawn(function()
        while getgenv().CardFarm do
            local c = LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not hum then waitForAlive(); continue end
            if hum.Health <= 0 then
                repeat task.wait(1)
                    c = LocalPlayer.Character
                    hum = c and c:FindFirstChildOfClass("Humanoid")
                until c and hum and hum.Health > 0
                task.wait(1)
            end
            pcall(function()
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local h = character:WaitForChild("Humanoid", 10)
                if not h then return end

                cardMove(Vector3.new(216.20, 3.37, -332.39)); task.wait(0.5)

                local idSellerNPC = workspace.Folders.NPCs:FindFirstChild("FakeIDSeller")
                if not idSellerNPC then return end
                local idAttach = idSellerNPC.UpperTorso:FindFirstChild("Attachment")
                if not idAttach then return end
                local idPrompt = idAttach:FindFirstChildOfClass("ProximityPrompt")
                if not idPrompt then return end

                local idCounter = 0
                repeat
                    if not getgenv().CardFarm then return end
                    pointCamAt(idSellerNPC.UpperTorso)
                    safeFirePrompt(idPrompt); task.wait(0.2)
                    idCounter += 1; if idCounter > 40 then return end
                until player.Backpack:FindFirstChild("Fake ID")

                local idTool = player.Backpack:FindFirstChild("Fake ID")
                if idTool then pcall(function() h:EquipTool(idTool) end) end

                for _, pos in ipairs({Vector3.new(216.62, 3.37, -332.63), Vector3.new(-48.74, 6.50, -317.00)}) do
                    if not getgenv().CardFarm then return end
                    cardMove(pos)
                end

                local tellerNPC = workspace.Folders.NPCs:FindFirstChild("Bank Teller")
                if not tellerNPC then return end
                local tellerAttach = tellerNPC.UpperTorso:FindFirstChild("Attachment")
                if not tellerAttach then return end
                local tellerPrompt = tellerAttach:FindFirstChildOfClass("ProximityPrompt")
                if not tellerPrompt then return end

                local waitCounter = 0
                repeat
                    task.wait(0.2); waitCounter += 1; if waitCounter > 50 then return end
                until (tellerPrompt.Enabled and tellerPrompt.Parent) or not getgenv().CardFarm

                local applyCounter = 0
                repeat
                    if not getgenv().CardFarm then return end
                    pointCamAt(tellerNPC.UpperTorso)
                    safeFirePrompt(tellerPrompt); task.wait(0.3)
                    applyCounter += 1; if applyCounter > 30 then return end
                until not character:FindFirstChild("Fake ID")

                task.wait(11.5)
                local notif = player.PlayerGui.Main.BasicNotification
                if not notif.Visible or notif.Text ~= "Your application was successful. Please allow 30 seconds for the bank to prepare your card." then
                    return
                end

                task.wait(35)
                cardMove(Vector3.new(-41.77, 3.37, -332.23))

                local cardPickup = workspace:FindFirstChild("CardPickup")
                if not cardPickup then return end
                local cardPickupAtt = cardPickup:FindFirstChild("Attachment")
                if not cardPickupAtt then return end
                local cardPickupPrompt = cardPickupAtt:FindFirstChildOfClass("ProximityPrompt")
                if not cardPickupPrompt then return end

                local pickupCounter = 0
                repeat
                    if not getgenv().CardFarm then return end
                    pointCamAt(cardPickup)
                    safeFirePrompt(cardPickupPrompt); task.wait(0.3)
                    pickupCounter += 1; if pickupCounter > 80 then return end
                until player.Backpack:FindFirstChild("Card")

                local cardTool = player.Backpack:FindFirstChild("Card")
                if cardTool then pcall(function() h:EquipTool(cardTool) end); task.wait(0.2) end

                local atmsFolder = workspace:FindFirstChild("Map")
                atmsFolder = atmsFolder and atmsFolder:FindFirstChild("ATMS")
                if not atmsFolder then return end

                local closestATM, shortestDist = nil, math.huge
                for _, atm in ipairs(atmsFolder:GetChildren()) do
                    if atm:IsA("BasePart") and atm.Name:match("^ATM%d*$") then
                        local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            local root2 = character:FindFirstChild("HumanoidRootPart")
                            if root2 then
                                local dist = (root2.Position - atm.Position).Magnitude
                                if dist < shortestDist then shortestDist = dist; closestATM = atm end
                            end
                        end
                    end
                end
                if not closestATM then return end

                local frontPos = closestATM.Position + (closestATM.CFrame.LookVector * -2.5)
                cardMove(frontPos); task.wait(0.5)

                local atmPrompt = closestATM:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not atmPrompt then return end

                local iStart = tick()
                repeat
                    if not getgenv().CardFarm then return end
                    pointCamAt(closestATM)
                    safeFirePrompt(atmPrompt); task.wait(0.5)
                until player.PlayerGui:FindFirstChild("ATM") or (tick() - iStart > 8)

                if player.PlayerGui:FindFirstChild("ATM") then
                    Config.AutoFarm.Card.Status.Swipes = Config.AutoFarm.Card.Status.Swipes + 1
                    local gStart = tick()
                    repeat
                        if not getgenv().CardFarm then break end
                        if not player.PlayerGui:FindFirstChild("ATM") then break end
                        pointCamAt(closestATM)
                        local atmFrame = player.PlayerGui.ATM:FindFirstChild("Frame")
                        local swipeBtn = atmFrame and atmFrame:FindFirstChild("Swipe")
                        if swipeBtn then game.GuiService.SelectedObject = swipeBtn end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game); task.wait(0.06)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game); task.wait(0.01)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.BackSlash, false, game); task.wait(0.06)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.BackSlash, false, game); task.wait(0.1)
                    until not player.PlayerGui:FindFirstChild("ATM") or not getgenv().CardFarm or (tick() - gStart > 12)
                end
            end)
            task.wait(2)
        end
        CardFarmRunning = false
    end)
end

-- 10. Chip Farm
local immChip = {false}
local camConnection = nil

local function startChipCamLock()
    if camConnection then camConnection:Disconnect() end
    Camera.CameraType = Enum.CameraType.Scriptable
    camConnection = RunService.RenderStepped:Connect(function()
        if chipFarmActive then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then Camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 12, 0), root.Position) end
        end
    end)
end

local function stopChipCamLock()
    if camConnection then camConnection:Disconnect() end
    camConnection = nil
    Camera.CameraType = Enum.CameraType.Custom
end

local function chipMove(pos)
    if not chipFarmActive then return "Stopped" end
    return Teleport(CFrame.new(pos))
end

local function chipMoveToNPC(npc)
    if not chipFarmActive then return false end
    local targetPos = npc and npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart.Position
    if not targetPos then return false end
    local result = Teleport(CFrame.new(targetPos))
    task.wait(0.3)
    return chipFarmActive and result ~= "Stopped"
end

local function startChipFarm()
    startChipCamLock()
    task.spawn(function()
        local storeEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase")
        local HomelessStorage = ReplicatedStorage:FindFirstChild("Workspace")
        HomelessStorage = HomelessStorage and HomelessStorage:FindFirstChild("Homeless")
        if not HomelessStorage then
            Syde:Notify({Title = "Chip Farm", Content = "HomelessStorage not found.", Duration = 5})
            chipFarmActive = false; stopChipCamLock(); return
        end

        local HomelessLive = workspace.Folders.HomelessPeople
        local wordNumbers = {"One","Two","Three","Four","Five","Six","Seven","Eight",
            "Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen"}

        local function getSittingNPCs(folder)
            local sitting = {}
            local c = LocalPlayer.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") then return sitting end
            if not folder or not folder.Parent then return sitting end
            for _, npc in ipairs(folder:GetChildren()) do
                if table.find(wordNumbers, npc.Name) and npc:GetAttribute("AnimationState") == "Sitting" then
                    table.insert(sitting, npc)
                end
            end
            return sitting
        end

        while chipFarmActive do
            local c = LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not hum or hum.Health <= 0 then waitForAlive(); continue end

            local targets = getSittingNPCs(HomelessStorage)
            if #targets == 0 then
                Syde:Notify({Title = "Chip Farm", Content = "Waiting for sitting targets...", Duration = 4})
                local ws = 0
                repeat
                    task.wait(1)
                    targets = getSittingNPCs(HomelessStorage)
                    ws += 1; if ws > 300 then break end
                until #targets > 0 or not chipFarmActive
            end
            if not chipFarmActive then break end

            Syde:Notify({Title = "Chip Farm", Content = "Targets found: " .. #targets, Duration = 3})
            task.wait(2)

            if chipMove(Vector3.new(-771, 4, -198)) == "Stopped" then break end
            local buyCounter = 0
            while chipFarmActive and (getItemCount("Potato") < #targets or getItemCount("Flour") < #targets) do
                buyCounter += 1; if buyCounter > 60 then break end
                if getItemCount("Potato") < #targets then
                    pcall(function() storeEvent:FireServer("Potato") end); task.wait(0.4)
                end
                if chipFarmActive and getItemCount("Flour") < #targets then
                    pcall(function() storeEvent:FireServer("Flour") end); task.wait(0.4)
                end
            end
            if not chipFarmActive then break end

            local processCounter = 0
            repeat
                if not chipFarmActive then break end
                processCounter += 1; if processCounter > 10 then break end

                if chipMove(Vector3.new(-479, 4, -436)) == "Stopped" then break end
                pressE(); task.wait(1)

                if chipMove(Vector3.new(-463, 4, -469)) == "Stopped" then break end
                safeEquip("Potato")
                local cutterOk, cutterPrompt = pcall(function()
                    return workspace.Map.Locations["The Laboratory"]["Cutting Boards"]["Potato Cutter"].Model.Union.Attachment.ProximityPrompt
                end)
                if cutterOk and cutterPrompt then safeFirePrompt(cutterPrompt) end
                task.wait(5.7)

                if not chipFarmActive then break end
                if chipMove(Vector3.new(-462, 4, -475)) == "Stopped" then break end
                local bagOk, bagPrompt = pcall(function()
                    return workspace.Map.Locations["The Laboratory"].Prompts["Plastic Bag"].Attachment.ProximityPrompt
                end)
                if bagOk and bagPrompt then safeFirePrompt(bagPrompt) end
                task.wait(5.7)

                if not chipFarmActive then break end
                if chipMove(Vector3.new(-487, 4, -536)) == "Stopped" then break end
                safeEquip("Flour")
                local bowlOk, bowlPrompt = pcall(function()
                    return workspace.Map.Locations["The Laboratory"].Bowls:GetChildren()[2].ProximityPrompt
                end)
                if bowlOk and bowlPrompt then safeFirePrompt(bowlPrompt) end
                task.wait(5.7)

                if not chipFarmActive then break end
                if chipMove(Vector3.new(-521, 4, -465)) == "Stopped" then break end
                local potOk, potPrompt = pcall(function()
                    return workspace.Map.Locations["The Laboratory"].Pots:GetChildren()[7].ProximityPrompt
                end)
                if potOk and potPrompt then safeFirePrompt(potPrompt) end

                local t = 0
                while chipFarmActive and t < 65 do task.wait(1); t += 1 end
                if chipFarmActive then pressE(); task.wait(1) end

            until not chipFarmActive or (getItemCount("Potato") == 0 and getItemCount("Flour") == 0)

            if not chipFarmActive then break end

            if chipMove(Vector3.new(-33, 4, -25)) == "Stopped" then break end
            local poorGuy = workspace.Folders.NPCs:FindFirstChild("Poor Guy")
            if not poorGuy then task.wait(2); continue end
            local poorPrompt = poorGuy.UpperTorso:FindFirstChildOfClass("ProximityPrompt")
            if not poorPrompt then task.wait(2); continue end
            safeFirePrompt(poorPrompt); task.wait(1.5)

            local deliverSafety = 0
            while chipFarmActive and getItemCount("Hot Chips") > 0 do
                deliverSafety += 1; if deliverSafety > 50 then break end
                local allTargets = getSittingNPCs(HomelessStorage)
                local liveTargets = getSittingNPCs(HomelessLive)
                for _, v in ipairs(liveTargets) do table.insert(allTargets, v) end

                if #allTargets == 0 then
                    task.wait(1)
                else
                    for _, npc in ipairs(allTargets) do
                        if not chipFarmActive or getItemCount("Hot Chips") <= 0 then break end
                        if not npc or not npc.Parent then continue end
                        if npc:GetAttribute("AnimationState") ~= "Sitting" then continue end
                        local c2 = LocalPlayer.Character
                        local hum2 = c2 and c2:FindFirstChildOfClass("Humanoid")
                        if not c2 or not hum2 or hum2.Health <= 0 then waitForAlive(); break end
                        if chipMoveToNPC(npc) then
                            safeEquip("Hot Chips")
                            Config.AutoFarm.Chips.Status.Earned = Config.AutoFarm.Chips.Status.Earned + 300
                            Config.AutoFarm.Chips.Status.Delivered = Config.AutoFarm.Chips.Status.Delivered + 1
                            task.wait(0.3); pressE(); task.wait(1.5)
                        end
                    end
                end
                task.wait(0.5)
            end
        end
        stopChipCamLock()
    end)
end

-- 11. UI menggunakan Syde
local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = { Enabled = false }
})

-- Tab AutoFarm
local AutoFarmTab = Window:InitTab({ Title = "AutoFarm" })

-- Movement Type dropdown
local moveDropdown = AutoFarmTab:Dropdown({
    Title = "Movement Type",
    Options = {"Safe Mode", "Teleport Mode", "Bike"},
    StarterOption = "Safe Mode",
    PlaceHolder = "Select movement",
    CallBack = function(choice)
        Config.AutoFarm.MovementType = choice
        if choice == "Teleport Mode" then
            Syde:Notify({ Title = "AutoFarm", Content = "Selected Teleport Mode (In‑Progress)", Duration = 3 })
        elseif choice == "Safe Mode" then
            Syde:Notify({ Title = "AutoFarm", Content = "Selected Safe Mode (Safe)", Duration = 3 })
        elseif choice == "Bike" then
            Syde:Notify({ Title = "AutoFarm", Content = "Selected Bike Mode (Risky)", Duration = 3 })
        end
    end
})

-- Button: Spawn Bike
AutoFarmTab:Button({
    Title = "Buy/Spawn Teleport Bike",
    Description = "Spawns your bike and teleports to it.",
    CallBack = function()
        local b = buffer.create(1)
        buffer.writeu8(b, 1, 1)
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RPC"):FireServer(b, "Spawn", "DirtBike")
        task.wait(0.5)
        local bike = Find_Bike()
        if bike then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = bike.PrimaryPart.CFrame end
            Syde:Notify({ Title = "Bike", Content = "Bike spawned and teleported!", Duration = 3 })
        else
            Syde:Notify({ Title = "Bike", Content = "Bike not found. Try again.", Duration = 3 })
        end
    end
})

-- Button: Buy Apartment
AutoFarmTab:Button({
    Title = "Buy Apartment -$250",
    Description = "Buys a vacant apartment if available.",
    CallBack = BuyApartment
})

-- Label for guidelines
AutoFarmTab:Label("Marshmallow guidelines:")
AutoFarmTab:Label("<font color='rgb(255,0,0)'>Auto Farm can be buggy!</font>")
AutoFarmTab:Label("1. You can buy apt if you want to but not required.")
AutoFarmTab:Label("2. Start crouching.")
AutoFarmTab:Label("3. Run the autofarm.")
AutoFarmTab:Label("4. Enjoy and relax.")

-- Cost label
local costLabel = AutoFarmTab:Label("You will spend -$190 for 1 marshmallow")

-- Slider for batch amount
AutoFarmTab:Slider({
    Title = "Batch Amount",
    Sliders = {{
        Title = "Amount",
        Range = {1, 100},
        Increment = 1,
        StarterValue = 1,
        CallBack = function(val)
            Config.AutoFarm.Marshmallow.BatchAmount = val
            local total = val * 190
            costLabel:SetText("You will spend <font color='rgb(255,0,0)'>-$" .. total .. "</font> for " .. val .. " marshmallow" .. (val > 1 and "s" or ""))
        end
    }}
})

-- Toggle for Marshmallow Farm
AutoFarmTab:Toggle({
    Title = "Marshmallow Farm <font color='rgb(39,192,80)'>Safe</font>",
    Description = "Automatically buy, cook, and sell marshmallows.",
    Value = false,
    CallBack = function(state)
        Config.AutoFarm.Marshmallow.Enabled = state
        if state then
            Start_MarshmallowFarm()
        else
            Stop_MarshmallowFarm()
        end
    end
})

-- Stats section (using Labels)
AutoFarmTab:Label("--- Stats ---")
local statusLabel = AutoFarmTab:Label("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
local situationLabel = AutoFarmTab:Label("Situation: Water")
local smallLabel = AutoFarmTab:Label("Small Sold: 0")
local mediumLabel = AutoFarmTab:Label("Medium Sold: 0")
local largeLabel = AutoFarmTab:Label("Large Sold: 0")
local totalSoldLabel = AutoFarmTab:Label("Total Sold: 0")
local earnedLabel = AutoFarmTab:Label("Session Earned: $0")
local deathLabel = AutoFarmTab:Label("Deaths: 0")

-- Update stats loop
task.spawn(function()
    while task.wait(1) do
        if Config.AutoFarm.Marshmallow.Enabled then
            statusLabel:SetText("Status: <font color='rgb(0,255,0)'>Running</font> 🟢")
        else
            statusLabel:SetText("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
        end
        situationLabel:SetText("Situation: " .. tostring(MarshMallowStep))
        smallLabel:SetText("Small Sold: " .. Config.AutoFarm.Marshmallow.Status.Sold_Type["Small Marshmallow Bag"])
        mediumLabel:SetText("Medium Sold: " .. Config.AutoFarm.Marshmallow.Status.Sold_Type["Medium Marshmallow Bag"])
        largeLabel:SetText("Large Sold: " .. Config.AutoFarm.Marshmallow.Status.Sold_Type["Large Marshmallow Bag"])
        totalSoldLabel:SetText("Total Sold: " .. Config.AutoFarm.Marshmallow.Status.Total_Sold)
        local e = Config.AutoFarm.Marshmallow.Status.Earned
        if e > 0 then
            earnedLabel:SetText("Session Earned: <font color='rgb(0,255,0)'>$" .. e .. "</font>")
        elseif e < 0 then
            earnedLabel:SetText("Session Earned: <font color='rgb(255,0,0)'>-$" .. math.abs(e) .. "</font>")
        else
            earnedLabel:SetText("Session Earned: $0")
        end
        deathLabel:SetText("Deaths: <font color='rgb(255,0,0)'>" .. Died_Counter .. "</font>")
    end
end)

-- Tab Card Farm
local CardTab = Window:InitTab({ Title = "Card Farm" })
CardTab:Label("Card Farm guidelines:")
CardTab:Label("1. Set Movement Type on AutoFarm tab")
CardTab:Label("2. Put bike on park if bike")
CardTab:Label("3. Start farming")

CardTab:Toggle({
    Title = "Card Farm",
    Description = "Automates Fake ID and ATM swipe.",
    Value = false,
    CallBack = function(state)
        getgenv().CardFarm = state
        Config.AutoFarm.Card.Enabled = state
        if state then
            pcall(function()
                local bankParts = workspace.Map.Locations["Community Bank"]
                if bankParts:GetChildren()[29] then bankParts:GetChildren()[29]:Destroy() end
                if bankParts:GetChildren()[19] then bankParts:GetChildren()[19]:Destroy() end
            end)
            startCardFarming()
        else
            immCard[1] = false
            CardFarmRunning = false
        end
    end
})

-- Card stats
local cardStatusLabel = CardTab:Label("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
local cardSwipesLabel = CardTab:Label("Swipes: 0")
task.spawn(function()
    while task.wait(1) do
        if Config.AutoFarm.Card.Enabled then
            cardStatusLabel:SetText("Status: <font color='rgb(0,255,0)'>Running</font> 🟢")
        else
            cardStatusLabel:SetText("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
        end
        cardSwipesLabel:SetText("Swipes: " .. Config.AutoFarm.Card.Status.Swipes)
    end
end)

-- Tab Chip Farm
local ChipTab = Window:InitTab({ Title = "Chip Farm" })
ChipTab:Label("Chip Farm guidelines:")
ChipTab:Label("1. Set Movement Type on AutoFarm tab")
ChipTab:Label("2. Put bike on park if bike")
ChipTab:Label("3. Start farming")

ChipTab:Toggle({
    Title = "Chip Farm",
    Description = "Automatically make and deliver chips.",
    Value = false,
    CallBack = function(state)
        chipFarmActive = state
        Config.AutoFarm.Chips.Enabled = state
        if state then
            startChipFarm()
        else
            stopChipCamLock()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            SafeModeCleanup()
            if LookDownConnection then LookDownConnection:Disconnect(); LookDownConnection = nil end
            if root and root.Parent then
                local surfacePos = Vector3.new(root.Position.X, 3, root.Position.Z)
                local Tween_Up = TweenService:Create(root,
                    TweenInfo.new(1, Enum.EasingStyle.Linear),
                    { CFrame = CFrame.new(surfacePos) * CFrame.Angles(0, math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z), 0) }
                )
                Tween_Up:Play(); Tween_Up.Completed:Wait()
            end
            local screen = LocalPlayer.PlayerGui:FindFirstChild("VolcanoWaitScreen")
            if screen then screen:Destroy() end
        end
    end
})

-- Chip stats
local chipStatusLabel = ChipTab:Label("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
local chipDeliveredLabel = ChipTab:Label("Chips Delivered: 0")
task.spawn(function()
    while task.wait(1) do
        if Config.AutoFarm.Chips.Enabled then
            chipStatusLabel:SetText("Status: <font color='rgb(0,255,0)'>Running</font> 🟢")
        else
            chipStatusLabel:SetText("Status: <font color='rgb(255,0,0)'>Stopped</font> 🔴")
        end
        chipDeliveredLabel:SetText("Chips Delivered: " .. Config.AutoFarm.Chips.Status.Delivered)
    end
end)

-- Anti‑AFK status (optional)
-- We can add a label for Anti‑AFK status if needed, but not critical.

Syde:Notify({ Title = "Script", Content = "All systems loaded!", Duration = 5 })