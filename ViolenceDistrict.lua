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

--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

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

-- สร้าง UI สำหรับ Toggle (ตามตัวอย่างที่คุณให้มา)
-- หมายเหตุ: คุณต้องมีไลบรารี่ UI ที่เหมาะสมก่อน
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Configuration Table
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

local folder = {
    ["Generator"] = workspace.Map,
    ["Gate"] = workspace.Map,
    ["Pallet"] = workspace.Map,
    ["Window"] = workspace,
    ["Hook"] = workspace.Map
}

-- ESP State
local ESPEnabled = false
local cache = {}
local espConnections = {}
local highlightCache = {}
local nametagCache = {}
local objectCache = {}

-- ESP Functions
local function ESP(obj, color)
    if not ESPEnabled then return end
    if obj:FindFirstChild("ESP_Highlight") then 
        highlightCache[obj] = obj.ESP_Highlight
        return obj.ESP_Highlight 
    end
    
    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
    
    highlightCache[obj] = h
    return h
end

local function createBillboard(text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Nametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
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
    if not ESPEnabled then return end
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local cacheKey = player.Name .. "_nametag"
    local currentTime = tick()
    
    if cache[cacheKey] and currentTime - cache[cacheKey] < 0.1 then
        return
    end
    cache[cacheKey] = currentTime
    
    local existingTag = humanoidRootPart:FindFirstChild("ESP_Nametag")
    if existingTag then existingTag:Destroy() end
    
    local role = getPlayerRole(player)
    if not Hook.Players[role].On then return end
    
    local color = Hook.Players[role].Color
    
    local distance = 0
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((humanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    
    local nametagText = player.Name .. "\n[" .. distance .. " studs]"
    local nametag = createBillboard(nametagText, color)
    nametag.Adornee = humanoidRootPart
    nametag.Parent = humanoidRootPart
    
    nametagCache[player] = nametag
end

local function updatePlayerESP(player)
    if not ESPEnabled then return end
    if not player.Character then return end
    
    local role = getPlayerRole(player)
    if not Hook.Players[role].On then 
        if highlightCache[player.Character] then
            highlightCache[player.Character]:Destroy()
            highlightCache[player.Character] = nil
        end
        return 
    end
    
    local color = Hook.Players[role].Color
    local highlight = ESP(player.Character, color)
    if highlight then
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
end

local function updateObjects()
    if not ESPEnabled then return end
    
    for t, f in pairs(folder) do
        if not Hook.Objects[t].On then
            for _, obj in pairs(objectCache[t] or {}) do
                if obj and obj.Parent then
                    local highlight = obj:FindFirstChild("ESP_Highlight")
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
            objectCache[t] = {}
            goto continue
        end
        
        for _, obj in ipairs(f:GetDescendants()) do
            if t == "Hook" and obj.Name == "Hook" then
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            local highlight = ESP(part, Hook.Objects[t].Color)
                            if highlight then
                                highlight.FillColor = Hook.Objects[t].Color
                                highlight.OutlineColor = Hook.Objects[t].Color
                            end
                            objectCache[t] = objectCache[t] or {}
                            table.insert(objectCache[t], part)
                        end
                    end
                end
                if obj:FindFirstChild("Cartoony Blood Puddle") then
                    local highlight = ESP(obj["Cartoony Blood Puddle"], Hook.Objects[t].Color)
                    if highlight then
                        highlight.FillColor = Hook.Objects[t].Color
                        highlight.OutlineColor = Hook.Objects[t].Color
                    end
                    objectCache[t] = objectCache[t] or {}
                    table.insert(objectCache[t], obj["Cartoony Blood Puddle"])
                end
            elseif obj.Name == (t == "Pallet" and "Palletwrong" or t) then
                local highlight = ESP(obj, Hook.Objects[t].Color)
                if highlight then
                    highlight.FillColor = Hook.Objects[t].Color
                    highlight.OutlineColor = Hook.Objects[t].Color
                end
                objectCache[t] = objectCache[t] or {}
                table.insert(objectCache[t], obj)
            end
        end
        ::continue::
    end
end

-- Main ESP Toggle Function
local function ToggleESP(state)
    ESPEnabled = state
    
    if ESPEnabled then
        -- Enable ESP for existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                updatePlayerESP(player)
                updatePlayerNametag(player)
            end
        end
        
        -- Enable ESP for objects
        updateObjects()
        
        -- Create connections
        espConnections.playerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                updatePlayerESP(player)
                updatePlayerNametag(player)
            end)
        end)
        
        espConnections.heartbeat = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - (cache["lastUpdate"] or 0) < 0.1 then return end
            cache["lastUpdate"] = currentTime
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    updatePlayerNametag(player)
                end
            end
        end)
        
        print("ESP: Enabled")
    else
        -- Disable all ESP
        for _, highlight in pairs(highlightCache) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        
        for _, nametag in pairs(nametagCache) do
            if nametag and nametag.Parent then
                nametag:Destroy()
            end
        end
        
        -- Clear caches
        highlightCache = {}
        nametagCache = {}
        objectCache = {}
        
        -- Disconnect connections
        for _, conn in pairs(espConnections) do
            conn:Disconnect()
        end
        espConnections = {}
        
        print("ESP: Disabled")
    end
end

