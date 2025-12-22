local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variables
local AutoRobEnabled = false
local CurrentATM = nil
local MoneyEarned = 0
local LastCashValue = LocalPlayer.leaderstats.Cash.Value
local DropOffPoint = Workspace.Game.Jobs.CriminalDropOffSpawners.CriminalDropOffSpawnerPermanent
local DropOffArea = nil

-- Security System Variables
local SecurityTeam = Teams.Security
local PoliceTeam = Teams.Security
local SECURITY_CHECK_RADIUS = 50 -- ระยะตรวจจับ Security
local ESCAPE_COOLDOWN = 3 -- รอ 3 วินาทีก่อนกลับมา
local isEscaping = false -- สถานะกำลังหลบหนี
local lastEscapeTime = 0 -- เวลาล่าสุดที่หลบหนี
local ShouldStopMovement = false -- Flag to stop all movement

local Window = WindUI:CreateWindow({
    Title = "GRIMM Hub - Auto Rob      ",
    Icon = "shield",
    Author = "by SORNOR",
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    Transparent = true,
})

-- Create Tabs
local Tab = Window:Tab({
    Title = "Auto Rob",
    Icon = "shield",
    Locked = false,
})
Tab:Select()

-- Create Section
local Section = Tab:Section({ 
    Title = "ATM Robbing System",
})

-- หา DropOffArea (บริเวณวงเงิน)
local function FindDropOffArea()
    -- หาจาก CollectionService
    for _, area in pairs(CollectionService:GetTagged("CriminalDropOff")) do
        if area:IsA("BasePart") then
            return area
        end
    end
    
    -- หาจาก Workspace
    for _, child in pairs(Workspace:GetDescendants()) do
        if child.Name == "CriminalDropOff" and child:IsA("BasePart") then
            return child
        end
    end
    
    -- หากไม่เจอ ให้ใช้พื้นที่รอบๆ DropOffPoint
    return DropOffPoint
end

-- Tween function for smooth movement
local function TweenToPosition(character, targetPosition, duration)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local hrp = character.HumanoidRootPart
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    -- Create tween
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    
    -- Start tween
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Wait()
    
    return tween
end

-- เรียกหา DropOffArea เริ่มต้น
DropOffArea = FindDropOffArea()

-- ฟังก์ชันตรวจสอบว่าเป็น Security หรือ Police
local function isSecurityPlayer(player)
    return player and (player.Team == SecurityTeam or player.Team == PoliceTeam)
end

-- ฟังก์ชันตรวจสอบมี Security ในรัศมีหรือไม่
local function checkSecurityInRange()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local playerPos = Character.HumanoidRootPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        -- ข้ามตัวผู้เล่นเอง
        if player ~= LocalPlayer then
            -- ตรวจสอบว่าเป็น Security หรือ Police
            if isSecurityPlayer(player) then
                local targetChar = player.Character
                if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                    local targetPos = targetChar.HumanoidRootPart.Position
                    local distance = (playerPos - targetPos).Magnitude
                    
                    if distance <= SECURITY_CHECK_RADIUS then
                        -- ตรวจสอบว่า Security ยังมีชีวิตอยู่
                        local humanoid = targetChar:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            return true, player
                        end
                    end
                end
            end
        end
    end
    
    return false, nil
end

