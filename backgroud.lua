local UILibrary = {}

-- ==========================================
-- 1. CẤU HÌNH GIAO DIỆN (Theme)
-- ==========================================
UILibrary.Theme = {
    BgColor = Color3.fromRGB(30, 30, 35),       -- Nền chính
    TabColor = Color3.fromRGB(45, 45, 50),      -- Nền danh mục
    TextColor = Color3.fromRGB(255, 255, 255),  -- Màu chữ
    RedColor = Color3.fromRGB(220, 50, 50),
    Font = Enum.Font.GothamBold                 -- Font chữ chung
}

-- ==========================================
-- 2. TẠO KHUNG BOX CHÍNH (Có Tiêu đề & Di chuyển được)
-- ==========================================
function UILibrary:CreateWindow(titleText)
    -- Tạo màn hình UI chứa box
    local coreGui = game:GetService("CoreGui")
    local guiName = "DYUHUB" -- Tên định danh độc nhất cho Script của bạn

    -- [QUAN TRỌNG 1]: XÓA BẢN CŨ KHI EXECUTE LẠI
    -- Nếu tìm thấy UI cũ đang chạy, lập tức tiêu diệt nó để tránh trùng lặp
    if coreGui:FindFirstChild(guiName) then
        coreGui[guiName]:Destroy()
    end
    -- Tạo Box chính
    local MainBox = Instance.new("Frame", ScreenGui)
    MainBox.Size = UDim2.new(0, 500, 0, 350)
    MainBox.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainBox.BackgroundColor3 = UILibrary.Theme.BgColor
    MainBox.Active = true
    MainBox.Draggable = true -- TÍNH NĂNG: Cho phép di chuyển Box bất cứ đâu
-- [QUAN TRỌNG 2]: Cho phép cắt bỏ phần hình ảnh bị tràn ra ngoài khung
    MainBox.ClipsDescendants = true
    -- Tạo Tiêu đề Box ở trên cùng
    local Title = Instance.new("TextLabel", MainBox)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Text = titleText
    Title.TextColor3 = UILibrary.Theme.TextColor
    Title.Font = UILibrary.Theme.Font
    Title.BackgroundTransparency = 1
