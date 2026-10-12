local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer

-- HW_BossScore tồn tại = đang đánh boss; không tồn tại = chưa đánh boss.
local AutoBossPausedForHouseAction = false
local AutoUnlockPending = false
local AutoKnockPending = false
local AutoHouseActionBusy = false
local NoHouseWorkSince = nil
local BossPathWasActive = false

local function IsBossFightActive()
    local workspaceRoot = workspace:FindFirstChild("duycheck022")
    local head = workspaceRoot and workspaceRoot:FindFirstChild("Head")
    local score = head and head:FindFirstChild("HW_BossScore")
    return score ~= nil and score:FindFirstChild("HW_BossScore") ~= nil
end

local function IsHouseActionBlockingBoss()
    return AutoBossPausedForHouseAction or AutoUnlockPending or AutoKnockPending or AutoHouseActionBusy
end

local ConfigFileName = "DYUHUB_Event_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local EventSettings = {
    AutoHatchWarBossTap = false,
    AutoEgg = false,
    AutoJump = false,
    AutoUnlock = false,
    AutoKnockHouse = false,
}

local function SaveConfig()
    if type(writefile) ~= "function" then return false end
    local ok = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(EventSettings))
    end)
    return ok
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    local existsOk, exists = pcall(function()
        return isfile(ConfigFileName)
    end)
    if not existsOk then return end
    if not exists then
        SaveConfig()
        return
    end

    local readOk, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFileName))
    end)
    if not readOk or type(data) ~= "table" then return end

    for key, value in pairs(data) do
        if EventSettings[key] ~= nil and type(value) == type(EventSettings[key]) then
            EventSettings[key] = value
        end
    end
end

LoadConfig()
local isLoaded = false
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or type(rawCode) ~= "string" or rawCode == "" then
    return
end
local compileUI = loadstring(rawCode)
if type(compileUI) ~= "function" then
    return
end
local moduleOk, UIModule = pcall(compileUI)
if not moduleOk or type(UIModule) ~= "table" or type(UIModule.Init) ~= "function" then
    return
end
local initOk, Window = pcall(function()
    return UIModule:Init({
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DYU_HUB",
            FileName = "Config"
        }
    })
end)
if not initOk or type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
    return
