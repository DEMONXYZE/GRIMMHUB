local AutoFarm = Window:Tab({
    Title = "Auto Farm",
    Icon = "crown", -- Fruit icon
    Locked = false,
})

AutoFarm:Toggle({
    Title = "Auto Wins",
    Desc = "Enable/Disable Auto Wins",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            getfenv()._AWRunning = true
            getfenv()._AWThread = task.spawn(function()
                while getfenv()._AWRunning do
                    task.wait(0.0001)
                    local args = {"WinGate_12", vector.create(1810.3023681640625, 783.3406982421875, -114392.9140625)}
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.5.1"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("FightService"):WaitForChild("RE"):WaitForChild("GetWinsEvent"):FireServer(unpack(args))
                end
            end)
        else
            getfenv()._AWRunning = false
            if getfenv()._AWThread then task.cancel(getfenv()._AWThread) end
        end
    end
})

local AutoFeedTab = Window:Tab({
    Title = "Auto Feed",
    Icon = "apple", -- Fruit icon
    Locked = false,
})

-- List of all available fruits
local fruits = {
    "ColossalPinecone",
    "BloodstoneCycad",
    "Pineapple",
    "Watermelon",
    "Corn",
    "Grape",
    "Strawberry", 
    "Blueberry",
    "Orange",
    "Apple",
    "Pear",
    "Banana"
}

-- Variables for storing state and data
local selectedFruit = "Strawberry"
local autoFeedRunning = false
local autoFeedThread = nil

-- Create Dropdown for fruit selection
AutoFeedTab:Dropdown({
    Title = "Select Fruit",
    Desc = "Choose which fruit to buy",
    Values = fruits,
    Value = selectedFruit,
    Callback = function(option) 
        selectedFruit = option
    end
})

-- Create Toggle for Auto Feed
AutoFeedTab:Toggle({
    Title = "Auto Feed",
    Desc = "Enable/Disable automatic fruit purchase",
    Icon = "shopping-cart", -- Shopping cart icon
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        if state then
            -- Enable Auto Feed
            autoFeedRunning = true
            
            autoFeedThread = task.spawn(function()
                while autoFeedRunning do
                    task.wait(0.1) -- Small delay
                    
                    -- Create args from selected fruit
                    local args = {
                        "Fruit_" .. selectedFruit
                    }
                    
                    -- Call BuyFruitEvent
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Packages")
                        :WaitForChild("_Index")
                        :WaitForChild("sleitnick_knit@1.5.1")
                        :WaitForChild("knit")
                        :WaitForChild("Services")
                        :WaitForChild("FruitShopService")
                        :WaitForChild("RE")
                        :WaitForChild("BuyFruitEvent"):FireServer(unpack(args))
                end
            end)
        else
            -- Disable Auto Feed
            autoFeedRunning = false
            
            if autoFeedThread then
                task.cancel(autoFeedThread)
                autoFeedThread = nil
            end
        end
    end
})
