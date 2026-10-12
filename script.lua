-- DYU-HUB SCRIPT BOXES
-- Các handler được nạp bởi loader.lua. Các dependency cần thiết được truyền qua environment.
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
-- [END] Box UpdateEnchant
-- [END] Các box xử lý riêng theo loại nhiệm vụ