end
local EventTab = Window:CreateTab({
    Name = "Event",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

-- [START] BuyMax: dùng EggCmds.GetMaxHatch và cập nhật cache mỗi 30 giây
local CurrentMaxEggHatchAmount = 1
local EggCmds

local function RefreshMaxEggHatchAmount()
    local ok, amount = pcall(function()
        local library = ReplicatedStorage:WaitForChild("Library")
        local client = library:WaitForChild("Client")
        EggCmds = EggCmds or require(client:WaitForChild("EggCmds"))
        return EggCmds.GetMaxHatch()
    end)

    if ok and type(amount) == "number" and amount >= 1 then
        CurrentMaxEggHatchAmount = math.floor(amount)
    elseif not ok then
        warn("[Auto Egg] Không đọc được EggCmds.GetMaxHatch(): " .. tostring(amount))
    end

    return CurrentMaxEggHatchAmount
end

-- Cập nhật ngay khi khởi động, sau đó cứ 30 giây làm mới số trứng tối đa.
task.spawn(function()
    RefreshMaxEggHatchAmount()
    while task.wait(30) do
        RefreshMaxEggHatchAmount()
    end
end)
-- [END] BuyMax: dùng EggCmds.GetMaxHatch và cập nhật cache mỗi 30 giây

-- [START] Auto Knock House: tự nhảy mỗi 5 phút từ lúc event.lua khởi chạy
task.spawn(function()
    while true do
        pcall(function()
            local character = Player.Character or Player.CharacterAdded:Wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
                or character:WaitForChild("Humanoid")
            if humanoid.Health > 0 then
                humanoid.Jump = true
            end
        end)

        task.wait(300)
    end
end)
-- [END] Auto Knock House: tự nhảy mỗi 5 phút từ lúc event.lua khởi chạy

-- Điều phối trạng thái boss và thao tác nhà.
task.spawn(function()
    while true do
        local active = IsBossFightActive()
        if active then
            BossPathWasActive = true
            NoHouseWorkSince = nil
            AutoBossPausedForHouseAction = true
        elseif AutoUnlockPending or AutoKnockPending or AutoHouseActionBusy then
            AutoBossPausedForHouseAction = true
            NoHouseWorkSince = nil
        elseif BossPathWasActive or AutoBossPausedForHouseAction then
            AutoBossPausedForHouseAction = true
            NoHouseWorkSince = NoHouseWorkSince or os.clock()
            if os.clock() - NoHouseWorkSince >= 1 then
                AutoBossPausedForHouseAction = false
                BossPathWasActive = false
                NoHouseWorkSince = nil
            end
        end
        task.wait(0.05)
    end
end)

-- [START] Auto Egg: teleport một lần, tìm ID trứng theo WorldPivot rồi hatch theo GetMaxHatch()
local AutoEggRunning = false
local AutoEggTeleported = false

local AutoEggTeleportPosition = Vector3.new(7536.7568359375, 16.33778953552246, 21966.52734375)
local AutoEggWorldPivotPosition = Vector3.new(7537.25, 21.3670044, 21939.1797)
local AutoEggEggId = nil

local function TeleportToAutoEggOnce()
    if AutoEggTeleported then return true end

    local ok, err = pcall(function()
        local character = Player.Character or Player.CharacterAdded:Wait()
        local root = character:FindFirstChild("HumanoidRootPart")
            or character:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(AutoEggTeleportPosition)
    end)

    if ok then
        AutoEggTeleported = true
        print("[Auto Egg] Đã teleport tới vị trí trứng một lần.")
        return true
    end

    warn("[Auto Egg] Teleport tới trứng thất bại: " .. tostring(err))
    return false
end

local function FindAutoEggIdByWorldPivot()
    local things = workspace:FindFirstChild("__THINGS")
    local eggs = things and things:FindFirstChild("CustomEggs")
    if not eggs then return nil end

    for _, egg in ipairs(eggs:GetChildren()) do
        if egg:IsA("Model") then
            local pivot = egg.WorldPivot
            if (pivot.Position - AutoEggWorldPivotPosition).Magnitude <= 0.15 then
                return egg.Name
            end
        end
    end

    return nil
end

local function StartAutoEgg()
    if AutoEggRunning then return end
    AutoEggRunning = true

    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local hatchRemote = network:WaitForChild("CustomEggs_Hatch")

        print("[Auto Egg] Đã tìm thấy remote CustomEggs_Hatch.")

        -- Teleport trước, đúng một lần; sau đó mới xác định ID trứng của server hiện tại.
        if not TeleportToAutoEggOnce() then
            AutoEggRunning = false
            return
        end

        local startedAt = os.clock()
        repeat
            AutoEggEggId = FindAutoEggIdByWorldPivot()
            if AutoEggEggId then break end
            task.wait(0.25)
        until not (EventSettings.AutoEgg and AutoEggRunning) or os.clock() - startedAt >= 15

        if not AutoEggEggId then
            warn("[Auto Egg] Không tìm thấy trứng có WorldPivot tại " .. tostring(AutoEggWorldPivotPosition))
            AutoEggRunning = false
            return
        end

        print("[Auto Egg] Đã xác định ID trứng theo WorldPivot: " .. AutoEggEggId)

        while EventSettings.AutoEgg and AutoEggRunning do
            -- ID được dò từ server hiện tại; không dùng ID cố định giữa các server.
            local ok, err = pcall(function()
                local amount = RefreshMaxEggHatchAmount()
                hatchRemote:InvokeServer(AutoEggEggId, amount)
            end)
            if not ok then
                warn("[Auto Egg] Gọi CustomEggs_Hatch thất bại: " .. tostring(err))
                task.wait(1)
            else
                task.wait(0.5)
            end
        end

        AutoEggRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Egg",
    CurrentValue = EventSettings.AutoEgg,
    Callback = function(Value)
        EventSettings.AutoEgg = Value
        SaveConfig()

        if Value then
            StartAutoEgg()
        else
            AutoEggRunning = false
        end
    end
})

