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
    Title = "Area farm",
    Values = AreaNames,
    Multi = true, -- chỉ chọn 1
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
local RockSection = tab.Home:AddSection("Rock Priority")
RockSection:AddLabel("high value = fisrt farm, small value = last farm ")
local RockValues  = {
    ["Basalt Rock"] = 0,
    ["Basalt Core"] = 0,
    ["Basalt Vein"] = 0,
   ["Volcanic Rock"] = 0
}
for rockName, v in pairs(RockValues) do
    RockSection:AddLabel(rockName .. " : " .. tostring(v))
end
_G.RockPriorityValue = 0 -- mặc định 0

RockSection:AddSlider("RockPrioritySlider", {
    Title = "Priority Threshold",
    Min = 0,
    Max = 10,
    Default = 0,
    Callback = function(val)
        _G.RockPriorityValue = math.floor(val + 0.5)
    end
})
