-- สคริปต์แถบแจ้งเตือนสไตล์ Demon Slayer แบบเรียบง่าย
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DemonSlayerNotifications"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- คลังเก็บการแจ้งเตือน
local notifications = {}
local MAX_NOTIFICATIONS = 3
local NOTIFICATION_HEIGHT = 60  -- ลดความสูงลง
local SPACING = 5  -- ลดระยะห่างลง

-- ฟอนต์สวยๆ สไตล์ Demon Slayer
local FONT = Enum.Font.FredokaOne
local TEXT_COLOR = Color3.fromRGB(255, 245, 245)
local ACCENT_COLOR = Color3.fromRGB(220, 20, 60) -- สีแดงเลือด
local BG_COLOR = Color3.fromRGB(15, 5, 25) -- สีม่วงเข้ม
local BORDER_COLOR = Color3.fromRGB(120, 10, 50)

-- ฟังก์ชันอัพเดทตำแหน่งการแจ้งเตือนทั้งหมด
function updateAllPositions()
    for i, notification in ipairs(notifications) do
        local targetY = 0.02 + (i - 1) * (NOTIFICATION_HEIGHT + SPACING) / 500  -- ปรับตำแหน่งเริ่มต้นให้สูงขึ้น
        local slideUp = TweenService:Create(
            notification.Frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -15, targetY, 0)}  -- ลดระยะห่างจากขอบ
        )
        slideUp:Play()
    end
end

