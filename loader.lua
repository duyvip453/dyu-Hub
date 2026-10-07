local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ConfigFileName = "DYUHUB_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"

local Settings = { 
    JumpToggle = false, 
    SpeedSlider = 16 
}

local function SaveConfig()
    writefile(ConfigFileName, HttpService:JSONEncode(Settings))
end

local function LoadConfig()
    if isfile(ConfigFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        if success and decoded then
            for k, v in pairs(decoded) do Settings[k] = v end
        end
    else
        SaveConfig()
    end
end
LoadConfig()
local isLoaded = false
-- 1. Ép Roblox tải bản mới nhất, chống dính Cache GitHub
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local UIModule = loadstring(game:HttpGet(bgUrl))()

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

-- Hàm giả lập kích hoạt sự kiện Click ngầm
local function clickBtn(btn)
    if not btn then return end
    if firesignal then
        firesignal(btn.MouseButton1Click)
    elseif getconnections then
        for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
            if type(conn.Function) == "function" then
                conn:Function()
            end
        end
    end
end

Tab1:CreateToggle({
    Name = "Auto Nhận Đồ Hộp Thư",
    Description = "Tự động bấm Claim All và nút Yes mỗi 5s",
    CurrentValue = false,
    Callback = function(Value)
        AutoClaimMail = Value
        if AutoClaimMail then
            task.spawn(function()
                while AutoClaimMail do
                    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                    
                    if playerGui then
                        -- 1. Bấm nút ClaimAll ngầm
                        local mailbox = playerGui:FindFirstChild("_MACHINES") and playerGui._MACHINES:FindFirstChild("MailboxMachine")
                        local claimAll = mailbox and mailbox.Frame.OptionsFrame:FindFirstChild("ClaimAll")
                        
                        if claimAll then
                            clickBtn(claimAll)
                        end
                        
                        -- Chờ 0.5 giây để bảng thông báo xuất hiện
                        task.wait(0.5)
                        
                        -- 2. Kiểm tra và bấm nút Yes ngầm nếu có
                        local message = playerGui:FindFirstChild("Message")
                        local yesBtn = message and message.Frame.Contents:FindFirstChild("Yes")
                        
                        if yesBtn then
                            clickBtn(yesBtn)
                        end
                    end
                    
                    task.wait(5) -- Lặp lại sau mỗi 5 giây
                end
            end)
        end
    end
})
}, "Slider_Speed")
task.wait(0.5)
isLoaded = true
