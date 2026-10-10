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

-- [START] Cập nhật Egg Slots một lần khi loader khởi động
task.spawn(function()
    task.wait(1)

    local RS = game:GetService("ReplicatedStorage")
    local gui = Player.PlayerGui._MACHINES.EggSlotsMachine
    local TabController = require(RS.Library.Client.TabController)

    TabController.OpenTab("EggSlotsMachine")
    task.wait()
    gui.Enabled = false
end)
-- [END] Cập nhật Egg Slots một lần khi loader khởi động

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
-- Số trứng lấy từ tổng các OwnedSlot trong EggSlotsMachine.
local CurrentMaxEggHatchAmount = 1
local function RefreshMaxEggHatchAmount()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local machines = playerGui and playerGui:FindFirstChild("_MACHINES")
    local eggSlotsMachine = machines and machines:FindFirstChild("EggSlotsMachine")
    local frame = eggSlotsMachine and eggSlotsMachine:FindFirstChild("Frame")
    local slots = frame and frame:FindFirstChild("Slots")
    local items = slots and slots:FindFirstChild("Items")
    local slotsSection = items and items:FindFirstChild("SlotsSection")
    local slotsContainer = slotsSection and slotsSection:FindFirstChild("Slots")
    if not slotsContainer then
        return CurrentMaxEggHatchAmount
    end

    local totalEggs = 0
    local foundOwnedSlot = false

    -- Mỗi OwnedSlot có Title dạng "+N Egg"; LockedSlot được tự động bỏ qua.
    for _, slot in ipairs(slotsContainer:GetDescendants()) do
        if slot.Name == "OwnedSlot" then
            local title = slot:FindFirstChild("Title", true)
            if title and title:IsA("TextLabel") then
                local amountText = tostring(title.Text or "")
                local amount = tonumber(amountText:match("%+(%d+)%s*[Ee]gg"))
                    or tonumber(amountText:match("%+(%d+)"))
                if amount and amount > 0 then
                    totalEggs = totalEggs + math.floor(amount)
                    foundOwnedSlot = true
                end
            end
        end
    end

    -- Chỉ cập nhật khi đã đọc được ít nhất một OwnedSlot hợp lệ,
    -- tránh đặt amount về 0 nếu UI machine chưa tải xong.
    if foundOwnedSlot then
        CurrentMaxEggHatchAmount = math.max(1, totalEggs)
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
    local teleported = pcall(function()
        root.CFrame = CFrame.new(targetPosition)
    end)
    if not teleported or not isEnabled() then return end

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
    BestAreaComet = nil,
    BestAreaCoinJar = nil,
    BestAreaLuckyBlock = nil,
    BestAreaPinata = nil,
    Collect = nil,
    CollectPotions = nil,
    CollectEnchants = nil,
    LegendaryEggs = nil,
    Eggs = nil,
    InventoryItems = nil,
    MakeGolden = nil,
    MakeRainbow = nil,
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
    {Group = "UpdatePotion", Keywords = {"upgrade", "potion"}, MatchAll = true},
    {Group = "UpdateEnchant", Keywords = {"upgrade", "enchant"}, MatchAll = true},
    -- Route Make Golden and Make Rainbow to separate handlers by their own keys.
    {Group = "MakeGolden", KeepNumbers = true, Keywords = {"make", "golden"}, MatchAll = true},
    {Group = "MakeRainbow", KeepNumbers = true, Keywords = {"make", "rainbow"}, MatchAll = true},
    -- ROUTING GUARD: LegendaryEggs and Eggs are distinct Groups despite sharing "hatch".
    -- LegendaryEggs requires BOTH "hatch" and "legend"; keep it before the generic Eggs rule.
    {Group = "LegendaryEggs", Keywords = {"hatch", "Legendary"}, MatchAll = true},
    -- Eggs accepts "hatch" only when the title does NOT contain "legend".
    {Group = "Eggs", Keywords = {"hatch"}, ExcludeKeywords = {"Legendary"}},
    {Group = "InventoryItems", Keywords = {"use"}},
    {Group = "CollectPotions", Keywords = {"collect", "potion"}, MatchAll = true},
    {Group = "CollectEnchants", Keywords = {"collect", "enchant"}, MatchAll = true},
    -- Mỗi event có Group và handler riêng để không dùng chung logic triệu hồi.
    {Group = "BestAreaComet", AnyKeywords = {"comet", "comets"}},
    {Group = "BestAreaCoinJar", AnyKeywords = {"coin jar", "coin jars"}},
    {Group = "BestAreaLuckyBlock", AnyKeywords = {"lucky block", "lucky blocks"}},
    {Group = "BestAreaPinata", AnyKeywords = {"piñata", "piñatas", "pinata", "pinatas"}},
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
        -- Exclusion guard prevents a shared keyword (e.g. "hatch") from routing
        -- a LegendaryEggs quest into the generic Eggs Group.
        if matched and rule.ExcludeKeywords then
            for _, keyword in ipairs(rule.ExcludeKeywords) do
                if text:find(keyword, 1, true) then
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
            remote:InvokeServer(entry.Id, 1)
        end)
        task.wait(1)
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

