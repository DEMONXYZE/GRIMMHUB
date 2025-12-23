local autokey = true
-- Required services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Configuration settings
local cfg = {
    api = "5ae9c304-43bf-4b17-8c32-75c874505533",
    service = "GRIMMHUB",
    provider = "GRIMMHUB",
    discord = "https://discord.gg/yXV378FDNk",
    junkieDev = "https://junkie-development.de/",
    logo = "rbxassetid://92179202190700",
    primaryColor = Color3.fromRGB(255, 255, 255), -- White
    accentColor = Color3.fromRGB(100, 100, 100), -- Gray
    keyFile = "GRIMMHUB.txt" -- File for storing key
}

-- Load WindUI early for notifications
local WindUI, WindWindow
local WindUILoaded = false

local function loadWindUI()
    if not WindUILoaded then
        local success, result = pcall(function()
            WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
            WindUILoaded = true
            return WindUI
        end)
        
        if not success then
            warn("Failed to load WindUI: " .. tostring(result))
            return nil
        end
    end
    return WindUI
end

-- Function to create notification using WindUI
local function createNotification(title, content, duration, icon)
    -- Try to load WindUI if not loaded
    local ui = loadWindUI()
    if ui then
        ui:Notify({
            Title = title,
            Content = content,
            Duration = duration or 1,
            Icon = icon or "shield" -- Default icon
        })
        return { Close = function() end } -- Return dummy table for compatibility
    else
        -- Fallback to simple notification if WindUI fails
        warn("WindUI not available, using fallback notification")
        local notif = Instance.new("ScreenGui")
        notif.Name = "FallbackNotif"
        notif.Parent = CoreGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 80)
        frame.Position = UDim2.new(1, -320, 1, -100)
        frame.AnchorPoint = Vector2.new(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = notif
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.TextSize = 16
        titleLabel.Font = Enum.Font.FredokaOne
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, -20, 0, 25)
        titleLabel.Position = UDim2.new(0, 10, 0, 10)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = frame
        
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Text = content
        contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        contentLabel.TextSize = 14
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.BackgroundTransparency = 1
        contentLabel.Size = UDim2.new(1, -20, 0, 40)
        contentLabel.Position = UDim2.new(0, 10, 0, 35)
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextWrapped = true
        contentLabel.Parent = frame
        
        -- Auto remove after duration
        if duration then
            task.delay(duration, function()
                frame:Destroy()
                notif:Destroy()
            end)
        end
        
        return { 
            Close = function()
                frame:Destroy()
                notif:Destroy()
            end 
        }
    end
end

-- Function to save to file (if writefile exists)
local function saveKey(key)
    if writefile then
        pcall(function() writefile(cfg.keyFile, key) end)
    end
end

-- Function to load key from file (if readfile exists)
local function loadKey()
    if readfile then
        local ok, data = pcall(function() return readfile(cfg.keyFile) end)
        if ok and data and data ~= "" then 
            return data 
        end
    end
    return ""
end

