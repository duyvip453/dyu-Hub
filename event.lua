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

-- [START] Auto Egg: lấy vị trí egg + Break Zone động, teleport một lần rồi hatch
local AutoEggRunning = false
local AutoEggTeleported = false
local AutoEggEggId = nil

local function GetAutoEggTargets()
    local things = workspace:FindFirstChild("__THINGS")
    local eggsFolder = things and things:FindFirstChild("CustomEggs")
    local instanceContainer = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = instanceContainer and instanceContainer:FindFirstChild("Active")
    local hatchWar = active and active:FindFirstChild("HatchWar")
    local zoneGround = hatchWar and hatchWar:FindFirstChild("ZONE_GROUND")
    local zone = zoneGround and zoneGround:FindFirstChild("6")

    if not eggsFolder or not zone or not zone:IsA("BasePart") then
        return nil, nil
    end

    -- Chọn egg có BottomLight gần Break Zone nhất trên mặt phẳng X/Z.
    local nearestEgg, nearestPart, nearestDistance = nil, nil, math.huge
    for _, egg in ipairs(eggsFolder:GetChildren()) do
        local bottomLight = egg:FindFirstChild("BottomLight", true)
        if bottomLight and bottomLight:IsA("BasePart") then
            local eggPos = bottomLight.Position
            local zonePos = zone.Position
            local dx = eggPos.X - zonePos.X
            local dz = eggPos.Z - zonePos.Z
            local distance = dx * dx + dz * dz
            if distance < nearestDistance then
                nearestEgg, nearestPart, nearestDistance = egg, bottomLight, distance
            end
        end
    end

    return nearestEgg, nearestPart, zone
end

local function TeleportToAutoEggOnce(eggPart, zone)
    if AutoEggTeleported then return true end

    local ok, err = pcall(function()
        local eggPos = eggPart.Position
        local zonePos = zone.Position
        -- Đứng ở trung điểm X/Z giữa egg và Break Zone, nhưng giữ Y bằng Y của egg.
        local target = Vector3.new(
            (eggPos.X + zonePos.X) / 2,
            eggPos.Y,
            (eggPos.Z + zonePos.Z) / 2
        )

        local character = Player.Character or Player.CharacterAdded:Wait()
        local root = character:FindFirstChild("HumanoidRootPart")
            or character:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(target)
    end)

    if ok then
        AutoEggTeleported = true
        print("[Auto Egg] Đã teleport một lần tới trung điểm X/Z, giữ Y theo BottomLight của egg.")
        return true
    end

    warn("[Auto Egg] Teleport thất bại: " .. tostring(err))
    return false
end

local function StartAutoEgg()
    if AutoEggRunning then return end
    AutoEggRunning = true

    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local hatchRemote = network:WaitForChild("CustomEggs_Hatch")
        print("[Auto Egg] Đã tìm thấy remote CustomEggs_Hatch.")

        local egg, eggPart, zone
        local startedAt = os.clock()
        repeat
            egg, eggPart, zone = GetAutoEggTargets()
            if egg and eggPart and zone then break end
            task.wait(0.25)
        until not (EventSettings.AutoEgg and AutoEggRunning) or os.clock() - startedAt >= 15

        if not (egg and eggPart and zone) then
            warn("[Auto Egg] Không tìm thấy egg có BottomLight hoặc Break Zone HatchWar ZONE_GROUND[6].")
            AutoEggRunning = false
            return
        end

        AutoEggEggId = egg.Name
        print("[Auto Egg] Đã xác định egg ID từ Model: " .. AutoEggEggId)

        -- Chỉ teleport một lần khi bật Auto Egg; không teleport trong vòng hatch.
        if not TeleportToAutoEggOnce(eggPart, zone) then
            AutoEggRunning = false
            return
        end

        while EventSettings.AutoEgg and AutoEggRunning do
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
-- [END] Auto Egg: lấy vị trí egg + Break Zone động, teleport một lần rồi hatch
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

-- [START] Auto Unlock: ĐÃ VÔ HIỆU HÓA
-- Tính năng Auto Unlock được tắt hoàn toàn để tránh quét inventory/nhà và gọi remote.
-- Giữ toggle hiển thị nhưng luôn tắt để tương thích giao diện; không tạo task nền.
EventSettings.AutoUnlock = false
AutoUnlockPending = false

EventTab:CreateToggle({
    Name = "Auto Unlock (Disabled)",
    CurrentValue = false,
    Callback = function(_)
        EventSettings.AutoUnlock = false
        AutoUnlockPending = false
        SaveConfig()
        warn("[Auto Unlock] Tính năng đã bị vô hiệu hóa trong event.lua.")
    end
})
-- [END] Auto Unlock: ĐÃ VÔ HIỆU HÓA

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

