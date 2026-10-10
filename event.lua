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

-- [START] Auto HW Boss Tap: toggle và vòng lặp thử nghiệm cục bộ
EventTab:CreateSection("Event")
EventTab:CreateLabel({
    Text = "Bật/tắt vòng lặp thử nghiệm cục bộ; không gửi RemoteEvent.",
    Style = 1
})
EventTab:CreateSection("Hatch War")

local AutoTapRunning = false
local AutoTapTicks = 0

-- Hàm xử lý thử nghiệm cục bộ. Thay phần thân bằng logic an toàn trong môi trường bạn sở hữu.
local function HandleAutoTapTestTick()
    AutoTapTicks += 1
end

local function StartAutoTapTest()
    if AutoTapRunning then return end
    AutoTapRunning = true

    task.spawn(function()
        while EventSettings.AutoHatchWarBossTap and AutoTapRunning do
            local ok, err = pcall(HandleAutoTapTestTick)
            if not ok then
                warn("[DYU HUB / EVENT] Auto HW Boss Tap test error:", err)
            end
            task.wait(0.1)
        end
        AutoTapRunning = false
    end)
end

EventTab:CreateToggle({
    Name = "Auto HW Boss Tap",
    CurrentValue = EventSettings.AutoHatchWarBossTap,
    Callback = function(Value)
        EventSettings.AutoHatchWarBossTap = Value
        SaveConfig()

        if Value then
            print("[DYU HUB / EVENT] Auto HW Boss Tap test: ON")
            StartAutoTapTest()
        else
            AutoTapRunning = false
            print("[DYU HUB / EVENT] Auto HW Boss Tap test: OFF")
        end
    end
})
-- [END] Auto HW Boss Tap: toggle và vòng lặp thử nghiệm cục bộ
