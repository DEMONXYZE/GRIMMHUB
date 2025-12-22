local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local Tab = Window:Tab({
    Title = "Mains",
    Icon = "bird",
    Locked = false,
})
Tab:Select()

local Section = Tab:Section({ 
    Title = "Combat Tab",
})

local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local attackCount = 100
local isSunbreathingEnabled = false
local excludedPlayers = {}
local SAFE_DISTANCE = 15

local lastTargetCheck = 0
local targetCheckCooldown = 0.2
local cachedTarget = nil
local lastExclusionCheck = 0
local exclusionCheckCooldown = 0.3

function refreshPlayerList()
    local playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    return playerNames
end

local Slider = Tab:Slider({
    Title = "Attack Settings",
    Desc = "Adjust number of flame breathing attacks",
    Step = 1,
    Value = {
        Min = 1,
        Max = 500,
        Default = 100,
    },
    Callback = function(AmountFlame)
        attackCount = math.floor(AmountFlame)
    end
})

local Toggle = Tab:Toggle({
    Title = "Sun Breathing",
    Desc = "Enable neck slash function, press X when targeting enemy",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        isSunbreathingEnabled = state
        WindUI:Notify({
            Title = "Sun Breathing",
            Content = state and "ENABLED - Press X when targeting enemy" or "DISABLED",
            Duration = 1,
            Icon = state and "sun" or "moon",
        })
    end
})

local skillAmount = 10
local systemEnabled = true
local canExecute = true
local cooldown = 0.0001