if EventSettings.AutoEgg then
    StartAutoEgg()
end
-- [END] Auto Egg: teleport một lần, tìm ID trứng theo WorldPivot rồi hatch theo GetMaxHatch()
-- [START] Auto HW Boss Tap
local AutoTapRunning = false

local function StartAutoHWTap()
    if AutoTapRunning then return end
    AutoTapRunning = true
-- [START] Teleport tọa độ mục tiêu
    local function TeleportToHWBossPosition()
        local ok, err = pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local root = character:WaitForChild("HumanoidRootPart")
            root.CFrame = CFrame.new(7626.8623046875, 16.33778953552246, 21981.595703125)
        end)
    end

    if not IsBossFightActive() and not IsHouseActionBlockingBoss() then
        TeleportToHWBossPosition()
    end
-- [END] Teleport tọa độ mục tiêu
-- [START] LiveCircle + HW_Boss_Tap
    task.spawn(function()
        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            -- Tap phải chạy khi boss đang hiện diện; chỉ tạm dừng lúc boss chưa active
            -- nhưng coordinator đang nhường lượt cho thao tác nhà.
            if not IsBossFightActive() and IsHouseActionBlockingBoss() then
                task.wait(0.2)
                continue
            end
            local ok, err = pcall(function()
                local player = game:GetService("Players").LocalPlayer
                local playerGui = player:WaitForChild("PlayerGui")
                local instances = playerGui:WaitForChild("_INSTANCES")
                local hatchWarBoss = instances:WaitForChild("HatchWarBoss")
                local button = hatchWarBoss:FindFirstChild("LiveCircle")

                if button and button:IsA("ImageButton") and button.Visible then
                    if type(firesignal) == "function" then
                        firesignal(button.Activated)
                    end
                end

                local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
                local tapRemote = network:WaitForChild("Instancing_FireCustomFromClient")
                tapRemote:FireServer("HatchWar", "HW_Boss_Tap", "circle")
            end)

            task.wait(0.2)
        end
    end)
-- [END] LiveCircle + HW_Boss_Tap
-- [START] HW_Boss_Start
    task.spawn(function()
        local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
        local startRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")

        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            if not IsBossFightActive() and not IsHouseActionBlockingBoss() then
                pcall(function()
                    startRemote:InvokeServer("HatchWar", "HW_Boss_Start", 6)
                end)
            end
            task.wait(0.5)
        end
    end)
-- [END] HW_Boss_Start
-- [START] Teleport mỗi 5 giây
    task.spawn(function()
        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            task.wait(5)
            if not (EventSettings.AutoHatchWarBossTap and AutoTapRunning) then
                break
            end

            if not IsBossFightActive() and not IsHouseActionBlockingBoss() then
                TeleportToHWBossPosition()
            end
        end
    end)
-- [END] Teleport mỗi 5 giây
end

EventTab:CreateToggle({
    Name = "Auto HW Boss Tap",
    CurrentValue = EventSettings.AutoHatchWarBossTap,
    Callback = function(Value)
        EventSettings.AutoHatchWarBossTap = Value
        SaveConfig()

        if Value then
            StartAutoHWTap()
        else
            AutoTapRunning = false
        end
    end
})

if EventSettings.AutoHatchWarBossTap then
    StartAutoHWTap()
end
-- [END] Auto HW Boss: LiveCircle + Tap remote + Boss Start remote

-- [START] Auto Unlock: chụp trạng thái nhà một lần, theo dõi giá bằng sự kiện
local AutoUnlockRunning = false
local HouseUnlockStates = {}
local HouseUnlockPrices = {}
local UnlockItemUID = "451067eb4fc14e64bf64aa8f755dfe08"