-- ฟังก์ชันหลบหนีไปส่งเงิน
local function escapeToDropOff()
    if isEscaping then return end
    
    isEscaping = true
    ShouldStopMovement = true
    
    -- บันทึกตำแหน่งปัจจุบันเพื่อกลับมา
    local returnPosition = nil
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        returnPosition = Character.HumanoidRootPart.Position
    end
    
    -- หา DropOffArea
    local currentDropOffArea = FindDropOffArea()
    
    -- แจ้งเตือน
    WindUI:Notify({
        Title = "⚠️ Security Detected!",
        Content = "กำลังหลบหนีไปส่งเงิน...",
        Duration = 2,
        Icon = "alert-triangle",
    })
    
    -- หยุดการปล้น ATM
    CurrentATM = nil
    
    -- Cleanup function
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        -- Stop movement
        Character.HumanoidRootPart.Velocity = Vector3.zero
        Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
        
        -- สร้างจุดเริ่มต้น (ห่างจากจุดส่งเงิน 10 studs)
        local angle = math.random() * 2 * math.pi
        local distance = 10
        local startPosition
        
        if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
            startPosition = currentDropOffArea.Position + Vector3.new(
                math.cos(angle) * distance,
                0,
                math.sin(angle) * distance
            )
        else
            startPosition = DropOffPoint.Position + Vector3.new(
                math.cos(angle) * distance,
                0,
                math.sin(angle) * distance
            )
        end
        
        -- วาปไปยังจุดเริ่มต้น
        Character:PivotTo(CFrame.new(startPosition))
        task.wait(0.5)
        
        -- Destroy money bags
        for _, bag in pairs(CollectionService:GetTagged("CriminalMoneyBagTool")) do
            bag:Destroy()
            task.wait(0.1)
        end
        
        -- Tween เข้าไปยังจุดส่งเงิน
        local targetPosition
        if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
            targetPosition = currentDropOffArea.Position + Vector3.new(0, 2, 0)
        else
            targetPosition = DropOffPoint.Position
        end
        
        WindUI:Notify({
            Title = "กำลังส่งเงิน",
            Content = "เคลื่อนที่ไปยังจุดส่งเงิน...",
            Duration = 2,
            Icon = "arrow-right",
        })
        
        -- ใช้ Tween เคลื่อนที่ไปยังจุดส่งเงิน
        local tween = TweenToPosition(Character, targetPosition, 1.5)
        
        task.wait(0.5)
        
        -- รออยู่ที่จุดส่งเงินสักพัก
        local waitStartTime = tick()
        local waitDuration = 3 -- รอ 3 วินาที
        
        WindUI:Notify({
            Title = "ส่งเงิน",
            Content = "รออยู่ที่จุดส่งเงิน...",
            Duration = waitDuration,
            Icon = "clock",
        })
        
        while tick() - waitStartTime < waitDuration do
            task.wait(0.1)
        end
    end
    
    CurrentATM = nil
    
    -- รอสักครู่หลังจากส่งเงิน
    task.wait(1)
    
    -- ถ้ามีตำแหน่งที่ต้องกลับไป
    if returnPosition and AutoRobEnabled then
        WindUI:Notify({
            Title = "กำลังกลับ",
            Content = "รอ " .. ESCAPE_COOLDOWN .. " วินาที...",
            Duration = ESCAPE_COOLDOWN,
            Icon = "clock",
        })
        
        -- รอตามเวลาที่กำหนด
        local waitStart = tick()
        while tick() - waitStart < ESCAPE_COOLDOWN do
            if not AutoRobEnabled then
                break
            end
            task.wait(0.1)
        end
        
        if AutoRobEnabled then
            -- กลับไปยังตำแหน่งเดิม
            WindUI:Notify({
                Title = "กลับไปทำภารกิจ",
                Content = "กำลังกลับไปตำแหน่งเดิม...",
                Duration = 2,
                Icon = "arrow-left",
            })
            
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                -- วาปกลับไปตำแหน่งเดิม (เพิ่มความสูงเล็กน้อย)
                local returnPosWithHeight = Vector3.new(
                    returnPosition.X,
                    returnPosition.Y + 5,
                    returnPosition.Z
                )
                
                Character:PivotTo(CFrame.new(returnPosWithHeight))
                task.wait(0.5)
            end
        end
    end
    
    -- รีเซ็ตสถานะ
    isEscaping = false
    ShouldStopMovement = false
    lastEscapeTime = tick()
    
    if AutoRobEnabled then
        WindUI:Notify({
            Title = "พร้อมทำงาน",
            Content = "ระบบ Auto Rob พร้อมทำงานอีกครั้ง",
            Duration = 2,
            Icon = "check",
        })
    end
end

