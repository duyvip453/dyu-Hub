-- [START] Khởi tạo dịch vụ, người chơi và tên file cấu hình
local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [START] Tải registry ID Potion/Enchant từ file dữ liệu riêng trên GitHub
-- Hai file phải trả về một Lua table bằng câu lệnh return {...}.
-- Các box về sau có thể dùng PotionUpgradeIDs.Entries và EnchantUpgradeIDs.Entries.
local PotionUpgradeIDs = { Version = 1, MachineRemote = "UpgradePotionsMachine_Activate", Entries = {} }
local EnchantUpgradeIDs = { Version = 1, MachineRemote = "UpgradeEnchantsMachine_Activate", Entries = {} }

local function LoadUpgradeIDRegistry(url, registryName)
    local ok, result = pcall(function()
        local source = game:HttpGet(url)
        assert(type(source) == "string" and source ~= "", "file dữ liệu rỗng")
        local compile = loadstring(source)
        assert(type(compile) == "function", "không biên dịch được file dữ liệu")
        local data = compile()
        assert(type(data) == "table", "file phải return một table Lua")
        assert(type(data.Entries) == "table", "thiếu bảng Entries")
        return data
    end)

    if not ok then
                return nil
    end

        return result
end

do
    local data = LoadUpgradeIDRegistry(
        "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/upd-potion",
        "Potion"
    )
    if data then PotionUpgradeIDs = data end
end

do
    local data = LoadUpgradeIDRegistry(
        "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/upd-enchant",
        "Enchant"
    )
    if data then EnchantUpgradeIDs = data end
end
-- [END] Tải registry ID Potion/Enchant từ file dữ liệu riêng trên GitHub
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
                return false
    end

    local ok, err = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)

    if not ok then
                return false
    end

    return true
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
                return
    end

    local existsOk, exists = pcall(function()
        return isfile(ConfigFileName)
    end)

    if not existsOk then
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
                return
    end

    for key, value in pairs(data) do
        if Settings[key] ~= nil and type(value) == type(Settings[key]) then
            Settings[key] = value
        end
    end
end

-- [END] Lưu/đọc cấu hình

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
local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

-- [START] Hiển thị Rank và tiến độ nhiệm vụ
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
-- [END] Hiển thị Rank và tiến độ nhiệm vụ

-- [START] Auto Update Egg slot và Pet slot
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
-- [END] Auto Update Egg slot và Pet slot

-- [START] Auto Farm Quest: cấu hình rank, đọc UI, phân loại và điều phối nhiệm vụ
-- KIẾN TRÚC HIỆN TẠI: 4 toggle Easy/Medium/Hard/Extreme chỉ là công tắc TEST theo rank.
-- KIẾN TRÚC ĐÍCH: một toggle Auto Rank duy nhất -> đọc nhiệm vụ mọi rank -> IdentifyQuestGroup
-- -> bộ sắp xếp ưu tiên chọn Group cần chạy -> DispatchQuest -> QuestScriptBoxes[Group].
-- Không xóa 4 toggle ở giai đoạn này; mọi handler bên dưới phải giữ độc lập theo Group.
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
-- [GROUP ROUTING CONTRACT]
-- Mỗi Group có handler riêng trong QuestScriptBoxes; không gắn handler trực tiếp vào 4 toggle rank.
-- IdentifyQuestGroup chỉ phân loại; bộ ưu tiên tương lai sẽ chọn Group cần chạy trước.
-- DispatchQuest là điểm trung gian duy nhất để gọi QuestScriptBoxes[group].
-- Mỗi handler nhận (questTitle, rank, isEnabled) và phải dừng khi bị hủy/quest hoàn tất.
-- Script boxes: put each group's farming function in its matching box.
-- Each function receives (questTitle, rank, isEnabled) and should return when its own progress is complete.
-- Quest egg automation: the rank-toggle scanner owns progress detection and cancellation.
-- Each hatch loop only checks isEnabled(); the scanner invalidates its generation when progress completes.
-- Current BuyMax hatch amount, refreshed continuously from the game's UI.
-- Auto Hatch reads this shared value so the requested amount can change during farming.
local CurrentMaxEggHatchAmount = 1
local function GetBuyMaxButton()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local misc = playerGui and playerGui:FindFirstChild("_MISC")
    local buyMultiple = misc and misc:FindFirstChild("BuyMultiple")
    local frame = buyMultiple and buyMultiple:FindFirstChild("Frame")
    local contents = frame and frame:FindFirstChild("Contents")
    local buyMax = contents and contents:FindFirstChild("BuyMax")
    if not buyMax then
        return nil
    end

    if buyMax:IsA("GuiButton") then
        return buyMax
    end

    for _, object in ipairs(buyMax:GetDescendants()) do
        if object:IsA("GuiButton") then
            return object
        end
    end

    return nil
