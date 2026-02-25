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

-- ฟังก์ชันวาป
local function teleportToPet(pet)
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local petRoot = pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Root")
    if hrp and petRoot then
        hrp.CFrame = petRoot.CFrame + Vector3.new(0, 5, 0)
    end
end

-- ฟังก์ชันสแกน
local function scanPets()
    local RoamingPets = workspace:FindFirstChild("RoamingPets")
    if not RoamingPets then return end
    local PetsFolder = RoamingPets:FindFirstChild("Pets")
    if not PetsFolder then return end

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
            print(string.format("✅ [%s][%s] Found: %s — Teleporting!", rarity, sizeName, petName))

            -- Notifier
            WindUI:Notify({
                Title = "Pet Found!",
                Content = string.format("[%s] [%s] %s", rarity, sizeName, petName),
                Duration = 5,
                Icon = "paw-print",
            })

            teleportToPet(pet)
            task.wait(1)
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

Window:Tag({
    Title = "V.1.0.0",
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
    Name = "Green Theme", -- theme name
    
    Accent = Color3.fromHex("#22c55e"), -- เขียวสด
    Background = Color3.fromHex("#101010"), -- ดำ
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#22c55e"), -- เขียวสด
    Icon = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    Hover = Color3.fromHex("#FFFFFF"), -- Text
    
    WindowBackground = Color3.fromHex("101010"), -- Background
    WindowShadow = Color3.fromHex("000000"),
    
    DialogBackground = Color3.fromHex("#101010"), -- Background
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#FFFFFF"),
    DialogContent = Color3.fromHex("#FFFFFF"),
    DialogIcon = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    WindowTopbarButtonIcon = Color3.fromHex("86efac"), -- เขียวอ่อน
    WindowTopbarTitle = Color3.fromHex("FFFFFF"),
    WindowTopbarAuthor = Color3.fromHex("FFFFFF"),
    WindowTopbarIcon = Color3.fromHex("FFFFFF"),
    
    TabBackground = Color3.fromHex("#22c55e"), -- เขียวสด
    TabTitle = Color3.fromHex("#FFFFFF"),
    TabIcon = Color3.fromHex("86efac"), -- เขียวอ่อน
    
    ElementBackground = Color3.fromHex("#22c55e"), -- เขียวสด
    ElementTitle = Color3.fromHex("#FFFFFF"),
    ElementDesc = Color3.fromHex("#FFFFFF"),
    ElementIcon = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    PopupBackground = Color3.fromHex("#101010"), -- Background
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromHex("#FFFFFF"),
    PopupContent = Color3.fromHex("#FFFFFF"),
    PopupIcon = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    DialogBackground = Color3.fromHex("#101010"), -- Background
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#FFFFFF"),
    DialogContent = Color3.fromHex("#FFFFFF"),
    DialogIcon = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    Toggle = Color3.fromHex("#22c55e"), -- เขียวสด
    ToggleBar = Color3.fromHex("#86efac"), -- เขียวอ่อน
    
    Checkbox = Color3.fromHex("#22c55e"), -- เขียวสด
    CheckboxIcon = Color3.fromHex("#FFFFFF"),
    
    Slider = Color3.fromHex("#22c55e"), -- เขียวสด
    SliderThumb = Color3.fromHex("#86efac"), -- เขียวอ่อน
})

WindUI:SetTheme("Green Theme")
