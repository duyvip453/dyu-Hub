-- ============================================================
-- TEST UI: EGG SLOT + AUTO HATCH
-- Chi chua UI va toggle; chua gan logic automation.
-- ============================================================

-- [START] Khoi tao dich vu va config rieng
local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
local ConfigFileName = "DYUHUB_TEST_UI_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"
-- [END] Khoi tao dich vu va config rieng


-- [START] Settings
local Settings = {
    AutoUpdateEgg = false,
    AutoUpdatePet = false,
    AutoHatch = false,
}
-- [END] Settings


-- [START] Luu config
local function SaveConfig()
    if type(writefile) ~= "function" then
        return
    end

    pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)
end
-- [END] Luu config


-- [START] Doc config
local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return
    end

    local ok, exists = pcall(function()
        return isfile(ConfigFileName)
    end)
    if not ok or not exists then
        return
    end

    local readOk, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFileName))
    end)
    if not readOk or type(data) ~= "table" then
        return
    end

    for key, defaultValue in pairs(Settings) do
        local value = data[key]
        if value ~= nil and type(value) == type(defaultValue) then
            Settings[key] = value
        end
    end
end

LoadConfig()
-- [END] Doc config


-- [START] Tai UI module
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local downloadOk, rawCode = pcall(function()
    return game:HttpGet(bgUrl)
end)
if not downloadOk or type(rawCode) ~= "string" or rawCode == "" then
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
-- [END] Tai UI module


-- [START] Khoi tao UI
local initOk, Window = pcall(function()
    return UIModule:Init({
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DYU_HUB_TEST",
            FileName = "LoaderUITest"
        }
    })
end)
if not initOk or type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
    return
end

local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})
-- [END] Khoi tao UI


-- [START] Toggle Auto Update Egg slot
Tab1:CreateToggle({
    Name = "Auto Update Egg slot",
    CurrentValue = Settings.AutoUpdateEgg,
    Callback = function(Value)
        Settings.AutoUpdateEgg = Value
        SaveConfig()
    end
})
-- [END] Toggle Auto Update Egg slot


-- [START] Toggle Auto Update pet slot
Tab1:CreateToggle({
    Name = "Auto Update pet slot",
    CurrentValue = Settings.AutoUpdatePet,
    Callback = function(Value)
        Settings.AutoUpdatePet = Value
        SaveConfig()
    end
})
-- [END] Toggle Auto Update pet slot


-- [START] Toggle Auto Hatch (UI only)
Tab1:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = Settings.AutoHatch,
    Callback = function(Value)
        Settings.AutoHatch = Value
        SaveConfig()
    end
})
-- [END] Toggle Auto Hatch