end

local function ClickBuyMaxButton()
    local button = GetBuyMaxButton()
    if not button then
                return false
    end

    local ok, err = pcall(function()
        button:Activate()
    end)

    if not ok then
                return false
    end

    return true
end

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
local function RunQuestEggHatch(eggName, targetPosition, questTitle, isEnabled, stopWhenReady)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local teleported, teleportError = pcall(function()
        root.CFrame = CFrame.new(targetPosition)
    end)
    if not teleported then
                return
    end
    -- Initialize the game's hatch-count state once before attempting any egg purchase.
    task.wait(1)
    if not isEnabled() then return end
    local hatchCountInitOk, hatchCountInitResult = pcall(function()
        return ReplicatedStorage:WaitForChild("Network"):WaitForChild("Index: Request Hatch Count"):InvokeServer()
    end)
    -- Kết quả khởi tạo hatch-count chưa được dùng; giữ lời gọi để khởi tạo trạng thái.
    -- if hatchCountInitOk then
    --     -- Chưa có xử lý kết quả được xác minh.
    -- end
    if not isEnabled() then return end
    ClickBuyMaxButton()
    task.wait(0.5)
    local hatchAmount = RefreshMaxEggHatchAmount()
        if not isEnabled() then return end
    local remote
    local ok, err = pcall(function()
        remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Eggs_RequestPurchase")
    end)
    if not ok then
                return
    end
    -- Do not read progress here. The Auto Farm Quest scanner stops this loop
    -- by invalidating isEnabled() when it detects full progress or a new quest.
    while isEnabled() do
        if stopWhenReady and stopWhenReady() then
                        return true
        end
        local amount = RefreshMaxEggHatchAmount()
        local success, result = pcall(function()
            return remote:InvokeServer(eggName, amount)
        end)
        if not success then
                        task.wait(1)
        else
                        task.wait(0.75)
        end
    end
    return false
end
local QuestScriptBoxes = {
    BestArea = nil,
    BestAreaEvent = nil,
    Collect = nil,
    CollectPotions = nil,
    CollectEnchants = nil,
    LegendaryEggs = nil,
    Eggs = nil,
    InventoryItems = nil,
    MakePet = nil,
    UpdatePotion = nil,
    UpdateEnchant = nil
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
    -- Upgrade potion/enchant rules require BOTH keywords; IdentifyQuestGroup checks all Keywords.
    {Group = "UpdatePotion", Keywords = {"upgrade", "potions"}, MatchAll = true},
    {Group = "UpdateEnchant", Keywords = {"upgrade", "enchants"}, MatchAll = true},
    -- MakePet is routed to its group; the handler distinguishes Golden from Rainbow.
    {Group = "MakePet", KeepNumbers = true, Keywords = {"make"}},
    -- PRIORITY ROUTING: LegendaryEggs must be listed before generic Eggs.
    -- Both keywords are required; generic Eggs below handles other hatch quests.
    {Group = "LegendaryEggs", Keywords = {"hatch", "legend"}, MatchAll = true},
    {Group = "Eggs", Keywords = {"hatch"}},
    {Group = "InventoryItems", Keywords = {"use"}},
    {Group = "CollectPotions", Keywords = {"collect", "potions"}, MatchAll = true},
    {Group = "CollectEnchants", Keywords = {"collect", "enchants"}, MatchAll = true},
    -- Các từ khóa trong AnyKeywords là lựa chọn thay thế nhau (OR), không phải bắt buộc xuất hiện cùng lúc.
    {Group = "BestAreaEvent", AnyKeywords = {"comets", "coin jars", "lucky blocks", "piñatas", "pinatas"}},
    {Group = "BestArea", AnyKeywords = {"best area", "breakables", "mini-chests", "mini-chest", "superior mini-chest", "mini chest", "diamond", "diamonds", "earn"}}
}