-- ฟังก์ชันตรวจจับ Security ตลอดเวลา
task.spawn(function()
    while true do
        task.wait(1) -- ตรวจสอบทุก 1 วินาที
        
        if AutoRobEnabled and not isEscaping and not ShouldStopMovement then
            local securityDetected, securityPlayer = checkSecurityInRange()
            
            if securityDetected then
                -- ตรวจสอบว่าไม่ได้หลบหนีไปนานแล้ว
                if tick() - lastEscapeTime > 10 then
                    WindUI:Notify({
                        Title = "Security Found!",
                        Content = "ตรวจจับ " .. securityPlayer.Name .. " ในระยะใกล้",
                        Duration = 2,
                        Icon = "user-check",
                    })
                    
                    -- เริ่มหลบหนี
                    escapeToDropOff()
                end
            end
        end
    end
end)

-- Toggle for Auto Rob
local AutoRobToggle = Section:Toggle({
    Title = "Auto Rob ATMs",
    Desc = "Enable automatic ATM robbing",
    Icon = "shield",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        AutoRobEnabled = state
        ShouldStopMovement = false -- Reset stop flag
        
        if state then
            WindUI:Notify({
                Title = "Auto Rob",
                Content = "ATM robbing system ENABLED",
                Duration = 2,
                Icon = "check",
            })
        else
            -- Set flag to stop all movement immediately
            ShouldStopMovement = true
            isEscaping = false
            
            -- Teleport และรออยู่ที่จุดส่งเงิน
            task.spawn(function()
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    -- หา DropOffArea อีกรอบ
                    local currentDropOffArea = FindDropOffArea()
                    
                    -- Stop any movement
                    Character.HumanoidRootPart.Velocity = Vector3.zero
                    Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                    
                    -- แจ้งเตือน
                    WindUI:Notify({
                        Title = "Auto Rob",
                        Content = "กำลังส่งเงินที่: " .. tostring(DropOffPoint.Position),
                        Duration = 3,
                        Icon = "map-pin",
                    })
                    
                    -- สร้างจุดเริ่มต้น (ห่างจากจุดส่งเงิน 10 studs)
                    local startPosition
                    if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                        -- หาจุดเริ่มต้นด้านนอกวงเงิน
                        local angle = math.random() * 2 * math.pi
                        local distance = 10
                        startPosition = currentDropOffArea.Position + Vector3.new(
                            math.cos(angle) * distance,
                            0,
                            math.sin(angle) * distance
                        )
                    else
                        -- หาจุดเริ่มต้นห่างจาก DropOffPoint
                        local angle = math.random() * 2 * math.pi
                        local distance = 10
                        startPosition = DropOffPoint.Position + Vector3.new(
                            math.cos(angle) * distance,
                            0,
                            math.sin(angle) * distance
                        )
                    end
                    
                    -- วาปไปยังจุดเริ่มต้น
                    Character:PivotTo(CFrame.new(startPosition))
                    task.wait(0.5)
                    
                    -- ทำความสะอาดกระเป๋าเงิน
                    for _, bag in pairs(CollectionService:GetTagged("CriminalMoneyBagTool")) do
                        bag:Destroy()
                        task.wait(0.1)
                    end
                    
                    -- Tween เข้าไปยังจุดส่งเงิน (ถ้าบริเวณวงเงินมีขนาดใหญ่)
                    local targetPosition
                    if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                        targetPosition = currentDropOffArea.Position + Vector3.new(0, 2, 0)
                    else
                        targetPosition = DropOffPoint.Position
                    end
                    
                    WindUI:Notify({
                        Title = "กำลังส่งเงิน",
                        Content = "เคลื่อนที่ไปยังจุดส่งเงิน...",
                        Duration = 2,
                        Icon = "arrow-right",
                    })
                    
                    -- ใช้ Tween เคลื่อนที่ไปยังจุดส่งเงิน
                    local tween = TweenToPosition(Character, targetPosition, 1.5)
                    
                    task.wait(0.5)
                    
                    -- รออยู่ที่จุดส่งเงินสักพัก
                    local waitStartTime = tick()
                    local waitDuration = 1
                    
                    WindUI:Notify({
                        Title = "ส่งเงิน",
                        Content = "รออยู่ที่จุดส่งเงิน...",
                        Duration = waitDuration,
                        Icon = "clock",
                    })
                    
                    while tick() - waitStartTime < waitDuration do
                        -- เพียงยืนนิ่งๆ อยู่ที่จุดส่งเงิน
                        task.wait(0.1)
                    end
                    
                    WindUI:Notify({
                        Title = "ส่งเงินเสร็จสิ้น",
                        Content = "ส่งเงินเรียบร้อยแล้ว",
                        Duration = 2,
                        Icon = "check",
                    })
                end
                
                CurrentATM = nil
            end)
            
            WindUI:Notify({
                Title = "Auto Rob",
                Content = "ATM robbing system DISABLED",
                Duration = 2,
                Icon = "x",
            })
        end
    end
})

