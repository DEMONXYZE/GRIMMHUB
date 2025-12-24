Window:Tag({
    Title = "Premium",
    Icon = "github",
    Color = Color3.fromHex("1F1F1F"),
    Radius = 13,
})

local Tab = Window:Tab({
    Title = "Auto Crate",
    Icon = "gift", -- optional
    Locked = false,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local basesFolder = workspace.Map.Bases

local playerBaseNumber = nil
local isRunning = false
local connection = nil

-- Find base once
local function findPlayerBaseOnce()
    if playerBaseNumber then
        return playerBaseNumber
    end
    
    for i = 1, 5 do
        local baseModel = basesFolder:FindFirstChild(tostring(i))
        if baseModel then
            local ownerValue = baseModel:FindFirstChild("Owner")
            if ownerValue and ownerValue:IsA("ObjectValue") then
                if ownerValue.Value and ownerValue.Value == player then
                    playerBaseNumber = i
                    break
                end
            end
        end
    end
    return playerBaseNumber
end

-- Main function
local function fireCrateRemote()
    if not playerBaseNumber then
        findPlayerBaseOnce()
        if not playerBaseNumber then
            WindUI:Notify({
                Title = "Error",
                Content = "Your base not found in the system",
                Duration = 3,
                Icon = "alert",
            })
            return
        end
    end
    
    local basePath = basesFolder:FindFirstChild(tostring(playerBaseNumber))
    if not basePath then 
        playerBaseNumber = nil -- Reset to find again
        return 
    end
    
    local crate = basePath:FindFirstChild("Crate")
    if not crate then return end
    
    local firedCount = 0
    for _, model in ipairs(crate:GetChildren()) do
        if model:IsA("Model") then
            local insideCrate = model:FindFirstChild("InsideCrate")
            if insideCrate then
                local hitRemote = insideCrate:FindFirstChild("Hit")
                if hitRemote and hitRemote:IsA("RemoteEvent") then
                    local args = {4000}
                    hitRemote:FireServer(unpack(args))
                    firedCount += 1
                end
            end
        end
    end
    
    return firedCount
end

-- Start/Stop loop function
local function toggleLoop(state)
    isRunning = state
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if state then
        -- Run first time
        local firedCount = fireCrateRemote()
        
        if firedCount and firedCount > 0 then
            WindUI:Notify({
                Title = "Success",
                Content = "Auto Crate started (found " .. firedCount .. " crates)",
                Duration = 3,
                Icon = "check",
            })
        else
            WindUI:Notify({
                Title = "Warning",
                Content = "Auto Crate started but no crates found",
                Duration = 3,
                Icon = "warning",
            })
        end
        
        -- Set up loop
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if isRunning then
                fireCrateRemote()
            else
                connection:Disconnect()
            end
        end)
        
        Toggle:SetTitle("Auto Crate (ON)")
    else
        WindUI:Notify({
            Title = "Stopped",
            Content = "Auto Crate stopped",
            Duration = 3,
            Icon = "stop",
        })
        Toggle:SetTitle("Auto Crate (OFF)")
    end
end

-- Create Toggle
local Toggle = Tab:Toggle({
    Title = "Auto Crate",
    Desc = "Automatically interact with crates in your base",
    Icon = "gift",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        toggleLoop(state)
    end
})

-- Auto Server Crate Variables
local isServerCrateRunning = false
local serverCrateConnection = nil
local lastCheckTime = 0
local CHECK_INTERVAL = 5 -- seconds

-- Function for server crates
local function checkAndHitServerCrates()
    local serverCrateFolder = workspace.Map:FindFirstChild("ServerCrate")
    if not serverCrateFolder then return 0 end
    
    local hitCount = 0
    
    for _, child in ipairs(serverCrateFolder:GetChildren()) do
        -- Skip if it's a part named "crate" (case-insensitive)
        if child:IsA("Part") and child.Name:lower() == "crate" then
            continue
        end
        
        local insideBigCrate = child:FindFirstChild("InsideBigCrate")
        if insideBigCrate then
            local hitRemote = insideBigCrate:FindFirstChild("Hit")
            if hitRemote and hitRemote:IsA("RemoteEvent") then
                hitRemote:FireServer(75)
                hitCount += 1
            end
        end
    end
    
    return hitCount
end

-- Function to start/stop server crate loop
local function toggleServerCrateLoop(state)
    isServerCrateRunning = state
    
    if serverCrateConnection then
        serverCrateConnection:Disconnect()
        serverCrateConnection = nil
    end
    
    if state then
        -- Run immediately on start
        local hitCount = checkAndHitServerCrates()
        
        if hitCount > 0 then
            WindUI:Notify({
                Title = "Server Crate",
                Content = "Started! Hit " .. hitCount .. " server crate(s)",
                Duration = 3,
                Icon = "check",
            })
        else
            WindUI:Notify({
                Title = "Server Crate",
                Content = "Started! No server crates found",
                Duration = 3,
                Icon = "info",
            })
        end
        
        -- Set up loop to check every 5 seconds
        serverCrateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            local currentTime = tick()
            if isServerCrateRunning and (currentTime - lastCheckTime) >= CHECK_INTERVAL then
                lastCheckTime = currentTime
                checkAndHitServerCrates()
            end
        end)
        
        ServerCrateToggle:SetTitle("Server Crate (ON)")
    else
        WindUI:Notify({
            Title = "Server Crate",
            Content = "Stopped",
            Duration = 3,
            Icon = "stop",
        })
        ServerCrateToggle:SetTitle("Server Crate (OFF)")
    end
end

-- Create Server Crate Toggle
local ServerCrateToggle = Tab:Toggle({
    Title = "Server Crate",
    Desc = "Auto-hit server crates every 5 seconds",
    Icon = "server",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        toggleServerCrateLoop(state)
    end
})


local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

local SettingsSection = SettingsTab:Section({ 
    Title = "Button Display Settings",
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
SettingsSection:Toggle({
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
