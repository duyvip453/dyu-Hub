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
--endslot


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
    Easy = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Easy"},
    Medium = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Medium"},
    Hard = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Hard"},
    Extreme = {"GoalsSide", "Frame", "Quests", "QuestsGradient", "QuestsHolder", "Extreme"}
}
-- Script boxes: put each group's farming function in its matching box.
-- Each function receives (questTitle, rank, isEnabled) and should return when its own progress is complete.
-- Quest egg automation: the rank-toggle scanner owns progress detection and cancellation.
-- Each hatch loop only checks isEnabled(); the scanner invalidates its generation when progress completes.
-- Current BuyMax hatch amount, refreshed continuously from the game's UI.
-- Auto Hatch reads this shared value so the requested amount can change during farming.
local CurrentMaxEggHatchAmount = 1
local function RefreshMaxEggHatchAmount()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local misc = playerGui and playerGui:FindFirstChild("_MISC")
    local buyMultiple = misc and misc:FindFirstChild("BuyMultiple")
    local frame = buyMultiple and buyMultiple:FindFirstChild("Frame")
    local contents = frame and frame:FindFirstChild("Contents")
    local buyMax = contents and contents:FindFirstChild("BuyMax")
    local textLabel = buyMax and buyMax:FindFirstChild("TextLabel")
    if not textLabel or not textLabel:IsA("TextLabel") then
        return CurrentMaxEggHatchAmount
    end
    local amountText = textLabel.Text
    local amount = tonumber(string.match(amountText, "%d+"))
    if amount and amount >= 1 then
        CurrentMaxEggHatchAmount = math.floor(amount)
    end
    return CurrentMaxEggHatchAmount
end
task.spawn(function()
    while task.wait(0.5) do
        RefreshMaxEggHatchAmount()
    end
end)
local function RunQuestEggHatch(eggName, targetPosition, questTitle, isEnabled)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local teleported, teleportError = pcall(function()
        root.CFrame = CFrame.new(targetPosition)
    end)
    if not teleported then
        warn("[DYU HUB] Không thể teleport cho nhiệm vụ " .. tostring(questTitle) .. ": " .. tostring(teleportError))
        return
    end
    -- Both egg quests wait one second after teleporting before the first hatch.
    task.wait(2)
    if not isEnabled() then return end
    local remote
    local ok, err = pcall(function()
        remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Eggs_RequestPurchase")
    end)
    if not ok then
        warn("[DYU HUB] Không tìm thấy remote mở trứng: " .. tostring(err))
        return
    end
    -- Do not read progress here. The Auto Farm Quest scanner stops this loop
    -- by invalidating isEnabled() when it detects full progress or a new quest.
    while isEnabled() do
        local success, result = pcall(function()
            return remote:InvokeServer(eggName, RefreshMaxEggHatchAmount())
        end)
        if not success then
            warn("[DYU HUB] Auto hatch " .. eggName .. " lỗi: " .. tostring(result))
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end
local QuestScriptBoxes = {
    BestArea = nil,
    BestAreaEvent = nil,
    Collect = nil,
    LegendaryEggs = nil,
    Eggs = nil,
    InventoryItems = nil,
    MakePet = nil
}
local QuestRankState = {}
for rank in pairs(QuestRankPaths) do
    QuestRankState[rank] = {
        ActiveQuest = nil,
        ActiveGroup = nil,
        CompletedQuest = nil,
        Running = false,
        Generation = 0,
        CompleteWaitUntil = 0
    }
end
local function GetQuestInfoFromPath(path)
    local current = Player:FindFirstChild("PlayerGui")
    if not current then return nil, nil end
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil, nil end
    end
    local title = current:FindFirstChild("Title")
    local progress = current:FindFirstChild("Progress")
    if not title or not progress then return nil, nil end
    return title.Text, progress.Text
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
    -- LegendaryEggs is handled by the explicit BOTH-keywords check in IdentifyQuestGroup.
    -- Generic Eggs only matches "hatch" when the title does not mention "legend".
    {Group = "Eggs", Keywords = {"hatch"}},
    {Group = "InventoryItems", Keywords = {"use"}},
    {Group = "Collect", Keywords = {"collect"}},
    {Group = "BestAreaEvent", Keywords = {"comets", "coin jars", "lucky blocks", "piñatas", "pinatas"}},
    {Group = "BestArea", Keywords = {"breakables", "mini-chests", "mini-chest", "mini chests", "mini chest", "diamond", "superior mini-chests", "superior mini-chest", "earn", "diamonds"}}
}

local function IdentifyQuestGroup(questTitle)
    local originalText = NormalizeQuestText(questTitle, true)
    local normalizedTitle = NormalizeQuestText(questTitle, true)

    -- A Legendary egg quest must contain both "hatch" and "legend".
    if normalizedTitle:find("hatch", 1, true) and normalizedTitle:find("legend", 1, true) then
        return "LegendaryEggs", originalText
    end

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

local function ParseQuestProgress(progressText)
    local text = tostring(progressText or ""):gsub(",", "")
    local current, target = text:match("(%d+)%s*/%s*(%d+)")
    if not current or not target then
        current, target = text:match("(%d+)%s+of%s+(%d+)")
    end
    if not current or not target then return nil, nil end
    return tonumber(current), tonumber(target)
end

