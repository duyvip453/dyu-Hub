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
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
--============================================================
-- PATH
--============================================================
local QuestLevels = {
    "Easy",
    "Medium",
    "Hard",
    "Extreme"
}
local function GetRank()
    return LocalPlayer.PlayerGui.GoalsSide.Frame.Top.Title
end
local function GetQuest(level, objectName)
    return LocalPlayer.PlayerGui
        .GoalsSide.Frame.Quests.QuestsGradient
        .QuestsHolder[level][objectName]
end
--============================================================
-- RANK
--============================================================
local khungRank = Tab1:CreateParagraph({
    Title = "🏆 RANK",
    Content = '<font size="24"><b>Đang tải...</b></font>'
})
--============================================================
-- QUEST
--============================================================
Tab1:CreateSection("Nhiệm vụ")
local khungQuest = {}
for _, level in ipairs(QuestLevels) do
    khungQuest[level] = Tab1:CreateParagraph({
        Title = "📌 " .. level,
        Content = '<font size="22"><b>Đang tải...</b></font>'
    })
end
--============================================================
-- CẬP NHẬT
--============================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            -------------------------------------------------
            -- RANK
            --------------------------------------------------
            local rank = GetRank()
            if rank then
                khungRank:Set({
                    Title = "🏆 RANK",

                    Content =
                        '<font size="26"><b>'
                        .. rank.Text
                        .. '</b></font>'
                })
            end
            --------------------------------------------------
            -- QUEST
            --------------------------------------------------
            for _, level in ipairs(QuestLevels) do
                local title = GetQuest(level, "Title")
                local progress = GetQuest(level, "Progress")
                if title and progress then
                    khungQuest[level]:Set({
                        Title = "📌 " .. level,
                        Content =
                            '<font size="22"><b>'
                            .. title.Text
                            .. '</b></font>'
                            .. "\n"
                            .. '<font size="20">'
                            .. progress.Text
                            .. '</font>'
                    })
                end
            end
        end)
    end
end)
task.wait(0.5)
isLoaded = true
