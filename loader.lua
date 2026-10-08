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

-- 1. Tạo bảng hiển thị
local Dashboard = Tab1:CreateParagraph({
    Title = "🏆 ĐANG TẢI RANK...",
    Content = "Đang đồng bộ dữ liệu..."
})

-- 2. Vòng lặp cập nhật (Code tối giản, chống lỗi tuyệt đối)
task.spawn(function()
    while task.wait(1) do
        local success, err = pcall(function()
            local PlayerGui = Player:FindFirstChild("PlayerGui")
            if not PlayerGui then return end
            
            local GoalsSide = PlayerGui:FindFirstChild("GoalsSide")
            if not GoalsSide then return end

            -- TÌM RANK (Tự động quét tìm frame "Top")
            local rankText = "N/A"
            local topFrame = GoalsSide:FindFirstChild("Top", true)
            if topFrame and topFrame:FindFirstChild("Title") then
                rankText = topFrame.Title.Text
            end

            -- TÌM NHIỆM VỤ (Tự động quét tìm "QuestsHolder")
            local contentText = ""
            local questsHolder = GoalsSide:FindFirstChild("QuestsHolder", true)
            
            if questsHolder then
                -- Lọc đúng 4 nhiệm vụ theo tên
                local diffs = {"Easy", "Medium", "Hard", "Extreme"}
                for _, diff in ipairs(diffs) do
                    local frame = questsHolder:FindFirstChild(diff)
                    if frame then
                        local tObj = frame:FindFirstChild("Title")
                        local pObj = frame:FindFirstChild("Progress")
                        
                        local titleText = tObj and tObj.Text or "Đang tải..."
                        local progText = pObj and pObj.Text or "0/0"
                        
                        -- Xử lý thanh tiến độ
                        local cleanProg = string.gsub(progText, ",", "")
                        local cur, max = string.match(cleanProg, "(%d+)/(%d+)")
                        local percent = 0
                        if cur and max and tonumber(max) > 0 then
                            percent = math.clamp(tonumber(cur) / tonumber(max), 0, 1)
                        end
                        
                        local filled = math.floor(percent * 20)
                        local bar = string.rep("█", filled) .. string.rep("░", 20 - filled)
                        
                        contentText = contentText .. string.format("📌 [%s] %s\n%s %d%%  (%s)\n\n", string.upper(diff), titleText, bar, math.floor(percent * 100), progText)
                    end
                end
            end

            if contentText == "" then
                contentText = "Đang chờ game hiển thị nhiệm vụ..."
            end

            -- CẬP NHẬT GIAO DIỆN
            Dashboard:Set({
                Title = "🏆 RANK HIỆN TẠI: " .. string.upper(rankText),
                Content = contentText
            })
        end)
        
        -- Nếu có lỗi không lường trước, báo ra F9 để dễ bắt bệnh
        if not success then
            warn("Lỗi Dashboard: ", err)
        end
    end
end)

task.wait(0.5)
isLoaded = true
