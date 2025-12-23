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

--[[
    ESP System for Dead By Daylight
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- ESP Configuration
local ESPConfig = {
    Enabled = false,
    Players = {
        Killer = {Enabled = true, Color = Color3.fromRGB(255, 93, 108)},
        Survivor = {Enabled = true, Color = Color3.fromRGB(64, 224, 255)}
    },
    Objects = {
        Generator = {Enabled = true, Color = Color3.fromRGB(210, 87, 255)},
        Gate = {Enabled = true, Color = Color3.fromRGB(255, 255, 255)},
        Pallet = {Enabled = true, Color = Color3.fromRGB(74, 255, 181)},
        Window = {Enabled = true, Color = Color3.fromRGB(74, 255, 181)},
        Hook = {Enabled = true, Color = Color3.fromRGB(132, 255, 169)}
    }
}

-- ESP Folders
local ESPFolders = {
    Generator = workspace.Map,
    Gate = workspace.Map,
    Pallet = workspace.Map,
    Window = workspace,
    Hook = workspace.Map
}

-- ESP Caches
local highlightCache = {}
local nametagCache = {}
local objectCache = {}
local espConnections = {}
local updateCache = {}

-- ESP Functions
local function CreateHighlight(obj, color)
    if obj:FindFirstChild("ESP_Highlight") then
        return obj.ESP_Highlight
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = obj
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = obj
    
    highlightCache[obj] = highlight
    return highlight
end

local function CreateNametag(text, color)
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

local function GetPlayerRole(player)
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

local function UpdatePlayerESP(player)
    if not ESPConfig.Enabled then return end
    if not player.Character then return end
    
    local role = GetPlayerRole(player)
    if not ESPConfig.Players[role].Enabled then
        if highlightCache[player.Character] then
            highlightCache[player.Character]:Destroy()
            highlightCache[player.Character] = nil
        end
        return
    end
    
    local color = ESPConfig.Players[role].Color
    local highlight = CreateHighlight(player.Character, color)
    if highlight then
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
end

local function UpdatePlayerNametag(player)
    if not ESPConfig.Enabled then return end
    if not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local currentTime = tick()
    if updateCache[player] and currentTime - updateCache[player] < 0.1 then
        return
    end
    updateCache[player] = currentTime
    
    local existingTag = humanoidRootPart:FindFirstChild("ESP_Nametag")
    if existingTag then existingTag:Destroy() end
    
    local role = GetPlayerRole(player)
    if not ESPConfig.Players[role].Enabled then return end
    
    local color = ESPConfig.Players[role].Color
    local distance = 0
    
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((humanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    
    local nametagText = player.Name .. "\n[" .. distance .. " studs]"
    local nametag = CreateNametag(nametagText, color)
    nametag.Adornee = humanoidRootPart
    nametag.Parent = humanoidRootPart
    
    nametagCache[player] = nametag
end

local function UpdateObjects()
    if not ESPConfig.Enabled then return end
    
    for objectType, folder in pairs(ESPFolders) do
        if not ESPConfig.Objects[objectType].Enabled then
            for _, obj in pairs(objectCache[objectType] or {}) do
                if obj and obj.Parent then
                    local highlight = obj:FindFirstChild("ESP_Highlight")
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
            objectCache[objectType] = {}
            goto continue
        end
        
        for _, obj in ipairs(folder:GetDescendants()) do
            if objectType == "Hook" and obj.Name == "Hook" then
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            local highlight = CreateHighlight(part, ESPConfig.Objects[objectType].Color)
                            if highlight then
                                highlight.FillColor = ESPConfig.Objects[objectType].Color
                                highlight.OutlineColor = ESPConfig.Objects[objectType].Color
                            end
                            objectCache[objectType] = objectCache[objectType] or {}
                            table.insert(objectCache[objectType], part)
                        end
                    end
                end
                if obj:FindFirstChild("Cartoony Blood Puddle") then
                    local highlight = CreateHighlight(obj["Cartoony Blood Puddle"], ESPConfig.Objects[objectType].Color)
                    if highlight then
                        highlight.FillColor = ESPConfig.Objects[objectType].Color
                        highlight.OutlineColor = ESPConfig.Objects[objectType].Color
                    end
                    objectCache[objectType] = objectCache[objectType] or {}
                    table.insert(objectCache[objectType], obj["Cartoony Blood Puddle"])
                end
            elseif obj.Name == (objectType == "Pallet" and "Palletwrong" or objectType) then
                local highlight = CreateHighlight(obj, ESPConfig.Objects[objectType].Color)
                if highlight then
                    highlight.FillColor = ESPConfig.Objects[objectType].Color
                    highlight.OutlineColor = ESPConfig.Objects[objectType].Color
                end
                objectCache[objectType] = objectCache[objectType] or {}
                table.insert(objectCache[objectType], obj)
            end
        end
        ::continue::
    end
end

local function ToggleESP(state)
    ESPConfig.Enabled = state
    
    if ESPConfig.Enabled then
        -- Enable ESP for existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                UpdatePlayerESP(player)
                UpdatePlayerNametag(player)
            end
        end
        
        -- Enable ESP for objects
        UpdateObjects()
        
        -- Create connections
        espConnections.playerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                UpdatePlayerESP(player)
                UpdatePlayerNametag(player)
            end)
        end)
        
        espConnections.heartbeat = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - (updateCache["lastUpdate"] or 0) < 0.1 then return end
            updateCache["lastUpdate"] = currentTime
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    UpdatePlayerNametag(player)
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
        updateCache = {}
        
        -- Disconnect connections
        for _, conn in pairs(espConnections) do
            conn:Disconnect()
        end
        espConnections = {}
        
        print("ESP: Disabled")
    end
end

local function UpdateColor(category, objectType, color)
    if category == "Players" and ESPConfig.Players[objectType] then
        ESPConfig.Players[objectType].Color = color
    elseif category == "Objects" and ESPConfig.Objects[objectType] then
        ESPConfig.Objects[objectType].Color = color
    end
    
    -- Refresh ESP with new colors
    if ESPConfig.Enabled then
        ToggleESP(false)
        task.wait(0.1)
        ToggleESP(true)
    end
end

local function UpdateToggle(category, objectType, state)
    if category == "Players" and ESPConfig.Players[objectType] then
        ESPConfig.Players[objectType].Enabled = state
    elseif category == "Objects" and ESPConfig.Objects[objectType] then
        ESPConfig.Objects[objectType].Enabled = state
    end
    
    -- Refresh ESP
    if ESPConfig.Enabled then
        if category == "Players" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    UpdatePlayerESP(player)
                    UpdatePlayerNametag(player)
                end
            end
        elseif category == "Objects" then
            UpdateObjects()
        end
    end
end

-- ============================================
-- ESP UI
-- ============================================

-- Create ESP Tab
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye",
    Locked = false,
})

