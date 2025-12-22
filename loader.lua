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
local tab = {
    Home = window:AddTab({
        Title = "farm"
    })
};
local FarmSection = tab.Home:AddSection("farm")
local v17 = UI.Options;
game:GetService("Players").LocalPlayer.Idled:connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
    wait();
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
end);
_G.AutoFarm = false

tab.Home:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        print("AutoFarm:", Value)
    end
})