local function getNearbyTargets(range)
    local nearbyTargets = {}
    local character = localPlayer.Character
    if not character then return nearbyTargets end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nearbyTargets end
    
    -- ตรวจหาผู้เล่น
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer and not excludedPlayers[otherPlayer.Name] and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (root.Position - otherRoot.Position).Magnitude
                if distance <= range then
                    table.insert(nearbyTargets, {
                        Name = otherPlayer.Name,
                        Character = otherPlayer.Character,
                        Type = "Player"
                    })
                end
            end
        end
    end
    
    -- ตรวจหาใน Workspace.Characters สำหรับ Dayz, Corpse, Xoku และ NPCs
    local charactersFolder = workspace:FindFirstChild("Characters")
    if charactersFolder then
        print("Searching in Characters folder...")
        
        for _, npc in pairs(charactersFolder:GetChildren()) do
            if npc:IsA("Model") and npc ~= character then
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                
                if npcHRP then
                    -- ตรวจสอบว่าเป็นศัตรูชนิดไหน
                    local npcType = "NPC"  -- ค่าเริ่มต้น
                    
                    if npc:FindFirstChild("Dayz") then
                        npcType = "Dayz"
                    elseif npc:FindFirstChild("Corpse") then
                        npcType = "Corpse"
                    elseif npc:FindFirstChild("Xoku") then
                        npcType = "Xoku"
                    elseif npc:FindFirstChildOfClass("Humanoid") then
                        npcType = "Humanoid"
                    end
                    
                    local distance = (root.Position - npcHRP.Position).Magnitude
                    
                    if distance <= range then
                        print("Found " .. npcType .. ": " .. npc.Name .. " | Distance: " .. math.floor(distance))
                        
                        table.insert(nearbyTargets, {
                            Name = npc.Name,
                            Character = npc,
                            Type = npcType,
                            Model = npc
                        })
                    end
                end
            end
        end
    end
    
    -- ตรวจหาใน Workspace โดยตรงด้วย
    print("Searching in Workspace...")
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= character and obj ~= charactersFolder then
            local npcHRP = obj:FindFirstChild("HumanoidRootPart")
            
            if npcHRP then
                local npcType = "NPC"
                
                if obj:FindFirstChild("Dayz") then
                    npcType = "Dayz"
                elseif obj:FindFirstChild("Corpse") then
                    npcType = "Corpse"
                elseif obj:FindFirstChild("Xoku") then
                    npcType = "Xoku"
                elseif obj:FindFirstChildOfClass("Humanoid") then
                    npcType = "Humanoid"
                end
                
                local distance = (root.Position - npcHRP.Position).Magnitude
                
                if distance <= range then
                    print("Found " .. npcType .. " in Workspace: " .. obj.Name .. " | Distance: " .. math.floor(distance))
                    
                    table.insert(nearbyTargets, {
                        Name = obj.Name,
                        Character = obj,
                        Type = npcType,
                        Model = obj
                    })
                end
            end
        end
    end
    
    print("Total enemies found: " .. #nearbyTargets)
    return nearbyTargets
end

local function executeMoves(targetData)
    -- ตรวจสอบเฉพาะว่าผู้เล่นไม่ได้อยู่ใน excludedPlayers
    if targetData.Type == "Player" and excludedPlayers[targetData.Name] then
        return -- ถ้าผู้เล่นอยู่ในรายการ excluded ให้ข้ามการโจมตี
    end
    
    if not targetData.Character then return end
    
    -- เริ่มโจมตีทันที
    coroutine.wrap(function()
        local function fireAirType()
            for i = 1, skillAmount do
                local args = {
                    "AirType",
                    "Activated",
                    targetData.Character
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveService"):WaitForChild("RE"):WaitForChild("UseMove"):FireServer(unpack(args))
            end
        end
        
        local function fireShootClose()
            for i = 1, skillAmount * 2 do
                local args2 = {
                    targetData.Character
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("AirTypeService"):WaitForChild("RE"):WaitForChild("ShootClose"):FireServer(unpack(args2))
            end
        end
        
        spawn(fireAirType)
        spawn(fireShootClose)
    end)()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.X and canExecute and systemEnabled then
        canExecute = false
        
        local nearbyTargets = getNearbyTargets(50)
        
        -- แสดงรายชื่อผู้เล่นที่ถูก exclude
        local excludedCount = 0
        local excludedNames = {}
        for excludedName, isExcluded in pairs(excludedPlayers) do
            if isExcluded then
                excludedCount = excludedCount + 1
                table.insert(excludedNames, excludedName)
            end
        end
        
        if #nearbyTargets > 0 then
            -- นับจำนวนเป้าหมายแต่ละประเภท
            local playerCount = 0
            local npcCount = 0
            
            for _, target in pairs(nearbyTargets) do
                if target.Type == "Player" then
                    playerCount = playerCount + 1
                elseif target.Type == "NPC" then
                    npcCount = npcCount + 1
                end
            end
            
            WindUI:Notify({
                Title = "AirType Skill",
                Content = "Executing on " .. #nearbyTargets .. " targets (" .. playerCount .. " players, " .. npcCount .. " NPCs) | Excluding " .. excludedCount .. " players",
                Duration = 3,
                Icon = "zap",
            })
            
            -- แสดงรายละเอียดแยก Notification ถ้ามีคนถูก exclude
            if excludedCount > 0 then
                WindUI:Notify({
                    Title = "Excluded Players",
                    Content = "Protected: " .. table.concat(excludedNames, ", "),
                    Duration = 4,
                    Icon = "shield",
                })
            end
            
            for _, targetData in pairs(nearbyTargets) do
                spawn(function()
                    executeMoves(targetData)
                end)
            end
        else
            WindUI:Notify({
                Title = "AirType Skill",
                Content = "No valid targets found (excluding " .. excludedCount .. " protected players)",
                Duration = 2,
                Icon = "swords",
            })
        end
        
        task.wait(cooldown)
        canExecute = true
    end
end)

local SkillAmountSlider = Tab:Slider({
    Title = "AirType Amount",
    Desc = "Adjust number of skills to execute (5-200)",
    Step = 1,
    Value = {
        Min = 5,
        Max = 50,
        Default = 10,
    },
    Callback = function(value)
        skillAmount = value
    end
})

local AutoSkillToggle = Tab:Toggle({
    Title = "AirType ",
    Desc = "Enable Shoot function, press X when enemy in range",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        systemEnabled = state
        WindUI:Notify({
            Title = "AirType",
            Content = "System " .. (systemEnabled and "ENABLED - Press X when enemy in range" or "DISABLED"),
            Duration = 1,
            Icon = systemEnabled and "check" or "x",
        })
    end
})

local includeNPCs = true  -- ตัวแปรเพิ่มเติม

local IncludeNPCToggle = Tab:Toggle({
    Title = "Include NPCs",
    Desc = "Enable to attack NPCs/Bots in range",
    Icon = "bot",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        includeNPCs = state
        WindUI:Notify({
            Title = "NPC Targeting",
            Content = state and "NPC targeting ENABLED" or "NPC targeting DISABLED",
            Duration = 1,
            Icon = state and "check" or "x",
        })
    end
})

function clearTargetCache()
    cachedTarget = nil
    lastTargetCheck = 0
    lastExclusionCheck = 0
end

function isNormalPlayerNearExcluded()
    local currentTime = tick()
    
    if currentTime - lastExclusionCheck < exclusionCheckCooldown then
        return false
    end
    
    lastExclusionCheck = currentTime
    
    if not next(excludedPlayers) then
        return false
    end
    
    local excludedPositions = {}
    for excludedName, isExcluded in pairs(excludedPlayers) do
        if isExcluded then
            local excludedPlayer = Players:FindFirstChild(excludedName)
            if excludedPlayer and excludedPlayer.Character then
                local excludedHRP = excludedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if excludedHRP then
                    table.insert(excludedPositions, excludedHRP.Position)
                end
            end
        end
    end
    
    if #excludedPositions == 0 then
        return false
    end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer and not excludedPlayers[otherPlayer.Name] then
            if otherPlayer.Character then
                local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherHRP then
                    local otherPos = otherHRP.Position
                    
                    for _, excludedPos in ipairs(excludedPositions) do
                        local distance = (otherPos - excludedPos).Magnitude
                        if distance <= SAFE_DISTANCE then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function findClosestPlayerInFront()
    local currentTime = tick()
    
    if cachedTarget and currentTime - lastTargetCheck < targetCheckCooldown then
        local targetPlayer = Players:FindFirstChild(cachedTarget)
        if targetPlayer and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local distance = (targetHRP.Position - humanoidRootPart.Position).Magnitude
                    if distance < 50 then
                        return targetPlayer
                    end
                end
            end
        end
    end
    
    lastTargetCheck = currentTime
    
    if isNormalPlayerNearExcluded() then
        cachedTarget = nil
        return nil
    end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    local maxAngle = 45
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        cachedTarget = nil
        return nil 
    end
    
    local camera = workspace.CurrentCamera
    local cameraDirection = camera.CFrame.LookVector
    local humanoidPos = humanoidRootPart.Position
    
    local potentialTargets = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and not excludedPlayers[player.Name] and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local targetPos = targetHRP.Position
                local distance = (targetPos - humanoidPos).Magnitude
                
                if distance < 50 then
                    table.insert(potentialTargets, {
                        player = player,
                        position = targetPos,
                        distance = distance
                    })
                end
            end
        end
    end
    
    if #potentialTargets == 0 then
        cachedTarget = nil
        return nil
    end
    
    for _, data in ipairs(potentialTargets) do
        local directionToTarget = (data.position - humanoidPos).Unit
        local dotProduct = cameraDirection:Dot(directionToTarget)
        local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))
        
        if angle <= maxAngle and data.distance < shortestDistance then
            shortestDistance = data.distance
            closestPlayer = data.player
        end
    end
    
    cachedTarget = closestPlayer and closestPlayer.Name or nil
    return closestPlayer
