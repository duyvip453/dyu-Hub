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

-- [START] Khởi tạo tab Event trên cửa sổ do loader.lua truyền vào
return function(Window)
    if type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
        warn("[DYU HUB / EVENT] Cửa sổ chính không hợp lệ.")
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
end
-- [END] Khởi tạo tab Event trên cửa sổ do loader.lua truyền vào