-- ฟังก์ชันสร้างแถบแจ้งเตือน
function createNotification(title, subtitle, duration, showProgress)
    duration = duration or 4
    subtitle = subtitle or "✓ ระบบพร้อมใช้งาน"
    showProgress = showProgress or false
    
    -- ถ้ามีการแจ้งเตือนครบ 3 อันแล้ว ให้ลบอันล่างสุด
    if #notifications >= MAX_NOTIFICATIONS then
        local oldestNotification = table.remove(notifications, 1)
        if oldestNotification then
            local slideOut = TweenService:Create(
                oldestNotification.Frame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 20, oldestNotification.Frame.Position.Y.Scale, 0)}
            )
            slideOut:Play()
            slideOut.Completed:Connect(function()
                oldestNotification.Frame:Destroy()
            end)
        end
    end
    
    -- สร้างเฟรมหลัก
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification"
    notificationFrame.Size = UDim2.new(0, 260, 0, NOTIFICATION_HEIGHT)  -- ลดความกว้างลง
    notificationFrame.Position = UDim2.new(1, 20, 0.02, 0)  -- ปรับตำแหน่งเริ่มต้น
    notificationFrame.AnchorPoint = Vector2.new(1, 0)
    notificationFrame.BackgroundColor3 = BG_COLOR
    notificationFrame.BackgroundTransparency = 0.05
    notificationFrame.BorderSizePixel = 0
    notificationFrame.ClipsDescendants = true
    notificationFrame.Parent = gui
    
    -- ขอบเอฟเฟกต์
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 3)  -- ลดความโค้งมุม
    borderCorner.Parent = notificationFrame
    
    local borderStroke = Instance.new("UIStroke")
    borderStroke.Color = BORDER_COLOR
    borderStroke.Thickness = 1.5  -- ลดความหนาลง
    borderStroke.Parent = notificationFrame
    
    -- เอฟเฟกต์แสงด้านใน
    local innerGlow = Instance.new("Frame")
    innerGlow.Name = "InnerGlow"
    innerGlow.Size = UDim2.new(1, -4, 1, -4)
    innerGlow.Position = UDim2.new(0, 2, 0, 2)
    innerGlow.BackgroundTransparency = 1
    innerGlow.BorderSizePixel = 0
    innerGlow.Parent = notificationFrame
    
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(255, 100, 130)
    innerStroke.Thickness = 0.8  -- ลดความหนาลง
    innerStroke.Transparency = 0.7
    innerStroke.Parent = innerGlow
    
    -- ไอคอนด้านซ้าย (สัญลักษณ์ดาบ)
    local iconContainer = Instance.new("Frame")
    iconContainer.Name = "IconContainer"
    iconContainer.Size = UDim2.new(0, 30, 1, -12)  -- ลดขนาดลง
    iconContainer.Position = UDim2.new(0, 6, 0, 6)  -- ปรับตำแหน่ง
    iconContainer.BackgroundTransparency = 1
    iconContainer.Parent = notificationFrame
    
    local swordIcon = Instance.new("ImageLabel")
    swordIcon.Name = "SwordIcon"
    swordIcon.Size = UDim2.new(1, 0, 1, 0)
    swordIcon.BackgroundTransparency = 1
    swordIcon.Image = "http://www.roblox.com/asset/?id=6031075938" -- ไอคอนดาบ
    swordIcon.ImageColor3 = ACCENT_COLOR
    swordIcon.ScaleType = Enum.ScaleType.Fit
    swordIcon.Parent = iconContainer
    
    -- พื้นที่ข้อความ
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -45, 1, -12)  -- ปรับขนาด
    textContainer.Position = UDim2.new(0, 40, 0, 6)  -- ปรับตำแหน่ง
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = notificationFrame
    
    -- ข้อความหลัก (Title)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = TEXT_COLOR
    titleLabel.TextScaled = false
    titleLabel.TextSize = 22  -- กำหนดขนาดฟอนต์คงที่
    titleLabel.Font = FONT
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    titleLabel.Parent = textContainer
    
    -- ข้อความรอง (Subtitle)
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitleLabel.TextScaled = false
    subtitleLabel.TextSize = 16  -- ขนาดฟอนต์เล็กกว่า
    subtitleLabel.TextTransparency = 0.2
    subtitleLabel.Font = Enum.Font.GothamMedium
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextYAlignment = Enum.TextYAlignment.Top
    subtitleLabel.Parent = textContainer
    
    -- แถบเวลา (แสดงเฉพาะเมื่อต้องการ)
    local timeBar = Instance.new("Frame")
    timeBar.Name = "TimeBar"
    timeBar.Size = UDim2.new(0, 0, 0, 2)
    timeBar.Position = UDim2.new(0, 0, 1, -2)
    timeBar.BackgroundColor3 = ACCENT_COLOR
    timeBar.BorderSizePixel = 0
    timeBar.Visible = showProgress
    timeBar.Parent = notificationFrame
    
    local timeBarCorner = Instance.new("UICorner")
    timeBarCorner.CornerRadius = UDim.new(0, 1)
    timeBarCorner.Parent = timeBar
    
    -- เพิ่มการแจ้งเตือนลงในคลัง
    local notificationData = {
        Frame = notificationFrame,
        Created = tick(),
        TimeBar = timeBar,
        ShowProgress = showProgress
    }
    table.insert(notifications, notificationData)
    
    -- อนิเมชันแสดงแถบแจ้งเตือน
    local slideIn = TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1),
        {Position = UDim2.new(1, -15, 0.02, 0)}  -- ปรับตำแหน่งสุดท้าย
    )
    
    slideIn:Play()
    
    -- อัพเดทตำแหน่งทั้งหมด
    updateAllPositions()
    
    -- เริ่มนับเวลา
    local startTime = tick()
    local connection
    
    if showProgress then
        -- แอนิเมชันแถบเวลา
        local timeTween = TweenService:Create(
            timeBar,
            TweenInfo.new(duration - 0.5, Enum.EasingStyle.Linear),
            {Size = UDim2.new(1, 0, 0, 2)}
        )
        timeTween:Play()
    end
    
    -- เชื่อมต่ออัพเดทแถบเวลา
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        
        if progress >= 1 then
            connection:Disconnect()
            
            -- ลบการแจ้งเตือนออกจากคลัง
            for i, notif in ipairs(notifications) do
                if notif.Frame == notificationFrame then
                    table.remove(notifications, i)
                    break
                end
            end
            
            -- อนิเมชันซ่อนแถบแจ้งเตือน
            local slideOut = TweenService:Create(
                notificationFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {
                    Position = UDim2.new(1, 20, notificationFrame.Position.Y.Scale, 0),
                    BackgroundTransparency = 1
                }
            )
            
            local textFade = TweenService:Create(
                titleLabel,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad),
                {TextTransparency = 1}
            )
            
            local subtitleFade = TweenService:Create(
                subtitleLabel,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad),
                {TextTransparency = 1}
            )
            
            slideOut:Play()
            textFade:Play()
            subtitleFade:Play()
            
            slideOut.Completed:Connect(function()
                notificationFrame:Destroy()
                updateAllPositions()
            end)
        end
    end)
    
    return notificationData
