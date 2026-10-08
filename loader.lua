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
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})



-- 4. Thêm Chức Năng vào Tab (Ví dụ với các Element của Luna)
-- Cấu hình dữ liệu Thuốc
local Player = game.Players.LocalPlayer

-- 1. Tạo một bảng Paragraph trên Tab1 để làm Dashboard
local Dashboard = Tab1:CreateParagraph({
    Title = "🏆 ĐANG TẢI RANK...",
    Content = "Đang đồng bộ dữ liệu nhiệm vụ với game..."
})

-- 2. Hàm toán học để vẽ thanh tiến độ (Ví dụ: [██████░░░░] 60%)
local function createProgressBar(progressText)
    -- Xóa dấu phẩy nếu có (VD: 1,200/5,000 -> 1200/5000)
    local cleanText = string.gsub(progressText or "", ",", "")
    -- Tách 2 con số hiện tại và tổng số
    local currentStr, maxStr = string.match(cleanText, "(%d+)/(%d+)")
    
    local percent = 0
    if currentStr and maxStr then
        local current = tonumber(currentStr) or 0
        local max = tonumber(maxStr) or 1
        if max > 0 then
            percent = math.clamp(current / max, 0, 1)
        end
    end

    -- Độ dài của thanh tiến độ (bạn có thể tăng giảm số 20 này nếu muốn thanh dài hay ngắn)
    local barLength = 20 
    local filled = math.floor(percent * barLength)
    local empty = barLength - filled
    
    -- Lắp ráp các ký tự thành thanh hoàn chỉnh
    local bar = string.rep("█", filled) .. string.rep("░", empty)
    local percentText = string.format("%d%%", math.floor(percent * 100))
    
    return string.format("%s %s  (%s)", bar, percentText, progressText)
end

-- 3. Vòng lặp chạy ngầm để cập nhật dữ liệu liên tục mỗi 1 giây
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local PlayerGui = Player:FindFirstChild("PlayerGui")
            if not PlayerGui then return end
            
            local GoalsSide = PlayerGui:FindFirstChild("GoalsSide")
            if not GoalsSide or not GoalsSide:FindFirstChild("Frame") then return end
            
            -- 1. LẤY RANK
            local rankText = "N/A"
            local rankTitleObj = GoalsSide.Frame.Top:FindFirstChild("Title")
            if rankTitleObj then
                rankText = rankTitleObj.Text
            end
            
            -- 2. LẤY 4 NHIỆM VỤ (Đoạn mới tự động quét)
            local questContent = ""
            local QuestsHolder = GoalsSide.Frame.Quests.QuestsGradient.QuestsHolder
            
            for _, DiffFrame in ipairs(QuestsHolder:GetChildren()) do
                if DiffFrame:IsA("GuiObject") then
                    local diffName = DiffFrame.Name
                    local titleObj = DiffFrame:FindFirstChild("Title")
                    local progressObj = DiffFrame:FindFirstChild("Progress")
                    
                    local titleText = titleObj and titleObj.Text or "Chưa có tên"
                    local progressText = progressObj and progressObj.Text or "0/0"
                    
                    local visualBar = createProgressBar(progressText)
                    questContent = questContent .. string.format("📌 [%s] %s\n%s\n\n", string.upper(diffName), titleText, visualBar)
                end
            end

            -- Cảnh báo nếu không tìm thấy ô nhiệm vụ
            if questContent == "" then
                questContent = "⚠️ Không tìm thấy khung nhiệm vụ nào trong QuestsHolder!"
            end
            
            -- 3. CẬP NHẬT LÊN DASHBOARD
            Dashboard:Set({
                Title = "🏆 RANK HIỆN TẠI: " .. string.upper(rankText),
                Content = questContent
            })
        end)
    end
end)


task.wait(0.5)
isLoaded = true