-- Tọa độ đứng tại từng căn nhà khi thực hiện Unlock
local HouseUnlockPositions = {
    [1] = Vector3.new(7489.35888671875, 19.386381149291992, 21917.291015625),
    [2] = Vector3.new(7486.86669921875, 19.636981964111328, 22083.65234375),
    [3] = Vector3.new(7544.9912109375, 19.636600494384766, 21916.857421875),
    [4] = Vector3.new(7534.037109375, 19.637348175048828, 22084.875),
    [5] = Vector3.new(7589.3935546875, 19.636981964111328, 21916.61328125),
    [6] = Vector3.new(7577.2265625, 19.636981964111328, 22083.76171875),
    [7] = Vector3.new(7635.36376953125, 19.386701583862305, 21917.314453125),
    [8] = Vector3.new(7634.15966796875, 19.636600494384766, 22084.72265625),
}

local HouseColorPaths = {
    [1] = { house = "House1", indices = {8, 10, 8} },
    [2] = { house = "House2", indices = {7, 6} },
    [3] = { house = "House3", indices = {8, 4, 9} },
    [4] = { house = "House4", indices = {7, 5, 5} },
    [5] = { house = "House5", indices = {5, 6, 10} },
    [6] = { house = "House6", modelModel = true, indices = {2, 13} },
    [7] = { house = "House7", indices = {6, 8} },
    [8] = { house = "House8", indices = {11, 5, 3} },
}

local function ResolveHouseColorTarget(housesFolder, pathInfo)
    local house = housesFolder:FindFirstChild(pathInfo.house)
    if not house then return nil end
    local current = house:FindFirstChild("Model")
    if not current then return nil end
    if pathInfo.modelModel then
        current = current:FindFirstChild("Model")
        if not current then return nil end
    end
    for _, childIndex in ipairs(pathInfo.indices) do
        current = current:GetChildren()[childIndex]
        if not current then return nil end
    end
    return current:IsA("BasePart") and current or nil
end

local function GetHatchWarHouses()
    local things = workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = instances and instances:FindFirstChild("Active")
    local hatchWar = active and active:FindFirstChild("HatchWar")
    local manor = hatchWar and hatchWar:FindFirstChild("6 | Count's Manor")
    return manor and manor:FindFirstChild("Houses"), hatchWar
end

local function ParseUnlockNumber(value)
    if typeof(value) == "number" then return math.max(0, value) end
    if typeof(value) == "string" then
        local text = value:gsub(",", ""):gsub("%s+", "")
        local number = tonumber(text:match("%d+%.?%d*"))
        if number then
            local suffix = text:lower():match("[kmb]$")
            local multiplier = suffix == "k" and 1e3 or suffix == "m" and 1e6 or suffix == "b" and 1e9 or 1
            return number * multiplier
        end
    end
    return nil
end

local function ReadUnlockItemAmount()
    local roots = { Player, Player:FindFirstChild("PlayerGui") }
    for _, root in ipairs(roots) do
        if root then
            for _, object in ipairs(root:GetDescendants()) do
                local uidMatches = object.Name == UnlockItemUID
                    or object:GetAttribute("UID") == UnlockItemUID
                    or object:GetAttribute("ItemUID") == UnlockItemUID
                    or object:GetAttribute("Id") == UnlockItemUID
                if uidMatches then
                    local amount
                    if object:IsA("IntValue") or object:IsA("NumberValue") then
                        amount = ParseUnlockNumber(object.Value)
                    end
                    amount = amount
                        or ParseUnlockNumber(object:GetAttribute("Amount"))
                        or ParseUnlockNumber(object:GetAttribute("Count"))
                    if amount == nil then
                        local amountObject = object:FindFirstChild("Amount") or object:FindFirstChild("Count")
                        if amountObject and (amountObject:IsA("IntValue") or amountObject:IsA("NumberValue")
                            or amountObject:IsA("StringValue")) then
                            amount = ParseUnlockNumber(amountObject.Value)
                        end
                    end
                    if amount ~= nil then return amount end
                end
            end
        end
    end
    return nil