-- Main ESP Toggle
local ESPMasterToggle = ESPTab:Toggle({
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
local PlayersSection = ESPTab:Section({
    Title = "Players ESP",
    Side = "Left"
})

-- Killer ESP
local KillerToggle = PlayersSection:Toggle({
    Title = "Killer ESP",
    Desc = "แสดง ESP สำหรับ Killer",
    Icon = "skull",
    Type = "Checkbox",
    Value = ESPConfig.Players.Killer.Enabled,
    Callback = function(state)
        UpdateToggle("Players", "Killer", state)
    end
})

local KillerColorpicker = PlayersSection:Colorpicker({
    Title = "Killer Color",
    Desc = "เลือกสีสำหรับ Killer",
    Default = ESPConfig.Players.Killer.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Players", "Killer", color)
    end
})

-- Survivor ESP
local SurvivorToggle = PlayersSection:Toggle({
    Title = "Survivor ESP",
    Desc = "แสดง ESP สำหรับ Survivor",
    Icon = "users",
    Type = "Checkbox",
    Value = ESPConfig.Players.Survivor.Enabled,
    Callback = function(state)
        UpdateToggle("Players", "Survivor", state)
    end
})

local SurvivorColorpicker = PlayersSection:Colorpicker({
    Title = "Survivor Color",
    Desc = "เลือกสีสำหรับ Survivor",
    Default = ESPConfig.Players.Survivor.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Players", "Survivor", color)
    end
})

-- Objects Section
local ObjectsSection = ESPTab:Section({
    Title = "Objects ESP",
    Side = "Right"
})

-- Generator ESP
local GeneratorToggle = ObjectsSection:Toggle({
    Title = "Generator ESP",
    Desc = "แสดง ESP สำหรับ Generator",
    Icon = "settings",
    Type = "Checkbox",
    Value = ESPConfig.Objects.Generator.Enabled,
    Callback = function(state)
        UpdateToggle("Objects", "Generator", state)
    end
})

local GeneratorColorpicker = ObjectsSection:Colorpicker({
    Title = "Generator Color",
    Desc = "เลือกสีสำหรับ Generator",
    Default = ESPConfig.Objects.Generator.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Generator", color)
    end
})

-- Gate ESP
local GateToggle = ObjectsSection:Toggle({
    Title = "Gate ESP",
    Desc = "แสดง ESP สำหรับ Gate",
    Icon = "door-open",
    Type = "Checkbox",
    Value = ESPConfig.Objects.Gate.Enabled,
    Callback = function(state)
        UpdateToggle("Objects", "Gate", state)
    end
})

local GateColorpicker = ObjectsSection:Colorpicker({
    Title = "Gate Color",
    Desc = "เลือกสีสำหรับ Gate",
    Default = ESPConfig.Objects.Gate.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Gate", color)
    end
})

-- Pallet ESP
local PalletToggle = ObjectsSection:Toggle({
    Title = "Pallet ESP",
    Desc = "แสดง ESP สำหรับ Pallet",
    Icon = "square",
    Type = "Checkbox",
    Value = ESPConfig.Objects.Pallet.Enabled,
    Callback = function(state)
        UpdateToggle("Objects", "Pallet", state)
    end
})

local PalletColorpicker = ObjectsSection:Colorpicker({
    Title = "Pallet Color",
    Desc = "เลือกสีสำหรับ Pallet",
    Default = ESPConfig.Objects.Pallet.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Pallet", color)
    end
})

-- Window ESP
local WindowToggle = ObjectsSection:Toggle({
    Title = "Window ESP",
    Desc = "แสดง ESP สำหรับ Window",
    Icon = "square",
    Type = "Checkbox",
    Value = ESPConfig.Objects.Window.Enabled,
    Callback = function(state)
        UpdateToggle("Objects", "Window", state)
    end
})

local WindowColorpicker = ObjectsSection:Colorpicker({
    Title = "Window Color",
    Desc = "เลือกสีสำหรับ Window",
    Default = ESPConfig.Objects.Window.Color,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        UpdateColor("Objects", "Window", color)
    end
})

-- Hook ESP
local HookToggle = ObjectsSection:Toggle({
    Title = "Hook ESP",
    Desc = "แสดง ESP สำหรับ Hook",
    Icon = "anchor",
    Type = "Checkbox",
    Value = ESPConfig.Objects.Hook.Enabled,
    Callback = function(state)
        UpdateToggle("Objects", "Hook", state)
    end
})

local HookColorpicker = ObjectsSection:Colorpicker({
    Title = "Hook Color",
    Desc = "เลือกสีสำหรับ Hook",
    Default = ESPConfig.Objects.Hook.Color,
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
