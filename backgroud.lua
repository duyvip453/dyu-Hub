-- [START] Tải thư viện Luna UI từ nguồn ngoài và khai báo module DYU HUB
local sourceOk, sourceCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true)
end)
if not sourceOk or type(sourceCode) ~= "string" or sourceCode == "" then
    return nil
end
sourceCode = sourceCode:gsub(
    'LoadingFrame%%.Version%%.Text = LoadingFrame%%.Frame%%.Frame%%.Title%%.Text == "Luna Interface Suite" and Release or "Luna UI"',
    'LoadingFrame.Version.Visible = false'
)

local compileLuna = loadstring(sourceCode)
if type(compileLuna) ~= "function" then
    return nil
end
local lunaOk, Luna = pcall(compileLuna)
if not lunaOk or type(Luna) ~= "table" or type(Luna.CreateWindow) ~= "function" then
    return nil
end
local UIModule = {}

-- [START] Cấu hình cửa sổ, logo, loading và thiết lập giao diện
function UIModule:Init()
local Window = Luna:CreateWindow({
	Name = "DYU HUB", -- This Is Title Of Your Window
	Subtitle = nil, -- A Gray Subtitle next To the main title.
	LogoID = "86628632168323", -- The Asset ID of your logo. Set to nil if you do not have a logo for Luna to use.
	LoadingEnabled = true, -- Whether to enable the loading animation. Set to false if you do not want the loading screen or have your own custom one.
	LoadingTitle = "DYU HUB", -- Header for loading screen
	LoadingSubtitle = "by duy duy", -- Subtitle for loading screen

	ConfigSettings = {
		ConfigFolder = "DYU HUB" -- The Name Of The Folder Where Luna Will Store Configs For This Script. DO NOT ADD A SLASH
	},

	KeySystem = false, -- As Of Beta 6, Luna Has officially Implemented A Key System!
	KeySettings = {
		Title = "Luna Example Key",
		Subtitle = "Key System",
		Note = "Best Key System Ever! Also, Please Use A HWID Keysystem like Pelican, Luarmor etc. that provide key strings based on your HWID since putting a simple string is very easy to bypass",
		SaveInRoot = false, -- Enabling will save the key in your RootFolder (YOU MUST HAVE ONE BEFORE ENABLING THIS OPTION)
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		Key = {"Example Key"}, -- List of keys that will be accepted by the system, please use a system like Pelican or Luarmor that provide key strings based on your HWID since putting a simple string is very easy to bypass
		SecondAction = {
			Enabled = true, -- Set to false if you do not want a second action,
			Type = "Link", -- Link / Discord.
			Parameter = "" -- If Type is Discord, then put your invite link (DO NOT PUT DISCORD.GG/). Else, put the full link of your key system here.
		}
	}
})
	return Window
end
-- [END] Cấu hình và khởi tạo cửa sổ
return UIModule
-- [END] Module giao diện DYU HUB
