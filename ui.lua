-- ==========================================
-- DILZ FARM UI SCRIPT
-- ==========================================

-- 1. Load the Syde Library
-- Note: Since your repo is private, ensure this URL is correct and accessible, 
-- or paste the entire library source code above this line and change this to: local Syde = loadstring(LIBRARY_SOURCE_CODE)()
local Syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/VernsDEV/Dilzfarm/refs/heads/main/library.lua"))()

--// 2. Show the Loading Screen (Optional but recommended for the full UI experience)
Syde:Load({
    Name = "Dilz Farm",
    Logo = "14554547135", -- Default Syde Logo ID
    ConfigFolder = "DilzFarm",
    Status = "Stable", -- Options: Stable, Unstable, Detected, Patched
    Accent = Color3.fromRGB(255, 151, 227),
    HitBox = Color3.fromRGB(255, 151, 227)
})

-- 3. Initialize the Main Window
local Window = Syde:Init({
    Title = "Dilz Farm",
    SubText = "VernsDEV",
    Home = {
        Enabled = false -- We disable the Home page to keep it simple and go straight to tabs
    }
})

-- 4. Create the "FARM" Tab
local FarmTab = Window:InitTab({
    Title = "FARM"
})

-- 5. Variables for your farm logic
local AutoFarmEnabled = false

-- 6. Create the Toggle for the Auto Farm
FarmTab:Toggle({
    Title = "Auto Farm",
    Description = "Enable or disable the continuous auto farming loop.",
    Value = false,
    CallBack = function(State)
        AutoFarmEnabled = State
        print("[Dilz Farm] Auto Farm is now:", AutoFarmEnabled)
        
        -- Start the farm loop if enabled
        if AutoFarmEnabled then
            task.spawn(function()
                while AutoFarmEnabled and task.wait(1) do -- Change task.wait(1) to your desired loop speed
                    -- ==========================================
                    -- PUT YOUR CONTINUOUS FARMING LOGIC HERE
                    -- ==========================================
                    print("Farming in progress...")
                end
            end)
        end
    end
})

-- 7. Create a Button (Optional: For executing a single farm action manually)
FarmTab:Button({
    Title = "Farm Once",
    Description = "Manually trigger the farm function a single time.",
    CallBack = function()
        print("[Dilz Farm] Executed manual farm action!")
        -- ==========================================
        -- PUT SINGLE FARM ACTION LOGIC HERE
        -- ==========================================
    end
})