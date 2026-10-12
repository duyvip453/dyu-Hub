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
        "https://raw.githubusercontent.com/duyvip453/dyu-Hub/main/upd-enchant",
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
    AutoQuestExtreme = false,
    AutoQuestRank = false
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

-- [START] Đọc số Egg buy max qua EggCmds, cập nhật cache mỗi 30 giây
local CurrentMaxEggHatchAmount = 1
local EggCmds
local CurrencyCmds
local CalcEggPricePlayer

local function RefreshMaxEggHatchAmount()
    local ok, amount = pcall(function()
        local RS = ReplicatedStorage
        local Library = RS:WaitForChild("Library")
        local Client = Library:WaitForChild("Client")
        local Balancing = Library:WaitForChild("Balancing")

        -- Nạp các module liên quan giống quy trình kiểm tra trong client.
        EggCmds = EggCmds or require(Client:WaitForChild("EggCmds"))
        CurrencyCmds = CurrencyCmds or require(Client:WaitForChild("CurrencyCmds"))
        CalcEggPricePlayer = CalcEggPricePlayer or require(Balancing:WaitForChild("CalcEggPricePlayer"))

        return EggCmds.GetMaxHatch()
    end)

    -- Nếu module chưa sẵn sàng hoặc trả dữ liệu không hợp lệ, giữ cache gần nhất.
    if ok and type(amount) == "number" and amount >= 1 then
        CurrentMaxEggHatchAmount = math.floor(amount)
    end

    return CurrentMaxEggHatchAmount
end

-- Đọc ngay một lần khi khởi tạo, sau đó làm mới định kỳ mỗi 30 giây.
task.spawn(function()
    RefreshMaxEggHatchAmount()
    while task.wait(30) do
        RefreshMaxEggHatchAmount()
    end
end)
-- [END] Đọc số Egg buy max qua EggCmds, cập nhật cache mỗi 30 giây

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
    Easy = Settings.AutoQuestRank,
    Medium = Settings.AutoQuestRank,
    Hard = Settings.AutoQuestRank,
    Extreme = Settings.AutoQuestRank
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
        -- Mỗi lượt đều lấy lại giới hạn hatch tối đa từ OwnedSlot.
        -- Không giảm amount theo số trứng còn thiếu của quest; scanner chỉ chịu trách nhiệm dừng box.
        local amount = math.max(1, RefreshMaxEggHatchAmount())
        local success = pcall(function()
            remote:InvokeServer(eggName, amount)
        end)
        if not success then
            task.wait(1)
        else
            task.wait(0.5)
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
    ["Use"] = nil,
    MakeGolden = nil,
    MakeRainbow = nil,
    UpdatePotion = nil,
    UpdateEnchant = nil
}
local QuestRankState = {}
for rank in pairs(QuestRankPaths) do
    QuestRankState[rank] = {
        ActiveQuest = nil,
        Running = false,
        Generation = 0
    }