end

function rapidAttack()
    if not isSunbreathingEnabled then
        return
    end
    
    if isNormalPlayerNearExcluded() then
        WindUI:Notify({
            Title = "Sun Breathing",
            Content = "Cannot attack - Normal player near excluded player",
            Duration = 2,
            Icon = "shield",
        })
        return
    end
    
    local targetPlayer = findClosestPlayerInFront()
    
    if not targetPlayer or not targetPlayer.Character then
        WindUI:Notify({
            Title = "Sun Breathing",
            Content = "No target found in front",
            Duration = 2,
            Icon = "eye-off",
        })
        return
    end
    
    WindUI:Notify({
        Title = "Sun Breathing",
        Content = "Attacking " .. targetPlayer.Name .. " with " .. attackCount .. " hits",
        Duration = 2,
        Icon = "swords",
    })
    
    local moveService = game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveService"):WaitForChild("RE"):WaitForChild("UseMove")
    local unknowningService = game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("UnknowningFireService"):WaitForChild("RE"):WaitForChild("Hit")
    
    local batchSize = 20
    local remaining = attackCount
    
    while remaining > 0 do
        local currentBatch = math.min(batchSize, remaining)
        
        for i = 1, currentBatch do
            if i % 10 == 0 then
                if isNormalPlayerNearExcluded() then
                    return
                end
            end
            
            local args1 = {
                "UnknowningFire",
                "Activated",
                targetPlayer.Character
            }
            
            pcall(function()
                moveService:FireServer(unpack(args1))
            end)
            
            local args2 = {
                targetPlayer.Character
            }
            
            pcall(function()
                unknowningService:FireServer(unpack(args2))
            end)
            
            if i % 5 == 0 then
                task.wait()
            else
                RunService.Heartbeat:Wait()
            end
        end
        
        remaining = remaining - currentBatch
        
        if remaining > 0 then
            task.wait()
        end
    end
    
    WindUI:Notify({
        Title = "Sun Breathing",
        Content = "Attack completed on " .. targetPlayer.Name,
        Duration = 2,
        Icon = "check-circle",
    })
end

local lastXPress = 0
local inputCooldown = 0

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        local currentTime = tick()
        if currentTime - lastXPress < inputCooldown then
            return
        end
        lastXPress = currentTime
        
        task.spawn(function()
            rapidAttack()
        end)
    end
end)

local function onCharacterAdded(char)
    character = char
    char:WaitForChild("Humanoid").Died:Connect(function()
        WindUI:Notify({
            Title = "Character",
            Content = "You died! Resetting target cache...",
            Duration = 1,
            Icon = "skull",
        })
        task.wait(3)
        character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        clearTargetCache()
    end)
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(char)
    onCharacterAdded(char)
    clearTargetCache()
end)

local Section = Tab:Section({ 
    Title = "Buffs Tab",
})

local isAllBuffEnabled = false
local selectedMoves = {}

local allMoves = {
    "Stance",
    "Uplift",
    "CompassNeedle", 
    "PoisonVein",
    "Remembrance",
    "ShiningSun",
    "MusicalScore",
    "Bloodlust",
    "Instinct",
    "Asleep"
    
}

local SkillDropdown = Tab:Dropdown({
    Title = "Select Buff Skills",
    Desc = "Choose which skills to activate",
    Values = allMoves,
    Value = {
        "Stance",
        "Uplift",
        "CompassNeedle", 
        "PoisonVein",
        "Remembrance",
        "ShiningSun",
        "MusicalScore",
        "Bloodlust"
    },
    Multi = true,
    AllowNone = true,
    Callback = function(selectedSkills) 
        selectedMoves = selectedSkills
    end
})

selectedMoves = {
    "Stance",
    "Uplift",
    "CompassNeedle", 
    "PoisonVein",
    "Remembrance",
    "ShiningSun",
    "MusicalScore",
    "Bloodlust"
}

local BuffToggle = Tab:Toggle({
    Title = "All Buffs",
    Desc = "Enable all buff functions, press R",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        isAllBuffEnabled = state
        WindUI:Notify({
            Title = "All Buffs",
            Content = state and "ENABLED - Press R to activate" or "DISABLED",
            Duration = 1,
            Icon = state and "shield-check" or "shield-off",
        })
    end
})

