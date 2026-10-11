local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
local ConfigFileName = "DYUHUB_Event_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local EventSettings = {
    AutoHatchWarBossTap = false,
    AutoEgg = false,
    AutoJump = false,
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

-- [START] Auto Knock House: nhảy mỗi 5 phút
local AutoJumpRunning = false

local function StartAutoJump()
    if AutoJumpRunning then return end
    AutoJumpRunning = true

    task.spawn(function()
        while EventSettings.AutoJump and AutoJumpRunning do
            pcall(function()
                local character = Player.Character or Player.CharacterAdded:Wait()
                local humanoid = character:WaitForChild("Humanoid")
                humanoid.Jump = true
            end)

            task.wait(300)
        end

        AutoJumpRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto Knock House",
    CurrentValue = EventSettings.AutoJump,
    Callback = function(Value)
        EventSettings.AutoJump = Value
        SaveConfig()

        if Value then
            StartAutoJump()
        else
            AutoJumpRunning = false
        end
    end
})

if EventSettings.AutoJump then
    StartAutoJump()
end
-- [END] Auto Knock House: nhảy mỗi 5 phút