end

local function ReadHousePriceFromDoor(hatchWar, houseNumber)
    local interact = hatchWar and hatchWar:FindFirstChild("INTERACT")
    local doors = interact and interact:FindFirstChild("Doors")
    local door = doors and doors:FindFirstChild(tostring(houseNumber))
    local billboard = door and door:FindFirstChild("HatchWarHouseBillboard")
    local houseBillboard = billboard and billboard:FindFirstChild("HatchWarHouse")
    local price = houseBillboard and houseBillboard:FindFirstChild("Price")
    local amount = price and price:FindFirstChild("Amount")
    if not amount then return nil end
    return ParseUnlockNumber(amount.Text)
end

-- Chỉ gọi lúc bật Auto Unlock: chụp trạng thái màu và giá của cả 8 nhà một lần.
local function InitializeHouseUnlockCache()
    table.clear(HouseUnlockStates)
    table.clear(HouseUnlockPrices)

    local houses, hatchWar = GetHatchWarHouses()
    if not houses or not hatchWar then
        warn("[Auto Unlock] Chưa tìm thấy HatchWar Houses để khởi tạo cache.")
        return false
    end

    for houseNumber, pathInfo in pairs(HouseColorPaths) do
        local target = ResolveHouseColorTarget(houses, pathInfo)
        if target then
            local color = target.Color
            HouseUnlockStates[houseNumber] = not (color.R == 0 and color.G == 0 and color.B == 0)
        else
            HouseUnlockStates[houseNumber] = nil
            warn("[Auto Unlock] Không tìm thấy Part màu của nhà " .. houseNumber .. " khi khởi tạo.")
        end

        local interact = hatchWar:FindFirstChild("INTERACT")
        local doors = interact and interact:FindFirstChild("Doors")
        local door = doors and doors:FindFirstChild(tostring(houseNumber))
        local billboard = door and door:FindFirstChild("HatchWarHouseBillboard")
        local houseBillboard = billboard and billboard:FindFirstChild("HatchWarHouse")
        local priceFolder = houseBillboard and houseBillboard:FindFirstChild("Price")
        local amountLabel = priceFolder and priceFolder:FindFirstChild("Amount")

        if amountLabel and (amountLabel:IsA("TextLabel") or amountLabel:IsA("TextButton")) then
            HouseUnlockPrices[houseNumber] = ParseUnlockNumber(amountLabel.Text)
        else
            HouseUnlockPrices[houseNumber] = nil
            warn("[Auto Unlock] Không tìm thấy Text giá nhà " .. houseNumber .. " khi khởi tạo.")
        end
    end
    print("[Auto Unlock] Đã cache trạng thái và giá 8 nhà; không quét lại nhà trong vòng lặp.")
    return true
end

local function GetFirstLockedHouse(itemAmount)
    for houseNumber = 1, 8 do
        if HouseUnlockStates[houseNumber] == false then
            local price = HouseUnlockPrices[houseNumber]
            if price ~= nil and itemAmount ~= nil and price < itemAmount then
                return houseNumber
            end
        end
    end
    return nil
end