function Allbuffactivate()
    if #selectedMoves == 0 then
        WindUI:Notify({
            Title = "All Buffs",
            Content = "No buff skills selected",
            Duration = 1,
            Icon = "alert-circle",
        })
        return
    end
    
    if not isAllBuffEnabled then
        WindUI:Notify({
            Title = "All Buffs",
            Content = "System is disabled",
            Duration = 1,
            Icon = "x",
        })
        return
    end
    for x = 1, 10 do
        task.wait(0.1)
        
        local moveService = game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveService"):WaitForChild("RE"):WaitForChild("UseMove")
        
        for _, moveName in ipairs(selectedMoves) do
            local args = {
                moveName,
                "Activated"
            }
            pcall(function()
                moveService:FireServer(unpack(args))
            end)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R and isAllBuffEnabled then
        task.spawn(function()
            Allbuffactivate()
        end)
    end
end)

local Tab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
    Locked = false,
})

local CoreGui = game:FindService("CoreGui")
local Players = game:FindService("Players")
local lp = Players.LocalPlayer

local ESPEnabled = false
local ESPColor = Color3.fromRGB(59,57,60)
local DepthMode = "AlwaysOnTop"
local FillTransparency = 0.5
local OutlineColor = Color3.fromRGB(255,255,255)
local OutlineTransparency = 0

local Storage = Instance.new("Folder")
Storage.Parent = CoreGui
Storage.Name = "Highlight_Storage"

local connections = {}
local highlights = {}
local characterConnections = {}

local updateCooldown = 0.5
local lastUpdate = tick()

local healthColors = {
    low = Color3.fromRGB(255, 50, 50),
    medium = Color3.fromRGB(255, 255, 50),
    normal = ESPColor
}

local function getHealthState(character)
    if not character then return "normal" end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return "normal" end
    
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = (health / maxHealth) * 100
    
    if healthPercent < 25 then
        return "low"
    elseif healthPercent < 75 then
        return "medium"
    end
    return "normal"
end

local function updateHighlightColor(highlight, character)
    if not highlight or not character then return end
    
    local state = getHealthState(character)
    highlight.FillColor = healthColors[state] or ESPColor
end

local function ClearAllESP()
    for _, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    highlights = {}
    
    for _, conn in pairs(connections) do
        if conn then
            conn:Disconnect()
        end
    end
    connections = {}
    
    for plr, conn in pairs(characterConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    characterConnections = {}
    
    Storage:ClearAllChildren()
end

local function batchUpdateColors()
    local currentTime = tick()
    
    if currentTime - lastUpdate < updateCooldown then
        return
    end
    
    lastUpdate = currentTime
    
    for plr, highlight in pairs(highlights) do
        if highlight and plr.Character then
            updateHighlightColor(highlight, plr.Character)
        end
    end
end

local function CreateHighlight(plr)
    if plr == lp then return end
    
    local Highlight = Instance.new("Highlight")
    Highlight.Name = plr.Name
    Highlight.FillColor = ESPColor
    Highlight.DepthMode = DepthMode
    Highlight.FillTransparency = FillTransparency
    Highlight.OutlineColor = OutlineColor
    Highlight.OutlineTransparency = OutlineTransparency
    Highlight.Parent = Storage
    
    local plrchar = plr.Character
    if plrchar then
        Highlight.Adornee = plrchar
        updateHighlightColor(Highlight, plrchar)
        
        characterConnections[plr] = plrchar:WaitForChild("Humanoid").HealthChanged:Connect(function()
            updateHighlightColor(Highlight, plrchar)
        end)
    end

    connections[plr] = plr.CharacterAdded:Connect(function(char)
        Highlight.Adornee = char
        updateHighlightColor(Highlight, char)
        
        if characterConnections[plr] then
            characterConnections[plr]:Disconnect()
        end
        
        task.wait(0.5)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            characterConnections[plr] = humanoid.HealthChanged:Connect(function()
                updateHighlightColor(Highlight, char)
            end)
        end
    end)
    
    highlights[plr] = Highlight
end

local function ToggleESP(state)
    ESPEnabled = state
    
    if ESPEnabled then
        local players = Players:GetPlayers()
        for i = 1, #players do
            local plr = players[i]
            if plr ~= lp then
                CreateHighlight(plr)
            end
        end
        
        if not connections["batchUpdate"] then
            connections["batchUpdate"] = RunService.Heartbeat:Connect(function()
                batchUpdateColors()
            end)
        end
    else
        ClearAllESP()
        
        if connections["batchUpdate"] then
            connections["batchUpdate"]:Disconnect()
            connections["batchUpdate"] = nil
        end
    end
end

local function UpdateESPColor(color)
    ESPColor = color
    healthColors.normal = color
    
    if ESPEnabled then
        for _, highlight in pairs(highlights) do
            if highlight and highlight:IsA("Highlight") then
                local plr = Players:FindFirstChild(highlight.Name)
                if plr and plr.Character then
                    updateHighlightColor(highlight, plr.Character)
                end
            end
        end
    end
end

local Section = Tab:Section({ 
    Title = "ESP Settings",
})

local Colorpicker = Tab:Colorpicker({
    Title = "ESP Color",
    Desc = "ESP color picker",
    Default = Color3.fromRGB(59,57,60),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        UpdateESPColor(color)
    end
})

local Toggle = Tab:Toggle({
    Title = "ESP Players",
    Desc = "Enable player ESP (See all players)",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        ToggleESP(state)
    end
})

local function PlayerAdded(plr)
    if ESPEnabled and plr ~= lp then
        CreateHighlight(plr)
    end
end

local function PlayerRemoving(plr)
    if highlights[plr] then
        highlights[plr]:Destroy()
        highlights[plr] = nil
    end
    if connections[plr] then
        connections[plr]:Disconnect()
        connections[plr] = nil
    end
    if characterConnections[plr] then
        characterConnections[plr]:Disconnect()
        characterConnections[plr] = nil
    end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

if ESPEnabled then
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp then
            CreateHighlight(plr)
        end
    end
end

local Section = Tab:Section({ 
    Title = "UI Tab",
})

local isRunning = false
local runningThread

local Toggle = Tab:Toggle({
    Title = "Sun Breathing UI",
    Desc = "Change flame breathing name in UI",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        if state and not isRunning then
            isRunning = true
            runningThread = task.spawn(function()
                while isRunning do
                    pcall(function()
                        local player = game.Players.LocalPlayer
                        local playerGui = player:WaitForChild("PlayerGui")
                        local hud = playerGui:WaitForChild("HUD")
                        local moves = hud:WaitForChild("Moves")
                        local list = moves:WaitForChild("List")
                        local unknowningFire = list:WaitForChild("UnknowningFire")

                        unknowningFire.Name = "UnknowningFire"
                        unknowningFire.Frame.move_name.Text = "Sunbreating"
                        unknowningFire.Frame.key.Text = "1"
                    end)
                    task.wait(1)
                end
            end)
        elseif not state and isRunning then
            isRunning = false
            if runningThread then
                task.cancel(runningThread)
                runningThread = nil
            end
        end
    end
})

if Toggle.Value then
    isRunning = true
    runningThread = task.spawn(function()
        while isRunning do
            pcall(function()
                local player = game.Players.LocalPlayer
                local playerGui = player:WaitForChild("PlayerGui")
                local hud = playerGui:WaitForChild("HUD")
                local moves = hud:WaitForChild("Moves")
                local list = moves:WaitForChild("List")
                local unknowningFire = list:WaitForChild("UnknowningFire")

                unknowningFire.Name = "UnknowningFire"
                unknowningFire.Frame.move_name.Text = "Sunbreating"
                unknowningFire.Frame.key.Text = "1"
            end)
            task.wait(1)
        end
    end)
end

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "ellipsis",
    Locked = false,
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Section = MiscTab:Section({ 
    Title = "Dash Tab",
})

local dashDelay = 0.8
local amountDash = 1
local isDashSystemEnabled = false
local isDashing = false
local dashConnection = nil

local Toggle = MiscTab:Toggle({
    Title = "Dash Lag",
    Desc = "Create dash effect, press C to toggle",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        isDashSystemEnabled = state
        
        if not state and isDashing then
            if dashConnection then
                dashConnection:Disconnect()
                dashConnection = nil
            end
            isDashing = false
        end
    end
})

local SliderDelay = MiscTab:Slider({
    Title = "Dash Speed",
    Desc = "Adjust dash speed (Lower = Faster, Higher = Slower)",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2.0,
        Default = 0.8,
    },
    Callback = function(value)
        dashDelay = value
    end
})