-- [TÍNH NĂNG MỚI]: Nút Thu Nhỏ (-)
    local MinimizeBtn = Instance.new("TextButton", MainBox)
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 25)
    MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = UILibrary.Theme.TextColor
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    MinimizeBtn.Font = UILibrary.Theme.Font
    MinimizeBtn.TextSize = 18

    local isMinimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            -- Cụp bảng lại (Chỉ hiện chiều cao 35px của thanh tiêu đề)
            MainBox.Size = UDim2.new(0, 500, 0, 35)
        else
            -- Mở bảng ra kích thước chuẩn ban đầu
            MainBox.Size = UDim2.new(0, 500, 0, 350)
        end
    end)

    -- [TÍNH NĂNG MỚI]: Nút Tắt (X)
    local CloseBtn = Instance.new("TextButton", MainBox)
    CloseBtn.Size = UDim2.new(0, 30, 0, 25)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = UILibrary.Theme.TextColor
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseBtn.Font = UILibrary.Theme.Font

    CloseBtn.MouseButton1Click:Connect(function()
        -- Hủy diệt toàn bộ giao diện khi bấm Tắt
        ScreenGui:Destroy()
    end)
    -- Tạo Ô Tìm Kiếm (Ngay dưới tiêu đề)
    local SearchBox = Instance.new("TextBox", MainBox)
    SearchBox.Size = UDim2.new(1, -20, 0, 30)
    SearchBox.Position = UDim2.new(0, 10, 0, 35)
    SearchBox.PlaceholderText = "Tìm kiếm chức năng..."
    SearchBox.BackgroundColor3 = UILibrary.Theme.TabColor
    SearchBox.TextColor3 = UILibrary.Theme.TextColor
    SearchBox.Font = UILibrary.Theme.Font

    -- Tạo Khung chứa các Mục Lớn (Bên trái)
    local TabContainer = Instance.new("ScrollingFrame", MainBox)
    TabContainer.Size = UDim2.new(0, 130, 1, -75)
    TabContainer.Position = UDim2.new(0, 10, 0, 70)
    TabContainer.BackgroundColor3 = UILibrary.Theme.TabColor
    
    local TabLayout = Instance.new("UIListLayout", TabContainer)
    TabLayout.Padding = UDim.new(0, 5)

    -- Tạo Khung chứa Chức Năng (Bên phải)
    local ItemContainer = Instance.new("Frame", MainBox)
    ItemContainer.Size = UDim2.new(1, -160, 1, -75)
    ItemContainer.Position = UDim2.new(0, 150, 0, 70)
    ItemContainer.BackgroundTransparency = 1

    -- Bảng chứa các tab để quản lý Tìm Kiếm & Chuyển Tab
    local WindowAPI = { CurrentTab = nil, Tabs = {} }

    -- ==========================================
    -- 3. TẠO MỤC LỚN (Tab Danh Mục)
    -- ==========================================
    function WindowAPI:CreateTab(tabName)
        -- Tạo nút bấm chọn Mục Lớn
        local TabBtn = Instance.new("TextButton", TabContainer)
        TabBtn.Size = UDim2.new(1, 0, 0, 30)
        TabBtn.Text = tabName
        TabBtn.TextColor3 = UILibrary.Theme.TextColor
        TabBtn.BackgroundColor3 = UILibrary.Theme.BgColor

        -- Tạo trang chứa các nút chức năng cho Mục Lớn này
        local TabPage = Instance.new("ScrollingFrame", ItemContainer)
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = false -- Mặc định ẩn đi
        
        local PageLayout = Instance.new("UIListLayout", TabPage)
        PageLayout.Padding = UDim.new(0, 5)

        WindowAPI.Tabs[tabName] = TabPage

        -- Logic chuyển Tab khi bấm vào
        TabBtn.MouseButton1Click:Connect(function()
            for _, page in pairs(WindowAPI.Tabs) do page.Visible = false end
            TabPage.Visible = true
            WindowAPI.CurrentTab = TabPage
            SearchBox.Text = "" -- Xóa chữ tìm kiếm khi đổi mục
        end)

        -- Hiển thị Tab đầu tiên mặc định
        if WindowAPI.CurrentTab == nil then
            TabPage.Visible = true
            WindowAPI.CurrentTab = TabPage
        end

        local TabAPI = {}

        -- ==========================================
        -- 4. TẠO NÚT CHỨC NĂNG (Nằm trong Mục Lớn)
        -- ==========================================
        function TabAPI:CreateButton(btnName, callbackFunc)
            local FuncBtn = Instance.new("TextButton", TabPage)
            FuncBtn.Name = btnName -- Lưu tên để thuật toán Tìm Kiếm quét được
            FuncBtn.Size = UDim2.new(1, 0, 0, 35)
            FuncBtn.Text = btnName
            FuncBtn.BackgroundColor3 = UILibrary.Theme.TabColor
            FuncBtn.TextColor3 = UILibrary.Theme.TextColor

            -- Kích hoạt chức năng từ File 2 khi bấm
            FuncBtn.MouseButton1Click:Connect(function()
                if callbackFunc then callbackFunc() end
            end)
        end

        return TabAPI
    end

    -- ==========================================
    -- 5. THUẬT TOÁN TÌM KIẾM
    -- ==========================================
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = string.lower(SearchBox.Text)
        if WindowAPI.CurrentTab then
            -- Quét tất cả các nút chức năng trong Mục Lớn đang mở
            for _, item in ipairs(WindowAPI.CurrentTab:GetChildren()) do
                if item:IsA("TextButton") then
                    local itemName = string.lower(item.Name)
                    -- Ẩn/Hiện nút dựa trên việc có trùng chữ tìm kiếm không
                    if string.find(itemName, searchText) then
                        item.Visible = true
                    else
                        item.Visible = false
                    end
                end
            end
        end
    end)

    return WindowAPI
end

return UILibrary