local function StartAutoUnlock()
    if AutoUnlockRunning then return end
    AutoUnlockRunning = true

    task.spawn(function()
        if not InitializeHouseUnlockCache() then
            AutoUnlockRunning = false
            return
        end

        local network = ReplicatedStorage:WaitForChild("Network")
        local unlockRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")
        local lastPrintedAmount, printedNotFound = nil, false
        local itemAmount = nil
        local nextInventoryScanAt = 0

        while EventSettings.AutoUnlock and AutoUnlockRunning do
            local now = os.clock()
            -- Giữ nguyên chu kỳ quét item 2 giây; tuyệt đối không scan lại trạng thái/màu nhà.
            if now >= nextInventoryScanAt then
                itemAmount = ReadUnlockItemAmount()
                nextInventoryScanAt = now + 2
            end

            if itemAmount ~= nil then
                if lastPrintedAmount ~= itemAmount then
                    print("[Auto Unlock] Item UID " .. UnlockItemUID .. " | số lượng: " .. tostring(itemAmount))
                    lastPrintedAmount = itemAmount
                end
                printedNotFound = false
            elseif not printedNotFound then
                warn("[Auto Unlock] Chưa tìm thấy item UID " .. UnlockItemUID .. " trong Player/PlayerGui.")
                printedNotFound = true
            end

            local targetHouse = GetFirstLockedHouse(itemAmount)
            AutoUnlockPending = targetHouse ~= nil and EventSettings.AutoUnlock and AutoUnlockRunning

            if targetHouse and not IsBossFightActive() and not AutoHouseActionBusy
                and not (EventSettings.AutoKnockHouse and AutoKnockPending) then
                AutoHouseActionBusy = true
                AutoBossPausedForHouseAction = true
                local succeeded = false

                local ok, err = pcall(function()
                    local character = Player.Character or Player.CharacterAdded:Wait()
                    local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
                    local originalCFrame = root.CFrame
                    local housePosition = HouseUnlockPositions[targetHouse]
                    if not housePosition or IsBossFightActive() then return end

                    root.CFrame = CFrame.new(housePosition)
                    task.wait(0.25)
                    if IsBossFightActive() then return end

                    unlockRemote:InvokeServer("HatchWar", "HW_Doors_Unlock", targetHouse)
                    task.wait(0.25)

                    if not IsBossFightActive() then
                        local currentCharacter = Player.Character
                        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                        if currentRoot then currentRoot.CFrame = originalCFrame end
                    end

                    -- Không scan lại nhà: nếu remote không lỗi, cập nhật cache để tránh thử mở lặp.
                    HouseUnlockStates[targetHouse] = true
                    succeeded = true
                end)

                if not ok then
                    warn("[Auto Unlock] Mở nhà " .. targetHouse .. " lỗi: " .. tostring(err))
                elseif succeeded then
                    print("[Auto Unlock] Đã đánh dấu nhà " .. targetHouse .. " là đã mở trong cache.")
                end

                AutoHouseActionBusy = false
                AutoBossPausedForHouseAction = false
            end

            task.wait(0.2)
        end

        AutoUnlockPending = false
        AutoUnlockRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Unlock",
    CurrentValue = EventSettings.AutoUnlock,
    Callback = function(Value)
        EventSettings.AutoUnlock = Value
        SaveConfig()
        if Value then
            StartAutoUnlock()
        else
            AutoUnlockRunning = false
        end
    end
})

if EventSettings.AutoUnlock then StartAutoUnlock() end
-- [END] Auto Unlock: chụp trạng thái nhà một lần, theo dõi giá bằng sự kiện


-- [START] Auto Knock House: toggle quét Roll, knock nhà theo thứ tự và tap boss
local AutoKnockHouseRunning = false

local function ReadHouseRollText(hatchWar, houseNumber)
    local interact = hatchWar and hatchWar:FindFirstChild("INTERACT")
    local doors = interact and interact:FindFirstChild("Doors")
    local door = doors and doors:FindFirstChild(tostring(houseNumber))
    local billboard = door and door:FindFirstChild("HatchWarHouseBillboard")
    local houseBillboard = billboard and billboard:FindFirstChild("HatchWarHouse")
    if not houseBillboard then return nil end

    -- Tìm Amount như đường dẫn giá; ưu tiên Amount trực tiếp, sau đó dò sâu.
    local amountObject = houseBillboard:FindFirstChild("Amount")
    if not amountObject then
        local amountContainer = houseBillboard:FindFirstChild("Price")
        amountObject = amountContainer and amountContainer:FindFirstChild("Amount")
    end
    if not amountObject then
        for _, descendant in ipairs(houseBillboard:GetDescendants()) do
            if descendant.Name == "Amount" and descendant:IsA("TextLabel") then
                amountObject = descendant
                break
            end
        end
    end

    if amountObject and (amountObject:IsA("TextLabel") or amountObject:IsA("TextButton")) then
        return tostring(amountObject.Text or "")
    end
    return nil
