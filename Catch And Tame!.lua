local Tab = Window:Tab({
    Title = "Auto Collect",
    Icon = "package",
    Locked = false,
})

local autoCollect = false
local collectDelay = 5

-- Slider
Tab:Slider({
    Title = "Collect Delay",
    Desc = "1-60 Second",
    Step = 1,
    Value = { Min = 1, Max = 60, Default = 5 },
    Callback = function(v) collectDelay = v end
})

-- Toggle
Tab:Toggle({
    Title = "Auto Collect",
    Desc = "collectAllPetCash",
    Type = "Checkbox",
    Value = false,
    Callback = function(s) autoCollect = s end
})

-- Loop
task.spawn(function()
    while task.wait(collectDelay) do
        if autoCollect then
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("collectAllPetCash"):FireServer()
        end
    end
end)

local Tab = Window:Tab({
    Title = "Auto Buy Food",
    Icon = "shopping-bag",
    Locked = false,
})

local autoBuyFood = false
local selectedFoods = {"Farmers Feed", "Enriched Feed", "Hay", "Bone", "Prime Feed", "Steak"}
local buyAmount = 50

-- Dropdown
Tab:Dropdown({
    Title = "Select Foods",
    Values = {"Farmers Feed", "Enriched Feed", "Hay", "Bone", "Prime Feed", "Steak"},
    Value = {"Farmers Feed", "Enriched Feed", "Hay", "Bone", "Prime Feed", "Steak"},
    Multi = true,
    AllowNone = false,
    Callback = function(v) selectedFoods = v end
})

-- Slider ปรับจำนวนซื้อ
Tab:Slider({
    Title = "Buy Amount",
    Desc = "Amount (1-50)",
    Step = 1,
    Value = {Min = 1, Max = 50, Default = 50},
    Callback = function(v) buyAmount = v end
})

-- Toggle
Tab:Toggle({
    Title = "Auto Buy Food",
    Type = "Checkbox",
    Value = false,
    Callback = function(s) autoBuyFood = s end
})

-- ฟังก์ชันซื้อ
local function BuyFood(name)
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("FoodService"):WaitForChild("RE"):WaitForChild("BuyFood"):FireServer(name, buyAmount)
    end)
end

-- Loop
task.spawn(function()
    while task.wait(3) do
        if autoBuyFood then
            for _, food in ipairs(selectedFoods) do
                BuyFood(food)
                task.wait(0.2)
            end
        end
    end
end)

-- ==================== AUTO PETS TAB ====================
local PetsTab = Window:Tab({
    Title = "Auto Pets",
    Icon = "paw-print",
    Locked = false,
})

local autoPetScan = false
local selectedRarities = {"Mythical", "Exclusive", "Secret"}
local selectedSizes = {"Tiny", "Normal", "Big", "Huge", "Colossal"}

-- Dropdown Rarity
PetsTab:Dropdown({
    Title = "Rarity",
    Desc = "Select pet rarity to scan",
    Values = {"Common", "Rare", "Epic", "Legendary", "Mythical", "Exclusive", "Secret"},
    Value = {"Mythical", "Exclusive", "Secret"},
    Multi = true,
    AllowNone = false,
    Callback = function(v)
        selectedRarities = v
    end
})

-- Dropdown SizeName
PetsTab:Dropdown({
    Title = "Size",
    Desc = "Select pet size to scan",
    Values = {"Tiny", "Normal", "Big", "Huge", "Colossal"},
    Value = {"Tiny", "Normal", "Big", "Huge", "Colossal"},
    Multi = true,
    AllowNone = false,
    Callback = function(v)
        selectedSizes = v
    end
})

-- Toggle
PetsTab:Toggle({
    Title = "Auto Scan & Teleport",
    Desc = "Scan and teleport to matching pets",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        autoPetScan = s
    end
})

-- Toggle MutationMachine UI
PetsTab:Toggle({
    Title = "Mutation Machine",
    Desc = "Toggle Mutation Machine UI",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        local Players = game:GetService("Players")
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local mutationMachine = playerGui:WaitForChild("MutationMachine")
        mutationMachine.Enabled = s
    end
})

-- ฟังก์ชันวาป
-- local function teleportToPet(pet)
--     local char = game.Players.LocalPlayer.Character
--     local hrp = char and char:FindFirstChild("HumanoidRootPart")
--     local petRoot = pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Root")
--     if hrp and petRoot then
--         hrp.CFrame = petRoot.CFrame + Vector3.new(0, 5, 0)
--     end
-- end

-- ฟังก์ชันจับสัตว์
local function catchPet(pet, folder)
    local petFolder = workspace:WaitForChild(folder):WaitForChild("Pets"):WaitForChild(pet.Name)
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- ส่ง minigameRequest
    local args = {
        petFolder,
        hrp and hrp.CFrame or CFrame.new()
    }
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("minigameRequest"):InvokeServer(unpack(args))
    end)

    task.wait(0.5)

    -- ส่ง Progress 25 → 70 → 100
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UpdateProgress")
    pcall(function() remote:FireServer(25) end)
    task.wait(0.3)
    pcall(function() remote:FireServer(70.00000000000001) end)
    task.wait(0.3)
    pcall(function() remote:FireServer(100) end)
