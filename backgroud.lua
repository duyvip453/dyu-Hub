local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "BlackKing", -- This Is Title Of Your Window
	Subtitle = nil, -- A Gray Subtitle next To the main title.
	LogoID = "82795327169782", -- The Asset ID of your logo. Set to nil if you do not have a logo for Luna to use.
	LoadingEnabled = true, -- Whether to enable the loading animation. Set to false if you do not want the loading screen or have your own custom one.
	LoadingTitle = "Luna Interface Suite", -- Header for loading screen
	LoadingSubtitle = "by Hland", -- Subtitle for loading screen

	ConfigSettings = {
		RootFolder = nil, -- The Root Folder Is Only If You Have A Hub With Multiple Game Scripts and u may remove it. DO NOT ADD A SLASH
		ConfigFolder = "Big Hub" -- The Name Of The Folder Where Luna Will Store Configs For This Script. DO NOT ADD A SLASH
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
local Tab = Window:CreateTab({
	Name = "Tab Example",
	Icon = "view_in_ar",
	ImageSource = "Material",
	ShowTitle = true -- This will determine whether the big header text in the tab will show
})
Window:CreateHomeTab({
	SupportedExecutors = {}, -- A Table Of Executors Your Script Supports. Add strings of the executor names for each executor.
	DiscordInvite = "1234", -- The Discord Invite Link. Do Not Include discord.gg/ | Only Include the code.
	Icon = 2, -- By Default, The Icon Is The Home Icon. If You would like to change it to dashboard, replace the interger with 2
})
local Paragraph = Tab:CreateParagraph({
	Title = "info",
	Text = "idk how to change icon"
})
local Button = Tab:CreateButton({
	Name = "Button Example!",
	Description = nil, -- Creates A Description For Users to know what the button does (looks bad if you use it all the time),
    	Callback = function()
         -- The function that takes place when the button is pressed
    	end
})
local ColorPicker = Tab:CreateColorPicker({
	Name = "Color Picker Example",
	Color = Color3.fromRGB(86, 171, 128),
	Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		-- The function that takes place every time the color picker is moved/changed
		-- The variable (Value) is a Color3fromRGB value based on which color is selected
	end
}, "ColorPicker") -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
local Slider = Tab:CreateSlider({
	Name = "Slider Example",
	Range = {0, 200}, -- The Minimum And Maximum Values Respectively
	Increment = 5, -- Basically The Changing Value/Rounding Off
	CurrentValue = 100, -- The Starting Value
    	Callback = function(Value)
       	 -- The function that takes place when the slider changes
       	 -- The variable (Value) is a number which correlates to the value the slider is currently at
    	end
}, "Slider") -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
local Dropdown = Tab:CreateDropdown({
	Name = "Dropdown Example",
    	Description = nil,
	Options = {"Option 1","Option 2"},
    	CurrentOption = {"Option 1"},
    	MultipleOptions = false,
    	SpecialType = nil,
    	Callback = function(Options)
     	 -- The function that takes place when the selected option is changed
    	 -- If MultipleOptions is true then The variable (Options) is a table of strings for the current selected options. Else, it is a string of the currentoption
	end
}, "Dropdown") -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
local Toggle = Tab:CreateToggle({
	Name = "Toggle Example",
	Description = nil,
	CurrentValue = false,
    	Callback = function(Value)
       	 -- The function that takes place when the toggle is switched
       	 -- The variable (Value) is a boolean on whether the toggle is true or false
    	end
}, "Toggle") -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
local Bind = Tab:CreateBind({
	Name = "Bind Example",
	Description = nil,
	CurrentBind = "Q", -- Check Roblox Studio Docs For KeyCode Names
	HoldToInteract = false, -- When true, Instead of toggling, You hold to achieve the active state of the Bind
    	Callback = function(BindState)
     	 -- The function that takes place when the keybind is pressed
     	 -- The variable (BindState) is a boolean for whether the Bind is being held or not (HoldToInteract needs to be true) OR it is whether the Bind is active
    	end,

	OnChangedCallback = function(Bind)
	 -- The function that takes place when the binded key changes
	 -- The variable (Bind) is a Enum.KeyCode for the new Binded Key
	end,
}, "Bind") -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
local Label = Tab:CreateLabel({
	Text = "Label Example",
	Style = 2 -- Luna Labels Have 3 Styles : A Basic Label, A Green Information Label and A Red Warning Label. Look At The Following Image For More Details
})