local function IsQuestProgressComplete(progressText)
    local current, target = ParseQuestProgress(progressText)
    return current ~= nil and target ~= nil and target > 0 and current >= target
end

local function IsQuestRankEnabled(rank)
    return QuestRankEnabled[rank] == true
end

local function DispatchQuest(rank, questTitle, questGroup)
    local state = QuestRankState[rank]
    local scriptBox = QuestScriptBoxes[questGroup]
    if not state or type(scriptBox) ~= "function" then return end
    if state.Running or state.ActiveQuest == questTitle then return end

    state.Generation = state.Generation + 1
    local generation = state.Generation
    state.ActiveQuest = questTitle
    state.ActiveGroup = questGroup
    state.Running = true

    task.spawn(function()
        local ok, err = pcall(scriptBox, questTitle, rank, function()
            return IsQuestRankEnabled(rank) and state.Generation == generation
        end)

        if not ok then
            warn("[DYU HUB] Quest script box '" .. questGroup .. "' lỗi: " .. tostring(err))
        end

        if state.Generation == generation then
            state.Running = false
        end
    end)
end

local function SetQuestRankEnabled(rank, value)
    QuestRankEnabled[rank] = value
    Settings["AutoQuest" .. rank] = value

    local state = QuestRankState[rank]
    if state then
        state.Generation = state.Generation + 1
        state.Running = false
        state.ActiveQuest = nil
        state.ActiveGroup = nil
        state.CompletedQuest = nil
        state.CompleteWaitUntil = 0
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
            local state = QuestRankState[rank]
            if state and IsQuestRankEnabled(rank) then
                local ok, title, progress = pcall(GetQuestInfoFromPath, path)
                if ok and title and title ~= "" and progress then
                    local complete = IsQuestProgressComplete(progress)
                    local now = os.clock()

                    if state.ActiveQuest and (complete or title ~= state.ActiveQuest) then
                        -- Completion may be observed as full progress or as the next title appearing first.
                        state.CompletedQuest = state.ActiveQuest
                        state.ActiveQuest = nil
                        state.ActiveGroup = nil
                        state.Running = false
                        state.Generation = state.Generation + 1
                        state.CompleteWaitUntil = now + 1.5
                    elseif state.CompletedQuest and title ~= state.CompletedQuest then
                        state.CompletedQuest = nil
                    elseif state.CompletedQuest == title and not complete then
                        -- Same quest title with reset progress means a fresh task instance.
                        state.CompletedQuest = nil
                    end

                    if now >= state.CompleteWaitUntil and not state.ActiveQuest and not state.Running then
                        if state.CompletedQuest ~= title and not complete then
                            local group = IdentifyQuestGroup(title)
                            if group then
                                DispatchQuest(rank, title, group)
                            end
                        elseif state.CompletedQuest ~= title and complete then
                            -- The quest UI may already show a completed task while transitioning.
                            state.CompleteWaitUntil = now + 1.5
                        end
                    end
                end
            end
        end
    end
end)

-- SCRIPT BOXES (keep these assignments at the bottom; fill in each function body).
-- The loader calls a box by name: QuestScriptBoxes.BestArea(...), QuestScriptBoxes.Eggs(...), etc.
-- The third argument is isEnabled(); check it in long-running loops and return when false.
-- Each box should read its own progress and return when current progress reaches the target.
-- BestArea: mỗi lần được dispatch cho một nhiệm vụ BestArea mới thì teleport tới điểm farm.


--box collect
-- Add the specific collect behavior here when ready; do not teleport to BestArea by default.
QuestScriptBoxes.Collect = function(questTitle, rank, isEnabled)
    if not isEnabled() then
        return
    end

    print("[DYU HUB] Collect quest detected; dedicated Collect box selected: " .. tostring(questTitle))
end
--boxarea
QuestScriptBoxes.BestArea = function(questTitle, rank, isEnabled)
    if not isEnabled() then
        return
    end

    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then
        return
    end

    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then
        return
    end

    local target = Vector3.new(-15044.65, 16.34, 2203.12)
    local ok, err = pcall(function()
        root.CFrame = CFrame.new(target)
    end)

    if ok then
        print("[DYU HUB] BestArea: đã teleport tới " .. tostring(target) .. " cho nhiệm vụ: " .. tostring(questTitle))
    else
        warn("[DYU HUB] BestArea teleport thất bại: " .. tostring(err))
    end
end
--
-- QuestScriptBoxes.BestAreaEvent = function(questTitle, rank, isEnabled)
--     -- Best Area + spawn event farming code.
-- end
--box legend
QuestScriptBoxes.LegendaryEggs = function(questTitle, rank, isEnabled)
    RunQuestEggHatch(
        "Veilroot Egg",
        Vector3.new(-14887.31, 16.34, 2209.57),
        questTitle,
        isEnabled
    )
end
--box egg
QuestScriptBoxes.Eggs = function(questTitle, rank, isEnabled)
    RunQuestEggHatch(
        "Hollow Egg",
        Vector3.new(-15044.67, 16.34, 2147.03),
        questTitle,
        isEnabled
    )
end
--
-- QuestScriptBoxes.InventoryItems = function(questTitle, rank, isEnabled)
--     -- Inventory-item usage code.
-- end
--
-- QuestScriptBoxes.MakePet = function(questTitle, rank, isEnabled)
--     -- Make-pet code; keep the original questTitle numbers.
-- end
