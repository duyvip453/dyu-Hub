local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
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

-- [START] BuyMax: tính tổng Egg Owned và cập nhật liên tục
local CurrentMaxEggHatchAmount = 1

local function RefreshMaxEggHatchAmount()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local machines = playerGui and playerGui:FindFirstChild("_MACHINES")
    local eggSlotsMachine = machines and machines:FindFirstChild("EggSlotsMachine")
    local frame = eggSlotsMachine and eggSlotsMachine:FindFirstChild("Frame")
    local slots = frame and frame:FindFirstChild("Slots")
    local items = slots and slots:FindFirstChild("Items")
    local slotsSection = items and items:FindFirstChild("SlotsSection")
    local slotsContainer = slotsSection and slotsSection:FindFirstChild("Slots")
    if not slotsContainer then
        return CurrentMaxEggHatchAmount
    end

    local totalEggs = 0
    local foundOwnedSlot = false

    for _, slot in ipairs(slotsContainer:GetDescendants()) do
        if slot.Name == "OwnedSlot" then
            local title = slot:FindFirstChild("Title", true)
            if title and title:IsA("TextLabel") then
                local amountText = tostring(title.Text or "")
                local amount = tonumber(amountText:match("%+(%d+)%s*[Ee]gg"))
                    or tonumber(amountText:match("%+(%d+)"))
                if amount and amount > 0 then
                    totalEggs = totalEggs + math.floor(amount)
                    foundOwnedSlot = true
                end
            end
        end
    end

    if foundOwnedSlot then
        CurrentMaxEggHatchAmount = math.max(1, totalEggs)
    end

    return CurrentMaxEggHatchAmount
end

task.spawn(function()
    while task.wait(0.5) do
        RefreshMaxEggHatchAmount()
    end
end)
-- [END] BuyMax: tính tổng Egg Owned và cập nhật liên tục

-- [START] Reset EggSlotsMachine BuyMax một lần khi khởi động
task.spawn(function()
    task.wait(1)

    local RS = game:GetService("ReplicatedStorage")
    local playerGui = Player:WaitForChild("PlayerGui")
    local machines = playerGui:WaitForChild("_MACHINES")
    local gui = machines:WaitForChild("EggSlotsMachine")
    local TabController = require(RS:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("TabController"))

    TabController.OpenTab("EggSlotsMachine")
    task.wait()
    gui.Enabled = false
end)
-- [END] Reset EggSlotsMachine BuyMax một lần khi khởi động

-- [START] Auto Egg: gọi CustomEggs_Hatch với tổng Owned Egg đã quét
local AutoEggRunning = false

