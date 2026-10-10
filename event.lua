-- [START] EVENT MODULE: dùng chung module giao diện từ backgroud.lua
-- File này độc lập với loader.lua; không sửa chức năng hoặc nội dung file khác.
-- Lưu ý: vì loader.lua chưa truyền Window hiện có sang đây, module này tự khởi tạo
-- một Window từ cùng backgroud.lua khi event.lua được chạy.

local BACKGROUND_URL = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua"

-- [START] Tải và kiểm tra module giao diện dùng chung
local fetchOk, backgroundSource = pcall(function()
    return game:HttpGet(BACKGROUND_URL)
end)

if not fetchOk or type(backgroundSource) ~= "string" or backgroundSource == "" then
    warn("[DYU HUB / EVENT] Không tải được backgroud.lua.")
    return
end

local compileBackground = loadstring(backgroundSource)
if type(compileBackground) ~= "function" then
    warn("[DYU HUB / EVENT] Không biên dịch được backgroud.lua.")
    return
end

local moduleOk, UIModule = pcall(compileBackground)
if not moduleOk or type(UIModule) ~= "table" or type(UIModule.Init) ~= "function" then
    warn("[DYU HUB / EVENT] Module giao diện không hợp lệ.")
    return
end
-- [END] Tải và kiểm tra module giao diện dùng chung

-- [START] Khởi tạo giao diện Event bằng cùng background
local initOk, Window = pcall(function()
    return UIModule:Init()
end)

if not initOk or type(Window) ~= "table" or type(Window.CreateTab) ~= "function" then
    warn("[DYU HUB / EVENT] Không khởi tạo được cửa sổ giao diện.")
    return
end

local EventTab = Window:CreateTab({
    Name = "Event",
    Icon = "calendar",
    ImageSource = "Material",
    ShowTitle = true
})

EventTab:CreateSection("Event")
EventTab:CreateLabel({
    Text = "Event module đã tải. Thêm chức năng Event riêng tại event.lua.",
    Style = 1
})
-- [END] Khởi tạo giao diện Event bằng cùng background

-- [END] EVENT MODULE