-- [START] Box BestAreaComet: chỉ xử lý nhiệm vụ Comet
QuestScriptBoxes.BestAreaComet = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local ok = pcall(function()
        root.CFrame = CFrame.new(Vector3.new(-15044.65, 16.34, 2203.12))
    end)
    if not ok then return end
    task.wait(2)
    if not isEnabled() then return end
    local network = ReplicatedStorage:WaitForChild("Network", 5)
    local remote = network and network:WaitForChild("Comet_Spawn", 5)
    if not remote or not remote:IsA("RemoteFunction") then return end
    while isEnabled() do
        pcall(function() remote:InvokeServer("1cb6f4264dc44d8f94bbfa21cf91a6ea") end)
        task.wait(0.1)
    end
end
-- [END] Box BestAreaComet

-- [START] Box BestAreaCoinJar: chỉ xử lý nhiệm vụ Coin Jar
QuestScriptBoxes.BestAreaCoinJar = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local ok = pcall(function()
        root.CFrame = CFrame.new(Vector3.new(-15044.65, 16.34, 2203.12))
    end)
    if not ok then return end
    task.wait(2)
    if not isEnabled() then return end
    local network = ReplicatedStorage:WaitForChild("Network", 5)
    local remote = network and network:WaitForChild("CoinJar_Spawn", 5)
    if not remote or not remote:IsA("RemoteFunction") then return end
    while isEnabled() do
        pcall(function() remote:InvokeServer("1946bd672d3e4329897c343f992f7e43") end)
        task.wait(0.1)
    end
end
-- [END] Box BestAreaCoinJar

-- [START] Box BestAreaLuckyBlock: chỉ xử lý nhiệm vụ Lucky Block
QuestScriptBoxes.BestAreaLuckyBlock = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local ok = pcall(function()
        root.CFrame = CFrame.new(Vector3.new(-15044.65, 16.34, 2203.12))
    end)
    if not ok then return end
    task.wait(2)
    if not isEnabled() then return end
    local network = ReplicatedStorage:WaitForChild("Network", 5)
    local remote = network and network:WaitForChild("MiniLuckyBlock_Consume", 5)
    if not remote or not remote:IsA("RemoteFunction") then return end
    while isEnabled() do
        pcall(function() remote:InvokeServer("71bb241b66ec486caed990f7a7fd9fce") end)
        task.wait(0.1)
    end
end
-- [END] Box BestAreaLuckyBlock

-- [START] Box BestAreaPinata: chỉ xử lý nhiệm vụ Pinata
QuestScriptBoxes.BestAreaPinata = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end
    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end
    local ok = pcall(function()
        root.CFrame = CFrame.new(Vector3.new(-15044.65, 16.34, 2203.12))
    end)
    if not ok then return end
    task.wait(2)
    if not isEnabled() then return end
    local network = ReplicatedStorage:WaitForChild("Network", 5)
    local remote = network and network:WaitForChild("MiniPinata_Consume", 5)
    if not remote or not remote:IsA("RemoteFunction") then return end
    while isEnabled() do
        pcall(function() remote:InvokeServer("a5ff9b42f8ae410bb1268c4e1416400f") end)
        task.wait(0.1)
    end