end

-- ฟังก์ชันสแกน (รองรับหลายโฟลเดอร์)
local PET_FOLDERS = {
    "RoamingPets",
    "SkyIslandPets", 
    "IceIslandPets",
}

local function scanPets()
    for _, folderName in ipairs(PET_FOLDERS) do
        local folder = workspace:FindFirstChild(folderName)
        if not folder then continue end
        
        local PetsFolder = folder:FindFirstChild("Pets")
        if not PetsFolder then continue end

        for _, pet in ipairs(PetsFolder:GetChildren()) do
            local rarity   = pet:GetAttribute("Rarity")
            local sizeName = pet:GetAttribute("SizeName")
            local petName  = pet:GetAttribute("Name") or pet.Name

            local rarityMatch = false
            local sizeMatch   = false

            if rarity then
                for _, sel in ipairs(selectedRarities) do
                    if rarity == sel then rarityMatch = true break end
                end
            end

            if sizeName then
                for _, sel in ipairs(selectedSizes) do
                    if sizeName == sel then sizeMatch = true break end
                end
            end

            if rarityMatch and sizeMatch then
            print(string.format("✅ [%s][%s][%s] Found: %s — Teleporting!", folderName, rarity, sizeName, petName))

            WindUI:Notify({
                Title = string.format("[%s] %s — %s", rarity, petName, folderName),
                Content = string.format("Size: %s", sizeName),
                Duration = 5,
                Icon = "paw-print",
            })

            -- teleportToPet(pet)
            -- task.wait(1) -- รอวาปถึงก่อน

            catchPet(pet, folderName) -- จับเลย
            task.wait(1)
            end
        end
    end
end

-- Loop
task.spawn(function()
    while task.wait(3) do
        if autoPetScan then
            scanPets()
        end
    end
end)

-- ==================== AUTO MERCHANT TAB ====================
local MerchantTab = Window:Tab({
    Title = "Auto Merchant",
    Icon = "store",
    Locked = false,
})

local autoMerchant = false
local merchantDelay = 3 -- นาที

MerchantTab:Slider({
    Title = "Merchant Delay",
    Desc = "Delay between each round (minutes)",
    Step = 1,
    Value = {Min = 1, Max = 5, Default = 3},
    Callback = function(v)
        merchantDelay = v
    end
})

MerchantTab:Toggle({
    Title = "Auto Merchant",
    Desc = "Buy all items",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        autoMerchant = s
    end
})

local function buyMerchant()
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuyMerchant")
    for slot = 1, 9 do
        for count = 1, 20 do
            pcall(function()
                remote:FireServer(slot)
            end)
            task.wait(0.2)
        end
    end
end

task.spawn(function()
    while true do
        if autoMerchant then
            buyMerchant()
        end
        task.wait(merchantDelay * 60) -- แปลงนาทีเป็นวินาที
    end
end)

Window:Tag({
    Title = "V.1.3.5",
    Icon = "github",
    Color = Color3.fromHex("1F1F1F"),
    Radius = 13,
})
Window:Tag({
    Title = "Catch And Tame!",
    Icon = "paw-print",
    Color = Color3.fromHex("86efac"),
    Radius = 13,
})

-- ==================== SETTINGS TAB ====================
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

-- ==================== ANTI-AFK SETTING ====================
-- ตัวแปรสำหรับ Anti-AFK
local antiAFKEnabled = false
local antiAFKConnection = nil

-- ฟังก์ชันเริ่ม Anti-AFK
local function startAntiAFK()
    if antiAFKEnabled then return end
    
    antiAFKEnabled = true
    local vu = game:GetService("VirtualUser")
    
    -- สร้าง connection สำหรับป้องกัน AFK
    antiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- ฟังก์ชันหยุด Anti-AFK
local function stopAntiAFK()
    if not antiAFKEnabled then return end
    
    antiAFKEnabled = false
    
    -- ตัดการเชื่อมต่อ
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
end

-- เพิ่ม Toggle Anti-AFK ใน Settings Section
SettingsTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevent being kicked for inactivity",
    Icon = "user-check",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        if state then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})

local showFPS = true
local showTime = true
local showPing = true
local showMemory = false
local RunService = game:GetService("RunService")

local currentFPS = 60
local function startFPSMonitor()
    local frames = 0
    local lastSecond = math.floor(tick())
    
    RunService.Heartbeat:Connect(function()
        frames = frames + 1
        local currentSecond = math.floor(tick())
        
        if currentSecond > lastSecond then
            currentFPS = frames
            frames = 0
            lastSecond = currentSecond
        end
    end)
end

task.spawn(startFPSMonitor)