local function StartAutoEgg()
    if AutoEggRunning then return end
    AutoEggRunning = true

    task.spawn(function()
        pcall(function()
            local character = Player.Character or Player.CharacterAdded:Wait()
            local root = character:WaitForChild("HumanoidRootPart")
            root.CFrame = CFrame.new(7537.853515625, 16.33778953552246, 21972.216796875)
        end)

        local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
        local hatchRemote = network:WaitForChild("CustomEggs_Hatch")

        while EventSettings.AutoEgg and AutoEggRunning do
            pcall(function()
                local amount = RefreshMaxEggHatchAmount()
                hatchRemote:InvokeServer("c63e54df863d449e934db74b66433996", amount)
            end)
            task.wait(0.5)
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
-- [END] Auto Egg: gọi CustomEggs_Hatch với tổng Owned Egg đã quét
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

    TeleportToHWBossPosition()
-- [END] Teleport tọa độ mục tiêu
-- [START] LiveCircle + HW_Boss_Tap
    task.spawn(function()
        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
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
            local ok, err = pcall(function()
                startRemote:InvokeServer("HatchWar", "HW_Boss_Start", 6)
            end)
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

            TeleportToHWBossPosition()
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

-- [START] Auto Unlock: quét trạng thái, chờ đủ item, mở nhà đầu tiên còn khóa
local AutoUnlockRunning = false
local HouseUnlockStates = {}
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
        local children = current:GetChildren()
        current = children[childIndex]
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

local function ScanHouseUnlockStates()
    local houses = GetHatchWarHouses()
    if not houses then return end

    for houseNumber, pathInfo in pairs(HouseColorPaths) do
        local target = ResolveHouseColorTarget(houses, pathInfo)
        if target then
            local color = target.Color
            HouseUnlockStates[houseNumber] = not (
                color.R == 0 and color.G == 0 and color.B == 0
            )
        else
            HouseUnlockStates[houseNumber] = nil
        end
    end
end

-- Đọc số lượng item theo UID từ các Value/Attribute có sẵn trong client.
-- Nếu game lưu inventory ở một module riêng không xuất hiện trong các instance này,
-- cần thay phần thân hàm bằng hàm đọc inventory chính xác của game.
local function ReadUnlockItemAmount()
    local roots = { Player, Player:FindFirstChild("PlayerGui") }
    local bestAmount = nil

    local function ParseAmount(value)
        if typeof(value) == "number" then
            return math.max(0, value)
        end
        if typeof(value) == "string" then
            local digits = value:gsub(",", ""):match("%d+")
            return digits and tonumber(digits) or nil
        end
        return nil
    end

    for _, root in ipairs(roots) do
        if root then
            for _, object in ipairs(root:GetDescendants()) do
                local uidMatches = object.Name == UnlockItemUID
                    or object:GetAttribute("UID") == UnlockItemUID
                    or object:GetAttribute("ItemUID") == UnlockItemUID
                    or object:GetAttribute("Id") == UnlockItemUID

                if uidMatches then
                    local amount = nil
                    if object:IsA("IntValue") or object:IsA("NumberValue") then
                        amount = ParseAmount(object.Value)
                    end

                    if amount == nil then
                        amount = ParseAmount(object:GetAttribute("Amount"))
                            or ParseAmount(object:GetAttribute("Count"))
                    end

                    if amount == nil then
                        local amountObject = object:FindFirstChild("Amount")
                            or object:FindFirstChild("Count")
                        if amountObject and (amountObject:IsA("IntValue") or amountObject:IsA("NumberValue")
                            or amountObject:IsA("StringValue")) then
                            amount = ParseAmount(amountObject.Value)
                        end
                    end

                    if amount ~= nil then
                        bestAmount = amount
                        break
                    end
                end
            end
        end
        if bestAmount ~= nil then break end
    end

    return bestAmount
end

local function ReadHousePrice(hatchWar, houseNumber)
    local interact = hatchWar and hatchWar:FindFirstChild("INTERACT")
    local doors = interact and interact:FindFirstChild("Doors")
    local door = doors and doors:FindFirstChild(tostring(houseNumber))
    local billboard = door and door:FindFirstChild("HatchWarHouseBillboard")
    local houseBillboard = billboard and billboard:FindFirstChild("HatchWarHouse")
    local price = houseBillboard and houseBillboard:FindFirstChild("Price")
    local amount = price and price:FindFirstChild("Amount")
    if not amount then return nil end

    local text = tostring(amount.Text or ""):gsub(",", "")
    local numericText = text:match("%d+%.?%d*")
    return numericText and tonumber(numericText) or nil
end

local function GetFirstLockedHouse()
    for houseNumber = 1, 8 do
        if HouseUnlockStates[houseNumber] == false then
            return houseNumber
        end
    end
    return nil
end

local function StartAutoUnlock()
    if AutoUnlockRunning then return end
    AutoUnlockRunning = true

    task.spawn(function()
        local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
        local unlockRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")
        local lastPrintedAmount = nil
        local lastPrintedStatus = nil
        local printedNotFound = false

        while EventSettings.AutoUnlock and AutoUnlockRunning do
            -- Mỗi vòng đều quét lại cả 8 nhà để tìm căn bị khóa đầu tiên hiện tại.
            pcall(ScanHouseUnlockStates)

            local itemAmount = ReadUnlockItemAmount()
            if itemAmount ~= nil then
                if lastPrintedAmount ~= itemAmount then
                    print("[Auto Unlock] Item UID " .. UnlockItemUID .. " | số lượng: " .. tostring(itemAmount))
                    lastPrintedAmount = itemAmount
                end
                printedNotFound = false
            elseif not printedNotFound then
                warn("[Auto Unlock] Chưa tìm thấy item UID " .. UnlockItemUID .. " trong Player/PlayerGui; cần xác minh đường dẫn inventory.")
                printedNotFound = true
            end

            local targetHouse = GetFirstLockedHouse()
            if targetHouse then
                local _, hatchWar = GetHatchWarHouses()
                local housePrice = ReadHousePrice(hatchWar, targetHouse)

                if itemAmount ~= nil and housePrice ~= nil and housePrice < itemAmount then
                    print("[Auto Unlock] Nhà " .. targetHouse .. " | giá: " .. tostring(housePrice)
                        .. " | item: " .. tostring(itemAmount) .. " | đang mở khóa")

                    local character = Player.Character or Player.CharacterAdded:Wait()
                    local root = character:FindFirstChild("HumanoidRootPart")
                        or character:WaitForChild("HumanoidRootPart")
                    local originalCFrame = root.CFrame
                    local housePosition = HouseUnlockPositions[targetHouse]

                    if housePosition then
                        local teleported = pcall(function()
                            root.CFrame = CFrame.new(housePosition)
                        end)

                        if teleported then
                            task.wait(0.25)
                            local unlockOk, unlockResult = pcall(function()
                                return unlockRemote:InvokeServer("HatchWar", "HW_Doors_Unlock", targetHouse)
                            end)
                            if not unlockOk then
                                warn("[Auto Unlock] Lệnh mở nhà " .. targetHouse .. " gặp lỗi: " .. tostring(unlockResult))
                            end
                            task.wait(0.25)

                            -- Trở về vị trí ban đầu sau khi gửi lệnh mở khóa.
                            pcall(function()
                                local currentCharacter = Player.Character or Player.CharacterAdded:Wait()
                                local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart")
                                    or currentCharacter:WaitForChild("HumanoidRootPart")
                                currentRoot.CFrame = originalCFrame
                            end)

                            -- Chờ trạng thái căn vừa xử lý cập nhật rồi mới quét chọn căn tiếp theo.
                            -- Tránh gọi Unlock lặp liên tục vào cùng một căn khi server cập nhật chậm.
                            local waitStarted = os.clock()
                            local houseOpened = false
                            repeat
                                task.wait(0.25)
                                pcall(ScanHouseUnlockStates)
                                houseOpened = HouseUnlockStates[targetHouse] == true
                            until houseOpened
                                or not (EventSettings.AutoUnlock and AutoUnlockRunning)
                                or os.clock() - waitStarted >= 5

                            if houseOpened then
                                print("[Auto Unlock] Nhà " .. targetHouse .. " đã được xác nhận mở; chuyển sang quét nhà tiếp theo.")
                            else
                                warn("[Auto Unlock] Chưa xác nhận được nhà " .. targetHouse .. " đã mở. Sẽ quét lại, không spam lệnh liên tục.")
                                task.wait(1)
                            end
                        end
                    end
                elseif itemAmount ~= nil and housePrice ~= nil then
                    -- Không dịch chuyển khi chưa đủ item; tiếp tục cập nhật giá và số lượng.
                    local status = "Nhà " .. targetHouse .. " | giá: " .. tostring(housePrice)
                        .. " | item: " .. tostring(itemAmount) .. " | chưa đủ điều kiện (cần giá < item)"
                    if status ~= lastPrintedStatus then
                        print("[Auto Unlock] " .. status)
                        lastPrintedStatus = status
                    end
                end
            else
                if lastPrintedStatus ~= "all-unlocked" then
                    print("[Auto Unlock] Không còn nhà nào được đánh dấu là đang khóa.")
                    lastPrintedStatus = "all-unlocked"
                end
            end

            task.wait(0.2)
        end

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

if EventSettings.AutoUnlock then
    StartAutoUnlock()
end
-- [END] Auto Unlock: quét trạng thái, chờ đủ item, mở nhà đầu tiên còn khóa

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
        local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
        local invokeRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")
        local tapRemote = network:WaitForChild("Instancing_FireCustomFromClient")
        local playerGui = Player:FindFirstChild("PlayerGui")
        local instances = playerGui and playerGui:FindFirstChild("_INSTANCES")
        local hatchWarBoss = instances and instances:FindFirstChild("HatchWarBoss")
        local liveCircle = hatchWarBoss and hatchWarBoss:FindFirstChild("LiveCircle")
        local originalCFrame = nil
        local wasAwayFromHome = false

        -- Chạy tap/start boss song song, nhưng không teleport đến boss để tránh xung đột với knock.
        task.spawn(function()
            while EventSettings.AutoKnockHouse and AutoKnockHouseRunning do
                pcall(function()
                    if liveCircle and liveCircle:IsA("ImageButton") and liveCircle.Visible
                        and type(firesignal) == "function" then
                        firesignal(liveCircle.Activated)
                    end
                    tapRemote:FireServer("HatchWar", "HW_Boss_Tap", "circle")
                end)
                pcall(function()
                    invokeRemote:InvokeServer("HatchWar", "HW_Boss_Start", 6)
                end)
                task.wait(0.2)
            end
        end)

        while EventSettings.AutoKnockHouse and AutoKnockHouseRunning do
            local _, hatchWar = GetHatchWarHouses()
            local rollHouses = {}

            -- Quét Amount của từng nhà; chỉ lấy text có chứa "roll", theo thứ tự nhà nhỏ trước.
            for houseNumber = 1, 8 do
                local amountText = ReadHouseRollText(hatchWar, houseNumber)
                if amountText and string.find(string.lower(amountText), "roll", 1, true) then
                    table.insert(rollHouses, houseNumber)
                end
            end

            if #rollHouses > 0 then
                if not originalCFrame then
                    pcall(function()
                        local character = Player.Character or Player.CharacterAdded:Wait()
                        local root = character:FindFirstChild("HumanoidRootPart")
                            or character:WaitForChild("HumanoidRootPart")
                        originalCFrame = root.CFrame
                    end)
                end

                for _, houseNumber in ipairs(rollHouses) do
                    if not (EventSettings.AutoKnockHouse and AutoKnockHouseRunning) then break end

                    -- Quét lại ngay trước khi knock để tránh knock nhà đã hết Roll.
                    local _, currentHatchWar = GetHatchWarHouses()
                    local currentText = ReadHouseRollText(currentHatchWar, houseNumber)
                    if currentText and string.find(string.lower(currentText), "roll", 1, true) then
                        if TeleportToHouse(houseNumber) then
                            task.wait(0.15)
                            local ok, result = pcall(function()
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

                -- Sau khi knock hết các nhà đang Roll, trở về vị trí ban đầu.
                if originalCFrame then
                    pcall(function()
                        local character = Player.Character or Player.CharacterAdded:Wait()
                        local root = character:FindFirstChild("HumanoidRootPart")
                            or character:WaitForChild("HumanoidRootPart")
                        root.CFrame = originalCFrame
                    end)
                end
            end

            task.wait(0.2)
        end

        AutoKnockHouseRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Knock House",
    CurrentValue = EventSettings.AutoKnockHouse,
    Callback = function(Value)
        EventSettings.AutoKnockHouse = Value
        SaveConfig()
        if Value then
            StartAutoKnockHouse()
        else
            AutoKnockHouseRunning = false
        end
    end
})

if EventSettings.AutoKnockHouse then
    StartAutoKnockHouse()
end
-- [END] Auto Knock House: toggle quét Roll, knock nhà theo thứ tự và tap boss

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