-- Track money earned
LocalPlayer.leaderstats.Cash:GetPropertyChangedSignal("Value"):Connect(function()
    local currentCash = LocalPlayer.leaderstats.Cash.Value
    local cashDifference = currentCash - LastCashValue
    
    if cashDifference > 0 then
        MoneyEarned = MoneyEarned + cashDifference
        
        if cashDifference > 1000 then
            WindUI:Notify({
                Title = "💰 Money Earned!",
                Content = "Gained $" .. cashDifference .. " from ATMs",
                Duration = 3,
                Icon = "dollar-sign",
            })
        end
    end
    
    LastCashValue = currentCash
end)

-- Safe wait function that checks AutoRobEnabled
local function SafeWait(seconds)
    local startTime = tick()
    while tick() - startTime < seconds do
        if not AutoRobEnabled or ShouldStopMovement or isEscaping then
            return false
        end
        task.wait(0.1)
    end
    return true
end

-- Main Rob ATM function
local function RobATM(atm)
    if not AutoRobEnabled or ShouldStopMovement or isEscaping then
        return false
    end
    
    -- ตรวจสอบ Security ก่อนทำการปล้น
    local securityDetected = checkSecurityInRange()
    if securityDetected then
        WindUI:Notify({
            Title = "หยุดการปล้น",
            Content = "มี Security อยู่ในบริเวณใกล้เคียง",
            Duration = 2,
            Icon = "shield",
        })
        return false
    end
    
    if atm:GetAttribute("State") == "Busted" then
        return false
    end
    
    CurrentATM = atm
    
    -- Teleport to ATM
    if not SafeWait(1) then return false end
    
    -- ตรวจสอบ Security อีกครั้งก่อนวาป
    if checkSecurityInRange() then
        return false
    end
    
    if Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.Velocity = Vector3.zero
        Character:PivotTo(atm.WorldPivot + Vector3.new(0, 5, 0))
        LocalPlayer.ReplicationFocus = nil
    end
    
    if not AutoRobEnabled or ShouldStopMovement or isEscaping then return false end
    
    -- ตรวจสอบ Security ระหว่างทำการปล้น
    for i = 1, 6 do
        if checkSecurityInRange() then
            WindUI:Notify({
                Title = "หยุดกลางคัน!",
                Content = "Security เข้ามาในพื้นที่",
                Duration = 2,
                Icon = "alert-circle",
            })
            return false
        end
        task.wait(1)
    end
    
    -- Start bust
    ReplicatedStorage.Remotes.AttemptATMBustStart:InvokeServer(atm)
    
    if not SafeWait(2.5) then return false end
    
    -- ตรวจสอบ Security ระหว่างรอ
    if checkSecurityInRange() then
        return false
    end
    
    if not AutoRobEnabled or ShouldStopMovement or isEscaping then return false end
    
    -- Complete bust
    ReplicatedStorage.Remotes.AttemptATMBustComplete:InvokeServer(atm)
    
    if not SafeWait(3) then return false end
    
    CurrentATM = nil
    return true
end

