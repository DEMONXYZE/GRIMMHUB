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
    discord = "https://discord.gg/pKWKZfja",
    logo = "rbxassetid://121595097202790",
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
        titleLabel.Font = Enum.Font.GothamBold
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

-- Function to build main UI
local function buildUI()
    local Part1 = {} -- Top level
    local Part2 = {} -- Header
    local Part3 = {} -- Content

    -- Create ScreenGui
    Part1.Screen = Instance.new("ScreenGui")
    Part1.Screen.Name = "GRIMMHUB"
    Part1.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Part1.Screen.ResetOnSpawn = false
    Part1.Screen.IgnoreGuiInset = true
    Part1.Screen.Parent = CoreGui

    -- Main frame
    Part1.Main = Instance.new("Frame")
    Part1.Main.Name = "Main"
    Part1.Main.Size = UDim2.new(0, 370, 0, 200) -- Size 370x200
    Part1.Main.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center
    Part1.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Part1.Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark black-gray
    Part1.Main.BackgroundTransparency = 0
    Part1.Main.BorderSizePixel = 0
    Part1.Main.ClipsDescendants = false
    Part1.Main.Parent = Part1.Screen

    Part1.Corner = Instance.new("UICorner")
    Part1.Corner.CornerRadius = UDim.new(0, 10) -- Rounded corners
    Part1.Corner.Parent = Part1.Main

    -- Header
    Part2.Top = Instance.new("Frame")
    Part2.Top.Name = "Top"
    Part2.Top.Size = UDim2.new(1, 0, 0, 35) -- Height 35 pixels
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
    Part2.TopCover.Size = UDim2.new(1, 0, 0, 20)
    Part2.TopCover.Position = UDim2.new(0, 0, 1, -20)
    Part2.TopCover.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Part2.TopCover.BorderSizePixel = 0
    Part2.TopCover.Parent = Part2.Top

    -- Separator line
    Part2.Line = Instance.new("Frame")
    Part2.Line.Name = "Line"
    Part2.Line.Size = UDim2.new(1, 0, 0, 1) -- 1 pixel height
    Part2.Line.Position = UDim2.new(0, 0, 1, 0) -- Bottom of header
    Part2.Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Darker gray
    Part2.Line.BorderSizePixel = 0
    Part2.Line.Parent = Part2.Top

    -- Logo icon
    Part2.Logo = Instance.new("ImageLabel")
    Part2.Logo.Name = "Logo"
    Part2.Logo.Size = UDim2.new(0, 20, 0, 20) -- 20x20
    Part2.Logo.Position = UDim2.new(0, 10, 0, 7) -- Top left
    Part2.Logo.BackgroundTransparency = 1
    Part2.Logo.Image = cfg.logo
    Part2.Logo.ImageColor3 = cfg.primaryColor -- White
    Part2.Logo.Parent = Part2.Top

    -- Window title
    Part2.Title = Instance.new("TextLabel")
    Part2.Title.Name = "Title"
    Part2.Title.Size = UDim2.new(0, 100, 0, 35)
    Part2.Title.Position = UDim2.new(0, 35, 0, 0) -- Next to icon
    Part2.Title.BackgroundTransparency = 1
    Part2.Title.Text = "GRIMM HUB" -- Hack name
    Part2.Title.TextColor3 = cfg.primaryColor -- White
    Part2.Title.TextSize = 18
    Part2.Title.Font = Enum.Font.GothamBold
    Part2.Title.TextXAlignment = Enum.TextXAlignment.Left
    Part2.Title.Parent = Part2.Top

    -- Close button
    Part2.Close = Instance.new("ImageButton")
    Part2.Close.Name = "Close"
    Part2.Close.Size = UDim2.new(0, 20, 0, 20)
    Part2.Close.Position = UDim2.new(1, -10, 0.5, 0) -- Top right
    Part2.Close.AnchorPoint = Vector2.new(1, 0.5)
    Part2.Close.BackgroundTransparency = 1
    Part2.Close.Image = "rbxassetid://122931434733842" -- X icon
    Part2.Close.ImageColor3 = cfg.primaryColor -- White
    Part2.Close.ScaleType = Enum.ScaleType.Fit
    Part2.Close.Parent = Part2.Top

    -- Key input section
    Part3.Input = Instance.new("Frame")
    Part3.Input.Name = "Input"
    Part3.Input.Size = UDim2.new(0.9, 0, 0, 35) -- 90% of window width
    Part3.Input.Position = UDim2.new(0.5, 0, 0, 60) -- 60 pixels from top
    Part3.Input.AnchorPoint = Vector2.new(0.5, 0)
    Part3.Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark gray
    Part3.Input.BackgroundTransparency = 0.1
    Part3.Input.BorderSizePixel = 0
    Part3.Input.Parent = Part1.Main

    -- Border
    Part3.InputStroke = Instance.new("UIStroke")
    Part3.InputStroke.Color = cfg.accentColor -- Gray
    Part3.InputStroke.Thickness = 1
    Part3.InputStroke.Transparency = 0.3
    Part3.InputStroke.Parent = Part3.Input

    Part3.InputCorner = Instance.new("UICorner")
    Part3.InputCorner.CornerRadius = UDim.new(0, 6)
    Part3.InputCorner.Parent = Part3.Input

    -- Text input box
    Part3.Box = Instance.new("TextBox")
    Part3.Box.Name = "Box"
    Part3.Box.Size = UDim2.new(0.9, 0, 1, 0) -- 90% of frame
    Part3.Box.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center
    Part3.Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Part3.Box.BackgroundTransparency = 1
    Part3.Box.Text = loadKey() -- Load saved key
    Part3.Box.TextColor3 = cfg.primaryColor -- White
    Part3.Box.PlaceholderText = "00000000-0000-0000-0000-000000000000" -- Key format example
    Part3.Box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120) -- Gray
    Part3.Box.TextSize = 14
    Part3.Box.Font = Enum.Font.Gotham
    Part3.Box.ClearTextOnFocus = false -- Don't clear on click
    Part3.Box.Parent = Part3.Input

    -- Buttons section
    Part3.Buttons = Instance.new("Frame")
    Part3.Buttons.Name = "Buttons"
    Part3.Buttons.Size = UDim2.new(0.9, 0, 0, 30)
    Part3.Buttons.Position = UDim2.new(0.5, 0, 1, -40) -- 40 pixels from bottom
    Part3.Buttons.AnchorPoint = Vector2.new(0.5, 1)
    Part3.Buttons.BackgroundTransparency = 1
    Part3.Buttons.Parent = Part1.Main

    local btnColor = Color3.fromRGB(60, 60, 60) -- Gray button

    -- Get Key button
    Part3.GetKey = Instance.new("TextButton")
    Part3.GetKey.Name = "GetKey"
    Part3.GetKey.Size = UDim2.new(0.45, -4, 1, 0) -- 45% of button area
    Part3.GetKey.Position = UDim2.new(0.25, 0, 0, 0)
    Part3.GetKey.AnchorPoint = Vector2.new(0.5, 0)
    Part3.GetKey.BackgroundColor3 = btnColor
    Part3.GetKey.BorderSizePixel = 0
    Part3.GetKey.Text = ""
    Part3.GetKey.AutoButtonColor = false -- Disable auto color change
    Part3.GetKey.Parent = Part3.Buttons

    -- Get Key button icon
    local getKeyIco = Instance.new("ImageLabel")
    getKeyIco.Size = UDim2.new(0, 16, 0, 16)
    getKeyIco.Position = UDim2.new(0.5, -20, 0.5, 0) -- Left aligned
    getKeyIco.AnchorPoint = Vector2.new(0.5, 0.5)
    getKeyIco.BackgroundTransparency = 1
    getKeyIco.Image = "rbxassetid://96510194465420" -- Key icon
    getKeyIco.ImageColor3 = cfg.primaryColor -- White
    getKeyIco.Parent = Part3.GetKey

    -- Get Key button text
    local getKeyTxt = Instance.new("TextLabel")
    getKeyTxt.Size = UDim2.new(1, 0, 1, 0)
    getKeyTxt.Position = UDim2.new(0.5, 8, 0, 0)
    getKeyTxt.AnchorPoint = Vector2.new(0.5, 0)
    getKeyTxt.BackgroundTransparency = 1
    getKeyTxt.Text = "Get Key" -- English
    getKeyTxt.TextColor3 = cfg.primaryColor -- White
    getKeyTxt.TextSize = 12
    getKeyTxt.Font = Enum.Font.GothamBold
    getKeyTxt.Parent = Part3.GetKey

    Part3.GetKeyCorner = Instance.new("UICorner")
    Part3.GetKeyCorner.CornerRadius = UDim.new(0, 8)
    Part3.GetKeyCorner.Parent = Part3.GetKey

    -- Verify button
    Part3.Verify = Instance.new("TextButton")
    Part3.Verify.Name = "Verify"
    Part3.Verify.Size = UDim2.new(0.45, -4, 1, 0) -- 45% of button area
    Part3.Verify.Position = UDim2.new(0.75, 0, 0, 0)
    Part3.Verify.AnchorPoint = Vector2.new(0.5, 0)
    Part3.Verify.BackgroundColor3 = btnColor
    Part3.Verify.BorderSizePixel = 0
    Part3.Verify.Text = ""
    Part3.Verify.AutoButtonColor = false
    Part3.Verify.Parent = Part3.Buttons

    -- Verify button icon
    local verifyIco = Instance.new("ImageLabel")
    verifyIco.Size = UDim2.new(0, 16, 0, 16)
    verifyIco.Position = UDim2.new(0.5, -20, 0.5, 0)
    verifyIco.AnchorPoint = Vector2.new(0.5, 0.5)
    verifyIco.BackgroundTransparency = 1
    verifyIco.Image = "rbxassetid://87354736164608" -- Check icon
    verifyIco.ImageColor3 = cfg.primaryColor -- White
    verifyIco.Parent = Part3.Verify

    -- Verify button text
    local verifyTxt = Instance.new("TextLabel")
    verifyTxt.Size = UDim2.new(1, 0, 1, 0)
    verifyTxt.Position = UDim2.new(0.5, 8, 0, 0)
    verifyTxt.AnchorPoint = Vector2.new(0.5, 0)
    verifyTxt.BackgroundTransparency = 1
    verifyTxt.Text = "Verify" -- English
    verifyTxt.TextColor3 = cfg.primaryColor -- White
    verifyTxt.TextSize = 12
    verifyTxt.Font = Enum.Font.GothamBold
    verifyTxt.Parent = Part3.Verify

    Part3.VerifyCorner = Instance.new("UICorner")
    Part3.VerifyCorner.CornerRadius = UDim.new(0, 8)
    Part3.VerifyCorner.Parent = Part3.Verify

    -- Return created UI
    return {
        gui = Part1.Screen,
        main = Part1.Main,
        box = Part3.Box,
        verify = Part3.Verify,
        getKey = Part3.GetKey,
        close = Part2.Close,
        top = Part2.Top
    }