end
-- [END] Box BestAreaPinata

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
        Vector3.new(-15043.85, 17.57, 2120.55),
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

-- [START] Box MakeGolden: mở Gold Machine, craft đúng số lượng nhiệm vụ rồi đóng máy
QuestScriptBoxes.MakeGolden = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local title = string.lower(tostring(questTitle or ""))
    if not title:find("golden", 1, true) then return end

    local requested = tonumber((title:gsub(",", "")):match("make%s+(%d+)"))
    if not requested or requested < 1 then return end
    requested = math.floor(requested)

    local RS = game:GetService("ReplicatedStorage")
    local Library = RS:WaitForChild("Library")
    local GUI = require(Library.Client.GUI)
    local TabController = require(Library.Client.TabController)
    local targetUID = "f69b09dd148145e19181cbb9d7ff31a1"

    local opened = pcall(function()
        GUI.GoldMachine()
        TabController.OpenTab("GoldMachine")
    end)
    if not opened then return end

    task.wait(0.3)
    if not isEnabled() then
        pcall(function() TabController.CloseTab("GoldMachine") end)
        return
    end

    local network = RS:FindFirstChild("Network")
    local remote = network and network:FindFirstChild("GoldMachine_Activate")
    if remote and remote:IsA("RemoteFunction") and isEnabled() then
        pcall(function()
            remote:InvokeServer(targetUID, requested)
        end)
    end

    task.wait(0.1)
    pcall(function() TabController.CloseTab("GoldMachine") end)
end
-- [END] Box MakeGolden