local SliderAmount = MiscTab:Slider({
    Title = "Dash Amount",
    Desc = "Adjust number of dashes per activation",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 1,
    },
    Callback = function(value)
        amountDash = value
end
})

function Dashactivate()
    if not isDashSystemEnabled then
        return
    end
    
    if isDashing then
        isDashing = false
        if dashConnection then
            dashConnection:Disconnect()
            dashConnection = nil
        end
    else
        isDashing = true

        dashConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not isDashing or not isDashSystemEnabled then
                if dashConnection then
                    dashConnection:Disconnect()
                    dashConnection = nil
                end
                isDashing = false
                return
            end
            
            for i = 1, amountDash do
                if not isDashing or not isDashSystemEnabled then
                    break
                end
                
                local args = {
                    Vector3.new(0.9853354096412659, 0, 0.17062853276729584)
                }
                pcall(function()
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dash"):FireServer(unpack(args))
                end)
                
                if i < amountDash then
                    task.wait(dashDelay)
                end
            end
            
            task.wait(dashDelay)
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C then
        Dashactivate()
    end
end)

local Section2 = MiscTab:Section({ 
    Title = "Combat 100%",
})

local Toggle2 = MiscTab:Toggle({
    Title = "Auto 100%",
    Desc = "Automatically maintain 100% Green Bar",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        if _G.SkillCheckLoop then
            _G.SkillCheckLoop:Disconnect()
            _G.SkillCheckLoop = nil
        end
        
        if state then
            local lastTime = tick()
            
            _G.SkillCheckLoop = RunService.Heartbeat:Connect(function()
                local currentTime = tick()
                
                if currentTime - lastTime >= 1 then
                    lastTime = currentTime
                    
                    local args = {100}
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("QEService"):WaitForChild("RE"):WaitForChild("ClickQE"):FireServer(unpack(args))
                    end)
                end
            end)
        end
    end
})

Toggle2.Callback(true)

local Section3 = MiscTab:Section({ 
    Title = "Invisibility",
})

local isInvisibilityEnabled = false
local invisibilityParts = {}
local invisibilityAnimation = nil
local invisibilityConnections = {}
local isCurrentlyInvisible = false

