local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFileName = "DYUHUB_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"
local Settings = { 
    JumpToggle = false, 
    SpeedSlider = 16 
}
local function SaveConfig()
    writefile(ConfigFileName, HttpService:JSONEncode(Settings :: any))
end

local function LoadConfig()
    if isfile(ConfigFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do Settings[k] = v end
        else
            SaveConfig()
        end
    else
        SaveConfig()
    end
end

LoadConfig()
local isLoaded = false
-- 1. Ép Roblox tải bản mới nhất, chống dính Cache GitHub
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or not rawCode or rawCode == "" then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub!")
end

local UIModule = loadstring(rawCode)()

-- 2. Khởi tạo Cửa sổ giao diện chính
local Window = UIModule:Init({
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DYU_HUB",
        FileName = "Config"
    }
})
-- 3. Tạo Các Tab (Danh mục lớn)
local Tab1 = Window:CreateTab({
    Name = "Người Chơi",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})
-- 4. Thêm Chức Năng vào Tab (Ví dụ với các Element của Luna)
-- Cấu hình dữ liệu Thuốc
local PotionIDs = {
    ["Treasure Hunter Potion"] = "Treasure Hunter",
    ["Lucky Eggs Potion"] = "Lucky Egg",
    ["Coins Potion"] = "Coins",
    ["Damage Potion"] = "Damage"
}

local SelectedPotion = "Treasure Hunter Potion"
local SelectedTier = 1
local SelectedAmount = 1
local IsConsuming = false

-- Hàm lấy UUID an toàn (không làm treo/lỗi script chính)
local function getPotionUUID(internalId, tier)
    local getSuccess, SaveData = pcall(function()
        local saveScript = ReplicatedStorage:WaitForChild("Library", 5):WaitForChild("Client", 5):WaitForChild("Save", 5)
        return require(saveScript).Get()
    end)
    
    if getSuccess and SaveData and SaveData.Inventory and SaveData.Inventory.Potion then
        for uuid, item in pairs(SaveData.Inventory.Potion) do
            local itemTier = item.tn or 1
            if item.id == internalId and itemTier == tier then
                return uuid, (item._am or 1)
            end
        end
    end
    return nil, 0
end

-- 1. Dropdown Chọn Thuốc
Tab1:CreateDropdown({
    Name = "Chọn Loại Thuốc",
    Options = {"Treasure Hunter Potion", "Lucky Eggs Potion", "Coins Potion", "Damage Potion"},
    Default = "Treasure Hunter Potion",
    CurrentOption = "Treasure Hunter Potion",
    Callback = function(Option)
        if type(Option) == "table" then
            SelectedPotion = Option[1] or "Treasure Hunter Potion"
        else
            SelectedPotion = Option
        end
    end
})

-- 2. Ô Nhập Cấp Độ (Tier)
Tab1:CreateInput({
    Name = "Cấp Độ Thuốc (Tier)",
    PlaceholderText = "Nhập cấp độ (VD: 1 đến 11)",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            SelectedTier = num
        else
            warn("[DYU HUB]: Cấp độ phải là chữ số!")
        end
    end
})

-- 3. Ô Nhập Số Lượng Cần Uống
Tab1:CreateInput({
    Name = "Số Lượng Cần Uống",
    PlaceholderText = "Nhập số lượng...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            SelectedAmount = num
        else
            warn("[DYU HUB]: Số lượng phải là chữ số!")
        end
    end
})

-- 4. Nút Kích Hoạt Auto Uống Thuốc
Tab1:CreateButton({
    Name = "Tiến Hành Uống Thuốc",
    Callback = function()
        if IsConsuming then
            warn("[DYU HUB]: Đang trong quá trình uống thuốc, vui lòng đợi!")
            return
        end
        
        task.spawn(function()
            IsConsuming = true
            local internalId = PotionIDs[SelectedPotion]
            local network = ReplicatedStorage:FindFirstChild("Network")
            local consumeRemote = network and network:FindFirstChild("Potions: Consume")
            
            if not consumeRemote then
                warn("[DYU HUB]: Lỗi - Không tìm thấy Remote 'Potions: Consume'!")
                IsConsuming = false
                return
            end

            for i = 1, SelectedAmount do
                local uuid, currentAmount = getPotionUUID(internalId, SelectedTier)
                
                if not uuid or currentAmount <= 0 then
                    warn("[DYU HUB]: Đã hết " .. tostring(SelectedPotion) .. " Cấp " .. tostring(SelectedTier) .. " trong kho đồ!")
                    break
                end
                
                local execSuccess = pcall(function()
                    consumeRemote:FireServer(uuid, 1)
                end)

                if execSuccess then
                    print(string.format("[DYU HUB]: Đã dùng (%d/%d) %s [Tier %d]", i, SelectedAmount, SelectedPotion, SelectedTier))
                else
                    warn("[DYU HUB]: Lỗi khi gửi lệnh uống thuốc!")
                end
                
                if i < SelectedAmount then
                    task.wait(2)
                end
            end
            
            print("[DYU HUB]: Đã hoàn tất quá trình sử dụng thuốc.")
            IsConsuming = false
        end)
    end
})
task.wait(0.5)
isLoaded = true
