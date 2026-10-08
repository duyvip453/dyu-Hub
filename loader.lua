local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer

local Settings = { 
    JumpToggle = false, 
    SpeedSlider = 16 
}

local ConfigFileName = "DYUHUB_" .. tostring(game.PlaceId) .. "_" .. tostring(Player.UserId) .. ".json"

local function SaveConfig()
    pcall(function()
        if writefile then writefile(ConfigFileName, HttpService:JSONEncode(Settings)) end
    end)
end

local function LoadConfig()
    if isfile and isfile(ConfigFileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        if success and type(result) == "table" then
            for k, v in pairs(result) do Settings[k] = v end
        else
            SaveConfig()
        end
    else
        SaveConfig()
    end
end

LoadConfig()

local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/main/backgroud.lua"
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)

if not success or not rawCode or string.find(rawCode, "404: Not Found") then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub! Kiểm tra lại link file.")
end

local loadFunc, err = loadstring(rawCode)
if not loadFunc then
    return warn("[DYU HUB]: File backgroud.lua bị lỗi code: " .. tostring(err))
end

local UIModule = loadFunc()
if type(UIModule) ~= "table" or not UIModule.Init then
    return warn("[DYU HUB]: File background không trả về thư viện hợp lệ!")
end

local Window = UIModule:Init()

local Tab1 = Window:CreateTab({
    Name = "Người Chơi",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

Tab1:CreateButton({
    Name = "Mở Hộp Thư Từ Xa",
    Description = "Mở trực tiếp MailboxMachine trong _MACHINES",
    Callback = function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        local machines = playerGui and playerGui:FindFirstChild("_MACHINES")
        local mailGui = machines and machines:FindFirstChild("MailboxMachine")

        if machines and mailGui then
            if machines:IsA("ScreenGui") then machines.Enabled = true end
            if mailGui:IsA("ScreenGui") then
                mailGui.Enabled = not mailGui.Enabled
            else
                mailGui.Visible = not mailGui.Visible
            end
        else
            warn("[DYU HUB]: Không tìm thấy PlayerGui._MACHINES.MailboxMachine!")
        end
    end
})

local AutoClaimMail = false
local function clickButton(btn)
    if not btn then return end
    if typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click) end) return
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                if typeof(conn.Fire) == "function" then conn:Fire()
                elseif type(conn.Function) == "function" then conn.Function() end
            end
        end) return
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim and btn.AbsolutePosition then
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local x = pos.X + (size.X / 2)
            local y = pos.Y + (size.Y / 2) + 36
            vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end
    end)
end

Tab1:CreateToggle({
    Name = "Auto Nhận Đồ Hộp Thư",
    Description = "Tự động nhận thư ngầm không cần mở GUI",
    CurrentValue = false,
    Callback = function(Value)
        AutoClaimMail = Value
        if AutoClaimMail then
            task.spawn(function()
                while AutoClaimMail do
                    pcall(function()
                        local playerGui = Player:FindFirstChild("PlayerGui")
                        if playerGui then
                            local machines = playerGui:FindFirstChild("_MACHINES")
                            local mailbox = machines and machines:FindFirstChild("MailboxMachine")
                            local claimAll = mailbox and mailbox:FindFirstChild("Frame") 
                                             and mailbox.Frame:FindFirstChild("OptionsFrame") 
                                             and mailbox.Frame.OptionsFrame:FindFirstChild("ClaimAll")
                            if claimAll then clickButton(claimAll) end
                            
                            task.wait(0.5)
                            
                            local message = playerGui:FindFirstChild("Message")
                            local yesBtn = message and message:FindFirstChild("Frame") 
                                           and message.Frame:FindFirstChild("Contents") 
                                           and message.Frame.Contents:FindFirstChild("Yes")
                            if yesBtn then clickButton(yesBtn) end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

local isLoaded = true
