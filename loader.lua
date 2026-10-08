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


Tab1:CreateToggle({
    Name = "Auto Nhận Đồ Hộp Thư",
    CurrentValue = false,
    Callback = function(Value)
        AutoClaimMail = Value
        if AutoClaimMail then
            task.spawn(function()
                while AutoClaimMail do
                    pcall(function()
                        local network = game:GetService("ReplicatedStorage"):FindFirstChild("Network")
                        if network then
                            -- Gọi trực tiếp Remote nhận tất cả thư
                            local claimAllRemote = network:FindFirstChild("Mailbox: Claim All")
                            if claimAllRemote then
                                claimAllRemote:InvokeServer()
                            end
                        end
                    end)
                    task.wait(3)
                end
            end)
        end
    end
})
Tab1:CreateToggle({
    Name = "Auto Nhặt Orb & Coin",
    Description = "Hút toàn bộ vật phẩm trên map vào người và tự động nhặt",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoCollectOrbs = Value
        if _G.AutoCollectOrbs then
            task.spawn(function()
                while _G.AutoCollectOrbs do
                    pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        local character = player.Character or player.CharacterAdded:Wait()
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        
                        local things = workspace:FindFirstChild("__THINGS")
                        local orbsFolder = things and things:FindFirstChild("Orbs")
                        
                        if orbsFolder and rootPart then
                            local orbIds = {}
                            
                            for _, orb in pairs(orbsFolder:GetChildren()) do
                                -- 1. Trích xuất ID
                                local id = tonumber(orb.Name)
                                if id then
                                    table.insert(orbIds, id)
                                end
                                
                                -- 2. MAGNET (Nam châm): Kéo vật thể bay thẳng vào người bạn
                                -- Vượt qua cơ chế kiểm tra khoảng cách của Server
                                if orb:IsA("BasePart") then
                                    orb.CFrame = rootPart.CFrame
                                elseif orb:IsA("Model") and orb.PrimaryPart then
                                    orb:SetPrimaryPartCFrame(rootPart.CFrame)
                                end
                            end
                            
                            -- 3. Gửi lệnh nhận lên Server
                            if #orbIds > 0 then
                                local network = game:GetService("ReplicatedStorage"):FindFirstChild("Network")
                                local collectRemote = network and network:FindFirstChild("Orbs: Collect")
                                if collectRemote then
                                    collectRemote:FireServer(orbIds)
                                end
                            end
                        end
                    end)
                    task.wait(0.1) -- Đẩy tốc độ quét lên 0.1 giây để hút ngay khi vừa rơi ra
                end
            end)
        end
    end
})
Tab1:CreateToggle({
    Name = "Auto Click Breakables (Vùng 200)",
    Description = "Tự động gửi tín hiệu click ngẫu nhiên vào vật thể trong phạm vi 200",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoClickBreak = Value
        if _G.AutoClickBreak then
            task.spawn(function()
                while _G.AutoClickBreak do
                    pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        local character = player.Character or player.CharacterAdded:Wait()
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        
                        local breakablesFolder = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Breakables")
                        
                        if breakablesFolder and rootPart then
                            local validTargets = {}
                            
                            for _, item in pairs(breakablesFolder:GetChildren()) do
                                local targetPart = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart"))
                                if targetPart then
                                    local distance = (rootPart.Position - targetPart.Position).Magnitude
                                    if distance <= 200 then
                                        table.insert(validTargets, {Item = item, Part = targetPart})
                                    end
                                end
                            end
                            
                            if #validTargets > 0 then
                                local chosen = validTargets[math.random(1, #validTargets)]
                                local targetPos = chosen.Part.Position
                                
                                -- Giả lập tín hiệu Click chuẩn xác lên vị trí vật thể
                                local args = {
                                    Ray.new(rootPart.Position, (targetPos - rootPart.Position).Unit * 200),
                                    targetPos
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Click"):FireServer(unpack(args))
                            end
                        end
                    end)
                    task.wait(0.25)
                end
            end)
        end
    end
})
task.wait(0.5)
isLoaded = true