end

-- ฟังก์ชันอัพเดท subtitle
function updateSubtitle(notificationData, newSubtitle)
    if notificationData and notificationData.Frame and notificationData.Frame:FindFirstChild("TextContainer") then
        local textContainer = notificationData.Frame.TextContainer
        if textContainer:FindFirstChild("Subtitle") then
            textContainer.Subtitle.Text = newSubtitle
        end
    end
end

-- ฟังก์ชันเรียกใช้งานหลัก
function showNotification(title, subtitle, duration, showProgress)
    return createNotification(title, subtitle, duration, showProgress)
end

-- ฟังก์ชันล้างการแจ้งเตือนทั้งหมด
function clearAllNotifications()
    for _, notification in ipairs(notifications) do
        notification.Frame:Destroy()
    end
    notifications = {}
end

-- ระบบ Debug รอแมพโหลด
function waitForMapLoad()
    local debugNotification = showNotification(
        "ระบบกำลังโหลดแมพ", 
        "⏳ รอแมพโหลด...", 
        999,  -- ระยะเวลานานมาก
        true  -- แสดงแถบความคืบหน้า
    )
    
    -- จำลองการรอแมพโหลด (ในความเป็นจริงคุณจะตรวจสอบเมื่อแมพโหลดเสร็จ)
    local counter = 0
    local maxWaitTime = 10 -- รอสูงสุด 10 วินาที
    
    local checkConnection
    checkConnection = RunService.Heartbeat:Connect(function()
        counter = counter + 0.1
        
        -- อัพเดทสถานะ
        if counter < 3 then
            updateSubtitle(debugNotification, "🔍 กำลังสแกนแมพ...")
        elseif counter < 6 then
            updateSubtitle(debugNotification, "📦 โหลดทรัพยากร...")
        elseif counter < 8 then
            updateSubtitle(debugNotification, "⚡ จัดเตรียมระบบ...")
        else
            updateSubtitle(debugNotification, "✅ โหลดเสร็จเกือบหมด...")
        end
        
        -- ตรวจสอบว่าแมพโหลดเสร็จหรือยัง (นี่คือตัวอย่าง, ปรับตามความต้องการจริง)
        local workspaceLoaded = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Terrain")
        
        if workspaceLoaded or counter >= maxWaitTime then
            checkConnection:Disconnect()
            
            -- อัพเดทเป็นการแจ้งเตือนสำเร็จ
            updateSubtitle(debugNotification, "✅ โหลดแมพเสร็จสิ้น!")
            
            -- รอสักครู่แล้วปิดการแจ้งเตือน debug
            wait(2)
            
            -- ลบการแจ้งเตือน debug ออกจากคลัง
            for i, notif in ipairs(notifications) do
                if notif == debugNotification then
                    table.remove(notifications, i)
                    break
                end
            end
            
            -- ซ่อนการแจ้งเตือน debug
            local slideOut = TweenService:Create(
                debugNotification.Frame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {
                    Position = UDim2.new(1, 20, debugNotification.Frame.Position.Y.Scale, 0),
                    BackgroundTransparency = 1
                }
            )
            
            slideOut:Play()
            slideOut.Completed:Connect(function()
                debugNotification.Frame:Destroy()
                updateAllPositions()
                
                -- แสดงการแจ้งเตือนสำเร็จ
                showNotification("SUNBREATH", "กด X ระหว่างล็อคศัตรู✓", 5)
            end)
        end
    end)
