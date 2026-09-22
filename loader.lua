
-- Thêm "?t=" .. tick() vào cuối link để ép tải bản mới nhất, bỏ qua cache của GitHub
local url = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?t=" .. tostring(tick())
local UILibrary = loadstring(game:HttpGet(url))()

-- Sau đó mới gọi hàm
local MyWindow = UILibrary:CreateWindow("DYU HUB")
-- 3. Tạo Các Mục Lớn
local TabNguoiChoi = MyWindow:CreateTab("event")


-- 4. Tạo Các Mục Chức Năng (Code game nằm hoàn toàn ở đây)

-- Chức năng cho mục Người Chơi

print("---> EXECUTOR HOẠT ĐỘNG BÌNH THƯỜNG! <---")
