local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFileName = "DYUHUB_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"
local Settings = {
    JumpToggle = false,
    SpeedSlider = 16,
    AutoUpgradeEggs = false
}
local function SaveConfig()
    pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    end)
end
local function LoadConfig()
    local ok, data = pcall(function()
        if isfile(ConfigFileName) then
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if Settings[k] ~= nil and type(v) == type(Settings[k]) then
                Settings[k] = v
            end
        end
    else
        SaveConfig()
    end
end

LoadConfig()
local isLoaded = false
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or not rawCode or rawCode == "" then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub!")
end
local UIModule = loadstring(rawCode)()
local Window = UIModule:Init({
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DYU_HUB",
        FileName = "Config"
    }
})
local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

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
local AutoUpdateEgg = false

Tab1:CreateToggle({
    Name = "Auto Update Egg slot",
    CurrentValue = false,
    Callback = function(Value)
AutoUpdateEgg = Value

    if Value then
        task.spawn(function()
            local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
            local remote = network:WaitForChild("EggHatchSlotsMachine_RequestPurchase")
            local id = 22

            while AutoUpdateEgg do
                for id = 1, 80 do
                    if not AutoUpdatePet then
                        break
                    end
                    pcall(function()
                        remote:InvokeServer(id)
                    end)
                    task.wait(0.5)
            end
        end)
    end
end
})
--endeggupd
local AutoUpdatePet = false

Tab1:CreateToggle({
    Name = "Auto Update pet slot",
    CurrentValue = false,
    Callback = function(Value)
        AutoUpdatePet = Value

        if Value then
            task.spawn(function()
                local remote = game:GetService("ReplicatedStorage")
                    :WaitForChild("Network")
                    :WaitForChild("EquipSlotsMachine_RequestPurchase")

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
task.wait(0.5)
isLoaded = true
