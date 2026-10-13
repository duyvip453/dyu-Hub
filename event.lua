local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer

-- HW_BossScore tồn tại = đang đánh boss; không tồn tại = chưa đánh boss.
local function IsBossFightActive()
    local workspaceRoot = workspace:FindFirstChild("duycheck022")
    local head = workspaceRoot and workspaceRoot:FindFirstChild("Head")
    local score = head and head:FindFirstChild("HW_BossScore")
    return score ~= nil and score:FindFirstChild("HW_BossScore") ~= nil
end

local ConfigFileName = "DYUHUB_Event_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local EventSettings = {
    AutoHatchWarBossTap = false,
    AutoEgg = false,
    AutoJump = false,
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

-- [START] Auto Egg: gọi hatch trực tiếp, không teleport
local AutoEggRunning = false
local AutoEggEggId = nil

local function GetAutoEggId()
    local things = workspace:FindFirstChild("__THINGS")
    local eggsFolder = things and things:FindFirstChild("CustomEggs")
    if not eggsFolder then
        return nil
    end

    -- Chọn egg có BottomLight gần nhân vật nhất, chỉ để xác định ID; không di chuyển nhân vật.
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local nearestEgg, nearestDistance = nil, math.huge

    for _, egg in ipairs(eggsFolder:GetChildren()) do
        local bottomLight = egg:FindFirstChild("BottomLight", true)
        if bottomLight and bottomLight:IsA("BasePart") and root then
            local distance = (bottomLight.Position - root.Position).Magnitude
            if distance < nearestDistance then
                nearestEgg, nearestDistance = egg, distance
            end
        end
    end

    return nearestEgg
end

local function StartAutoEgg()
    if AutoEggRunning then return end
    AutoEggRunning = true

    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local hatchRemote = network:WaitForChild("CustomEggs_Hatch")

        local startedAt = os.clock()
        local egg
        repeat
            egg = GetAutoEggId()
            if egg then break end
            task.wait(0.25)
        until not (EventSettings.AutoEgg and AutoEggRunning) or os.clock() - startedAt >= 15

        if not egg then
            warn("[Auto Egg] Không tìm thấy egg để lấy ID.")
            AutoEggRunning = false
            return
        end

        AutoEggEggId = egg.Name
        print("[Auto Egg] Egg ID: " .. tostring(AutoEggEggId) .. "; không teleport.")

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
-- [END] Auto Egg: gọi hatch trực tiếp, không teleport
-- [START] Auto HW Boss Tap
local AutoTapRunning = false
-- Auto Knock có thể chặn vòng bắt đầu boss mới trong khi vẫn để Auto Tap chạy tới hết trận.
local AutoBossStartSuppressed = false

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

    if not IsBossFightActive() then
        TeleportToHWBossPosition()
    end
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
            if not AutoBossStartSuppressed and not IsBossFightActive() then
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

            if not IsBossFightActive() then
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

-- [START] Auto Knock House: quét H1-H8, xử lý mọi nhà có giá chứa "roll".
local AutoKnockRunning = false
local HousePositions = {
    [1] = Vector3.new(7489.3994140625, 19.386381149291992, 21917.48046875),
    [2] = Vector3.new(7487.59326171875, 19.636981964111328, 22083.86328125),
    [3] = Vector3.new(7545.201171875, 19.386701583862305, 21917.572265625),
    [4] = Vector3.new(7534.21435546875, 19.637348175048828, 22083.759765625),
    [5] = Vector3.new(7589.15625, 19.636981964111328, 21916.24609375),
    [6] = Vector3.new(7577.74755859375, 19.636981964111328, 22084.13671875),
    [7] = Vector3.new(7635.67431640625, 19.636600494384766, 21915.638671875),
    [8] = Vector3.new(7634.23095703125, 19.636600494384766, 22084.3125),
}

local function GetOpenHouseNumbers()
    local openHouses = {}
    local things = workspace:FindFirstChild("__THINGS")
    local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = container and container:FindFirstChild("Active")
    local hatchWar = active and active:FindFirstChild("HatchWar")
    local interact = hatchWar and hatchWar:FindFirstChild("INTERACT")
    local doors = interact and interact:FindFirstChild("Doors")

    if not doors then
        warn("[Auto Knock] Không tìm thấy path INTERACT.Doors.")
        return openHouses
    end

    for houseNumber = 1, 8 do
        local door = doors:FindFirstChild(tostring(houseNumber))
        local billboard = door and door:FindFirstChild("HatchWarHouseBillboard")
        local house = billboard and billboard:FindFirstChild("HatchWarHouse")
        local price = house and house:FindFirstChild("Price")
        local amount = price and price:FindFirstChild("Amount")
        local text = ""

        if amount then
            if amount:IsA("TextLabel") or amount:IsA("TextButton") or amount:IsA("TextBox") then
                text = amount.Text
            else
                local textOk, value = pcall(function() return amount.Text end)
                if textOk and type(value) == "string" then
                    text = value
                end
            end
        end

        if text:lower():find("roll", 1, true) then
            table.insert(openHouses, houseNumber)
        end
    end

    return openHouses