-- Find and rob ATMs
local function FindAndRobATM()
    if not AutoRobEnabled or ShouldStopMovement or isEscaping then return end
    
    for _, atm in pairs(CollectionService:GetTagged("CriminalATM")) do
        if AutoRobEnabled and not ShouldStopMovement and not isEscaping and atm:GetAttribute("State") ~= "Busted" then
            local success = RobATM(atm)
            if success then
                WindUI:Notify({
                    Title = "ATM Robbed",
                    Content = "Successfully robbed an ATM",
                    Duration = 2,
                    Icon = "check",
                })
            end
            if not AutoRobEnabled or ShouldStopMovement or isEscaping then break end
        end
    end
    
    if not AutoRobEnabled or ShouldStopMovement or isEscaping then return end
    
    for _, atm in pairs(game:GetService("NilService"):GetNilInstances()) do
        if atm.Name == "CriminalATM" and AutoRobEnabled and not ShouldStopMovement and not isEscaping and atm:GetAttribute("State") ~= "Busted" then
            local success = RobATM(atm)
            if success then
                WindUI:Notify({
                    Title = "ATM Robbed",
                    Content = "Successfully robbed a hidden ATM",
                    Duration = 2,
                    Icon = "check",
                })
            end
            if not AutoRobEnabled or ShouldStopMovement or isEscaping then break end
        end
    end
end

-- Load new ATMs
local ATMLoaderCooldown = false
local function LoadNewATMs()
    if ATMLoaderCooldown or not AutoRobEnabled or ShouldStopMovement or isEscaping then return end
    
    ATMLoaderCooldown = true
    
    task.spawn(function()
        for _, spawner in pairs(Workspace.Game.Jobs.CriminalATMSpawners:GetChildren()) do
            if not AutoRobEnabled or ShouldStopMovement or isEscaping then break end
            LocalPlayer.ReplicationFocus = spawner
            if not SafeWait(1) then break end
        end
        
        for _, spawner in pairs(game:GetService("NilService"):GetNilInstances()) do
            if spawner.Name == "CriminalATMSpawner" and AutoRobEnabled and not ShouldStopMovement and not isEscaping then
                LocalPlayer.ReplicationFocus = spawner
                if not SafeWait(1) then break end
            end
        end
        
        LocalPlayer.ReplicationFocus = nil
        ATMLoaderCooldown = false
    end)
end

-- Main loop for auto robbing
task.spawn(function()
    while task.wait(1) do
        if AutoRobEnabled and not ShouldStopMovement and not isEscaping then
            pcall(function()
                FindAndRobATM()
                
                if not ATMLoaderCooldown and not CurrentATM and not ShouldStopMovement and not isEscaping then
                    LoadNewATMs()
                end
            end)
        end
    end
end)

-- Anti-AFK system
LocalPlayer.Idled:Connect(function()
    WindUI:Notify({
        Title = "Anti-AFK",
        Content = "Anti-AFK activated to prevent kicking",
        Duration = 2,
        Icon = "shield",
    })
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- Character handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    task.wait(2)
    
    -- หา DropOffArea ใหม่เมื่อเปลี่ยนตัวละคร
    DropOffArea = FindDropOffArea()
    
    -- รีเซ็ตสถานะหลบหนี
    isEscaping = false
    ShouldStopMovement = false
    
    if AutoRobEnabled then
        WindUI:Notify({
            Title = "Character Loaded",
            Content = "Auto Rob system resumed",
            Duration = 2,
            Icon = "check",
        })
    end
end)