-- [START] Box MakeRainbow: kiểm tra Rainbow trước; nếu thiếu thì craft Golden trung gian
QuestScriptBoxes.MakeRainbow = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local title = string.lower(tostring(questTitle or ""))
    if not title:find("rainbow", 1, true) then return end

    local requested = tonumber((title:gsub(",", "")):match("make%s+(%d+)"))
    if not requested or requested < 1 then return end
    requested = math.floor(requested)

    local RS = game:GetService("ReplicatedStorage")
    local Library = RS:WaitForChild("Library")
    local GUI = require(Library.Client.GUI)
    local TabController = require(Library.Client.TabController)
    local playerGui = Player:WaitForChild("PlayerGui")
    local rainbowUID = "192c592642a445c8963250710c12bf69"
    local goldenUID = "f69b09dd148145e19181cbb9d7ff31a1"
    local requiredGoldenPets = requested * 10

    local function ReadItemUID(slot)
        local properties = slot:FindFirstChild("Properties")
        if properties then
            local uidObject = properties:FindFirstChild("itemUID") or properties:FindFirstChild("ItemUID")
            if uidObject and (uidObject:IsA("StringValue") or uidObject:IsA("TextLabel")) then
                return tostring(uidObject.Value or uidObject.Text)
            end
            local uidAttribute = properties:GetAttribute("itemUID") or properties:GetAttribute("ItemUID")
            if uidAttribute ~= nil then return tostring(uidAttribute) end
        end

        local uidAttribute = slot:GetAttribute("itemUID") or slot:GetAttribute("ItemUID")
        if uidAttribute ~= nil then return tostring(uidAttribute) end
        local uidObject = slot:FindFirstChild("itemUID") or slot:FindFirstChild("ItemUID")
        if uidObject and (uidObject:IsA("StringValue") or uidObject:IsA("TextLabel")) then
            return tostring(uidObject.Value or uidObject.Text)
        end
        return nil
    end

    local function ReadQuantity(slot)
        local quantity = slot:FindFirstChild("Quantity", true)
        if not quantity or not (quantity:IsA("TextLabel") or quantity:IsA("TextButton")) then
            return nil
        end
        local raw = tostring(quantity.Text or ""):gsub(",", ""):gsub("%s+", "")
        local number, suffix = raw:match("^(%d+%.?%d*)([kKmMbB]?)$")
        number = tonumber(number)
        if number then
            local multiplier = ({k=1e3,m=1e6,b=1e9})[string.lower(suffix or "")] or 1
            return math.floor(number * multiplier)
        end
        return tonumber(raw:match("(%d+)"))
    end

    local function GetMachineQuantity(machineName, targetUID)
        local machines = playerGui:FindFirstChild("_MACHINES")
        local machine = machines and machines:FindFirstChild(machineName)
        local frame = machine and machine:FindFirstChild("Frame")
        local itemsFrame = frame and frame:FindFirstChild("ItemsFrame")
        local items = itemsFrame and itemsFrame:FindFirstChild("Items")
        if not items then return nil end

        for _, object in ipairs(items:GetDescendants()) do
            if object.Name == "ItemSlot" and ReadItemUID(object) == targetUID then
                local quantity = ReadQuantity(object)
                if quantity ~= nil then return quantity end
            end
        end
        return nil
    end

    local function OpenMachine(machineName, openGui)
        local ok = pcall(function()
            openGui()
            TabController.OpenTab(machineName)
        end)
        if not ok then return false end
        task.wait(0.3)
        return isEnabled()
    end

    local function CloseMachine(machineName)
        pcall(function() TabController.CloseTab(machineName) end)
    end

    local function Craft(machineName, targetUID, amount)
        if not isEnabled() then return false end
        local network = RS:FindFirstChild("Network")
        local remoteName = machineName .. "_Activate"
        local remote = network and network:FindFirstChild(remoteName)
        if not remote or not remote:IsA("RemoteFunction") then return false end
        local ok = pcall(function()
            remote:InvokeServer(targetUID, amount)
        end)
        return ok
    end

    -- Mở Rainbow Machine và kiểm tra số lượng Rainbow hiện có.
    if not OpenMachine("RainbowMachine", function() GUI.RainbowMachine() end) then
        CloseMachine("RainbowMachine")
        return
    end

    local rainbowQuantity = GetMachineQuantity("RainbowMachine", rainbowUID)
    if rainbowQuantity ~= nil and rainbowQuantity / 10 >= requested then
        Craft("RainbowMachine", rainbowUID, requiredGoldenPets)
        task.wait(0.1)
        CloseMachine("RainbowMachine")
        return
    end

    -- Rainbow chưa đủ: chuyển sang Gold Machine để craft requested * 10 Golden.
    CloseMachine("RainbowMachine")
    if not isEnabled() then return end

    if not OpenMachine("GoldMachine", function() GUI.GoldMachine() end) then
        CloseMachine("GoldMachine")
        return
    end

    if not isEnabled() then
        CloseMachine("GoldMachine")
        return
    end

    local goldCrafted = Craft("GoldMachine", goldenUID, requiredGoldenPets)
    task.wait(0.1)
    CloseMachine("GoldMachine")
    if not goldCrafted or not isEnabled() then return end

    -- Sau khi craft Golden, mở lại Rainbow Machine, craft Rainbow rồi đóng máy.
    if not OpenMachine("RainbowMachine", function() GUI.RainbowMachine() end) then
        CloseMachine("RainbowMachine")
        return
    end

    if isEnabled() then
        Craft("RainbowMachine", rainbowUID, requiredGoldenPets)
    end
    task.wait(0.1)
    CloseMachine("RainbowMachine")
end
-- [END] Box MakeRainbow

-- [START] Box UpdatePotion: khung trống chờ bổ sung logic
-- Chưa triển khai UpdatePotion.
-- QuestScriptBoxes.UpdatePotion = function(questTitle, rank, isEnabled)
--     -- Bổ sung sau khi xác minh quy trình nâng cấp.
-- end
-- [END] Box UpdatePotion

-- [START] Box UpdateEnchant: chọn ngẫu nhiên ID enchant rồi gọi máy nâng cấp
QuestScriptBoxes.UpdateEnchant = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local entries = EnchantUpgradeIDs.Entries or {}
    local usableEntries = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.Id) == "string" and entry.Id ~= "" then
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
            remote:InvokeServer(entry.Id, 1)
        end)
        task.wait(1)
    end
end
-- [END] Box UpdateEnchant
-- [END] Các box xử lý riêng theo loại nhiệm vụ