end
local function GetQuestInfoFromPath(path)
    local current = Player:FindFirstChild("PlayerGui")
    if not current then return nil, nil end
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil, nil end
    end
    -- UI của một số rank đặt Title/Progress sâu hơn trong card quest.
    local title = current:FindFirstChild("Title", true)
    local progress = current:FindFirstChild("Progress", true)
    if not title or not progress then return nil, nil end
    if not title:IsA("TextLabel") and not title:IsA("TextButton") then return nil, nil end
    if not progress:IsA("TextLabel") and not progress:IsA("TextButton") then return nil, nil end
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
    -- Any quest containing "legendary" must route to LegendaryEggs,
    -- even if the title does not contain the word "hatch".
    {Group = "LegendaryEggs", AnyKeywords = {"legendary"}},
    -- Egg quest titles can vary: "Hatch ... eggs", "Hatch ... of your best eggs", etc.
    -- Route by hatch OR egg/eggs wording, excluding legendary quests handled above.
    {Group = "Eggs", AnyKeywords = {"hatch", "egg", "eggs"}, ExcludeKeywords = {"legendary"}},
    {Group = "Use", Keywords = {"use"}},
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
    local text = tostring(progressText or ""):lower():gsub(",", "")
    local function ParseCount(value)
        if not value then return nil end
        value = value:gsub("%s+", "")
        local number, suffix = value:match("^(%d+%.?%d*)([km]?)$")
        number = tonumber(number)
        if not number then return nil end
        if suffix == "k" then number = number * 1000 end
        if suffix == "m" then number = number * 1000000 end
        return math.floor(number + 0.5)
    end

    -- Hỗ trợ cả dạng 43/1500, 43/1.5k và 43 of 1.5k.
    local currentText, targetText = text:match("([%d%.]+%s*[km]?)%s*/%s*([%d%.]+%s*[km]?)")
    if not currentText or not targetText then
        currentText, targetText = text:match("([%d%.]+%s*[km]?)%s+of%s+([%d%.]+%s*[km]?)")
    end
    local current = ParseCount(currentText)
    local target = ParseCount(targetText)
    if not current or not target then return nil, nil end
    return current, target
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
    if not state or type(scriptBox) ~= "function" then
        return false, "Không có script box: " .. tostring(questGroup)
    end
    if state.Running or state.ActiveQuest == questTitle then
        return false, "Nhiệm vụ đã được dispatch"
    end

    -- Gọi box qua một điểm trung tâm; không log mỗi lần dispatch.

    state.Generation = state.Generation + 1
    local generation = state.Generation
    state.ActiveQuest = questTitle
    state.Running = true

    task.spawn(function()
        local ok, err = pcall(scriptBox, questTitle, rank, function()
            return IsQuestRankEnabled(rank) and state.Generation == generation
        end)

        if state.Generation == generation then
            state.Running = false
            if not ok then
                SetQuestDebug("box lỗi: " .. tostring(questGroup) .. " / " .. tostring(err))
            end
            -- Scheduler observes Running=false and handles the next dispatch.
        end
    end)
    return true
end

local function SetQuestRankEnabled(rank, value)
    QuestRankEnabled[rank] = value
    Settings["AutoQuest" .. rank] = value

    local state = QuestRankState[rank]
    if state then
        state.Generation = state.Generation + 1
        state.Running = false
        state.ActiveQuest = nil
    end
end

-- [AUTO FARM RANK: BẢNG ƯU TIÊN + BỘ ĐIỀU PHỐI]
-- QuestGroupPriority: số nhỏ hơn nghĩa là nhiệm vụ được ưu tiên chạy trước.
local QuestGroupPriority = {
    Use = 1,
    CollectPotions = 2,
    CollectEnchants = 3,
    UpdatePotion = 4,
    UpdateEnchant = 5,
    LegendaryEggs = 6,
    Eggs = 7,
    MakeGolden = 8,
    MakeRainbow = 9,
    BestAreaComet = 10,
    BestAreaLuckyBlock = 11,
    BestAreaPinata = 12,
    BestAreaCoinJar = 13,
    BestArea = 14
}
local RankScanOrder = {"Easy", "Medium", "Hard", "Extreme"}
-- Bốn dòng ưu tiên và một dòng chẩn đoán ngắn cho nhiệm vụ đang xử lý.
Tab1:CreateSection("Bảng ưu tiên nhiệm vụ")
local PriorityLabels = {}
for index = 1, 4 do
    PriorityLabels[index] = Tab1:CreateLabel({Text = "", Style = 1})
end
local QuestDebugLabel = Tab1:CreateLabel({Text = "Auto Rank: idle", Style = 1})
local function SetQuestDebug(text)
    if QuestDebugLabel then
        pcall(function()
            QuestDebugLabel:Set("Auto Rank: " .. tostring(text))
        end)
    end
end