end

-- ตัวอย่างการใช้งาน
wait(1)
showNotification("สคริปต์เริ่มทำงานแล้ว!", "✓ ระบบพร้อมใช้งาน", 2)
wait(1.5)
showNotification("ระบบกำลังโหลดข้อมูล", "📊 โหลดข้อมูลผู้เล่น...", 3)
wait(1.2)

-- เริ่มต้นระบบ Debug รอแมพโหลด
waitForMapLoad()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- ฟังก์ชันหาผู้เล่นที่ใกล้ที่สุดในทิศทางที่หันหน้าไป
function findClosestPlayerInFront()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local maxAngle = 45 -- มุมสูงสุด 45 องศาจากทิศทางที่หันหน้า
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local camera = workspace.CurrentCamera
    local cameraDirection = camera.CFrame.LookVector
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                -- คำนวณระยะทางและทิศทาง
                local directionToTarget = (targetHRP.Position - humanoidRootPart.Position)
                local distance = directionToTarget.Magnitude
                directionToTarget = directionToTarget.Unit
                
                -- คำนวณมุมระหว่างทิศทางที่หันหน้ากับทิศทางไปยังผู้เล่น
                local dotProduct = cameraDirection:Dot(directionToTarget)
                local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))
                
                -- ตรวจสอบว่าผู้เล่นอยู่ในมุมที่กำหนดและอยู่ในระยะที่เหมาะสม
                if angle <= maxAngle and distance < shortestDistance and distance < 50 then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- ฟังก์ชันโจมตี 100 ครั้งทันที
function rapidAttack100()
    local targetPlayer = findClosestPlayerInFront()
    
    if targetPlayer and targetPlayer.Character then
        print("เริ่มโจมตี " .. targetPlayer.Name .. " 100 ครั้งทันที!")
        
        -- โจมตี 100 ครั้งแบบไม่รอ
        for i = 1, 1000 do
            -- โจมตีครั้งที่ 1: ใช้ MoveService
            local args1 = {
                "UnknowningFire",
                "Activated",
                targetPlayer.Character
            }
            
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveService"):WaitForChild("RE"):WaitForChild("UseMove"):FireServer(unpack(args1))
            end)
            
            -- โจมตีครั้งที่ 2: ใช้ UnknowningFireService
            local args2 = {
                targetPlayer.Character
            }
            
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("UnknowningFireService"):WaitForChild("RE"):WaitForChild("Hit"):FireServer(unpack(args2))
            end)
        end
        
        print("โจมตีครบ 100 ครั้งแล้ว!")
    else
        warn("ไม่พบผู้เล่นเป้าหมายในทิศทางที่หันหน้าไป")
    end
end

-- ระบบกดปุ่ม
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        rapidAttack100()
    end
end)

-- การเชื่อมต่อ Event สำหรับเมื่อ Character เกิดใหม่
localPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

print("พร้อมใช้งาน! กดปุ่ม X เพื่อโจมตีเป้าหมายที่อยู่ข้างหน้า 100 ครั้งทันที")

local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("HUD")
local moves = hud:WaitForChild("Moves")
local list = moves:WaitForChild("List")
local unknowningFire = list:WaitForChild("UnknowningFire")

-- Clone
local clone = unknowningFire:Clone()

-- เปลี่ยนชื่อและข้อความ
clone.Name = "Sunbreating"
clone.Frame.move_name.Text = "Sunbreating"
clone.Frame.key.Text = "X"
-- วางในตำแหน่งเดิม
clone.Parent = list

return {
    ShowNotification = showNotification,
    ClearAll = clearAllNotifications,
    UpdateSubtitle = updateSubtitle,
    WaitForMapLoad = waitForMapLoad
}