local currentPing = 0
local function startPingMonitor()
    local stats = game:GetService("Stats")
    
    while true do
        pcall(function()
            local pingValue = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            currentPing = math.floor(pingValue)
        end)
        task.wait(2)
    end
end

task.spawn(startPingMonitor)

local currentMemory = 0
local function startMemoryMonitor()
    while true do
        currentMemory = math.floor(collectgarbage("count") / 1024 * 100) / 100
        task.wait(5)
    end
end

task.spawn(startMemoryMonitor)

local function updateUIButton()
    local parts = {"GRIMMHUB"}
    
    if showTime then
        table.insert(parts, os.date("%H:%M"))
    end
    
    if showFPS then
        table.insert(parts, currentFPS .. " FPS")
    end
    
    if showPing and currentPing > 0 then
        table.insert(parts, currentPing .. "ms")
    end
    
    if showMemory then
        table.insert(parts, currentMemory .. " MB")
    end
    
    local buttonText = table.concat(parts, " | ")
    
    Window:EditOpenButton({
        Title = buttonText,
        Icon = "monitor",
        CornerRadius = UDim.new(0,16),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("FF0F7B"), 
            Color3.fromHex("F89B29")
        ),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    })
end

local function startUIUpdater()
    while true do
        updateUIButton()
        task.wait(1)
    end
end

task.spawn(startUIUpdater)

SettingsTab:Toggle({
    Title = "Show Time",
    Desc = "Display current time on button",
    Icon = "clock",
    Type = "Checkbox",
    Value = showTime,
    Callback = function(state) 
        showTime = state
    end
})

SettingsTab:Toggle({
    Title = "Show FPS",
    Desc = "Display FPS counter on button",
    Icon = "zap",
    Type = "Checkbox",
    Value = showFPS,
    Callback = function(state) 
        showFPS = state
    end
})

SettingsTab:Toggle({
    Title = "Show Ping",
    Desc = "Display network ping on button",
    Icon = "signal",
    Type = "Checkbox",
    Value = showPing,
    Callback = function(state) 
        showPing = state
    end
})

SettingsTab:Toggle({
    Title = "Show Memory",
    Desc = "Display memory usage on button",
    Icon = "hard-drive",
    Type = "Checkbox",
    Value = showMemory,
    Callback = function(state) 
        showMemory = state
    end
})

local Keybind = SettingsTab:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open ui",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

WindUI:AddTheme({
    Name = "Green Theme",
    
    Accent = Color3.fromHex("#4ade80"),           -- เขียวกลาง
    Background = Color3.fromHex("#1a2e1a"),        -- เขียวเข้มมาก (แทนดำ)
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#86efac"),
    Text = Color3.fromHex("#e2f5e2"),              -- ขาวอมเขียวอ่อน
    Placeholder = Color3.fromHex("#6b9e7a"),
    Button = Color3.fromHex("#16a34a"),            -- เขียวกลางเข้ม
    Icon = Color3.fromHex("#86efac"),
    
    Hover = Color3.fromHex("#e2f5e2"),
    
    WindowBackground = Color3.fromHex("#1e3a1e"),  -- เขียวเข้ม
    WindowShadow = Color3.fromHex("#0f1f0f"),
    
    DialogBackground = Color3.fromHex("#1e3a1e"),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#e2f5e2"),
    DialogContent = Color3.fromHex("#bbf7d0"),
    DialogIcon = Color3.fromHex("#86efac"),
    
    WindowTopbarButtonIcon = Color3.fromHex("#86efac"),
    WindowTopbarTitle = Color3.fromHex("#e2f5e2"),
    WindowTopbarAuthor = Color3.fromHex("#bbf7d0"),
    WindowTopbarIcon = Color3.fromHex("#86efac"),
    
    TabBackground = Color3.fromHex("#166534"),     -- เขียวเข้มกลาง
    TabTitle = Color3.fromHex("#e2f5e2"),
    TabIcon = Color3.fromHex("#86efac"),
    
    ElementBackground = Color3.fromHex("#14532d"), -- เขียวเข้ม
    ElementTitle = Color3.fromHex("#e2f5e2"),
    ElementDesc = Color3.fromHex("#bbf7d0"),
    ElementIcon = Color3.fromHex("#86efac"),
    
    PopupBackground = Color3.fromHex("#1e3a1e"),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromHex("#e2f5e2"),
    PopupContent = Color3.fromHex("#bbf7d0"),
    PopupIcon = Color3.fromHex("#86efac"),
    
    Toggle = Color3.fromHex("#16a34a"),
    ToggleBar = Color3.fromHex("#4ade80"),
    
    Checkbox = Color3.fromHex("#16a34a"),
    CheckboxIcon = Color3.fromHex("#e2f5e2"),
    
    Slider = Color3.fromHex("#16a34a"),
    SliderThumb = Color3.fromHex("#86efac"),
})

WindUI:SetTheme("Green Theme")
