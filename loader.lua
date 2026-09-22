
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua"))()

-- 2. Tạo Box Chính
local MyWindow = UILibrary:CreateWindow("SUPER HUB 2026")

-- 3. Tạo Các Mục Lớn
local TabNguoiChoi = MyWindow:CreateTab("Người Chơi")
local TabVuKhi = MyWindow:CreateTab("Vũ Khí")

-- 4. Tạo Các Mục Chức Năng (Code game nằm hoàn toàn ở đây)

-- Chức năng cho mục Người Chơi
TabNguoiChoi:CreateButton("Tăng Tốc Độ (Speed)", function()
    -- Path chỉ định đối tượng LocalPlayer như bạn đã nói
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 50
    end
end)

TabNguoiChoi:CreateButton("Bật Nhảy Cao (Jump)", function()
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = 100
        player.Character.Humanoid.UseJumpPower = true
    end
end)

-- Chức năng cho mục Vũ Khí
TabVuKhi:CreateButton("Tự Động Bắn", function()
    print("Code tự động bắn sẽ viết ở đây...")
end)
