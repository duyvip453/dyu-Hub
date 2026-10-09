local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFileName = "DYUHUB_Config.json"

local Settings = {
    JumpToggle = false,
    SpeedSlider = 16,
    AutoUpgradeEggs = false,
    AutoUpdateEgg = false,
    AutoUpdatePet = false,
    AutoQuestBestArea = false,
    AutoQuestEggs = false,
    AutoQuestEvent = false,
    AutoQuestInventory = false
}

local function SaveConfig()
    if type(writefile) ~= "function" then
        warn("[DYU HUB] Executor không hỗ trợ writefile; không thể lưu cấu hình.")
        return false
    end

    local ok, err = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)

    if not ok then
        warn("[DYU HUB] Lưu cấu hình thất bại: " .. tostring(err))
        return false
    end

    return true
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        warn("[DYU HUB] Executor không hỗ trợ isfile/readfile; dùng cấu hình mặc định.")
        return
    end

    local existsOk, exists = pcall(function()
        return isfile(ConfigFileName)
    end)

    if not existsOk then
        warn("[DYU HUB] Không kiểm tra được file cấu hình.")
        return
    end

    if not exists then
        SaveConfig()
        return
    end

    local readOk, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFileName))
    end)

    if not readOk or type(data) ~= "table" then
        warn("[DYU HUB] Đọc file cấu hình lỗi; dùng cấu hình mặc định.")
        return
    end

    for key, value in pairs(data) do
        if Settings[key] ~= nil and type(value) == type(Settings[key]) then
            Settings[key] = value
        end
    end
end

LoadConfig()
local isLoaded = false
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or not rawCode or rawCode == "" then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub!")
end
local UIModule = loadstring(rawCode)()
local Window = UIModule:Init({
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DYU_HUB",
        FileName = "Config"
    }
})
local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

--rank
local CoreGui = game:GetService("CoreGui")
local RankLabel = Tab1:CreateLabel({Text="Đang tải Rank...",Style=1})
local RankTextObject
for _,object in next, CoreGui:GetDescendants() do
    if object:IsA("TextLabel") and object.Text == "Đang tải Rank..." then
        RankTextObject = object
        break
    end
end
if RankTextObject then
    RankTextObject.TextSize = 28
    RankTextObject.Font = Enum.Font.GothamBold
end
Tab1:CreateSection("Auto Farm Quest")

local QuestGroupEnabled = {
    BestArea = Settings.AutoQuestBestArea,
    Eggs = Settings.AutoQuestEggs,
    BestAreaEvent = Settings.AutoQuestEvent,
    InventoryItems = Settings.AutoQuestInventory
}

local QuestScriptRouter = {
    BestArea = nil,
    Eggs = nil,
    BestAreaEvent = nil,
    InventoryItems = nil
}

local function NormalizeQuestText(text)
    text = string.lower(tostring(text or ""))
    text = text:gsub("[%d,%.]", " ")
    text = text:gsub("%s+", " ")
    return text
end

local function IdentifyQuestGroup(questTitle)
    local text = NormalizeQuestText(questTitle)

    if text:find("hatch") and (
        text:find("best egg") or
        text:find("rainbow pets") or
        text:find("golden pets") or
        text:find("legendary") or
        text:find("or above")
    ) then
        return "Eggs"
    end

    if text:find("use") and (
        text:find("tier") and text:find("potion") or
        text:find("flags")
    ) then
        return "InventoryItems"
    end

    if (
        text:find("trigger") and text:find("lucky blocks")
    ) or (
        text:find("break") and text:find("in best area") and (
            text:find("comets") or
            text:find("mini%-chests") or
            text:find("coin jars") or
            text:find("piñatas") or
            text:find("pinatas")
        )
    ) then
        return "BestAreaEvent"
    end

    if text:find("in best area") and (
        text:find("breakables") or
        text:find("superior mini%-chest") or
        text:find("collect") and text:find("potions") or
        text:find("collect") and text:find("enchants") or
        text:find("diamond breakables") or
        text:find("earn") and text:find("diamonds")
    ) then
        return "BestArea"
    end

    return nil
end

local function HandleRecognizedQuest(questTitle, questGroup, difficulty)
    local scriptHandler = QuestScriptRouter[questGroup]
    if type(scriptHandler) == "function" then
        scriptHandler(questTitle, difficulty)
    end
end

local function SetQuestGroupEnabled(groupName, value)
    QuestGroupEnabled[groupName] = value

    if groupName == "BestArea" then
        Settings.AutoQuestBestArea = value
    elseif groupName == "Eggs" then
        Settings.AutoQuestEggs = value
    elseif groupName == "BestAreaEvent" then
        Settings.AutoQuestEvent = value
    elseif groupName == "InventoryItems" then
        Settings.AutoQuestInventory = value
    end

    SaveConfig()
end

Tab1:CreateToggle({
    Name = "Quest: Best Area",
    CurrentValue = QuestGroupEnabled.BestArea,
    Callback = function(Value)
        SetQuestGroupEnabled("BestArea", Value)
    end
})

Tab1:CreateToggle({
    Name = "Quest: Hatch Eggs",
    CurrentValue = QuestGroupEnabled.Eggs,
    Callback = function(Value)
        SetQuestGroupEnabled("Eggs", Value)
    end
})

