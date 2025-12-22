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
local Areas = {
    {
        Name = "Island2CaveDanger1",
        Path = workspace.Rocks.Island2CaveDanger1
    },
    {
        Name = "Island2CaveDanger2",
        Path = workspace.Rocks.Island2CaveDanger2
    },
     {
        Name = "Island2CaveDanger3",
        Path = workspace.Rocks.Island2CaveDanger3
    },
     {
        Name = "Island2CaveDanger4",
        Path = workspace.Rocks.Island2CaveDanger4
    },
     {
        Name = "Cave LavaIsland2CaveDangerClosed",
        Path = workspace.Rocks.Island2CaveDangerClosed
    },
     {
        Name = "Island2CaveDeep",
        Path = workspace.Rocks.Island2CaveDeep
    },
     {
        Name = "Island2CaveLavaClosed",
        Path = workspace.Rocks.Island2CaveLavaClosed
    },
     {
        Name = "Island2CaveMid",
        Path = workspace.Rocks.Island2CaveMid
    },
     {
        Name = "Island2CaveStart",
        Path = workspace.Rocks.Island2CaveStart
    }
}
local CurrentArea = nil
local AreaNames = {}

for _, area in pairs(Areas) do
    table.insert(AreaNames, area.Name)
end

tab.Home:AddDropdown("AreaSelect", {
    Title = "Chọn khu vực farm",
    Values = AreaNames,
    Multi = false, -- chỉ chọn 1
    Default = nil,
    Callback = function(value)
        for _, area in pairs(Areas) do
            if area.Name == value then
                CurrentArea = area
                break
            end
        end
    end
})
