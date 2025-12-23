-- สร้าง Tab
local Tab = Window:Tab({
    Title = "Auto Heal",
    Icon = "heart",
    Locked = false,
})

-- ตัวแปรเก็บสถานะ
local SelectedPlayers = {}
local HealingEnabled = false
local HealThread = nil

-- ฟังก์ชันดึงรายชื่อผู้เล่นทั้งหมด
local function GetPlayerList()
    local players = game:GetService("Players"):GetPlayers()
    local playerNames = {}
    
    for _, player in ipairs(players) do
        table.insert(playerNames, player.Name)
    end
    
    return playerNames
end

-- ฟังก์ชันตรวจสอบเลือดผู้เล่น
local function GetHealthPercentage(player)
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.MaxHealth > 0 then
            return (humanoid.Health / humanoid.MaxHealth) * 100
        end
    end
    return 100
end

-- ฟังก์ชันรักษาผู้เล่นที่เลือดน้อยกว่า 90%
local function HealLowHealthPlayers()
    for _, playerName in ipairs(SelectedPlayers) do
        local player = game:GetService("Players"):FindFirstChild(playerName)
        if player and player.Character then
            local healthPercent = GetHealthPercentage(player)
            
            if healthPercent < 90 then
                local args = {
                    player.Character:WaitForChild("HumanoidRootPart"),
                    true
                }
                
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Healing"):WaitForChild("HealEvent"):FireServer(unpack(args))
                end)
            end
        end
    end
end

-- Toggle สำหรับเปิด/ปิดระบบรักษา
local HealingToggle = Tab:Toggle({
    Title = "Enable Auto Heal",
    Desc = "เปิด/ปิดระบบรักษาผู้เล่นอัตโนมัติ",
    Value = false,
    Callback = function(state)
        HealingEnabled = state
        
        if state then
            -- เริ่มระบบรักษา
            HealThread = task.spawn(function()
                while HealingEnabled do
                    HealLowHealthPlayers()
                    task.wait(10) -- รอ 10 วินาที
                end
            end)
            print("Auto Heal: ON")
        else
            -- หยุดระบบรักษา
            if HealThread then
                task.cancel(HealThread)
                HealThread = nil
            end
            print("Auto Heal: OFF")
        end
    end
})

-- Dropdown สำหรับเลือกผู้เล่น
local PlayerDropdown = Tab:Dropdown({
    Title = "Select Players",
    Desc = "เลือกผู้เล่นที่ต้องการรักษา (เลือกได้หลายคน)",
    Values = GetPlayerList(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        SelectedPlayers = selected
        print("Selected players: " .. game:GetService("HttpService"):JSONEncode(selected))
    end
})

-- อัพเดตรายชื่อผู้เล่นอัตโนมัติ
game:GetService("Players").PlayerAdded:Connect(function()
    PlayerDropdown:SetValues(GetPlayerList())
end)

game:GetService("Players").PlayerRemoving:Connect(function()
    PlayerDropdown:SetValues(GetPlayerList())
end)

print("Auto Heal System Loaded - Select players and toggle ON")

-- Settings Tab (keep your existing settings code)
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

local SettingsSection = SettingsTab:Section({ 
    Title = "Button Display Settings",
})

local showFPS = true
local showTime = true
local showPing = true
local showMemory = false

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

SettingsSection:Toggle({
    Title = "Show Time",
    Desc = "Display current time on button",
    Icon = "clock",
    Type = "Checkbox",
    Value = showTime,
    Callback = function(state) 
        showTime = state
    end
})

SettingsSection:Toggle({
    Title = "Show FPS",
    Desc = "Display FPS counter on button",
    Icon = "zap",
    Type = "Checkbox",
    Value = showFPS,
    Callback = function(state) 
        showFPS = state
    end
})

SettingsSection:Toggle({
    Title = "Show Ping",
    Desc = "Display network ping on button",
    Icon = "signal",
    Type = "Checkbox",
    Value = showPing,
    Callback = function(state) 
        showPing = state
    end
})

SettingsSection:Toggle({
    Title = "Show Memory",
    Desc = "Display memory usage on button",
    Icon = "hard-drive",
    Type = "Checkbox",
    Value = showMemory,
    Callback = function(state) 
        showMemory = state
    end
})