-- Button to manually drop money bags
Section:Button({
    Title = "Drop Money Bags",
    Desc = "Manually drop all collected money bags",
    Icon = "package",
    Callback = function()
        ShouldStopMovement = true
        isEscaping = false
        task.wait(0.5)
        
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            -- หา DropOffArea
            local currentDropOffArea = FindDropOffArea()
            
            -- สร้างจุดเริ่มต้น (ห่างจากจุดส่งเงิน 10 studs)
            local angle = math.random() * 2 * math.pi
            local distance = 10
            local startPosition
            
            if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                startPosition = currentDropOffArea.Position + Vector3.new(
                    math.cos(angle) * distance,
                    0,
                    math.sin(angle) * distance
                )
            else
                startPosition = DropOffPoint.Position + Vector3.new(
                    math.cos(angle) * distance,
                    0,
                    math.sin(angle) * distance
                )
            end
            
            -- วาปไปยังจุดเริ่มต้น
            Character:PivotTo(CFrame.new(startPosition))
            task.wait(0.5)
            
            -- Destroy money bags
            for _, bag in pairs(CollectionService:GetTagged("CriminalMoneyBagTool")) do
                bag:Destroy()
                task.wait(0.1)
            end
            
            -- Tween เข้าไปยังจุดส่งเงิน
            local targetPosition
            if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                targetPosition = currentDropOffArea.Position + Vector3.new(0, 2, 0)
            else
                targetPosition = DropOffPoint.Position
            end
            
            WindUI:Notify({
                Title = "กำลังส่งเงิน",
                Content = "เคลื่อนที่ไปยังจุดส่งเงิน...",
                Duration = 2,
                Icon = "arrow-right",
            })
            
            -- ใช้ Tween เคลื่อนที่ไปยังจุดส่งเงิน
            local tween = TweenToPosition(Character, targetPosition, 1.5)
            
            task.wait(0.5)
            
            -- รออยู่ที่จุดส่งเงินสักพัก
            local waitStartTime = tick()
            local waitDuration = 3 -- รอ 3 วินาที
            
            WindUI:Notify({
                Title = "ส่งเงิน",
                Content = "รออยู่ที่จุดส่งเงิน...",
                Duration = waitDuration,
                Icon = "clock",
            })
            
            while tick() - waitStartTime < waitDuration do
                task.wait(0.1)
            end
        end
        
        WindUI:Notify({
            Title = "Money Dropped",
            Content = "ส่งเงินเรียบร้อยแล้ว",
            Duration = 2,
            Icon = "check",
        })
        ShouldStopMovement = false
    end
})

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local AutoHopEnabled = false
local HopCooldown = 7 -- นาที
local isHopping = false
local lastHopTime = tick() -- เปลี่ยนจาก 0 เป็น tick() เพื่อนับเวลาจากตอนนี้

-- Toggle for Auto Hop
local AutoHopToggle = Section:Toggle({
    Title = "Enable Auto Hop",
    Desc = "Automatically hop to new servers",
    Icon = "refresh-cw",
    Type = "Checkbox",
    Value = true, -- เปลี่ยนจาก true เป็น false ให้ปิดไว้ก่อน
    Callback = function(state) 
        AutoHopEnabled = state
        
        if state then
            -- รีเซ็ตเวลาเมื่อเปิด Auto Hop
            lastHopTime = tick()
            WindUI:Notify({
                Title = "Auto Hop",
                Content = "Auto Hop system ENABLED - Starting timer",
                Duration = 3,
                Icon = "check",
            })
        else
            WindUI:Notify({
                Title = "Auto Hop",
                Content = "Auto Hop system DISABLED",
                Duration = 2,
                Icon = "x",
            })
        end
    end
})

-- Slider for Minimum Time (15-30 minutes)
local HopTimeSlider = Section:Slider({
    Title = "Hop Cooldown",
    Desc = "Minimum time before hopping (minutes)",
    Icon = "clock",
    Step = 1,
    Value = {
        Min = 3,
        Max = 30,
        Default = 7,
    },
    Callback = function(value)
        HopCooldown = value
        WindUI:Notify({
            Title = "Cooldown Updated",
            Content = "Minimum time set to " .. value .. " minutes",
            Duration = 2,
            Icon = "settings",
        })
    end
})

