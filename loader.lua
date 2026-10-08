local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SaveModule = require(ReplicatedStorage.Library.Client.Save)

-- Bảng ánh xạ Tên UI sang ID chuẩn trong hệ thống game
local PotionIDs = {
    ["Treasure Hunter Potion"] = "Treasure Hunter",
    ["Lucky Eggs Potion"] = "Lucky Eggs",
    ["Coins Potion"] = "Coins",
    ["Damage Potion"] = "Damage"
}

-- Biến lưu trạng thái người dùng chọn (mặc định)
local SelectedPotion = "Treasure Hunter Potion"
local SelectedTier = 1
local SelectedAmount = 1
local IsConsuming = false

-- Hàm tìm UUID động của thuốc trong kho đồ
local function getPotionUUID(internalId, tier)
    local Save = SaveModule.Get()
    if Save and Save.Inventory and Save.Inventory.Potion then
        for uuid, item in pairs(Save.Inventory.Potion) do
            local itemTier = item.tn or 1
            if item.id == internalId and itemTier == tier then
                return uuid, (item._am or 1)
            end
        end
    end
    return nil, 0
end

-- 1. Dropdown Chọn Thuốc
Tab2:CreateDropdown({
    Name = "Chọn Loại Thuốc",
    Options = {"Treasure Hunter Potion", "Lucky Eggs Potion", "Coins Potion", "Damage Potion"},
    CurrentOption = "Treasure Hunter Potion",
    Callback = function(Option)
        SelectedPotion = Option
    end
})

-- 2. Ô Nhập Cấp Độ (Tier) Bằng Tay
Tab2:CreateInput({
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

-- 3. Ô Nhập Số Lượng Cần Uống Bằng Tay
Tab2:CreateInput({
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
Tab2:CreateButton({
    Name = "Tiến Hành Uống Thuốc",
    Callback = function()
        if IsConsuming then
            warn("[DYU HUB]: Đang trong quá trình uống thuốc, vui lòng đợi!")
            return
        end
        
        task.spawn(function()
            IsConsuming = true
            local internalId = PotionIDs[SelectedPotion]
            local consumeRemote = Network:FindFirstChild("Potions: Consume")
            
            if not consumeRemote then
                warn("[DYU HUB]: Lỗi - Không tìm thấy tín hiệu uống thuốc từ Server!")
                IsConsuming = false
                return
            end

            for i = 1, SelectedAmount do
                -- Quét lại kho đồ mỗi lần uống để lấy UUID chuẩn nhất
                local uuid, currentAmount = getPotionUUID(internalId, SelectedTier)
                
                if not uuid or currentAmount <= 0 then
                    warn("[DYU HUB]: Đã hết " .. SelectedPotion .. " Cấp " .. SelectedTier .. " trong kho đồ!")
                    break
                end
                
                -- Thực thi gọi Remote
                local success = pcall(function()
                    consumeRemote:FireServer(uuid, 1)
                end)

                if success then
                    print(string.format("[DYU HUB]: Đã dùng (%d/%d) %s [Tier %d]", i, SelectedAmount, SelectedPotion, SelectedTier))
                else
                    warn("[DYU HUB]: Lỗi khi cố gắng uống thuốc!")
                end
                
                -- Thời gian chờ 2 giây trước bình tiếp theo (Bỏ qua delay ở bình cuối cùng)
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