Tab1:CreateToggle({
    Name = "Quest: Best Area + Event",
    CurrentValue = QuestGroupEnabled.BestAreaEvent,
    Callback = function(Value)
        SetQuestGroupEnabled("BestAreaEvent", Value)
    end
})

Tab1:CreateToggle({
    Name = "Quest: Inventory Items",
    CurrentValue = QuestGroupEnabled.InventoryItems,
    Callback = function(Value)
        SetQuestGroupEnabled("InventoryItems", Value)
    end
})

Tab1:CreateSection("Nhiệm vụ")
local EasyLabel = Tab1:CreateLabel({Text="Easy: Đang tải...",Style=1})
local MediumLabel = Tab1:CreateLabel({Text="Medium: Đang tải...",Style=1})
local HardLabel = Tab1:CreateLabel({Text="Hard: Đang tải...",Style=1})
local ExtremeLabel = Tab1:CreateLabel({Text="Extreme: Đang tải...",Style=1})
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local PlayerGui = Player:FindFirstChild("PlayerGui")
            if not PlayerGui then return end
            local GoalsSide = PlayerGui:FindFirstChild("GoalsSide")
            if not GoalsSide then return end
            local Frame = GoalsSide:FindFirstChild("Frame")
            if not Frame then return end
            local Top = Frame:FindFirstChild("Top")
            if Top and Top:FindFirstChild("Title") then
                RankLabel:Set(Top.Title.Text)
            end
            local Quests = Frame:FindFirstChild("Quests")
            local QuestsGradient = Quests and Quests:FindFirstChild("QuestsGradient")
            local QuestsHolder = QuestsGradient and QuestsGradient:FindFirstChild("QuestsHolder")
            if not QuestsHolder then return end
            local Easy = QuestsHolder:FindFirstChild("Easy")
            local Medium = QuestsHolder:FindFirstChild("Medium")
            local Hard = QuestsHolder:FindFirstChild("Hard")
            local Extreme = QuestsHolder:FindFirstChild("Extreme")

            local function ProcessQuest(questFrame, difficulty)
                if not questFrame or not questFrame:FindFirstChild("Title") then
                    return
                end

                local title = questFrame.Title.Text
                local group = IdentifyQuestGroup(title)
                if group and QuestGroupEnabled[group] then
                    HandleRecognizedQuest(title, group, difficulty)
                end
            end

            ProcessQuest(Easy, "Easy")
            ProcessQuest(Medium, "Medium")
            ProcessQuest(Hard, "Hard")
            ProcessQuest(Extreme, "Extreme")
            if Easy and Easy:FindFirstChild("Title") and Easy:FindFirstChild("Progress") then
                EasyLabel:Set(Easy.Title.Text .. " | " .. Easy.Progress.Text)
            end
            if Medium and Medium:FindFirstChild("Title") and Medium:FindFirstChild("Progress") then
                MediumLabel:Set(Medium.Title.Text .. " | " .. Medium.Progress.Text)
            end
            if Hard and Hard:FindFirstChild("Title") and Hard:FindFirstChild("Progress") then
                HardLabel:Set(Hard.Title.Text .. " | " .. Hard.Progress.Text)
            end
            if Extreme and Extreme:FindFirstChild("Title") and Extreme:FindFirstChild("Progress") then
                ExtremeLabel:Set(Extreme.Title.Text .. " | " .. Extreme.Progress.Text)
            end
        end)
    end
end)
--endrank
local AutoUpdateEgg = Settings.AutoUpdateEgg
local AutoUpdatePet = Settings.AutoUpdatePet

local function RunEggUpdater()
    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local remote = network:WaitForChild("EggHatchSlotsMachine_RequestPurchase")

        while AutoUpdateEgg do
            for id = 1, 60 do
                if not AutoUpdateEgg then
                    break
                end
                pcall(function()
                    remote:InvokeServer(id)
                end)
                task.wait(0.5)
            end
        end
    end)
end

local function RunPetUpdater()
    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local remote = network:WaitForChild("EquipSlotsMachine_RequestPurchase")

        while AutoUpdatePet do
            for id = 1, 60 do
                if not AutoUpdatePet then
                    break
                end
                pcall(function()
                    remote:InvokeServer(id)
                end)
                task.wait(0.5)
            end
        end
    end)
end

Tab1:CreateToggle({
    Name = "Auto Update Egg slot",
    CurrentValue = AutoUpdateEgg,
    Callback = function(Value)
        AutoUpdateEgg = Value
        Settings.AutoUpdateEgg = Value
        SaveConfig()
        if Value then
            RunEggUpdater()
        end
    end
})

Tab1:CreateToggle({
    Name = "Auto Update pet slot",
    CurrentValue = AutoUpdatePet,
    Callback = function(Value)
        AutoUpdatePet = Value
        Settings.AutoUpdatePet = Value
        SaveConfig()
        if Value then
            RunPetUpdater()
        end
    end
})

if AutoUpdateEgg then
    RunEggUpdater()
end
if AutoUpdatePet then
    RunPetUpdater()
end

task.wait(0.5)
isLoaded = true