-- Function to hop server
-- Function to hop server (แก้ไขใหม่ให้ส่งเงินก่อน hopping)
local function hopServer()
    if isHopping then return end
    
    isHopping = true
    
    -- 1. หยุด Auto Rob ก่อน
    AutoRobEnabled = false
    ShouldStopMovement = true
    isEscaping = false
    
    WindUI:Notify({
        Title = "เตรียมตัว Hopping",
        Content = "กำลังส่งเงินก่อนเปลี่ยนเซิร์ฟเวอร์...",
        Duration = 3,
        Icon = "refresh-cw",
    })
    
    -- 2. ส่งเงินก่อน hopping
    task.spawn(function()
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            -- หา DropOffArea
            local currentDropOffArea = FindDropOffArea()
            
            -- สร้างจุดเริ่มต้น (ห่างจากจุดส่งเงิน 10 studs)
            local angle = math.random() * 2 * math.pi
            local distance = 10
            local startPosition
            
            if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                startPosition = currentDropOffArea.Position + Vector3.new(
                    math.cos(angle) * distance,
                    0,
                    math.sin(angle) * distance
                )
            else
                startPosition = DropOffPoint.Position + Vector3.new(
                    math.cos(angle) * distance,
                    0,
                    math.sin(angle) * distance
                )
            end
            
            -- วาปไปยังจุดเริ่มต้น
            Character:PivotTo(CFrame.new(startPosition))
            task.wait(0.5)
            
            -- ทำลายกระเป๋าเงินทั้งหมด
            for _, bag in pairs(CollectionService:GetTagged("CriminalMoneyBagTool")) do
                bag:Destroy()
                task.wait(0.1)
            end
            
            -- Tween เข้าไปยังจุดส่งเงิน
            local targetPosition
            if currentDropOffArea and currentDropOffArea:IsA("BasePart") then
                targetPosition = currentDropOffArea.Position + Vector3.new(0, 2, 0)
            else
                targetPosition = DropOffPoint.Position
            end
            
            WindUI:Notify({
                Title = "กำลังส่งเงิน",
                Content = "ส่งเงินก่อนเปลี่ยนเซิร์ฟเวอร์...",
                Duration = 2,
                Icon = "arrow-right",
            })
            
            -- ใช้ Tween เคลื่อนที่ไปยังจุดส่งเงิน
            local tween = TweenToPosition(Character, targetPosition, 1.5)
            
            task.wait(0.5)
            
            -- รออยู่ที่จุดส่งเงินสักพัก
            local waitStartTime = tick()
            local waitDuration = 2
            
            while tick() - waitStartTime < waitDuration do
                task.wait(0.1)
            end
            
            WindUI:Notify({
                Title = "ส่งเงินเสร็จสิ้น",
                Content = "พร้อมเปลี่ยนเซิร์ฟเวอร์...",
                Duration = 2,
                Icon = "check",
            })
        end
    end)
    
    task.wait(5) -- รอให้ส่งเงินเสร็จ
    
    -- 3. เริ่มหาเซิร์ฟเวอร์ใหม่
    WindUI:Notify({
        Title = "กำลังหาเซิร์ฟเวอร์ใหม่",
        Content = "ค้นหาเซิร์ฟเวอร์ที่มีผู้เล่นน้อย...",
        Duration = 3,
        Icon = "server",
    })
    
    -- Get servers
    local success, servers = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        )
    end)
    
    if success and servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.playing ~= server.maxPlayers and server.id ~= game.JobId then
                WindUI:Notify({
                    Title = "พบเซิร์ฟเวอร์ใหม่",
                    Content = string.format("กำลังเข้าร่วม: %d/%d ผู้เล่น", server.playing, server.maxPlayers),
                    Duration = 3,
                    Icon = "arrow-right",
                })
                
                task.wait(1)
                
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                return true
            end
        end
        
        WindUI:Notify({
            Title = "ไม่พบเซิร์ฟเวอร์ที่เหมาะสม",
            Content = "ลองใหม่อีกครั้งในภายหลัง",
            Duration = 3,
            Icon = "x",
        })
    else
        WindUI:Notify({
            Title = "การเชื่อมต่อล้มเหลว",
            Content = "ไม่สามารถดึงรายการเซิร์ฟเวอร์ได้",
            Duration = 3,
            Icon = "wifi-off",
        })
    end
    
    -- ถ้า hopping ล้มเหลว ให้รีเซ็ตสถานะ
    AutoRobEnabled = AutoHopToggle.Value -- คืนค่าตาม toggle
    ShouldStopMovement = false
    isHopping = false
    
    return false
end

