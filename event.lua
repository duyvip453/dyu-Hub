-- [START] EVENT MODULE: dùng chung UI từ backgroud.lua, còn chức năng và config độc lập.

-- [START] Config riêng của Event (cùng cơ chế save/load như loader.lua)
local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
local ConfigFileName = "DYUHUB_Event_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local EventSettings = {
    AutoHatchWarBossTap = false,
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
-- [END] Config riêng của Event

-- [START] Tải module giao diện và tạo cửa sổ/tab chính
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


-- [END] Tải module giao diện và tạo cửa sổ/tab chính

-- [START] Auto HW Boss: LiveCircle + Tap remote + Boss Start remote
EventTab:CreateSection("Hatch War")

local AutoTapRunning = false

local function StartAutoHWTap()
    if AutoTapRunning then return end
    AutoTapRunning = true

    -- [START] Teleport ngay khi bật toggle, trước khi chạy hai loop remote
    local function TeleportToHWBossPosition()
        local ok, err = pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local root = character:WaitForChild("HumanoidRootPart")
            root.CFrame = CFrame.new(6950.587890625, 16.337787628173828, 21980.33984375)
        end)

        if not ok then
            warn("[DYU HUB / EVENT] Auto HW Teleport error:", err)
        end
    end

    TeleportToHWBossPosition()
    -- [END] Teleport ngay khi bật toggle, trước khi chạy hai loop remote

    -- [START] Loop 1: kích hoạt LiveCircle và gọi Tap remote
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

            if not ok then
                warn("[DYU HUB / EVENT] Auto HW Tap error:", err)
            end

            task.wait(0.2)
        end
    end)
    -- [END] Loop 1: kích hoạt LiveCircle và gọi Tap remote

    -- [START] Loop 2: gọi Boss Start remote tuần tự, có khoảng nghỉ
    task.spawn(function()
        local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
        local startRemote = network:WaitForChild("Instancing_InvokeCustomFromClient")

        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            local ok, err = pcall(function()
                startRemote:InvokeServer("HatchWar", "HW_Boss_Start", 4)
            end)

            if not ok then
                warn("[DYU HUB / EVENT] Auto HW Boss Start error:", err)
            end

            -- InvokeServer có thể yield; nghỉ thêm để tránh gửi yêu cầu quá dày.
            task.wait(0.5)
        end
    end)
    -- [END] Loop 2: gọi Boss Start remote tuần tự, có khoảng nghỉ

    -- [START] Loop 3: teleport lại về tọa độ mục tiêu mỗi 5 giây
    task.spawn(function()
        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            task.wait(5)
            if not (EventSettings.AutoHatchWarBossTap and AutoTapRunning) then
                break
            end

            TeleportToHWBossPosition()
        end
    end)
    -- [END] Loop 3: teleport lại về tọa độ mục tiêu mỗi 5 giây
end

EventTab:CreateToggle({
    Name = "Auto HW Boss Tap",
    CurrentValue = EventSettings.AutoHatchWarBossTap,
    Callback = function(Value)
        EventSettings.AutoHatchWarBossTap = Value
        SaveConfig()

        if Value then
            print("[DYU HUB / EVENT] Auto HW Boss: ON")
            StartAutoHWTap()
        else
            AutoTapRunning = false
            print("[DYU HUB / EVENT] Auto HW Boss: OFF")
        end
    end
})

if EventSettings.AutoHatchWarBossTap then
    StartAutoHWTap()
end
-- [END] Auto HW Boss: LiveCircle + Tap remote + Boss Start remote