local function IdentifyQuestGroup(questTitle)
    local originalText = NormalizeQuestText(questTitle, true)
    local normalizedTitle = NormalizeQuestText(questTitle, true)

    -- Phân loại toàn bộ nhiệm vụ qua QuestMatchRules để sau này bộ ưu tiên
    -- có thể chọn Group trước khi gọi QuestScriptBoxes[Group].
    for _, rule in ipairs(QuestMatchRules) do
        local text = NormalizeQuestText(questTitle, rule.KeepNumbers == true)
        local matched = false
        if rule.AnyKeywords then
            -- Chỉ cần khớp một từ khóa là đủ cho nhóm có nhiều tên nhiệm vụ khác nhau.
            for _, keyword in ipairs(rule.AnyKeywords) do
                if text:find(keyword, 1, true) then
                    matched = true
                    break
                end
            end
        else
            -- Keywords mặc định yêu cầu tất cả từ khóa, dùng cho Upgrade Potions/Enchants.
            matched = true
            for _, keyword in ipairs(rule.Keywords or {}) do
                if not text:find(keyword, 1, true) then
                    matched = false
                    break
                end
            end
        end
        if matched then
            return rule.Group, originalText
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
            -- Lỗi box được cô lập để không làm sập bộ quét nhiệm vụ.
            -- Chưa thêm log theo yêu cầu không dùng warn/print.
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

-- [TEST TOGGLES / TEMPORARY ROUTING]
-- 4 nút dưới đây chỉ để test từng rank độc lập. Khi chuyển sang Auto Rank,
-- thay lớp toggle này bằng một toggle duy nhất; không đặt logic nhiệm vụ trong callback nút.
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

-- [END] Auto Farm Quest: bộ quét tiến độ và điều phối nhiệm vụ

-- [START] Các box xử lý riêng theo loại nhiệm vụ
-- SCRIPT BOXES (keep these assignments at the bottom; fill in each function body).
-- The loader calls a box by name: QuestScriptBoxes.BestArea(...), QuestScriptBoxes.Eggs(...), etc.
-- The third argument is isEnabled(); check it in long-running loops and return when false.
-- Each box should read its own progress and return when current progress reaches the target.
-- BestArea: mỗi lần được dispatch cho một nhiệm vụ BestArea mới thì teleport tới điểm farm.


-- [START] Box Collect: hiện chỉ nhận diện/log nhiệm vụ
--box collect
-- Add the specific collect behavior here when ready; do not teleport to BestArea by default.
-- Chưa triển khai hành vi Collect; để vô hiệu hóa thay vì chạy box rỗng.
-- QuestScriptBoxes.Collect = function(questTitle, rank, isEnabled)
--     if not isEnabled() then return end
-- end
-- [END] Box Collect