-- Function to build main UI with 3 tabs like in the image
local function buildUI()
    local Part1 = {} -- Top level
    local Part2 = {} -- Header
    local Part3 = {} -- Tabs
    local Part4 = {} -- Content

    -- Create ScreenGui
    Part1.Screen = Instance.new("ScreenGui")
    Part1.Screen.Name = "GRIMMHUB"
    Part1.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Part1.Screen.ResetOnSpawn = false
    Part1.Screen.IgnoreGuiInset = true
    Part1.Screen.Parent = CoreGui

    -- Main frame - เล็กลง
    Part1.Main = Instance.new("Frame")
    Part1.Main.Name = "Main"
    Part1.Main.Size = UDim2.new(0, 380, 0, 280) -- เล็กลงจาก 450x350 เป็น 380x280
    Part1.Main.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center
    Part1.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Part1.Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark black-gray
    Part1.Main.BackgroundTransparency = 0
    Part1.Main.BorderSizePixel = 0
    Part1.Main.ClipsDescendants = true
    Part1.Main.Parent = Part1.Screen

    Part1.Corner = Instance.new("UICorner")
    Part1.Corner.CornerRadius = UDim.new(0, 10) -- Rounded corners
    Part1.Corner.Parent = Part1.Main

    -- Header - สั้นลง
    Part2.Top = Instance.new("Frame")
    Part2.Top.Name = "Top"
    Part2.Top.Size = UDim2.new(1, 0, 0, 35) -- Height 35 pixels (จาก 50)
    Part2.Top.Position = UDim2.new(0, 0, 0, 0) -- Top
    Part2.Top.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Medium gray
    Part2.Top.BorderSizePixel = 0
    Part2.Top.Parent = Part1.Main

    Part2.TopCorner = Instance.new("UICorner")
    Part2.TopCorner.CornerRadius = UDim.new(0, 10)
    Part2.TopCorner.Parent = Part2.Top

    -- Cover bottom part of header
    Part2.TopCover = Instance.new("Frame")
    Part2.TopCover.Name = "TopCover"
    Part2.TopCover.Size = UDim2.new(1, 0, 0, 15)
    Part2.TopCover.Position = UDim2.new(0, 0, 1, -15)
    Part2.TopCover.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Part2.TopCover.BorderSizePixel = 0
    Part2.TopCover.Parent = Part2.Top

    -- Logo icon - เล็กลง
    Part2.Logo = Instance.new("ImageLabel")
    Part2.Logo.Name = "Logo"
    Part2.Logo.Size = UDim2.new(0, 25, 0, 25) -- 25x25
    Part2.Logo.Position = UDim2.new(0, 8, 0.5, 0) -- Center vertically
    Part2.Logo.AnchorPoint = Vector2.new(0, 0.5)
    Part2.Logo.BackgroundTransparency = 1
    Part2.Logo.Image = cfg.logo
    Part2.Logo.ImageColor3 = cfg.primaryColor -- White
    Part2.Logo.Parent = Part2.Top

    -- Window title
    Part2.Title = Instance.new("TextLabel")
    Part2.Title.Name = "Title"
    Part2.Title.Size = UDim2.new(0, 120, 0, 35)
    Part2.Title.Position = UDim2.new(0, 40, 0, 0) -- Next to icon
    Part2.Title.BackgroundTransparency = 1
    Part2.Title.Text = "GRIMM HUB"
    Part2.Title.TextColor3 = cfg.primaryColor -- White
    Part2.Title.TextSize = 18 -- เล็กลง
    Part2.Title.Font = Enum.Font.FredokaOne
    Part2.Title.TextXAlignment = Enum.TextXAlignment.Left
    Part2.Title.Parent = Part2.Top

    -- Close button
    Part2.Close = Instance.new("ImageButton")
    Part2.Close.Name = "Close"
    Part2.Close.Size = UDim2.new(0, 20, 0, 20)
    Part2.Close.Position = UDim2.new(1, -8, 0.5, 0) -- Top right
    Part2.Close.AnchorPoint = Vector2.new(1, 0.5)
    Part2.Close.BackgroundTransparency = 1
    Part2.Close.Image = "rbxassetid://122931434733842" -- X icon
    Part2.Close.ImageColor3 = cfg.primaryColor -- White
    Part2.Close.ScaleType = Enum.ScaleType.Fit
    Part2.Close.Parent = Part2.Top

    -- Tab buttons container
    Part3.Tabs = Instance.new("Frame")
    Part3.Tabs.Name = "Tabs"
    Part3.Tabs.Size = UDim2.new(1, 0, 0, 30) -- สั้นลง
    Part3.Tabs.Position = UDim2.new(0, 0, 0, 35) -- Below header
    Part3.Tabs.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Part3.Tabs.BorderSizePixel = 0
    Part3.Tabs.Parent = Part1.Main

    -- Tab buttons
    local tabNames = {"insert key", "verifykey", "getkeys"}
    local tabButtons = {}
    
    for i, name in ipairs(tabNames) do
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(1/3, 0, 1, 0)
        tab.Position = UDim2.new((i-1)/3, 0, 0, 0)
        tab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tab.BorderSizePixel = 0
        tab.Text = name:upper()
        tab.TextColor3 = cfg.primaryColor
        tab.TextSize = 11 -- เล็กลง
        tab.Font = Enum.Font.FredokaOne
        tab.AutoButtonColor = false
        tab.Parent = Part3.Tabs
        
        -- Highlight for active tab
        local highlight = Instance.new("Frame")
        highlight.Name = "Highlight"
        highlight.Size = UDim2.new(1, 0, 0, 3)
        highlight.Position = UDim2.new(0, 0, 1, -3)
        highlight.BackgroundColor3 = cfg.accentColor
        highlight.BorderSizePixel = 0
        highlight.Visible = (i == 1) -- First tab active by default
        highlight.Parent = tab
        
        tabButtons[name] = tab
    end

    -- Content area
    Part4.Content = Instance.new("Frame")
    Part4.Content.Name = "Content"
    Part4.Content.Size = UDim2.new(1, 0, 1, -65) -- Fill rest below header + tabs
    Part4.Content.Position = UDim2.new(0, 0, 0, 65)
    Part4.Content.BackgroundTransparency = 1
    Part4.Content.ClipsDescendants = true
    Part4.Content.Parent = Part1.Main

    -- Create 3 pages
    local pages = {}
    
    -- Page 1: Insert Key
    pages["insert key"] = Instance.new("Frame")
    pages["insert key"].Name = "InsertKeyPage"
    pages["insert key"].Size = UDim2.new(1, 0, 1, 0)
    pages["insert key"].Position = UDim2.new(0, 0, 0, 0)
    pages["insert key"].BackgroundTransparency = 1
    pages["insert key"].Visible = true
    pages["insert key"].Parent = Part4.Content
    
    -- Key input box for page 1
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.85, 0, 0, 40)
    inputFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
    inputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inputFrame.BackgroundTransparency = 0.1
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = pages["insert key"]
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputFrame
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = cfg.accentColor
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.3
    inputStroke.Parent = inputFrame
    
    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyBox"
    keyBox.Size = UDim2.new(0.9, 0, 1, 0)
    keyBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    keyBox.AnchorPoint = Vector2.new(0.5, 0.5)
    keyBox.BackgroundTransparency = 1
    keyBox.Text = loadKey()
    keyBox.TextColor3 = cfg.primaryColor
    keyBox.PlaceholderText = "00000000-0000-0000-0000-000000000000"
    keyBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    keyBox.TextSize = 14
    keyBox.Font = Enum.Font.Gotham
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = inputFrame
    
    local hint = Instance.new("TextLabel")
    hint.Text = "Press ENTER after pasting to verify"
    hint.TextColor3 = Color3.fromRGB(150, 150, 150)
    hint.TextSize = 11
    hint.Font = Enum.Font.Gotham
    hint.BackgroundTransparency = 1
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 1, 5)
    hint.TextXAlignment = Enum.TextXAlignment.Center
    hint.Parent = inputFrame

    -- Page 2: Verify Key
    pages["verifykey"] = Instance.new("Frame")
    pages["verifykey"].Name = "VerifyPage"
    pages["verifykey"].Size = UDim2.new(1, 0, 1, 0)
    pages["verifykey"].Position = UDim2.new(0, 0, 0, 0)
    pages["verifykey"].BackgroundTransparency = 1
    pages["verifykey"].Visible = false
    pages["verifykey"].Parent = Part4.Content
    
    local verifyIcon = Instance.new("ImageLabel")
    verifyIcon.Size = UDim2.new(0, 60, 0, 60) -- เล็กลง
    verifyIcon.Position = UDim2.new(0.5, 0, 0.3, 0)
    verifyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    verifyIcon.BackgroundTransparency = 1
    verifyIcon.Image = "rbxassetid://87354736164608" -- Check icon
    verifyIcon.ImageColor3 = cfg.primaryColor
    verifyIcon.Parent = pages["verifykey"]
    
    local verifyText = Instance.new("TextLabel")
    verifyText.Text = "Verify your key to continue"
    verifyText.TextColor3 = cfg.primaryColor
    verifyText.TextSize = 16
    verifyText.Font = Enum.Font.FredokaOne
    verifyText.BackgroundTransparency = 1
    verifyText.Size = UDim2.new(1, -40, 0, 25)
    verifyText.Position = UDim2.new(0.5, 0, 0.55, 0)
    verifyText.AnchorPoint = Vector2.new(0.5, 0)
    verifyText.TextXAlignment = Enum.TextXAlignment.Center
    verifyText.Parent = pages["verifykey"]
    
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Name = "VerifyButton"
    verifyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    verifyBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
    verifyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "VERIFY KEY"
    verifyBtn.TextColor3 = cfg.primaryColor
    verifyBtn.TextSize = 14
    verifyBtn.Font = Enum.Font.FredokaOne
    verifyBtn.AutoButtonColor = false
    verifyBtn.Parent = pages["verifykey"]
    
    local verifyCorner = Instance.new("UICorner")
    verifyCorner.CornerRadius = UDim.new(0, 8)
    verifyCorner.Parent = verifyBtn

    -- Page 3: Get Keys
    pages["getkeys"] = Instance.new("Frame")
    pages["getkeys"].Name = "GetKeysPage"
    pages["getkeys"].Size = UDim2.new(1, 0, 1, 0)
    pages["getkeys"].Position = UDim2.new(0, 0, 0, 0)
    pages["getkeys"].BackgroundTransparency = 1
    pages["getkeys"].Visible = false
    pages["getkeys"].Parent = Part4.Content
    
    -- Key icon - เล็กลง
    local keyIcon = Instance.new("ImageLabel")
    keyIcon.Size = UDim2.new(0, 55, 0, 55)
    keyIcon.Position = UDim2.new(0.5, 0, 0.2, 0)
    keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    keyIcon.BackgroundTransparency = 1
    keyIcon.Image = "rbxassetid://96510194465420" -- Key icon
    keyIcon.ImageColor3 = cfg.primaryColor
    keyIcon.Parent = pages["getkeys"]
    
    local getKeyText = Instance.new("TextLabel")
    getKeyText.Text = "Get your key from:"
    getKeyText.TextColor3 = cfg.primaryColor
    getKeyText.TextSize = 16
    getKeyText.Font = Enum.Font.FredokaOne
    getKeyText.BackgroundTransparency = 1
    getKeyText.Size = UDim2.new(1, -40, 0, 25)
    getKeyText.Position = UDim2.new(0.5, 0, 0.45, 0)
    getKeyText.AnchorPoint = Vector2.new(0.5, 0)
    getKeyText.TextXAlignment = Enum.TextXAlignment.Center
    getKeyText.Parent = pages["getkeys"]
    
    -- Buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Size = UDim2.new(0.8, 0, 0, 90) -- สั้นลง (ลบปุ่ม JUNKYDEV ออก)
    buttonsContainer.Position = UDim2.new(0.5, 0, 0.75, 0)
    buttonsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = pages["getkeys"]
    
    -- Discord Button (อันเดียว)
    local discordBtn = Instance.new("TextButton")
    discordBtn.Name = "DiscordButton"
    discordBtn.Size = UDim2.new(1, 0, 0, 35)
    discordBtn.Position = UDim2.new(0.5, 0, 0, 10)
    discordBtn.AnchorPoint = Vector2.new(0.5, 0)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord blue
    discordBtn.BorderSizePixel = 0
    discordBtn.Text = "DISCORD"
    discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordBtn.TextSize = 14
    discordBtn.Font = Enum.Font.FredokaOne
    discordBtn.AutoButtonColor = false
    discordBtn.Parent = buttonsContainer
    
    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordBtn
    
    -- Get Key Link Button (from original code)
    local getLinkBtn = Instance.new("TextButton")
    getLinkBtn.Name = "GetLinkButton"
    getLinkBtn.Size = UDim2.new(1, 0, 0, 35)
    getLinkBtn.Position = UDim2.new(0.5, 0, 0, 50) -- ตำแหน่งต่ำลง
    getLinkBtn.AnchorPoint = Vector2.new(0.5, 0)
    getLinkBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 120) -- Purple
    getLinkBtn.BorderSizePixel = 0
    getLinkBtn.Text = "GET KEY LINK"
    getLinkBtn.TextColor3 = cfg.primaryColor
    getLinkBtn.TextSize = 14
    getLinkBtn.Font = Enum.Font.FredokaOne
    getLinkBtn.AutoButtonColor = false
    getLinkBtn.Parent = buttonsContainer
    
    local linkCorner = Instance.new("UICorner")
    linkCorner.CornerRadius = UDim.new(0, 8)
    linkCorner.Parent = getLinkBtn

    -- Return created UI
    return {
        gui = Part1.Screen,
        main = Part1.Main,
        keyBox = keyBox,
        tabButtons = tabButtons,
        pages = pages,
        verifyBtn = verifyBtn,
        discordBtn = discordBtn,
        getLinkBtn = getLinkBtn,
        close = Part2.Close,
        top = Part2.Top
    }
