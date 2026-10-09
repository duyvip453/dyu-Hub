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
    AutoQuestEasy = false,
    AutoQuestMedium = false,
    AutoQuestHard = false,
    AutoQuestExtreme = false
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

Tab1:CreateSection("Auto Farm Quest")

local QuestRankEnabled = {
    Easy = Settings.AutoQuestEasy,
    Medium = Settings.AutoQuestMedium,
    Hard = Settings.AutoQuestHard,
    Extreme = Settings.AutoQuestExtreme
}

local QuestRankPaths = {
    Easy = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Easy", "Title"},
    Medium = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Medium", "Title"},
    Hard = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Hard", "Title"},
    Extreme = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Extreme", "Title"}
}

-- Add each task's actual farming code in its matching slot at the bottom.
local QuestScriptRouter = {
    BestArea = nil,
    BestAreaEvent = nil,
    Eggs = nil,
    InventoryItems = nil,
    MakePet = nil
}

local LastDispatchedQuest = {}

local function GetQuestTitleFromPath(path)
    local current = Player:FindFirstChild("PlayerGui")
    if not current then return nil end

    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end

    if current:IsA("TextLabel") or current:IsA("TextButton") or current:IsA("TextBox") then
        return current.Text
    end

    return nil
end

local function NormalizeQuestText(value, keepNumbers)
    local text = string.lower(tostring(value or ""))
    if not keepNumbers then
        text = text:gsub("[%d,%.]", " ")
    end
    text = text:gsub("%s+", " ")
    return text
end

local QuestMatchRules = {
    -- Make is checked first and keeps numbers for identifying the requested pet.
    {Group = "MakePet", KeepNumbers = true, Keywords = {"make"}},
    {Group = "Eggs", Keywords = {"hatch"}},
    {Group = "InventoryItems", Keywords = {"use"}},
    {Group = "BestAreaEvent", Keywords = {"comets", "coin jars", "lucky blocks", "piñatas", "pinatas"}},
    {Group = "BestArea", Keywords = {"breakables", "diamond", "superior mini-chests", "superior mini-chest", "earn", "diamonds", "collect"}}
}

local function IdentifyQuestGroup(questTitle)
    local originalText = NormalizeQuestText(questTitle, true)

    for _, rule in ipairs(QuestMatchRules) do
        local text = NormalizeQuestText(questTitle, rule.KeepNumbers == true)
        for _, keyword in ipairs(rule.Keywords) do
            if text:find(keyword, 1, true) then
                return rule.Group, originalText
            end
        end
    end

    return nil, originalText
end

local function HandleRecognizedQuest(questTitle, questGroup, rank)
    local scriptHandler = QuestScriptRouter[questGroup]
    if type(scriptHandler) ~= "function" then return end

    local questKey = rank .. ":" .. questGroup
    if LastDispatchedQuest[questKey] == questTitle then return end

    LastDispatchedQuest[questKey] = questTitle
    task.spawn(function()
        pcall(scriptHandler, questTitle, rank)
    end)
end

local function SetQuestRankEnabled(rank, value)
    QuestRankEnabled[rank] = value
    Settings["AutoQuest" .. rank] = value
    for _, group in ipairs({"BestArea", "BestAreaEvent", "Eggs", "InventoryItems", "MakePet"}) do
        LastDispatchedQuest[rank .. ":" .. group] = nil
    end
    SaveConfig()
end

Tab1:CreateToggle({
    Name = "Auto Farm Quest - Easy",
    CurrentValue = QuestRankEnabled.Easy,
    Callback = function(Value)
        SetQuestRankEnabled("Easy", Value)
    end
})

Tab1:CreateToggle({
    Name = "Auto Farm Quest - Medium",
    CurrentValue = QuestRankEnabled.Medium,
    Callback = function(Value)
        SetQuestRankEnabled("Medium", Value)
    end
})

Tab1:CreateToggle({
    Name = "Auto Farm Quest - Hard",
    CurrentValue = QuestRankEnabled.Hard,
    Callback = function(Value)
        SetQuestRankEnabled("Hard", Value)
    end
})

Tab1:CreateToggle({
    Name = "Auto Farm Quest - Extreme",
    CurrentValue = QuestRankEnabled.Extreme,
    Callback = function(Value)
        SetQuestRankEnabled("Extreme", Value)
    end
})

task.spawn(function()
    while task.wait(0.5) do
        for rank, path in pairs(QuestRankPaths) do
            if QuestRankEnabled[rank] then
                local title = GetQuestTitleFromPath(path)
                if title and title ~= "" then
                    local group = IdentifyQuestGroup(title)
                    if group then
                        HandleRecognizedQuest(title, group, rank)
                    end
                end
            end
        end
    end
end)

-- SCRIPT SLOT: BestArea
-- QuestScriptRouter.BestArea = function(questTitle, rank)
--     -- Put the Best Area script here.
-- end

-- SCRIPT SLOT: BestAreaEvent
-- QuestScriptRouter.BestAreaEvent = function(questTitle, rank)
--     -- Put the Best Area + spawn event script here.
-- end

-- SCRIPT SLOT: Eggs
-- QuestScriptRouter.Eggs = function(questTitle, rank)
--     -- Put the egg-hatching script here.
-- end

-- SCRIPT SLOT: InventoryItems
-- QuestScriptRouter.InventoryItems = function(questTitle, rank)
--     -- Put the inventory-item script here.
-- end

-- SCRIPT SLOT: MakePet
-- QuestScriptRouter.MakePet = function(questTitle, rank)
--     -- Put the make-pet script here; keep the original questTitle numbers.
-- end