-- Update Color Function
local function UpdateColor(category, type, color)
    if category == "Players" and Hook.Players[type] then
        Hook.Players[type].Color = color
    elseif category == "Objects" and Hook.Objects[type] then
        Hook.Objects[type].Color = color
    end
    
    -- Refresh ESP with new colors
    if ESPEnabled then
        ToggleESP(false)
        task.wait(0.1)
        ToggleESP(true)
    end
end

-- Update Toggle Function
local function UpdateToggle(category, type, state)
    if category == "Players" and Hook.Players[type] then
        Hook.Players[type].On = state
    elseif category == "Objects" and Hook.Objects[type] then
        Hook.Objects[type].On = state
    end
    
    -- Refresh ESP
    if ESPEnabled then
        if category == "Players" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    updatePlayerESP(player)
                    updatePlayerNametag(player)
                end
            end
        elseif category == "Objects" then
            updateObjects()
        end
    end
end

-- Create ESP Tab
local Tab = Window:Tab({
    Title = "ESP",
    Icon = "eye", -- หรือไอคอนอื่นที่ต้องการ
    Locked = false,
})

-- Main ESP Toggle
local MainToggle = Tab:Toggle({
    Title = "ESP Master",
    Desc = "เปิด/ปิด ระบบ ESP ทั้งหมด",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        ToggleESP(state)
    end
})

-- Players Section
local PlayersSection = Tab:Section({
    Title = "Players ESP",
    Side = "Left"
})

local KillerToggle = PlayersSection:Toggle({
    Title = "Killer ESP",
    Desc = "แสดง ESP สำหรับ Killer",
    Icon = "skull",
    Type = "Checkbox",
    Value = Hook.Players["Killer"].On,
    Callback = function(state)
        UpdateToggle("Players", "Killer", state)
    end
})

local KillerColor = PlayersSection:Colorpicker({
    Title = "Killer Color",
    Desc = "เลือกสีสำหรับ Killer",
    Default = Hook.Players["Killer"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Players", "Killer", color)
    end
})

local SurvivorToggle = PlayersSection:Toggle({
    Title = "Survivor ESP",
    Desc = "แสดง ESP สำหรับ Survivor",
    Icon = "users",
    Type = "Checkbox",
    Value = Hook.Players["Survivor"].On,
    Callback = function(state)
        UpdateToggle("Players", "Survivor", state)
    end
})

local SurvivorColor = PlayersSection:Colorpicker({
    Title = "Survivor Color",
    Desc = "เลือกสีสำหรับ Survivor",
    Default = Hook.Players["Survivor"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Players", "Survivor", color)
    end
})

-- Objects Section
local ObjectsSection = Tab:Section({
    Title = "Objects ESP",
    Side = "Right"
})

-- Generator
local GeneratorToggle = ObjectsSection:Toggle({
    Title = "Generator ESP",
    Desc = "แสดง ESP สำหรับ Generator",
    Icon = "settings",
    Type = "Checkbox",
    Value = Hook.Objects["Generator"].On,
    Callback = function(state)
        UpdateToggle("Objects", "Generator", state)
    end
})

local GeneratorColor = ObjectsSection:Colorpicker({
    Title = "Generator Color",
    Desc = "เลือกสีสำหรับ Generator",
    Default = Hook.Objects["Generator"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Generator", color)
    end
})

-- Gate
local GateToggle = ObjectsSection:Toggle({
    Title = "Gate ESP",
    Desc = "แสดง ESP สำหรับ Gate",
    Icon = "door-open",
    Type = "Checkbox",
    Value = Hook.Objects["Gate"].On,
    Callback = function(state)
        UpdateToggle("Objects", "Gate", state)
    end
})

local GateColor = ObjectsSection:Colorpicker({
    Title = "Gate Color",
    Desc = "เลือกสีสำหรับ Gate",
    Default = Hook.Objects["Gate"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Gate", color)
    end
})

-- Pallet
local PalletToggle = ObjectsSection:Toggle({
    Title = "Pallet ESP",
    Desc = "แสดง ESP สำหรับ Pallet",
    Icon = "square",
    Type = "Checkbox",
    Value = Hook.Objects["Pallet"].On,
    Callback = function(state)
        UpdateToggle("Objects", "Pallet", state)
    end
})

local PalletColor = ObjectsSection:Colorpicker({
    Title = "Pallet Color",
    Desc = "เลือกสีสำหรับ Pallet",
    Default = Hook.Objects["Pallet"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Pallet", color)
    end
})

-- Window
local WindowToggle = ObjectsSection:Toggle({
    Title = "Window ESP",
    Desc = "แสดง ESP สำหรับ Window",
    Icon = "square",
    Type = "Checkbox",
    Value = Hook.Objects["Window"].On,
    Callback = function(state)
        UpdateToggle("Objects", "Window", state)
    end
})

local WindowColor = ObjectsSection:Colorpicker({
    Title = "Window Color",
    Desc = "เลือกสีสำหรับ Window",
    Default = Hook.Objects["Window"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Window", color)
    end
})

-- Hook
local HookToggle = ObjectsSection:Toggle({
    Title = "Hook ESP",
    Desc = "แสดง ESP สำหรับ Hook",
    Icon = "anchor",
    Type = "Checkbox",
    Value = Hook.Objects["Hook"].On,
    Callback = function(state)
        UpdateToggle("Objects", "Hook", state)
    end
})

local HookObjColor = ObjectsSection:Colorpicker({
    Title = "Hook Color",
    Desc = "เลือกสีสำหรับ Hook",
    Default = Hook.Objects["Hook"].Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Hook", color)
    end
})

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