-- [START] Box CollectPotions: chọn ngẫu nhiên ID potion rồi gọi máy nâng cấp
QuestScriptBoxes.CollectPotions = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local entries = PotionUpgradeIDs.Entries or {}
    local usableEntries = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.Id) == "string" and entry.Id ~= "" then
            table.insert(usableEntries, entry)
        end
    end
    if #usableEntries == 0 then return end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local remoteName = PotionUpgradeIDs.MachineRemote or "UpgradePotionsMachine_Activate"
    local remote = network and network:FindFirstChild(remoteName)
    if not remote or not remote:IsA("RemoteFunction") then return end

    while isEnabled() do
        local entry = usableEntries[math.random(1, #usableEntries)]
        if not isEnabled() then break end
        pcall(function()
            remote:InvokeServer(entry.Id)
        end)
        task.wait(0.75)
    end
end
-- [END] Box CollectPotions

-- [START] Box CollectEnchants: chọn ngẫu nhiên ID enchant rồi gọi máy nâng cấp
QuestScriptBoxes.CollectEnchants = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local entries = EnchantUpgradeIDs.Entries or {}
    local usableEntries = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.Id) == "string" and entry.Id ~= "" then
            -- Chỉ dùng những ID đã được điền; registry hiện để trống sẽ tự bỏ qua.
            table.insert(usableEntries, entry)
        end
    end
    if #usableEntries == 0 then return end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local remoteName = EnchantUpgradeIDs.MachineRemote or "UpgradeEnchantsMachine_Activate"
    local remote = network and network:FindFirstChild(remoteName)
    if not remote or not remote:IsA("RemoteFunction") then return end

    while isEnabled() do
        local entry = usableEntries[math.random(1, #usableEntries)]
        if not isEnabled() then break end
        pcall(function()
            remote:InvokeServer(entry.Id)
        end)
        task.wait(0.75)
    end
end
-- [END] Box CollectEnchants

-- [START] Box BestArea: teleport tới khu vực farm
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

    -- Teleport đã được thử; chưa cần nhánh xử lý rỗng.
    -- if ok then
    --     -- Chưa có xử lý bổ sung.
    -- end
end
-- [END] Box BestArea

-- [START] Box BestAreaEvent: khung chờ bổ sung logic event
-- QuestScriptBoxes.BestAreaEvent = function(questTitle, rank, isEnabled)
--     -- Best Area + spawn event farming code.
-- end
-- [END] Box BestAreaEvent

-- [START] Box LegendaryEggs: mở Veilroot Egg tại vị trí chỉ định
--box legend
QuestScriptBoxes.LegendaryEggs = function(questTitle, rank, isEnabled)
    RunQuestEggHatch(
        "Veilroot Egg",
        Vector3.new(-14887.31, 16.34, 2209.57),
        questTitle,
        isEnabled
    )
end
-- [END] Box LegendaryEggs

-- [START] Box Eggs: mở Hollow Egg tại vị trí chỉ định
--box egg
QuestScriptBoxes.Eggs = function(questTitle, rank, isEnabled)
    RunQuestEggHatch(
        "Hollow Egg",
        Vector3.new(-15044.67, 16.34, 2147.03),
        questTitle,
        isEnabled
    )
end
-- [END] Box Eggs

-- [START] Box InventoryItems: khung chờ bổ sung logic dùng vật phẩm
-- QuestScriptBoxes.InventoryItems = function(questTitle, rank, isEnabled)
--     -- Inventory-item usage code.
-- end
-- [END] Box InventoryItems

-- [START] Box MakePet: nhận diện Golden/Rainbow và gọi remote máy tương ứng
-- MakePet: Golden consumes normal pets; Rainbow consumes Golden pets only.
-- The machine remotes require the inventory pet ID and the amount to consume.
QuestScriptBoxes.MakePet = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end
    local title = string.lower(tostring(questTitle or ""))
    local isRainbow = title:find("rainbow", 1, true) ~= nil
    local isGolden = title:find("golden", 1, true) ~= nil
    if not isRainbow and not isGolden then
                return
    end

    local requested = tonumber((title:gsub(",", "")):match("make%s+(%d+)"))
    if not requested or requested < 1 then
                return
    end
    requested = math.floor(requested)

    -- [GOLDEN] 10 pet thường tạo được 1 Golden.
    -- [RAINBOW] 100 pet thường tạo được 1 Rainbow: tạo Golden trước, sau đó ghép Rainbow.
    local requiredNormalPets = requested * (isRainbow and 100 or 10)
    local requiredGoldenPets = requested * 10

    -- Đọc Quantity từ ItemSlot trong GoldMachine; dùng chung cho kiểm tra Golden và Rainbow.
    local function GetGoldMachineQuantity()
        local playerGui = Player:FindFirstChild("PlayerGui")
        local machines = playerGui and playerGui:FindFirstChild("_MACHINES")
        local machine = machines and machines:FindFirstChild("GoldMachine")
        local frame = machine and machine:FindFirstChild("Frame")
        local itemsFrame = frame and frame:FindFirstChild("ItemsFrame")
        local items = itemsFrame and itemsFrame:FindFirstChild("Items")
        local pets = items and items:FindFirstChild("Pets")
        if not pets then return nil end
        local slots = {}
        if pets.Name == "ItemSlot" then table.insert(slots, pets) end
        for _, object in ipairs(pets:GetDescendants()) do
            if object.Name == "ItemSlot" then table.insert(slots, object) end
        end
        for _, slot in ipairs(slots) do
            local icon = slot:FindFirstChild("Icon")
            local quantity = slot:FindFirstChild("Quantity")
            if icon and quantity and quantity:IsA("TextLabel") then
                local raw = quantity.Text:gsub(",", ""):gsub("%s+", "")
                local number, suffix = raw:match("^(%d+%.?%d*)([kKmMbB]?)$")
                number = tonumber(number)
                if number then
                    local multiplier = ({k=1e3,m=1e6,b=1e9})[string.lower(suffix or "")] or 1
                    return math.floor(number * multiplier)
                end
                local digits = tonumber(raw:match("(%d+)"))
                if digits then return digits end
            end
        end
        return nil
    end

    local function MakeAtMachine(remoteName, petId, amount, label)
        if not isEnabled() then return false end
        local network = ReplicatedStorage:FindFirstChild("Network")
        local remote = network and network:FindFirstChild(remoteName)
        if not remote then
                        return false
        end
        local ok, result = pcall(function()
            return remote:InvokeServer(petId, amount)
        end)
        if not ok then
                        return false
        end
                return true
    end

    -- Dùng lại helper hatch Hollow Egg hiện có; chỉ thêm điều kiện dừng theo Quantity.
    local function HatchUntilEnough()
        return RunQuestEggHatch(
            "Hollow Egg",
            Vector3.new(-15044.67, 16.34, 2147.03),
            questTitle,
            isEnabled,
            function()
                local quantity = GetGoldMachineQuantity()
                return quantity ~= nil and quantity >= requiredNormalPets
            end
        )
    end

    local quantity = GetGoldMachineQuantity()
    if not quantity then
                return
    end
    if quantity < requiredNormalPets then
                if not HatchUntilEnough() then return end
    end
    if not isEnabled() then return end

    -- Kiểm tra lại số lượng ngay trước khi gọi máy.
    quantity = GetGoldMachineQuantity()
    if not quantity or quantity < requiredNormalPets then
                return
    end

    if isGolden then
        MakeAtMachine("GoldMachine_Activate", "f69b09dd148145e19181cbb9d7ff31a1", requiredNormalPets, "Golden")
        return
    end

    -- [RAINBOW] Đủ 100 pet thường cho mỗi Rainbow: ghép Golden trước (10 pet thường/Golden),
    -- rồi mới dùng 10 Golden cho mỗi Rainbow. Quantity của GoldMachine được kiểm tra trước bước này.
    local goldenMade = MakeAtMachine("GoldMachine_Activate", "f69b09dd148145e19181cbb9d7ff31a1", requiredNormalPets, "Golden trung gian")
    if not goldenMade or not isEnabled() then return end
    task.wait(1)
    if not isEnabled() then return end
    MakeAtMachine("RainbowMachine_Activate", "192c592642a445c8963250710c12bf69", requiredGoldenPets, "Rainbow")
end
-- [END] Box MakePet

-- [START] Box UpdatePotion: khung trống chờ bổ sung logic
-- Chưa triển khai UpdatePotion.
-- QuestScriptBoxes.UpdatePotion = function(questTitle, rank, isEnabled)
--     -- Bổ sung sau khi xác minh quy trình nâng cấp.
-- end
-- [END] Box UpdatePotion

-- [START] Box UpdateEnchant: khung trống chờ bổ sung logic
-- Chưa triển khai UpdateEnchant.
-- QuestScriptBoxes.UpdateEnchant = function(questTitle, rank, isEnabled)
--     -- Bổ sung sau khi xác minh ID và quy trình nâng cấp.
-- end
-- [END] Box UpdateEnchant
-- [END] Các box xử lý riêng theo loại nhiệm vụ