local InvisibilityToggle = MiscTab:Toggle({
    Title = "Invisibility",
    Desc = "Toggle invisibility with V key",
    Icon = "eye-off",
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        isInvisibilityEnabled = state
        if not state and isCurrentlyInvisible then
            cleanupInvisibility()
            isCurrentlyInvisible = false
        end
    end
})

function setTransparency(transparencyValue, character)
    if not character then return end
    
    local bodyParts = {
        "Head",
        "Torso", 
        "Left Arm",
        "Right Arm",
        "Left Leg",
        "Right Leg"
    }
    
    for _, partName in ipairs(bodyParts) do
        local bodyPart = character:FindFirstChild(partName)
        if bodyPart and bodyPart:IsA("BasePart") then
            bodyPart.Transparency = transparencyValue
            invisibilityParts[partName] = bodyPart
        end
    end
end

function cleanupInvisibility()
    for _, connection in pairs(invisibilityConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    invisibilityConnections = {}
    
    if invisibilityAnimation and invisibilityAnimation.IsPlaying then
        invisibilityAnimation:Stop()
        invisibilityAnimation:Destroy()
    end
    invisibilityAnimation = nil
    
    local character = Players.LocalPlayer.Character
    if character then
        for partName, part in pairs(invisibilityParts) do
            if part and part.Parent and part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = 0
                end)
            end
        end
    end
    invisibilityParts = {}
    
    isCurrentlyInvisible = false
end

function setupInvisibility(character)
    if not character or not isInvisibilityEnabled then 
        return 
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    
    local animator = humanoid:FindFirstChildOfClass("Animator") 
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    if invisibilityAnimation then
        if invisibilityAnimation.IsPlaying then
            invisibilityAnimation:Stop()
        end
        invisibilityAnimation:Destroy()
        invisibilityAnimation = nil
    end
    
    local freezeAnimation = Instance.new("Animation")
    freezeAnimation.AnimationId = "rbxassetid://77076150781560"
    
    invisibilityAnimation = animator:LoadAnimation(freezeAnimation)
    if not invisibilityAnimation then
        return
    end
    
    invisibilityAnimation.Priority = Enum.AnimationPriority.Action4
    
    setTransparency(0.5, character)
    
    for _, connection in pairs(invisibilityConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    invisibilityConnections = {}
    
    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not isCurrentlyInvisible or not isInvisibilityEnabled then return end
        
        if invisibilityAnimation and not invisibilityAnimation.IsPlaying then
            invisibilityAnimation:Play()
        end
        if invisibilityAnimation then
            invisibilityAnimation:AdjustSpeed(0)
            invisibilityAnimation.TimePosition = 6.5
        end
    end)
    
    local renderConnection = RunService.RenderStepped:Connect(function()
        if not isCurrentlyInvisible or not isInvisibilityEnabled then return end
        
        if invisibilityAnimation and invisibilityAnimation.IsPlaying then
            invisibilityAnimation:Stop()
        end
    end)
    
    table.insert(invisibilityConnections, heartbeatConnection)
    table.insert(invisibilityConnections, renderConnection)
    
    isCurrentlyInvisible = true
end

function toggleInvisibility()
    if not isInvisibilityEnabled then 
        return 
    end
    
    local character = Players.LocalPlayer.Character
    if not character then 
        return 
    end
    
    if isCurrentlyInvisible then
        cleanupInvisibility()
    else
        cleanupInvisibility()
        setupInvisibility(character)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.V and not gameProcessed then
        toggleInvisibility()
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    
    if isInvisibilityEnabled and isCurrentlyInvisible then
        cleanupInvisibility()
        setupInvisibility(newCharacter)
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    newCharacter:WaitForChild("Humanoid").Died:Connect(function()
        cleanupInvisibility()
        
        task.wait(3)
        
        if isInvisibilityEnabled and isCurrentlyInvisible then
            local respawnedCharacter = Players.LocalPlayer.Character
            if respawnedCharacter then
                task.wait(0.5)
                setupInvisibility(respawnedCharacter)
            end
        end
    end)
end)

local Tab = Window:Tab({
    Title = "Codes",
    Icon = "book-marked",
    Locked = false,
})

local Button = Tab:Button({
    Title = "Redeem All Codes",
    Color = Color3.fromHex("#CEE44C"),
    Justify = "Center",
    IconAlign = "Left",
    Icon = "book-marked",
    Callback = function()
        local codes = {
            "NEARLYINFINITY",
            "XOKUATTEMPT2",
            "XOKU", 
            "Glad",
            "ian",
            "SORRYFORTHEBUGS",
            "HALLOWEEN",
            "MUGENHUB",
            "CORPSEINFINITY",
            "Shockdayz",
            "UPDATEISNEAR",
            "INFINITYISSOON",
            "TSUNAMIONTOP",
            "CONSOLECURSOR",
            "MUGENINFINITY",
            "INFINITYISNEAR",
            "MUGENONTOP",
            "MUGENHUB",
            "INFINITYSOON",
            "TSUNAMISOON",
            "THUNDERISHERE",
            "SORRY4CONFUSION",
            "TSUNAMIISNEXT",
            "MUGENISBACK",
            "SORRY4CANCEL",
            "200KINTERESTED",
            "DEMONKARTZ",
            "LAGFIXES",
            "SORRY4LAG",
            "120kwow",
            "beastisnext",
            "50kwow",
            "LAGFIXED?",
            "AWAKENINGS",
            "SRRYSRRY",
            "PATCHMEUP",
            "TESTING",
            "SORRY4DELAY",
            "125KINTERESTED",
            "INFINITYISHERE",
            "50KINTERESTED*",
            "100KINTERESTED*"
            
        }

        local RewardService = game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("RewardService"):WaitForChild("RF"):WaitForChild("RedeemCode")

        for i, code in ipairs(codes) do
            local args = {code}
            pcall(function()
                RewardService:InvokeServer(unpack(args))
            end)
            task.wait(0.1)
        end
    end
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local selectedOptions = {}
local isAutoSpinning = false
local autoSpinTask = nil

local function arrayToLookup(arr)
    local lookup = {}
    for _, v in ipairs(arr) do
        lookup[v] = true
    end
    return lookup
end

local function showNotification(title, content, icon)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = 3,
        Icon = icon
    })
