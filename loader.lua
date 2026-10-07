local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ConfigFileName = "DYUHUB_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local function SaveConfig()
    writefile(ConfigFileName, HttpService:JSONEncode(Settings))
end

local function LoadConfig()
    if isfile(ConfigFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        -- Kiểm tra chắc chắn dữ liệu đọc ra phải là 1 bảng (table) thì mới lấy dữ liệu
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do Settings[k] = v end
        else
            SaveConfig() -- Nếu file bị hỏng (nil) sẽ tự động tạo lại file mới
        end
    else
LoadConfig()
local isLoaded = false
-- 1. Ép Roblox tải bản mới nhất, chống dính Cache GitHub
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or not rawCode or rawCode == "" then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub!")
end

local UIModule = loadstring(rawCode)()

-- 2. Khởi tạo Cửa sổ giao diện chính từ Background
local Window = UIModule:Init()

-- 3. Tạo Các Tab (Danh mục lớn)
local Tab1 = Window:CreateTab({
    Name = "Người Chơi",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})

-- 4. Thêm Chức Năng vào Tab (Ví dụ với các Element của Luna)
-- Nút Mở Hộp Thư Từ Xa
Tab1:CreateButton({
    Name = "Mở Hộp Thư Từ Xa",
    Description = "Mở trực tiếp MailboxMachine trong _MACHINES",
    Callback = function()
        local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        local machines = playerGui and playerGui:FindFirstChild("_MACHINES")
        local mailGui = machines and machines:FindFirstChild("MailboxMachine")

        if machines and mailGui then
            -- Nếu _MACHINES là ScreenGui, đảm bảo lớp ngoài luôn bật
            if machines:IsA("ScreenGui") then
                machines.Enabled = true
            end

            -- Bật/tắt MailboxMachine (Nhấn 1 lần mở, nhấn 1 lần đóng)
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
        pcall(function() firesignal(btn.MouseButton1Click) end)
        return
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                if typeof(conn.Fire) == "function" then conn:Fire()
                elseif type(conn.Function) == "function" then conn.Function() end
            end
        end)
        return
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
                        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        if playerGui then
                            -- 1. Tìm và bấm nút Claim All
                            local machines = playerGui:FindFirstChild("_MACHINES")
                            local mailbox = machines and machines:FindFirstChild("MailboxMachine")
                            local claimAll = mailbox and mailbox:FindFirstChild("Frame") 
                                             and mailbox.Frame:FindFirstChild("OptionsFrame") 
                                             and mailbox.Frame.OptionsFrame:FindFirstChild("ClaimAll")
                            
                            if claimAll then
                                clickButton(claimAll)
                            end
                            
                            task.wait(0.5)
                            
                            -- 2. Tìm và bấm nút Yes
                            local message = playerGui:FindFirstChild("Message")
                            local yesBtn = message and message:FindFirstChild("Frame") 
                                           and message.Frame:FindFirstChild("Contents") 
                                           and message.Frame.Contents:FindFirstChild("Yes")
                            
                            if yesBtn then
                                clickButton(yesBtn)
                            end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})
task.wait(0.5)
isLoaded = true
