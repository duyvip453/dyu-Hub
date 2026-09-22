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

-- Nút Bấm (Button)
Tab1:CreateButton({
    Name = "Tăng Tốc Độ Chạy",
    Description = "Đặt tốc độ nhân vật lên 50",
    Callback = function()
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 50
        end
    end
})

-- Nút Bật/Tắt (Toggle)
Tab1:CreateToggle({
    Name = "Nhảy Cao",
    Description = "Bật/Tắt khả năng nhảy cao",
    CurrentValue = false,
    Callback = function(Value)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            if Value then
                hum.JumpPower = 120
                hum.UseJumpPower = true
            else
                hum.JumpPower = 50
            end
        end
    end
}, "Toggle_Jump")

-- Thanh Trượt (Slider)
Tab1:CreateSlider({
    Name = "Chỉnh Tốc Độ Custom",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
}, "Slider_Speed")