end

local function startAutoSpin(selectedItems)
    if isAutoSpinning then return end
    
    isAutoSpinning = true
    
    showNotification(
        "Auto Spin Started",
        "Looking for selected results...\nSelected: " .. #selectedItems .. " items",
        "loader"
    )
    
    local rollService = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Packages")
        :WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("RollService")
    
    local spinFunction = rollService:WaitForChild("RF"):WaitForChild("Spin")
    
    local targetLookup = arrayToLookup(selectedItems)
    
    autoSpinTask = task.spawn(function()
        local args = {"Lucky"}
        
        while isAutoSpinning do
            local result = spinFunction:InvokeServer(unpack(args))
            
            if targetLookup[result] then
                showNotification(
                    "Got Selected Result",
                    "Result: " .. result .. "\nAuto Spin stopped",
                    "check-circle"
                )
                
                isAutoSpinning = false
                if AutoSpinToggle then
                    AutoSpinToggle:Set(false)
                end
                break
            end
            
            task.wait(0.1)
        end
        
        isAutoSpinning = false
    end)
end

local function stopAutoSpin()
    if not isAutoSpinning then return end
    
    isAutoSpinning = false
    if autoSpinTask then
        task.cancel(autoSpinTask)
        autoSpinTask = nil
    end
    showNotification("Auto Spin Stopped", "Auto Spin has been stopped", "stop-circle")
end

local Dropdown = Tab:Dropdown({
    Title = "Auto Spin - Select Results to Stop",
    Desc = "Select Moveset",
    Values = {
        "Tsunami", "Shockwave", "Mist", "Flame", 
        "Sound", "Sickles", "Thunder", 
        "Blood", "Beast", "Water"
    },
    Value = {"Shockwave", "Mist", "Flame", "Tsunami"},
    Multi = true,
    AllowNone = false,
    Callback = function(option)
        selectedOptions = option
        if #option > 0 then
            showNotification(
                "Selection Updated",
                "Selected " .. #option .. " items",
                "check"
            )
        end
    end
})

local AutoSpinToggle = Tab:Toggle({
    Title = "Auto Spin",
    Desc = "Toggle Auto Spin On/Off",
    Value = false,
    Callback = function(value)
        if value then
            if #selectedOptions == 0 then
                showNotification("No Selection", "Please select at least 1 result", "alert-circle")
                AutoSpinToggle:Set(false)
                return
            end
            
            if isAutoSpinning then
                showNotification("Already Running", "Auto Spin is already running", "loader")
                return
            end
            
            startAutoSpin(selectedOptions)
        else
            stopAutoSpin()
        end
    end
})

local Tab = Window:Tab({
    Title = "Sounds",
    Icon = "volume-2",
    Locked = false,
})

local Toggle = Tab:Toggle({
    Title = "Mute Sun Breathing",
    Desc = "Disable flame breathing sounds",
    Icon = "volume-off",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) 
        if state then
            game.ReplicatedStorage.Assets.Sounds.Finishers.RengokuFinisher1.Volume = 0
            game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownHit.Volume = 0
            game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownStart.Volume = 0
            game.ReplicatedStorage.Assets.Sounds.Knockback.Volume = 0
            
            local function protectSound(sound)
                sound:GetPropertyChangedSignal("Volume"):Connect(function()
                    if state then
                        sound.Volume = 0
                    end
                end)
            end
            
            protectSound(game.ReplicatedStorage.Assets.Sounds.Finishers.RengokuFinisher1)
            protectSound(game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownHit)
            protectSound(game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownStart)
            protectSound(game.ReplicatedStorage.Assets.Sounds.Knockback)
            
        else
            game.ReplicatedStorage.Assets.Sounds.Finishers.RengokuFinisher1.Volume = 1
            game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownHit.Volume = 1
            game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownStart.Volume = 1
            game.ReplicatedStorage.Assets.Sounds.Knockback.Volume = 1
        end
    end
})

if Toggle.Value then
    game.ReplicatedStorage.Assets.Sounds.Finishers.RengokuFinisher1.Volume = 0
    game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownHit.Volume = 0
    game.ReplicatedStorage.Assets.Sounds.Moves.Rengoku.UnknownStart.Volume = 0
    game.ReplicatedStorage.Assets.Sounds.Knockback.Volume = 0
end

