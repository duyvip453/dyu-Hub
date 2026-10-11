-- ============================================================
-- TEST PROJECT: UI LOADER + AUTO HATCH TOGGLE (CHUA CO SCRIPT)
-- Muc dich: test giao dien va luu config doc lap, khong chay logic hatch.
-- ============================================================

-- [START] Khoi tao dich vu va danh tinh config rieng cho TEST
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Config rieng cua test: tach theo PlaceId va UserId de khong de file khac ghi de.
local ConfigFileName = "DYUHUB_TEST_AutoHatch_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

-- [END] Khoi tao dich vu va danh tinh config rieng cho TEST


-- [START] Settings rieng cua file TEST
local Settings = {
    AutoHatch = false,
}

-- [END] Settings rieng cua file TEST


-- [START] Luu config rieng cua file TEST
local function SaveConfig()
    if type(writefile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)

    return ok
end

-- [END] Luu config rieng cua file TEST


-- [START] Doc config rieng cua file TEST
local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return
    end

    local existsOk, exists = pcall(function()
        return isfile(ConfigFileName)
    end)

    if not existsOk or not exists then
        return
    end

    local readOk, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFileName))
    end)

    if not readOk or type(data) ~= "table" then
        return
    end

    -- Chi nap key da khai bao va dung kieu du lieu.
    for key, defaultValue in pairs(Settings) do
        local value = data[key]
        if value ~= nil and type(value) == type(defaultValue) then
            Settings[key] = value
        end
    end
end

LoadConfig()
-- [END] Doc config rieng cua file TEST


-- [START] Tai dung UI module ma loader chinh dang su dung
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)

local downloadOk, rawCode = pcall(function()
    return game:HttpGet(bgUrl)
end)

if not downloadOk or type(rawCode) ~= "string" or rawCode == "" then
    warn("[TEST] Khong tai duoc UI module.")
    return
end

local compileUI = loadstring(rawCode)
if type(compileUI) ~= "function" then
    warn("[TEST] Khong bien dich duoc UI module.")
    return
end

local moduleOk, UIModule = pcall(compileUI)
if not moduleOk or type(UIModule) ~= "table" or type(UIModule.Init) ~= "function" then
    warn("[TEST] UI module khong hop le.")
    return
end
-- [END] Tai dung UI module


-- [START] Khoi tao UI voi namespace config rieng cho TEST
-- FolderName/FileName duoc tach khoi config cua loader va cac file khac.
local initOk, Window = pcall(function()
    return UIModule:Init({
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DYU_HUB_TEST",
            FileName = "AutoHatchTest"
        }
    })
end)

if not initOk or type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
    warn("[TEST] Khoi tao UI that bai.")
    return
end

local TestTab = Window:CreateTab({
    Name = "TEST",
    Icon = "flask-conical",
    ImageSource = "Material",
    ShowTitle = true
})
-- [END] Khoi tao UI


-- [START] Toggle Auto Hatch (CHI TEST UI, CHUA CO SCRIPT)
TestTab:CreateSection("Auto Hatch - TEST")

TestTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = Settings.AutoHatch,
    Callback = function(Value)
        -- Chi cap nhat va luu trang thai toggle.
        -- CHUA co loop, remote, hatch request hay automation nao duoc chay.
        Settings.AutoHatch = Value
        SaveConfig()

        print("[TEST] Auto Hatch toggle =", Value, "(UI only; script chua duoc gan)")
    end
})
-- [END] Toggle Auto Hatch


-- [START] Hoan tat khoi dong
print("[TEST] UI da khoi dong. Auto Hatch hien chi la toggle, chua co script.")
-- [END] Hoan tat khoi dong