end

-- Function for window dragging (อัพเดทให้ดึงได้ทั้งหน้าต่าง)
local function drag(ui)
    local dragInput, dragStart, startPos
    
    -- สามารถลากได้จาก header
    ui.top.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then -- Left click
            dragInput = inp
            dragStart = inp.Position
            startPos = ui.main.Position
            inp.Changed:Connect(function() 
                if inp.UserInputState == Enum.UserInputState.End then 
                    dragInput = nil 
                end 
            end)
        end
    end)
    
    -- สามารถลากได้จาก main frame ด้วย (เพิ่มส่วนนี้)
    ui.main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then -- Left click
            dragInput = inp
            dragStart = inp.Position
            startPos = ui.main.Position
            inp.Changed:Connect(function() 
                if inp.UserInputState == Enum.UserInputState.End then 
                    dragInput = nil 
                end 
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            ui.main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Function to switch tabs
local function switchTab(ui, tabName)
    -- Hide all pages
    for name, page in pairs(ui.pages) do
        page.Visible = false
    end
    
    -- Show selected page
    ui.pages[tabName].Visible = true
    
    -- Update tab highlights
    for name, tab in pairs(ui.tabButtons) do
        tab.Highlight.Visible = (name == tabName)
    end
end

-- Function for button pulse effect
local function pulse(btn)
    local orig = btn.BackgroundColor3
    local pop = Color3.new(
        math.min(orig.R*1.5, 1),
        math.min(orig.G*1.5, 1), 
        math.min(orig.B*1.5, 1)
    )
    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=pop}):Play()
    task.wait(0.15)
    TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {BackgroundColor3=orig}):Play()