end

local function TeleportToHouse(houseNumber)
    local position = HouseUnlockPositions[houseNumber]
    if not position then return false end
    local ok = pcall(function()
        local character = Player.Character or Player.CharacterAdded:Wait()
        local root = character:FindFirstChild("HumanoidRootPart")
            or character:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(position)
    end)
    return ok
end

local function StartAutoKnockHouse()
    if AutoKnockHouseRunning then return end
    AutoKnockHouseRunning = true

    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local invokeRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")
        local originalCFrame = nil

        while EventSettings.AutoKnockHouse and AutoKnockHouseRunning do
            local _, hatchWar = GetHatchWarHouses()
            local rollHouses = {}
            for houseNumber = 1, 8 do
                local amountText = ReadHouseRollText(hatchWar, houseNumber)
                if amountText and string.find(string.lower(amountText), "roll", 1, true) then
                    table.insert(rollHouses, houseNumber)
                end
            end
            AutoKnockPending = #rollHouses > 0 and EventSettings.AutoKnockHouse and AutoKnockHouseRunning

            if #rollHouses > 0 and not IsBossFightActive() and not AutoHouseActionBusy
                and not (EventSettings.AutoUnlock and AutoUnlockPending) then
                AutoHouseActionBusy = true
                AutoBossPausedForHouseAction = true
                if not originalCFrame then
                    pcall(function()
                        local ch = Player.Character or Player.CharacterAdded:Wait()
                        local rt = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart")
                        originalCFrame = rt.CFrame
                    end)
                end

                for _, houseNumber in ipairs(rollHouses) do
                    if not AutoKnockHouseRunning or IsBossFightActive() then break end
                    local _, currentHatchWar = GetHatchWarHouses()
                    local currentText = ReadHouseRollText(currentHatchWar, houseNumber)
                    if currentText and string.find(string.lower(currentText), "roll", 1, true)
                        and not IsBossFightActive() then
                        local teleported = TeleportToHouse(houseNumber)
                        if teleported then
                            task.wait(0.15)
                            if IsBossFightActive() then break end
                            local ok, result = pcall(function()
                                if IsBossFightActive() then return end
                                return invokeRemote:InvokeServer("HatchWar", "HW_Doors_Knock", houseNumber)
                            end)
                            if not ok then
                                warn("[Auto Knock House] Knock nhà " .. houseNumber .. " lỗi: " .. tostring(result))
                            else
                                print("[Auto Knock House] Đã gửi Knock nhà " .. houseNumber .. " | Amount: " .. currentText)
                            end
                            task.wait(0.15)
                        end
                    end
                end

                if originalCFrame and not IsBossFightActive() then
                    pcall(function()
                        local ch = Player.Character or Player.CharacterAdded:Wait()
                        local rt = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart")
                        if not IsBossFightActive() then rt.CFrame = originalCFrame end
                    end)
                end
                AutoHouseActionBusy = false
                AutoBossPausedForHouseAction = false
            end

            task.wait(0.2)
        end
        AutoKnockPending = false
        AutoKnockHouseRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Knock House",
    CurrentValue = EventSettings.AutoKnockHouse,
    Callback = function(Value)
        EventSettings.AutoKnockHouse = Value
        SaveConfig()
        if Value then StartAutoKnockHouse() else AutoKnockHouseRunning = false end
    end
})

if EventSettings.AutoKnockHouse then StartAutoKnockHouse() end
-- [END] Auto Knock House: toggle quét Roll, knock nhà theo thứ tự và tap boss

