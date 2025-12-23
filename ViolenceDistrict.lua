local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "GRIMM Hub    ",
    Icon = "shield",
    Author = "by SORNOR",
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    Transparent = true,
})

-- สร้าง Tab
local Tab = Window:Tab({
    Title = "Auto Heal",
    Icon = "heart",
    Locked = true,
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

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP        = Players.LocalPlayer
local PG        = LP:WaitForChild("PlayerGui")
local CheckGui  = PG:WaitForChild("SkillCheckPromptGui")
local Check     = CheckGui:WaitForChild("Check")
local Line      = Check:WaitForChild("Line")
local Goal      = Check:WaitForChild("Goal")

local HeartbeatConn = nil
local AutoSkillCheckEnabled = false -- ตัวแปรเก็บสถานะ Toggle

-- ฟังก์ชันกด Space
local function PressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- ตรวจสอบว่า Line อยู่ใน Goal หรือไม่
local function LineInGoal()
    local lr = Line.Rotation % 360
    local gr = Goal.Rotation % 360
    local gs = (gr + 104) % 360
    local ge = (gr + 114) % 360

    if gs > ge then
        return lr >= gs or lr <= ge
    else
        return lr >= gs and lr <= ge
    end
end

-- ฟังก์ชันตรวจสอบหลัก
local function HeartbeatCheck()
    if not AutoSkillCheckEnabled then return end
    if LP.Team and LP.Team.Name == "Survivors" then
        if LineInGoal() then
            PressSpace()
            if HeartbeatConn then
                HeartbeatConn:Disconnect()
                HeartbeatConn = nil
            end
        end
    elseif HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
end

-- เมื่อ Check ปรากฏหรือหายไป
local function OnCheckVisible()
    if not AutoSkillCheckEnabled then return end
    if LP.Team and LP.Team.Name == "Survivors" then
        if Check.Visible then
            if HeartbeatConn then HeartbeatConn:Disconnect() end
            HeartbeatConn = RunService.Heartbeat:Connect(HeartbeatCheck)
        elseif HeartbeatConn then
            HeartbeatConn:Disconnect()
            HeartbeatConn = nil
        end
    elseif HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
end

-- เริ่มต้นเชื่อมต่อ Signal
Check:GetPropertyChangedSignal("Visible"):Connect(OnCheckVisible)

-- ฟังก์ชันเปิด/ปิด Auto Skill Check
local function ToggleAutoSkillCheck(state)
    AutoSkillCheckEnabled = state
    
    if not AutoSkillCheckEnabled and HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
    
    print("Auto Skill Check: " .. (AutoSkillCheckEnabled and "Enabled" or "Disabled"))
end

local Tab = Window:Tab({
    Title = "Auto Skill Check",
    Icon = "target", -- หรือไอคอนอื่นที่ต้องการ
    Locked = false,
})

local Toggle = Tab:Toggle({
    Title = "Auto Skill Check",
    Desc = "ออโต้กด Space เมื่อ Skill Check ปรากฏ",
    Icon = "target",
    Type = "Checkbox",
    Value = false, -- ค่าเริ่มต้นเป็นปิด
    Callback = function(state) 
        ToggleAutoSkillCheck(state)
    end
})

--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Hook = {
    Players = {
        ["Killer"] = {Color = Color3.fromRGB(255, 93, 108), On = true},
        ["Survivor"] = {Color = Color3.fromRGB(64, 224, 255), On = true}
    },
    Objects = {
        ["Generator"] = {Color = Color3.fromRGB(210, 87, 255), On = true},
        ["Gate"] = {Color = Color3.fromRGB(255, 255, 255), On = true},
        ["Pallet"] = {Color = Color3.fromRGB(74, 255, 181), On = true},
        ["Window"] = {Color = Color3.fromRGB(74, 255, 181), On = true},
        ["Hook"] = {Color = Color3.fromRGB(132, 255, 169), On = true}
    }
}

-- ตัวแปรควบคุมการแสดง ESP ทั้งหมด
local ESPEnabled = {
    Players = true,
    Objects = true
}

local folder = {
    ["Generator"] = workspace.Map,
    ["Gate"] = workspace.Map,
    ["Pallet"] = workspace.Map,
    ["Window"] = workspace,
    ["Hook"] = workspace.Map
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local cache = {}
local espConnections = {}

-- ฟังก์ชันล้าง ESP ทั้งหมด
local function clearAllESP()
    -- ล้าง ESP ผู้เล่น
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, obj in ipairs(player.Character:GetDescendants()) do
                if obj.Name == "H" then
                    obj:Destroy()
                end
                local nametag = obj:FindFirstChild("BitchHook")
                if nametag then
                    nametag:Destroy()
                end
            end
        end
    end
    
    -- ล้าง ESP วัตถุ
    for _, f in pairs(folder) do
        if f then
            for _, obj in ipairs(f:GetDescendants()) do
                if obj.Name == "H" then
                    obj:Destroy()
                end
                local nametag = obj:FindFirstChild("BitchHook")
                if nametag then
                    nametag:Destroy()
                end
            end
        end
    end
end

-- ฟังก์ชันล้าง ESP เฉพาะผู้เล่น
local function clearPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, obj in ipairs(player.Character:GetDescendants()) do
                if obj.Name == "H" then
                    obj:Destroy()
                end
                local nametag = obj:FindFirstChild("BitchHook")
                if nametag then
                    nametag:Destroy()
                end
            end
        end
    end
end

-- ฟังก์ชันล้าง ESP เฉพาะวัตถุ
local function clearObjectESP()
    for _, f in pairs(folder) do
        if f then
            for _, obj in ipairs(f:GetDescendants()) do
                if obj.Name == "H" then
                    obj:Destroy()
                end
                local nametag = obj:FindFirstChild("BitchHook")
                if nametag then
                    nametag:Destroy()
                end
            end
        end
    end
end

local function ESP(obj, color)
    if not obj or not color then return end
    if obj:FindFirstChild("H") then return end
    local h = Instance.new("Highlight")
    h.Name = "H"
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
end

local function createBillboard(text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BitchHook"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "BitchHook"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 10
    textLabel.TextWrapped = true
    textLabel.Parent = billboard
    
    return billboard
end

local function getPlayerRole(player)
    if player.Team then
        local teamName = player.Team.Name:lower()
        if teamName:find("killer") then
            return "Killer"
        elseif teamName:find("survivor") then
            return "Survivor"
        end
    end
    return "Survivor"
end

local function updatePlayerNametag(player)
    if not ESPEnabled.Players then return end
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local cacheKey = player.Name .. "_nametag"
    local currentTime = tick()
    
    if cache[cacheKey] and currentTime - cache[cacheKey] < 0.1 then
        return
    end
    cache[cacheKey] = currentTime
    
    local existingTag = humanoidRootPart:FindFirstChild("BitchHook")
    if existingTag then existingTag:Destroy() end
    
    local role = getPlayerRole(player)
    local config = Hook.Players[role]
    if not config or not config.On then return end
    
    local color = config.Color
    
    local distance = 0
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((humanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    
    local nametagText = player.Name .. "\n[" .. distance .. " studs]"
    local nametag = createBillboard(nametagText, color)
    nametag.Adornee = humanoidRootPart
    nametag.Parent = humanoidRootPart
end

local function updatePlayerESP(player)
    if not ESPEnabled.Players then return end
    if not player.Character then return end
    
    local role = getPlayerRole(player)
    local config = Hook.Players[role]
    if not config or not config.On then return end
    
    ESP(player.Character, config.Color)
end

local function updateObjectsESP()
    if not ESPEnabled.Objects then return end
    
    for t, f in pairs(folder) do
        if not f then continue end
        local config = Hook.Objects[t]
        if not config or not config.On then continue end
        
        for _, obj in ipairs(f:GetDescendants()) do
            if t == "Hook" and obj.Name == "Hook" then
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            ESP(part, config.Color)
                        end
                    end
                end
                if obj:FindFirstChild("Cartoony Blood Puddle") then
                    ESP(obj["Cartoony Blood Puddle"], config.Color)
                end
            elseif obj.Name == (t == "Pallet" and "Palletwrong" or t) then
                ESP(obj, config.Color)
            end
        end
    end
end

-- ฟังก์ชันเริ่มต้น ESP ทั้งระบบ
local function initializeESP()
    -- ล้าง ESP เก่าทั้งหมด
    clearAllESP()
    
    -- เริ่ม ESP ผู้เล่น
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            updatePlayerESP(player)
            updatePlayerNametag(player)
            
            -- เชื่อมต่ออีเวนต์เมื่อผู้เล่นสปอวน์ใหม่
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                updatePlayerESP(player)
                updatePlayerNametag(player)
            end)
        end
    end
    
    -- เริ่ม ESP วัตถุ
    updateObjectsESP()
end

-- Heartbeat สำหรับอัพเดตข้อมูลแบบ real-time
local lastUpdate = 0
local heartbeatConnection = RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate < 0.1 then return end
    lastUpdate = currentTime
    
    if ESPEnabled.Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                updatePlayerNametag(player)
            end
        end
    end
end)

-- เก็บการเชื่อมต่อ
espConnections.heartbeat = heartbeatConnection

-- ฟังก์ชันเปิด-ปิด ESP ผู้เล่น
local function togglePlayerESP(enabled)
    ESPEnabled.Players = enabled
    if not enabled then
        clearPlayerESP()
    else
        -- สร้าง ESP ผู้เล่นใหม่
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                updatePlayerESP(player)
                updatePlayerNametag(player)
            end
        end
    end
end

-- ฟังก์ชันเปิด-ปิด ESP วัตถุ
local function toggleObjectESP(enabled)
    ESPEnabled.Objects = enabled
    if not enabled then
        clearObjectESP()
    else
        updateObjectsESP()
    end
end

-- ฟังก์ชันเปิด-ปิด ESP ทั้งหมด
local function toggleAllESP(enabled)
    ESPEnabled.Players = enabled
    ESPEnabled.Objects = enabled
    
    if not enabled then
        clearAllESP()
    else
        initializeESP()
    end
end

-- เริ่มต้น ESP ครั้งแรก
initializeESP()

-- สร้าง UI Toggles
local Tab = Window:Tab({
    Title = "ESP",
    Icon = "target",
    Locked = false,
})

-- Toggle สำหรับ ESP ทั้งหมด
local ToggleAll = Tab:Toggle({
    Title = "ESP ทั้งหมด",
    Desc = "เปิด/ปิด ESP ทั้งหมด",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        toggleAllESP(state)
    end
})

-- Toggle สำหรับ ESP ผู้เล่น
local TogglePlayers = Tab:Toggle({
    Title = "ESP ผู้เล่น",
    Desc = "แสดง ESP สำหรับผู้เล่น",
    Icon = "users",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        togglePlayerESP(state)
    end
})

-- Toggle สำหรับ ESP วัตถุ (อันที่คุณต้องการ)
local ToggleObjects = Tab:Toggle({
    Title = "ESP วัตถุ",
    Desc = "แสดง ESP สำหรับวัตถุในเกม",
    Icon = "target",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        toggleObjectESP(state)
    end
})

-- Toggle สำหรับแต่ละประเภทวัตถุ
local ToggleGenerator = Tab:Toggle({
    Title = "เครื่องปั่นไฟ",
    Desc = "แสดง ESP สำหรับเครื่องปั่นไฟ",
    Icon = "zap",
    Type = "Checkbox",
    Value = Hook.Objects.Generator.On,
    Callback = function(state) 
        Hook.Objects.Generator.On = state
        if ESPEnabled.Objects then
            clearObjectESP()
            updateObjectsESP()
        end
    end
})

local ToggleGate = Tab:Toggle({
    Title = "ประตู",
    Desc = "แสดง ESP สำหรับประตู",
    Icon = "door-open",
    Type = "Checkbox",
    Value = Hook.Objects.Gate.On,
    Callback = function(state) 
        Hook.Objects.Gate.On = state
        if ESPEnabled.Objects then
            clearObjectESP()
            updateObjectsESP()
        end
    end
})

local TogglePallet = Tab:Toggle({
    Title = "พาเลท",
    Desc = "แสดง ESP สำหรับพาเลท",
    Icon = "box",
    Type = "Checkbox",
    Value = Hook.Objects.Pallet.On,
    Callback = function(state) 
        Hook.Objects.Pallet.On = state
        if ESPEnabled.Objects then
            clearObjectESP()
            updateObjectsESP()
        end
    end
})

local ToggleWindow = Tab:Toggle({
    Title = "หน้าต่าง",
    Desc = "แสดง ESP สำหรับหน้าต่าง",
    Icon = "layout",
    Type = "Checkbox",
    Value = Hook.Objects.Window.On,
    Callback = function(state) 
        Hook.Objects.Window.On = state
        if ESPEnabled.Objects then
            clearObjectESP()
            updateObjectsESP()
        end
    end
})

local ToggleHook = Tab:Toggle({
    Title = "ตะขอ",
    Desc = "แสดง ESP สำหรับตะขอ",
    Icon = "anchor",
    Type = "Checkbox",
    Value = Hook.Objects.Hook.On,
    Callback = function(state) 
        Hook.Objects.Hook.On = state
        if ESPEnabled.Objects then
            clearObjectESP()
            updateObjectsESP()
        end
    end
})

-- ฟังก์ชันทำความสะอาดเมื่อสคริปต์ถูกปิด
local function cleanup()
    for _, connection in pairs(espConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    clearAllESP()
end

-- เชื่อมต่ออีเวนต์เมื่อผู้เล่นใหม่เข้าร่วม
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled.Players then
            updatePlayerESP(player)
            updatePlayerNametag(player)
        end
    end)
end)

-- ทำความสะอาดเมื่อเกมจบ
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        cleanup()
    end
end)
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