-- Auto hop logic (แก้ไข)
task.spawn(function()
    while true do
        task.wait(5) -- Check every 5 seconds
        
        if AutoHopEnabled and not isHopping then
            local currentTime = tick()
            local timeSinceLastHop = currentTime - lastHopTime
            
            -- แสดงเวลาที่เหลือ
            local remainingTime = math.max(0, HopCooldown * 60 - timeSinceLastHop)
            local minutes = math.floor(remainingTime / 60)
            local seconds = math.floor(remainingTime % 60)
            
            -- Check if cooldown has passed
            if timeSinceLastHop >= HopCooldown * 60 then
                WindUI:Notify({
                    Title = "Auto Hop เริ่มทำงาน",
                    Content = string.format("ครบกำหนดเวลา %d นาที", HopCooldown),
                    Duration = 3,
                    Icon = "refresh-cw",
                })
                
                lastHopTime = tick()
                hopServer()
            end
        end
    end
end)

-- Manual hop button (แก้ไข)
Section:Button({
    Title = "Hop Now",
    Desc = "ส่งเงินแล้วเปลี่ยนเซิร์ฟเวอร์ทันที",
    Icon = "refresh-cw",
    Callback = function()
        if isHopping then
            WindUI:Notify({
                Title = "กำลังดำเนินการ",
                Content = "กำลังเปลี่ยนเซิร์ฟเวอร์อยู่...",
                Duration = 2,
                Icon = "clock",
            })
            return
        end
        
        WindUI:Notify({
            Title = "เริ่ม Hopping แบบ Manual",
            Content = "จะส่งเงินก่อนเปลี่ยนเซิร์ฟเวอร์...",
            Duration = 2,
            Icon = "refresh-cw",
        })
        
        lastHopTime = tick()
        hopServer()
    end
})

-- UI button customization
Window:EditOpenButton({
    Title = "GRIMM HUB",
    Icon = "shield",
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

-- Final notification
WindUI:Notify({
    Title = "GRIMM Hub - Auto Rob",
    Content = "Auto Rob ATM system loaded successfully!",
    Duration = 4,
    Icon = "check",
})

Window:Tag({
    Title = "Premium",
    Icon = "github",
    Color = Color3.fromHex("1F1F1F"),
    Radius = 13,
})


-- Settings Tab
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

-- Security Settings
local SecuritySection = SettingsTab:Section({ 
    Title = "Security Settings",
})

SecuritySection:Slider({
    Title = "Security Detection Radius",
    Desc = "ระยะตรวจจับ Security (studs)",
    Icon = "ruler",
    Min = 10,
    Max = 100,
    Value = SECURITY_CHECK_RADIUS,
    Callback = function(value)
        SECURITY_CHECK_RADIUS = value
        WindUI:Notify({
            Title = "Security Radius Updated",
            Content = "Detection radius set to " .. value .. " studs",
            Duration = 2,
            Icon = "settings",
        })
    end
})

SecuritySection:Slider({
    Title = "Escape Cooldown",
    Desc = "เวลารอก่อนกลับมาทำงานต่อ (วินาที)",
    Icon = "clock",
    Min = 1,
    Max = 10,
    Value = ESCAPE_COOLDOWN,
    Callback = function(value)
        ESCAPE_COOLDOWN = value
        WindUI:Notify({
            Title = "Cooldown Updated",
            Content = "Escape cooldown set to " .. value .. " seconds",
            Duration = 2,
            Icon = "settings",
        })
    end
})

-- แสดงสถานะหลบหนีใน UI
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if AutoRobEnabled and isEscaping then
            -- อัพเดทปุ่ม UI แสดงสถานะหลบหนี
            local statusText = "🛡️ ESCAPING..."
            Window:EditOpenButton({
                Title = statusText,
                Icon = "shield-off",
                CornerRadius = UDim.new(0,16),
                StrokeThickness = 2,
                Color = ColorSequence.new(
                    Color3.fromHex("FF0000"), 
                    Color3.fromHex("FF4500")
                ),
                OnlyMobile = false,
                Enabled = true,
                Draggable = true,
            })
        elseif AutoRobEnabled then
            -- อัพเดทกลับไปตามปกติหลังจากหลบหนีเสร็จ
            updateUIButton()
        end
    end
end)