local Button = Tab:Button({
    Title = "Disable Akaza",
    Color = Color3.fromHex("#333333"),
    Justify = "Center",
    IconAlign = "Left",
    Icon = "volume-off",
    Callback = function()
        game.ReplicatedStorage.Knit.Controllers.MoveControllers.Akaza.AirTypeController.Projectile:Destroy()
    end
})

Window:Tag({
    Title = "v1.5.2",
    Icon = "github",
    Color = Color3.fromHex("#FB3F41"),
    Radius = 13,
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

local Section = SettingsTab:Section({ 
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

local Section2 = SettingsTab:Section({ 
    Title = "Combat Protection Settings",
})

local PlayerDropdown

PlayerDropdown = SettingsTab:Dropdown({
    Title = "Exclude Player",
    Desc = "Select a player who will not be attacked and protect players near them",
    Values = refreshPlayerList(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selectedPlayers) 
        excludedPlayers = {}
        for _, playerName in pairs(selectedPlayers) do
            excludedPlayers[playerName] = true
        end
    end
})

-- ฟังก์ชันอัพเดทผู้เล่นแบบเสถียร
local function safeUpdatePlayerList()
    while true do
        local currentTime = tick()
        local nextUpdateTime = currentTime + 5
        
        -- รอจนกว่าจะถึงเวลาอัพเดทถัดไป
        while tick() < nextUpdateTime do
            RunService.Heartbeat:Wait()
        end
        
        -- อัพเดทรายชื่อผู้เล่น
        local success, errorMsg = pcall(function()
            local currentPlayers = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= localPlayer and player:IsDescendantOf(game) then
                    table.insert(currentPlayers, player.Name)
                end
            end
            
            if PlayerDropdown and PlayerDropdown.SetValues then
                PlayerDropdown:SetValues(currentPlayers)
                -- สำหรับ debugging:
                print(string.format("[GRIMM Hub] Updated player list: %d players", #currentPlayers))
            end
        end)
        
        if not success then
            warn("[GRIMM Hub] Player list update failed:", errorMsg)
        end
    end
end

-- อัพเดททันทีเมื่อมีผู้เล่นเข้าร่วม
local function onPlayerAdded(player)
    if player ~= localPlayer then
        task.wait(0.5) -- รอให้ระบบโหลดเสร็จ
        local success, errorMsg = pcall(function()
            local currentPlayers = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= localPlayer and p:IsDescendantOf(game) then
                    table.insert(currentPlayers, p.Name)
                end
            end
            
            if PlayerDropdown and PlayerDropdown.SetValues then
                PlayerDropdown:SetValues(currentPlayers)
                print(string.format("[GRIMM Hub] Player added: %s, Total: %d", player.Name, #currentPlayers))
            end
        end)
        
        if not success then
            warn("[GRIMM Hub] Error adding player:", errorMsg)
        end
    end
end

-- อัพเดททันทีเมื่อมีผู้เล่นออก
local function onPlayerRemoving(player)
    if player ~= localPlayer then
        if excludedPlayers[player.Name] then
            excludedPlayers[player.Name] = nil
        end
        
        local success, errorMsg = pcall(function()
            local currentPlayers = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= localPlayer and p:IsDescendantOf(game) then
                    table.insert(currentPlayers, p.Name)
                end
            end
            
            if PlayerDropdown and PlayerDropdown.SetValues then
                PlayerDropdown:SetValues(currentPlayers)
                print(string.format("[GRIMM Hub] Player removed: %s, Total: %d", player.Name, #currentPlayers))
            end
        end)
        
        if not success then
            warn("[GRIMM Hub] Error removing player:", errorMsg)
        end
    end
end

-- เริ่มต้นระบบอัพเดท
coroutine.wrap(safeUpdatePlayerList)()

-- เชื่อมต่อ event
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ใส่ DistanceSlider ตามปกติ
local DistanceSlider = SettingsTab:Slider({
    Title = "Safe Distance",
    Desc = "Adjust the distance from the excluded player",
    Step = 5,
    Value = {
        Min = 10,
        Max = 25,
        Default = 15,
    },
    Callback = function(distance)
        SAFE_DISTANCE = math.floor(distance)
    end
})

local Section3 = SettingsTab:Section({ 
    Title = "Job ID Teleport"
})

local currentJobId = tostring(game.JobId) or "No Job ID Found"
local jobIdSection = Section3:Code({
    Title = "Current Job ID",
    Code = currentJobId,
    Language = "text"
})

local teleportInput = Section3:Input({
    Title = "Target Job ID",
    Placeholder = "Enter Job ID to teleport...",
    Numeric = true,
    Finished = false
})

Section3:Button({
    Title = "Teleport",
    Callback = function()
        local targetJobId = teleportInput:GetValue()
        
        if targetJobId and targetJobId ~= "" then
            local TeleportService = game:GetService("TeleportService")
            local player = game.Players.LocalPlayer
            
            print("Attempting to teleport to Job ID: " .. targetJobId)
            
            -- พยายาม Teleport
            local success, errorMsg = pcall(function()
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    targetJobId,
                    player
                )
            end)
            
            if not success then
                warn("Teleport failed: " .. tostring(errorMsg))
                print("Please check if the Job ID is correct and the server is still active.")
            else
                print("Teleporting...")
            end
        else
            warn("Please enter a valid Job ID")
        end
    end
})

if setclipboard then
    setclipboard(tostring(game.JobId))
end

