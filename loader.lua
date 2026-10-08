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

local QuestPath = {
    Rank = "game:GetService('Players').LocalPlayer.PlayerGui.GoalsSide.Frame.Top.Title",

    Quest = "game:GetService('Players').LocalPlayer.PlayerGui.GoalsSide.Frame.Quests.QuestsGradient.QuestsHolder.%s.%s"
}

local QuestLevels = {
    "Easy",
    "Medium",
    "Hard",
    "Extreme"
}


--============================================================
-- UI HIỂN THỊ TRONG TAB 1
--============================================================

local khungRank = Tab1:CreateParagraph({
    Title = "🏆 RANK",
    Content = "Đang tải..."
})
Tab1:CreateSection("Nhiệm vụ")
local khungQuest = {}
for _, level in ipairs(QuestLevels) do
    khungQuest[level] = Tab1:CreateParagraph({
        Title = "📌 " .. level,
        Content = "Đang tải..."
    })
end
--============================================================
-- HÀM LẤY OBJECT TỪ PATH
--============================================================
local function GetObjectFromPath(path)
    local success, object = pcall(function()
        local result = loadstring("return " .. path)()
        return result
    end)
    if success then
        return object
    end
    return nil
end
--============================================================
-- CẬP NHẬT RANK + QUEST
--===========================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            --------------------------------------------------
            -- RANK
            --------------------------------------------------
            local rankObject = GetObjectFromPath(QuestPath.Rank)
            local rankText = "N/A"
            if rankObject then
                rankText = rankObject.Text or "N/A"
            end
            khungRank:Set({
                Title = "🏆 RANK",
                Content = rankText
            })
            --------------------------------------------------
            -- QUEST
            --------------------------------------------------
            for _, level in ipairs(QuestLevels) do
                -- Path Title
                local titlePath = string.format(
                    QuestPath.Quest,
                    level,
                    "Title"
                )
                -- Path Progress
                local progressPath = string.format(
                    QuestPath.Quest,
                    level,
                    "Progress"
                )
                local titleObject = GetObjectFromPath(titlePath)
                local progressObject = GetObjectFromPath(progressPath)
                local questName =
                    titleObject and titleObject.Text
                    or "N/A"

                local progressText =
                    progressObject and progressObject.Text
                    or "0/0"
                --------------------------------------------------
                -- TÍNH %
                --------------------------------------------------
                local cleanProgress = string.gsub(
                    progressText,
                    ",",
                    ""
                )
                local current, maximum =
                    string.match(
                        cleanProgress,
                        "(%d+)/(%d+)"
                    )
                current = tonumber(current) or 0
                maximum = tonumber(maximum) or 0
                local percent = 0

                if maximum > 0 then
                    percent = math.clamp(
                        current / maximum,
                        0,
                        1
                    )
                end
                --------------------------------------------------
                -- THANH TIẾN ĐỘ
                --------------------------------------------------
                local barLength = 18
                local filled = math.floor(
                    percent * barLength
                )
                local empty = barLength - filled
                local bar =
                    string.rep("█", filled)
                    ..
                    string.rep("░", empty)
                --------------------------------------------------
                -- HIỂN THỊ
                --------------------------------------------------
                khungQuest[level]:Set({
                    Title =
                        "📌 "
                        .. level
                        .. ": "
                        .. questName,
                    Content =
                        bar
                        .. string.format(
                            " %d%%  (%s)",
                            math.floor(percent * 100),
                            progressText
                        )
                })
            end
        end)
    end
end)
task.wait(0.5)
isLoaded = true