end

-- Function to validate key
local function validateKey(ui)
    local key = ui.keyBox.Text:gsub("%s+", "") -- Remove spaces
    if key == "" then 
        createNotification("Key Required", "Please enter a key to continue", 3, "exclamation")
        return false
    end
    
    createNotification("Verifying...", "Validating your key. Please wait...", 2, "loader")
    
    -- Load Junkie SDK
    local success, sdk = pcall(function()
        return loadstring(game:HttpGet("https://junkie-development.de/sdk/JunkieKeySystem.lua"))()
    end)
    
    if not success then
        createNotification("Error", "Failed to load SDK. Please try again", 3, "exclamation")
        return false
    end
    
    -- Verify key
    local ok = sdk.verifyKey(cfg.api, key, cfg.service)
    
    if ok then
        saveKey(key) -- Save key
        createNotification("Success!", "Key is valid. Loading script...", 1, "check")
        -- Animation for closing window
        TweenService:Create(ui.main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.5, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.4)
        ui.gui:Destroy() -- Remove UI
        
        -- Now load the main hub with WindUI
        local WindUI = loadWindUI()
        if WindUI then
            WindWindow = WindUI:CreateWindow({
                Title = "GRIMM Hub    ",
                Icon = "shield",
                Author = "by SORNOR",
                Topbar = {
                    Height = 44,
                    ButtonsType = "Mac",
                },
                Transparent = true,
            })
            loadstring(game:HttpGet("https://raw.githubusercontent.com/DEMONXYZE/GRIMMHUB/refs/heads/main/MainHub"))()
        else
            warn("Failed to load WindUI for main hub")
        end
        
        return true
    else
        createNotification("Invalid Key", "The key you entered is invalid", 1, "x")
        return false
    end