end

local function GetCharacterRoot()
    local character = Player.Character or Player.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
end

local function PauseAutoBossStart()
    local wasEnabled = EventSettings.AutoHatchWarBossTap
    -- Ngăn remote bắt đầu trận mới, nhưng vẫn cho vòng Auto Tap xử lý trận hiện tại.
    AutoBossStartSuppressed = true

    if IsBossFightActive() then
        print("[Auto Knock] Đang có boss; chờ trận hiện tại kết thúc.")
        repeat task.wait(0.2) until not IsBossFightActive() or not AutoKnockRunning
    end

    if not AutoKnockRunning then
        AutoBossStartSuppressed = false
        return false, wasEnabled
    end

    if wasEnabled then
        EventSettings.AutoHatchWarBossTap = false
        AutoTapRunning = false
        SaveConfig()
    end

    -- Đợi 1 giây và xác nhận score path không còn tồn tại trước khi teleport.
    task.wait(1)
    if IsBossFightActive() then
        warn("[Auto Knock] Score path vẫn tồn tại; chờ boss kết thúc trước khi Knock.")
        repeat task.wait(0.2) until not IsBossFightActive() or not AutoKnockRunning
    end

    return AutoKnockRunning, wasEnabled
end

local function RestoreAutoBoss(wasEnabled)
    AutoBossStartSuppressed = false
    if wasEnabled then
        EventSettings.AutoHatchWarBossTap = true
        SaveConfig()
        StartAutoHWTap()
    end
end

local function ProcessOpenHouses(openHouses)
    if #openHouses == 0 then
        print("[Auto Knock] Không có nhà nào chứa 'roll'.")
        return
    end

    local wasBossEnabled = EventSettings.AutoHatchWarBossTap
    local ready = PauseAutoBossStart()

    if not ready then
        RestoreAutoBoss(wasBossEnabled)
        return
    end

    -- Lưu vị trí ngay trước khi bắt đầu teleport qua các nhà.
    local root = GetCharacterRoot()
    local originalCFrame = root.CFrame
    print("[Auto Knock] Đã lưu vị trí ban đầu; sẽ quay về sau khi xử lý danh sách nhà.")

    local network = ReplicatedStorage:WaitForChild("Network")
    local knockRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")

    local ok, err = pcall(function()
        for _, houseNumber in ipairs(openHouses) do
            if not AutoKnockRunning or not EventSettings.AutoKnockHouse then
                break
            end

            local targetPosition = HousePositions[houseNumber]
            if targetPosition then
                root = GetCharacterRoot()
                root.CFrame = CFrame.new(targetPosition)
                task.wait(0.25)

                -- Ghi rõ kết quả remote để phân biệt lỗi gọi hàm với server từ chối hành động.
                print(string.format(
                    "[Auto Knock] Gọi Knock: house=%d, position=(%.2f, %.2f, %.2f)",
                    houseNumber, targetPosition.X, targetPosition.Y, targetPosition.Z
                ))
                local callOk, result = pcall(function()
                    return knockRemote:InvokeServer("HatchWar", "HW_Doors_Knock", houseNumber)
                end)

                if callOk then
                    print("[Auto Knock] Remote trả về cho nhà " .. tostring(houseNumber) .. ": " .. tostring(result))
                else
                    warn("[Auto Knock] Remote lỗi ở nhà " .. tostring(houseNumber) .. ": " .. tostring(result))
                end
                task.wait(0.75)
            end
        end
    end)

    -- Sau khi xử lý xong danh sách nhà, đưa nhân vật về vị trí đã lưu.
    local returnOk, returnErr = pcall(function()
        local currentRoot = GetCharacterRoot()
        currentRoot.CFrame = originalCFrame
    end)
    if returnOk then
        print("[Auto Knock] Đã quay về vị trí ban đầu.")
    else
        warn("[Auto Knock] Không thể quay về vị trí ban đầu: " .. tostring(returnErr))
    end

    RestoreAutoBoss(wasBossEnabled)

    if not ok then
        warn("[Auto Knock] Lỗi khi xử lý nhà: " .. tostring(err))
    end
end

local function StartAutoKnock()
    if AutoKnockRunning then return end
    AutoKnockRunning = true

    task.spawn(function()
        while AutoKnockRunning and EventSettings.AutoKnockHouse do
            local openHouses = GetOpenHouseNumbers()
            if #openHouses > 0 then
                ProcessOpenHouses(openHouses)
            end
            task.wait(5)
        end
        AutoKnockRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Knock House",
    CurrentValue = EventSettings.AutoKnockHouse,
    Callback = function(Value)
        EventSettings.AutoKnockHouse = Value
        SaveConfig()
        if Value then
            StartAutoKnock()
        else
            AutoKnockRunning = false
        end
    end
})

if EventSettings.AutoKnockHouse then
    StartAutoKnock()
end
-- [END] Auto Knock House

