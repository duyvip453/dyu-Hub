local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFileName = "DYUHUB_" .. game.PlaceId .. "_" .. Player.UserId .. ".json"
local Settings = { 
    JumpToggle = false, 
    SpeedSlider = 16 
}
local function SaveConfig()
    writefile(ConfigFileName, HttpService:JSONEncode(Settings :: any))
end

local function LoadConfig()
    if isfile(ConfigFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do Settings[k] = v end
        else
            SaveConfig()
        end
    else
        SaveConfig()
    end
end

LoadConfig()
local isLoaded = false
-- 1. Ép Roblox tải bản mới nhất, chống dính Cache GitHub
local bgUrl = "https://raw.githubusercontent.com/duyvip453/dyu-Hub/refs/heads/main/backgroud.lua?v=" .. math.random(1, 100000)
local success, rawCode = pcall(function() return game:HttpGet(bgUrl) end)
if not success or not rawCode or rawCode == "" then
    return warn("[DYU HUB]: Không thể tải background UI từ GitHub!")
end

local UIModule = loadstring(rawCode)()

-- 2. Khởi tạo Cửa sổ giao diện chính
local Window = UIModule:Init({
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DYU_HUB",
        FileName = "Config"
    }
})
-- 3. Tạo Các Tab (Danh mục lớn)
local Tab1 = Window:CreateTab({
    Name = "chơi đê",
    Icon = "person",
    ImageSource = "Material",
    ShowTitle = true
})



-- 4. Thêm Chức Năng vào Tab (Ví dụ với các Element của Luna)
-- Cấu hình dữ liệu Thuốc
--============================================================
-- KHU VỰC: BẢNG RANK & NHIỆM VỤ (nằm NGAY TRONG TAB 1)
-- Đoạn này thay thế toàn bộ khối "1. Tạo bảng hiển thị" và
-- "2. Vòng lặp cập nhật" cũ trong loader.lua.
--============================================================

--------------------------------------------------------------
-- BƯỚC 1: TẠO KHUNG HIỂN THỊ RANK (to, rõ, nằm trên cùng)
--------------------------------------------------------------
-- Dùng Paragraph thay vì Label vì Paragraph đã được xác nhận
-- cập nhật được bằng :Set(), tránh rủi ro Label không hỗ trợ
local khungRank = Tab1:CreateParagraph({
	Title = "🏆 RANK",
	Content = "Đang đồng bộ dữ liệu..."
})

-- Đường kẻ + tiêu đề phụ để tách rõ khu rank với khu nhiệm vụ
Tab1:CreateSection("Nhiệm vụ")
Tab1:CreateDivider()

--------------------------------------------------------------
-- BƯỚC 2: TẠO 4 KHUNG RIÊNG CHO 4 CẤP ĐỘ NHIỆM VỤ
--------------------------------------------------------------
-- Mỗi cấp độ 1 khung riêng (không nhồi chung 1 khối chữ như cũ)
-- để nhìn vào là thấy ngay nhiệm vụ nào đang ở đâu

local danhSachCapDoQuest = { "Easy", "Medium", "Hard", "Extreme" }

-- Bảng lưu khung Paragraph của từng cấp độ, để lát cập nhật
local khungTheoCapDo = {}

for _, tenCapDo in ipairs(danhSachCapDoQuest) do
	khungTheoCapDo[tenCapDo] = Tab1:CreateParagraph({
		Title = "📌 " .. tenCapDo .. ": Đang tải...",
		Content = "Đang đồng bộ..."
	})
end

--------------------------------------------------------------
-- BƯỚC 3: HÀM TẠO THANH TIẾN ĐỘ BẰNG KÝ TỰ (vì Luna không có
-- sẵn thanh progress bar dạng đồ họa)
--------------------------------------------------------------
local function taoThanhTienDo(phanTram, doDai)
	doDai = doDai or 20
	local soOChay = math.floor(phanTram * doDai)
	return string.rep("█", soOChay) .. string.rep("░", doDai - soOChay)
end

--------------------------------------------------------------
-- BƯỚC 4: VÒNG LẶP CẬP NHẬT (giữ cách làm cũ: mỗi giây 1 lần,
-- bọc pcall để lỗi vặt không làm đứng cả vòng lặp)
--------------------------------------------------------------
task.spawn(function()
	while task.wait(1) do
		local thanhCong, loi = pcall(function()
			local nguoiChoi = game.Players.LocalPlayer
			local giaoDienGoc = nguoiChoi:FindFirstChild("PlayerGui")
			if not giaoDienGoc then return end

			local khungGoalsSide = giaoDienGoc:FindFirstChild("GoalsSide")
			if not khungGoalsSide then return end

			----------------------------------------------------
			-- CẬP NHẬT RANK
			----------------------------------------------------
			local chuRank = "N/A"
			local khungTop = khungGoalsSide:FindFirstChild("Top", true)
			if khungTop and khungTop:FindFirstChild("Title") then
				chuRank = khungTop.Title.Text
			end
			khungRank:Set({
				Title = "🏆 RANK",
				Content = chuRank
			})

			----------------------------------------------------
			-- CẬP NHẬT TỪNG CẤP ĐỘ NHIỆM VỤ
			----------------------------------------------------
			local khungCacQuest = khungGoalsSide:FindFirstChild("QuestsHolder", true)
			if not khungCacQuest then return end

			for _, tenCapDo in ipairs(danhSachCapDoQuest) do
				local khungQuestGoc = khungCacQuest:FindFirstChild(tenCapDo)
				if khungQuestGoc then
					local oTen = khungQuestGoc:FindFirstChild("Title")
					local oTienDo = khungQuestGoc:FindFirstChild("Progress")

					local tenNhiemVu = oTen and oTen.Text or "Đang tải..."
					local chuTienDo = oTienDo and oTienDo.Text or "0/0"

					-- Tách số hiện tại / số tối đa, bỏ dấu phẩy nếu có
					local chuoiSach = string.gsub(chuTienDo, ",", "")
					local soHienTai, soToiDa = string.match(chuoiSach, "(%d+)/(%d+)")
					soHienTai = tonumber(soHienTai) or 0
					soToiDa = tonumber(soToiDa) or 0

					local phanTram = 0
					if soToiDa > 0 then
						phanTram = math.clamp(soHienTai / soToiDa, 0, 1)
					end

					local noiDungHienThi = taoThanhTienDo(phanTram)
						.. string.format(" %d%%  (%s)", math.floor(phanTram * 100), chuTienDo)

					khungTheoCapDo[tenCapDo]:Set({
						Title = "📌 " .. tenCapDo .. ": " .. tenNhiemVu,
						Content = noiDungHienThi
					})
				end
			end
		end)

		if not thanhCong then
			warn("Lỗi Bảng Rank/Quest: ", loi)
		end
	end
end)

task.wait(0.5)
isLoaded = true
