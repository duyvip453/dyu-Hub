-- ============================================================
-- TEST PROJECT: MIRROR UI CUA LOADER + AUTO HATCH (UI ONLY)
-- Chi dung de thu nghiem UI/config. Khong chay script farm/hatch.
-- ============================================================

-- [START] Khoi tao dich vu va config rieng cho TEST
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- File JSON rieng, tach theo PlaceId/UserId, khong dung chung voi loader/event.
local ConfigFileName = "DYUHUB_TEST_UI_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

-- [END] Khoi tao dich vu va config rieng cho TEST


-- [START] Settings rieng cho UI TEST
local Settings = {
    AutoUpdateEgg = false,
    AutoUpdatePet = false,
    AutoQuestRank = false,
    AutoHatch = false,
}
-- [END] Settings rieng cho UI TEST


-- [START] Luu config TEST
local function SaveConfig()
    if type(writefile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)

    return ok
end
-- [END] Luu config TEST


-- [START] Doc config TEST
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

    -- Chi doc key da khai bao trong Settings cua file TEST.
    for key, defaultValue in pairs(Settings) do
        local value = data[key]
        if value ~= nil and type(value) == type(defaultValue) then
            Settings[key] = value
        end
    end
end

LoadConfig()
-- [END] Doc config TEST


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
-- [END] Tai UI module


-- [START] Khoi tao UI voi namespace luu config rieng
-- Config cua thu vien UI va config JSON cua script deu duoc tach rieng.
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
    warn("[TEST] Khoi tao UI that bai.")
    return
end

local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})
-- [END] Khoi tao UI


-- [START] Mirror UI: Rank va cac dong nhiem vu (chi hien thi placeholder)
local RankLabel = Tab1:CreateLabel({Text = "Rank: TEST UI (chua ket noi)", Style = 1})

Tab1:CreateSection("Nhiệm vụ")
local EasyLabel = Tab1:CreateLabel({Text = "Easy: Chưa kết nối", Style = 1})
local MediumLabel = Tab1:CreateLabel({Text = "Medium: Chưa kết nối", Style = 1})
local HardLabel = Tab1:CreateLabel({Text = "Hard: Chưa kết nối", Style = 1})
local ExtremeLabel = Tab1:CreateLabel({Text = "Extreme: Chưa kết nối", Style = 1})
-- [END] Mirror UI: Rank/nhiem vu


-- [START] Mirror UI: Auto Update Egg slot (chi toggle + save)
Tab1:CreateToggle({
    Name = "Auto Update Egg slot",
    CurrentValue = Settings.AutoUpdateEgg,
    Callback = function(Value)
        Settings.AutoUpdateEgg = Value
        SaveConfig()
        print("[TEST UI] Auto Update Egg slot =", Value, "(chua gan script)")
    end
})
-- [END] Mirror UI: Auto Update Egg slot


-- [START] Mirror UI: Auto Update pet slot (chi toggle + save)
Tab1:CreateToggle({
    Name = "Auto Update pet slot",
    CurrentValue = Settings.AutoUpdatePet,
    Callback = function(Value)
        Settings.AutoUpdatePet = Value
        SaveConfig()
        print("[TEST UI] Auto Update pet slot =", Value, "(chua gan script)")
    end
})
-- [END] Mirror UI: Auto Update pet slot


-- [START] Mirror UI: Auto Farm Quest section
Tab1:CreateSection("Auto Farm Quest")
-- [END] Mirror UI: Auto Farm Quest section


-- [START] Toggle Auto Hatch moi (UI ONLY - CHUA CO SCRIPT)
Tab1:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = Settings.AutoHatch,
    Callback = function(Value)
        Settings.AutoHatch = Value
        SaveConfig()
        print("[TEST UI] Auto Hatch =", Value, "(UI only; chua co script)")
    end
})
-- [END] Toggle Auto Hatch


-- [START] Mirror UI: Bang uu tien nhiem vu (placeholder)
Tab1:CreateSection("Bảng ưu tiên nhiệm vụ")
local PriorityLabels = {}
for index = 1, 4 do
    PriorityLabels[index] = Tab1:CreateLabel({
        Text = "",
        Style = 1
    })
end
-- [END] Mirror UI: Bang uu tien nhiem vu


-- [START] Mirror UI: Auto Farm Rank (chi toggle + save)
Tab1:CreateToggle({
    Name = "Auto Farm Rank",
    CurrentValue = Settings.AutoQuestRank,
    Callback = function(Value)
        Settings.AutoQuestRank = Value
        SaveConfig()
        print("[TEST UI] Auto Farm Rank =", Value, "(chua gan script)")
    end
})
-- [END] Mirror UI: Auto Farm Rank


-- [START] Trang thai khoi dong
print("[TEST] Da nap UI mirror. Cac toggle chi luu config, chua chay automation.")
-- [END] Trang thai khoi dong