end

-- Function to get key link (from original code)
local function getKeyLink()
    createNotification("Getting Key...", "Generating key link...", 2, "key")
    
    local success, sdk = pcall(function()
        return loadstring(game:HttpGet("https://junkie-development.de/sdk/JunkieKeySystem.lua"))()
    end)
    
    if success then
        local link = sdk.getLink(cfg.api, cfg.provider, cfg.service)
        if link and setclipboard then
            setclipboard(link)
            createNotification("Link Copied", "Key link copied to clipboard", 3, "clipboard")
            return true
        else
            createNotification("Failed", "Unable to generate key link", 2, "x")
            return false
        end
    else
        createNotification("Error", "Failed to load SDK. Please try again", 3, "exclamation")
        return false
    end
end

-- Function for auto verification
local function autoVerify(ui)
    local key = loadKey()
    if key and key ~= "" then
        ui.keyBox.Text = key
        createNotification("Auto Mode", "Auto-verifying key...", 1, "loader")
        task.wait(1)
        pulse(ui.verifyBtn)
        return validateKey(ui)
    else
        createNotification("No Key Found", "No saved key found. Please enter key manually", 3, "exclamation")
        return false
    end
end

-- Main function
local function main()
    if getgenv().JunkieUILoaded then return end
    getgenv().JunkieUILoaded = true
    
    loadWindUI()
    
    local ui = buildUI()
    drag(ui) -- ทำให้ลากได้
    
    -- Switch to insert key tab by default
    switchTab(ui, "insert key")
    
    -- Tab switching
    for name, tab in pairs(ui.tabButtons) do
        tab.MouseButton1Click:Connect(function()
            switchTab(ui, name)
            pulse(tab)
        end)
    end
    
    -- Verify key on ENTER press in insert key page
    ui.keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            createNotification("Verifying...", "Checking your key...", 1, "loader")
            task.wait(0.5)
            validateKey(ui)
        end
    end)
    
    -- Verify button
    ui.verifyBtn.MouseButton1Click:Connect(function()
        pulse(ui.verifyBtn)
        validateKey(ui)
    end)
    
    -- Discord button
    ui.discordBtn.MouseButton1Click:Connect(function()
        pulse(ui.discordBtn)
        createNotification("Discord", "Opening Discord invite...", 2, "discord")
        if setclipboard then
            setclipboard(cfg.discord)
            createNotification("Link Copied", "Discord link copied to clipboard", 3, "clipboard")
        end
    end)
    
    -- Get Key Link button
    ui.getLinkBtn.MouseButton1Click:Connect(function()
        pulse(ui.getLinkBtn)
        getKeyLink()
    end)
    
    -- Close button
    ui.close.MouseButton1Click:Connect(function()
        createNotification("Closing...", "See you next time!", 2, "heart")
        TweenService:Create(ui.main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.5, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.4)
        ui.gui:Destroy()
    end)
    
    -- Hover effects for tab buttons
    for name, tab in pairs(ui.tabButtons) do
        tab.MouseEnter:Connect(function()
            TweenService:Create(tab, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            }):Play()
        end)
        tab.MouseLeave:Connect(function()
            if not tab.Highlight.Visible then
                TweenService:Create(tab, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                }):Play()
            end
        end)
    end
    
    -- If auto mode is enabled, verify automatically
    if autokey then
        task.wait(0.5)
        autoVerify(ui)
    end
end

-- Start program
main()
