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
    Icon = "calendar",
    ImageSource = "Material",
    ShowTitle = true
})
-- [END] Tải module giao diện và tạo cửa sổ/tab chính

-- [START] Tạo tab Event theo đúng API của loader.lua
local EventTab = Window:CreateTab({
    Name = "Event",
    Icon = "calendar",
    ImageSource = "Material",
    ShowTitle = true
})

EventTab:CreateSection("Event")
EventTab:CreateLabel({
    Text = "Event module đã tải. Chức năng và config Event được quản lý riêng tại event.lua.",
    Style = 1
})

-- [START] TOGGLE: AUTO HW BOSS TAP
-- Toggle chỉ lưu trạng thái; không tự gửi RemoteEvent tới server game.
EventTab:CreateSection("Hatch War")
EventTab:CreateToggle({
    Name = "Auto HW Boss Tap",
    CurrentValue = EventSettings.AutoHatchWarBossTap,
    Callback = function(Value)
        EventSettings.AutoHatchWarBossTap = Value
        SaveConfig()
        if Value then
            print("[DYU HUB / EVENT] Auto HW Boss Tap: ON")
        else
            print("[DYU HUB / EVENT] Auto HW Boss Tap: OFF")
        end
    end
})
-- [END] TOGGLE: AUTO HW BOSS TAP
-- [END] Tạo tab Event theo đúng API của loader.lua
