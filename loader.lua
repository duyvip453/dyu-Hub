local UI = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))();
local window = UI:CreateWindow({
    Title = "SclScl Hub",-- thay tên bạn muốn đặt
    SubTitle = "By duyvip",-- tên bạn
    TabWidth = 160,
    Theme = "Dark",--màu
    Acrylic = false,
    Size = UDim2.fromOffset(500, 320),
    MinimizeKey = Enum.KeyCode.End
});
local v17 = UI.Options;
local forge = loadstring(game:HttpGet("https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/forge.lua"))()
forge(UI, window);