local function ClearPriorityTable()
    for index = 1, 4 do
        PriorityLabels[index]:Set("")
    end
end

-- ScanAndSortQuestRanks: quét im lặng bốn rank, bỏ nhiệm vụ hoàn thành,
-- sắp xếp theo Group priority rồi cập nhật tối đa bốn dòng trên bảng.
local function ScanAndSortQuestRanks()
    local found = {}

    for scanOrder, rank in ipairs(RankScanOrder) do
        local path = QuestRankPaths[rank]
        local ok, title, progress = pcall(GetQuestInfoFromPath, path)
        if ok and title and title ~= "" and progress then
            local group = IdentifyQuestGroup(title)
            local priority = group and QuestGroupPriority[group]
            -- Chỉ loại quest khi parser đọc được target và xác nhận đã hoàn thành.
            -- Progress lạ/viết tắt không được xem là hoàn thành, tránh làm mất egg quest.
            if group and priority and not IsQuestProgressComplete(progress) then
                table.insert(found, {
                    Rank = rank,
                    Title = title,
                    Group = group,
                    Priority = priority,
                    ScanOrder = scanOrder
                })
            end
        end
    end

    table.sort(found, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.ScanOrder < b.ScanOrder
    end)

    -- Reset bảng trước mỗi lần cập nhật để không giữ lại dòng từ lần quét trước.
    ClearPriorityTable()
    for index = 1, math.min(4, #found) do
        PriorityLabels[index]:Set(string.format("%d. %s", index, found[index].Title))
    end

    return found
end

-- StopDispatchedQuest: tăng Generation để box đang chạy biết phải dừng,
-- rồi xóa trạng thái active của rank mà không phát log hoặc cảnh báo.
local function StopDispatchedQuest(rank)
    local state = QuestRankState[rank]
    if not state then return end
    state.Generation = state.Generation + 1
    state.Running = false
    state.ActiveQuest = nil
end

-- AutoFarmRankLoop: chờ một giây, sau đó quét cả bốn rank liên tục.
-- Chỉ dispatch nhiệm vụ đầu bảng khi chưa có box nào đang được điều phối.
-- Trong lúc box chạy, mỗi vòng vẫn cập nhật bảng và đọc progress im lặng.
local AutoFarmRankGeneration = 0
local AutoFarmRankRunning = false

local function StartAutoFarmRankLoop()
    -- Kiểm tra trước khi đổi generation để không vô hiệu hóa nhầm loop đang chạy.
    if AutoFarmRankRunning then return end
    AutoFarmRankGeneration = AutoFarmRankGeneration + 1
    local loopGeneration = AutoFarmRankGeneration
    AutoFarmRankRunning = true

    task.spawn(function()
        task.wait(1)
        local activeRank = nil
        local activeTitle = nil
        while Settings.AutoQuestRank and loopGeneration == AutoFarmRankGeneration do
            local found = ScanAndSortQuestRanks()

            if activeRank then
                local activePath = QuestRankPaths[activeRank]
                local latestTitle, latestProgress = GetQuestInfoFromPath(activePath)
                local isFinished = latestTitle == activeTitle
                    and latestProgress
                    and IsQuestProgressComplete(latestProgress)
                local questChanged = latestTitle ~= activeTitle or not latestProgress
                local activeState = QuestRankState[activeRank]
                local handlerStopped = not activeState or not activeState.Running

                if isFinished or questChanged or handlerStopped then
                    StopDispatchedQuest(activeRank)
                    activeRank = nil
                    activeTitle = nil
                    task.wait(0.1)
                else
                    task.wait(0.5)
                end
            else
                -- S1 không được dispatch khi S4 chưa xuất hiện trong bảng priority.
                local first = found[1]
                local fourth = found[4]
                if not first or not fourth then
                    SetQuestDebug("đang chờ đủ S1 và S4")
                    task.wait(0.2)
                else
                    -- S4 đã có: quét lại toàn bộ bảng một lần, xác nhận S1 và S4
                    -- vẫn tồn tại và S1 chưa bị đổi trước khi gọi box.
                    local verified = ScanAndSortQuestRanks()
                    local verifiedFirst = verified[1]
                    local verifiedFourth = verified[4]
                    local sameFirst = verifiedFirst
                        and verifiedFirst.Rank == first.Rank
                        and verifiedFirst.Title == first.Title
                        and verifiedFirst.Group == first.Group

                    if sameFirst and verifiedFourth then
                        local path = QuestRankPaths[verifiedFirst.Rank]
                        local currentTitle, currentProgress
                        if path then
                            currentTitle, currentProgress = GetQuestInfoFromPath(path)
                        end

                        if currentTitle == verifiedFirst.Title
                            and currentProgress
                            and not IsQuestProgressComplete(currentProgress) then
                            local dispatched, dispatchReason = DispatchQuest(
                                verifiedFirst.Rank,
                                verifiedFirst.Title,
                                verifiedFirst.Group
                            )
                            if dispatched then
                                activeRank = verifiedFirst.Rank
                                activeTitle = verifiedFirst.Title
                                SetQuestDebug("đã dispatch " .. verifiedFirst.Title)
                            else
                                SetQuestDebug("dispatch thất bại: " .. tostring(dispatchReason))
                                task.wait(0.2)
                            end
                        else
                            task.wait(0.1)
                        end
                    else
                        -- S1/S4 chưa ổn định qua lần quét xác nhận; đợi vòng sau.
                        task.wait(0.1)
                    end
                end
            end
        end

        -- Chỉ loop hiện hành được phép dọn state; loop cũ không được dừng handler mới.
        if loopGeneration == AutoFarmRankGeneration then
            if activeRank then StopDispatchedQuest(activeRank) end
            AutoFarmRankRunning = false
        end
    end)
end
-- Auto Farm Rank toggle: bật/tắt đồng bộ bốn rank và phân loại quest
Tab1:CreateToggle({
    Name = "Auto Farm Rank",
    CurrentValue = Settings.AutoQuestRank,
    Callback = function(Value)
        Settings.AutoQuestRank = Value
        for _, rank in ipairs({"Easy", "Medium", "Hard", "Extreme"}) do
            SetQuestRankEnabled(rank, Value)
        end
        SaveConfig()

        if Value then
            StartAutoFarmRankLoop()
        else
            AutoFarmRankGeneration = AutoFarmRankGeneration + 1
            -- SetQuestRankEnabled đã vô hiệu hóa generation và xóa state từng rank.
            AutoFarmRankRunning = false
            ClearPriorityTable()
            SetQuestDebug("đã tắt")
        end
    end
})

-- [END] AUTO FARM RANK: BẢNG ƯU TIÊN + BỘ ĐIỀU PHỐI

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

-- [START] Box CollectPotions: dùng số lượng còn thiếu theo progress của quest
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

    local questPath = QuestRankPaths[rank]
    if not questPath then return end

    while isEnabled() do
        -- Chỉ xử lý khi đúng quest vẫn còn; đọc progress để tính số lượng còn thiếu.
        local currentTitle, progressText = GetQuestInfoFromPath(questPath)
        if currentTitle ~= questTitle or not progressText then return end

        local current, target = ParseQuestProgress(progressText)
        if not current or not target or target <= 0 or current >= target then return end
        local amountRemaining = math.max(1, math.floor(target - current))

        -- Gửi số lượng còn thiếu thay vì nâng cấp từng món theo vòng lặp.
        local entry = usableEntries[math.random(1, #usableEntries)]
        if not isEnabled() then return end
        pcall(function()
            remote:InvokeServer(entry.Id, amountRemaining)
        end)

        -- Chờ UI cập nhật progress; chỉ gửi lượt tiếp nếu quest vẫn chưa đủ.
        task.wait(0.5)
    end
end
-- [END] Box CollectPotions

-- [START] Box CollectEnchants: chỉ nâng một enchant mỗi 0,5 giây
QuestScriptBoxes.CollectEnchants = function(questTitle, rank, isEnabled)
    local entries = EnchantUpgradeIDs and EnchantUpgradeIDs.Entries or {}
    local usable = {}

    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.Id) == "string" and entry.Id ~= "" then
            usable[#usable + 1] = entry
        end
    end
    if #usable == 0 then return end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local remote = network and network:FindFirstChild(
        EnchantUpgradeIDs.MachineRemote or "UpgradeEnchantsMachine_Activate"
    )
    if not remote or not remote:IsA("RemoteFunction") then return end

    while isEnabled() do
        local entry = usable[math.random(1, #usable)]
        if not isEnabled() then break end

        pcall(function()
            remote:InvokeServer(entry.Id, 1)
        end)

        task.wait(0.5)
    end
end
-- [END] Box CollectEnchants

-- [START] Box BestArea: chỉ teleport một lần cho mỗi quest/rank
local BestAreaTeleported = {}

QuestScriptBoxes.BestArea = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    -- Ghi nhớ theo rank + tên quest để việc dispatch lại không teleport lần nữa.
    local questKey = tostring(rank) .. "|" .. tostring(questTitle)
    if BestAreaTeleported[questKey] then return end

    local character = Player.Character or Player.CharacterAdded:Wait()
    if not isEnabled() then return end

    local root = character:WaitForChild("HumanoidRootPart")
    if not isEnabled() then return end

    local target = Vector3.new(-15044.65, 16.34, 2203.12)
    local ok = pcall(function()
        root.CFrame = CFrame.new(target)
    end)

    -- Chỉ đánh dấu đã teleport nếu thao tác thành công.
    if ok then
        BestAreaTeleported[questKey] = true
    end
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

-- [START] Box Use: dùng potion có FromTier khớp Tier La Mã trong quest
QuestScriptBoxes.Use = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    -- Đọc Tier La Mã từ tiêu đề, ví dụ: "Use Tier IV Potion".
    local title = string.lower(tostring(questTitle or ""))
    local romanTiers = {
        ["i"] = 1,
        ["ii"] = 2,
        ["iii"] = 3,
        ["iv"] = 4,
        ["v"] = 5,
        ["vi"] = 6
    }

    local tierText = title:match("tier%s+([ivx]+)")
    local requestedTier = tierText and romanTiers[tierText]
    if not requestedTier then return end

    -- Chọn các potion có FromTier đúng bằng tier nhiệm vụ yêu cầu.
    local entries = PotionUpgradeIDs and PotionUpgradeIDs.Entries
    if type(entries) ~= "table" then return end

    local matchingEntries = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table"
            and tonumber(entry.FromTier) == requestedTier
            and type(entry.Id) == "string"
            and entry.Id ~= "" then
            table.insert(matchingEntries, entry)
        end
    end
    if #matchingEntries == 0 then return end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local remote = network and network:FindFirstChild("Potions: Consume")
    if not remote or not remote:IsA("RemoteEvent") then return end

    local questPath = QuestRankPaths[rank]
    if not questPath then return end

    while isEnabled() do
        -- Chỉ theo dõi quest được giao cho đúng rank này.
        local currentTitle, currentProgress = GetQuestInfoFromPath(questPath)
        if not currentTitle or currentTitle ~= questTitle then return end
        if IsQuestProgressComplete(currentProgress) then return end
        if not isEnabled() then return end

        -- Có thể dùng bất kỳ potion nào ở FromTier tương ứng; chọn ngẫu nhiên.
        local entry = matchingEntries[math.random(1, #matchingEntries)]
        pcall(function()
            remote:FireServer(entry.Id, 1)
        end)

        task.wait(0.5)
    end
end
-- [END] Box Use

-- [START] Box MakeGolden: gọi thẳng remote, không cần mở Gold Machine
QuestScriptBoxes.MakeGolden = function(questTitle, rank, isEnabled)
    if not isEnabled() then return end

    local title = string.lower(tostring(questTitle or ""))
    if not title:find("golden", 1, true) then return end

    local requested = tonumber((title:gsub(",", "")):match("make%s+(%d+)"))
    if not requested or requested < 1 then return end
    requested = math.floor(requested)

    local targetUID = "f69b09dd148145e19181cbb9d7ff31a1"
    local network = ReplicatedStorage:FindFirstChild("Network")
    local remote = network and network:FindFirstChild("GoldMachine_Activate")
    if not remote or not remote:IsA("RemoteFunction") or not isEnabled() then return end

    pcall(function()
        remote:InvokeServer(targetUID, requested)
    end)
end
-- [END] Box MakeGolden

-- [START] Box MakeRainbow: thử Rainbow, kiểm tra quest, bổ sung Golden rồi lặp
QuestScriptBoxes.MakeRainbow = function(questTitle, rank, isEnabled)
    local title = tostring(questTitle or "")
    local requested = tonumber((title:lower():gsub(",", "")):match("make%s+(%d+)"))
    if not requested or requested < 1 then return end
    requested = math.floor(requested)

    local questPath = QuestRankPaths[rank]
    local network = ReplicatedStorage:FindFirstChild("Network")
    local rainbowRemote = network and network:FindFirstChild("RainbowMachine_Activate")
    local goldenRemote = network and network:FindFirstChild("GoldMachine_Activate")
    local rainbowUID = "192c592642a445c8963250710c12bf69"
    local goldenUID = "f69b09dd148145e19181cbb9d7ff31a1"

    if not questPath or not rainbowRemote or not rainbowRemote:IsA("RemoteFunction")
        or not goldenRemote or not goldenRemote:IsA("RemoteFunction") then
        SetQuestDebug("MakeRainbow: thiếu quest path hoặc remote craft")
        return
    end

    local function ReadQuestState()
        local currentTitle, progress = GetQuestInfoFromPath(questPath)
        if currentTitle ~= questTitle then
            return "changed", currentTitle, progress
        end
        if progress and IsQuestProgressComplete(progress) then
            return "complete", currentTitle, progress
        end
        -- Progress nil/chưa đọc được không có nghĩa quest đã xong hoặc đổi.
        return "pending", currentTitle, progress
    end

    while isEnabled() do
        local state = ReadQuestState()
        if state == "changed" or state == "complete" then return end

        -- Thử craft đúng số Rainbow mà quest yêu cầu.
        local rainbowOk, rainbowResult = pcall(function()
            return rainbowRemote:InvokeServer(rainbowUID, requested)
        end)
        if not rainbowOk then
            SetQuestDebug("MakeRainbow: Rainbow remote lỗi: " .. tostring(rainbowResult))
        end

        task.wait(0.5)
        if not isEnabled() then return end

        -- Chỉ thoát khi quest đổi hoặc đã hoàn thành; thiếu Progress thì vẫn tiếp tục.
        state = ReadQuestState()
        if state == "changed" or state == "complete" then return end

        -- Nếu vẫn chưa hoàn thành/Progress đang chờ cập nhật, thử tạo Golden theo tỷ lệ 10:1.
        local goldenOk, goldenResult = pcall(function()
            return goldenRemote:InvokeServer(goldenUID, requested * 10)
        end)
        if not goldenOk then
            SetQuestDebug("MakeRainbow: Golden remote lỗi: " .. tostring(goldenResult))
        else
            SetQuestDebug("MakeRainbow: đã gửi yêu cầu Golden x" .. tostring(requested * 10))
        end

        -- Chờ Golden được xử lý rồi vòng lặp quay lại thử Rainbow.
        task.wait(1)
    end
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