end

-- Function for window dragging
local function drag(ui)
    local dragInput, dragStart, startPos
    ui.top.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then -- Left click
            dragInput = inp
            dragStart = inp.Position
            startPos = ui.main.Position
            -- Track when mouse is released
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

-- Function for button pulse effect on click
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
    local key = ui.box.Text:gsub("%s+", "") -- Remove spaces
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
            -- Fallback if WindUI fails to load
            warn("Failed to load WindUI for main hub")
        end
        
        return true
    else
        createNotification("Invalid Key", "The key you entered is invalid", 1, "x")
        return false
    end
end

-- Function for auto verification
local function autoVerify(ui)
    local key = loadKey()
    if key and key ~= "" then
        ui.box.Text = key -- Put key into input box
        createNotification("Auto Mode", "Auto-verifying key...", 1, "loader")
        
        -- Wait a bit for UI to load completely
        task.wait(1)
        
        -- Call key validation function
        pulse(ui.verify) -- Button pulse effect
        return validateKey(ui)
    else
        createNotification("No Key Found", "No saved key found. Please enter key manually", 3, "exclamation")
        return false
    end
end

-- Main function
local function main()
    if getgenv().JunkieUILoaded then return end -- Prevent duplicate loading
    getgenv().JunkieUILoaded = true
    
    -- Pre-load WindUI for notifications
    loadWindUI()
    
    local ui = buildUI() -- Build UI
    drag(ui) -- Make draggable

    -- Key validation function
    local function validate()
        pulse(ui.verify)
        validateKey(ui)
    end

    -- Verify button click
    ui.verify.MouseButton1Click:Connect(function()
        validate()
    end)

    -- Enter key in input box
    ui.box.FocusLost:Connect(function(enter) 
        if enter then -- If Enter was pressed
            validate()
        end 
    end)

    -- Get Key button click
    ui.getKey.MouseButton1Click:Connect(function()
        pulse(ui.getKey)
        createNotification("Getting Key...", "Generating key link...", 2, "key")
        
        local success, sdk = pcall(function()
            return loadstring(game:HttpGet("https://junkie-development.de/sdk/JunkieKeySystem.lua"))()
        end)
        
        if success then
            local link = sdk.getLink(cfg.api, cfg.provider, cfg.service)
            if link and setclipboard then
                setclipboard(link) -- Copy link
                createNotification("Link Copied", "Key link copied to clipboard", 3, "clipboard")
            else
                createNotification("Failed", "Unable to generate key link", 2, "x")
            end
        else
            createNotification("Error", "Failed to load SDK. Please try again", 3, "exclamation")
        end
    end)

    -- Close button click
    ui.close.MouseButton1Click:Connect(function()
        createNotification("Closing...", "See you next time!", 2, "heart")
        TweenService:Create(ui.main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.5, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.4)
        ui.gui:Destroy()
    end)

    -- Effects when input box is focused
    ui.box.Focused:Connect(function()
        TweenService:Create(ui.box.Parent, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(ui.box.Parent.UIStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
    end)

    ui.box.FocusLost:Connect(function()
        TweenService:Create(ui.box.Parent, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(ui.box.Parent.UIStroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
    end)

    -- Hover effects for buttons
    for _, btn in ipairs({ui.verify, ui.getKey}) do
        btn.MouseEnter:Connect(function()
            local orig = btn.BackgroundColor3
            local bright = Color3.new(
                math.min(orig.R*1.25, 1),
                math.min(orig.G*1.25, 1),
                math.min(orig.B*1.25, 1)
            )
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = bright}):Play()
        end)
        btn.MouseLeave:Connect(function()
            local orig = btn.BackgroundColor3
            local dim = Color3.new(orig.R/1.25, orig.G/1.25, orig.B/1.25)
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = dim}):Play()
        end)
    end

    -- If auto mode is enabled, verify automatically
    if autokey then
        task.wait(0.5) -- Wait for UI to load
        autoVerify(ui)
    end
end

-- Start program
main()
