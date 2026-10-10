-- [START] EVENT MODULE: dùng chung UI từ backgroud.lua, còn chức năng và config độc lập.

-- [START] Config riêng của Event (cùng cơ chế save/load như loader.lua)
local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
local ConfigFileName = "DYUHUB_Event_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local EventSettings = {
    -- Khai báo các setting riêng của Event tại đây.
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

-- [START] Tải module UI dùng chung từ backgroud.lua
local BACKGROUND_URL = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua"
local fetchOk, backgroundSource = pcall(function()
    return game:HttpGet(BACKGROUND_URL)
end)
if not fetchOk or type(backgroundSource) ~= "string" or backgroundSource == "" then
    warn("[DYU HUB / EVENT] Không tải được backgroud.lua.")
    return
end

local compileBackground = loadstring(backgroundSource)
if type(compileBackground) ~= "function" then
    warn("[DYU HUB / EVENT] Không biên dịch được backgroud.lua.")
    return
end

local moduleOk, UIModule = pcall(compileBackground)
if not moduleOk or type(UIModule) ~= "table" or type(UIModule.Init) ~= "function" then
    warn("[DYU HUB / EVENT] Module giao diện không hợp lệ.")
    return
end
-- [END] Tải module UI dùng chung từ backgroud.lua

-- [START] Khởi tạo giao diện riêng của Event
local initOk, Window = pcall(function()
    return UIModule:Init()
end)
if not initOk or type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
    warn("[DYU HUB / EVENT] Không khởi tạo được cửa sổ giao diện.")
    return
end

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

-- Khi thêm setting/toggle Event: khai báo key trong EventSettings,
-- dùng EventSettings.Key làm CurrentValue và gọi SaveConfig() trong callback.
-- [END] Khởi tạo giao diện riêng của Event

-- [END] EVENT MODULE