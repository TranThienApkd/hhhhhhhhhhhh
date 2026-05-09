-- PS99_GetIDs.lua
-- BƯỚC 1: Debug để tìm đường dẫn đúng trong ReplicatedStorage
-- BƯỚC 2: Lấy toàn bộ item ID và gửi Discord

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local webhook = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU"

-- ============================================================
-- HELPER: Gửi status đơn giản (màu tùy chỉnh, không cần text dài)
-- color: 0x00ff00 = xanh, 0xffaa00 = cam, 0xff0000 = đỏ
-- ============================================================
local function sendStatus(title, desc, color)
    pcall(function()
        request({
            Url     = webhook,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = HttpService:JSONEncode({
                embeds = {{
                    title       = title,
                    description = desc,
                    color       = color or 0x00ff00,
                }}
            }),
        })
    end)
end

-- ============================================================
-- HELPER: Gửi text dài tới Discord (tự chia chunk)
-- ============================================================
local function sendDiscord(title, text)
    local MAX = 1800
    local parts = {}
    while #text > 0 do
        table.insert(parts, text:sub(1, MAX))
        text = text:sub(MAX + 1)
    end
    for i, part in ipairs(parts) do
        local payload = {
            embeds = {{
                title       = title .. (i > 1 and (" (cont. "..i..")") or ""),
                description = "```\n" .. part .. "\n```",
                color       = 0x00ff00,
            }}
        }
        pcall(function()
            request({
                Url     = webhook,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = HttpService:JSONEncode(payload),
            })
        end)
        wait(1.2) -- tránh rate-limit
    end
end

-- ============================================================
-- THÔNG BÁO BẮT ĐẦU
-- ============================================================
local plr = game.Players.LocalPlayer
sendStatus(
    "🟡 BẮT ĐẦU QUÉT CATALOG",
    string.format("**Người dùng:** %s\n**Game:** %s\n**Thời gian:** %s",
        plr.Name,
        game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        os.date("%H:%M:%S %d/%m/%Y")
    ),
    0xffaa00  -- màu cam = đang chạy
)
print("[PS99] === BẮT ĐẦU QUÉT CATALOG ===")

-- ============================================================
-- BƯỚC 1: Tìm đường dẫn chính xác trong RS
-- In ra tất cả children của RS để biết cấu trúc
-- ============================================================
local debugLines = {}
local function explore(obj, depth, maxDepth)
    if depth > maxDepth then return end
    for _, child in ipairs(obj:GetChildren()) do
        table.insert(debugLines, string.rep("  ", depth) .. child.ClassName .. " : " .. child.Name)
        if child:IsA("Folder") or child:IsA("ModuleScript") then
            explore(child, depth + 1, maxDepth)
        end
    end
end

print("[PS99] Scanning ReplicatedStorage structure...")
explore(RS, 0, 3)  -- scan 3 cấp sâu
local structureText = table.concat(debugLines, "\n")
print(structureText)
sendDiscord("RS Structure (depth 3)", structureText)

-- ============================================================
-- BƯỚC 2: Thử lấy item IDs từ các đường dẫn phổ biến
-- Dựa theo ZapHub gốc: RS.Library.Directory.Pets[item.id]
-- ============================================================
print("[PS99] Trying to extract item IDs...")

local allItems = {}

-- Thử từng path phổ biến trong PS99
local tryPaths = {
    -- path gốc từ ZapHub.md
    {label = "Pets",        path = function() return require(RS.Library.Directory.Pets) end},
    {label = "Eggs",        path = function() return require(RS.Library.Directory.Eggs) end},
    {label = "Charms",      path = function() return require(RS.Library.Directory.Charms) end},
    {label = "Enchant",     path = function() return require(RS.Library.Directory.Enchant) end},
    {label = "Potions",     path = function() return require(RS.Library.Directory.Potions) end},
    {label = "Misc",        path = function() return require(RS.Library.Directory.Misc) end},
    {label = "Hoverboards", path = function() return require(RS.Library.Directory.Hoverboards) end},
    {label = "Booths",      path = function() return require(RS.Library.Directory.Booths) end},
    {label = "Ultimates",   path = function() return require(RS.Library.Directory.Ultimates) end},
    -- Đôi khi tên là số ít
    {label = "Potion",      path = function() return require(RS.Library.Directory.Potion) end},
    {label = "Hoverboard",  path = function() return require(RS.Library.Directory.Hoverboard) end},
    {label = "Booth",       path = function() return require(RS.Library.Directory.Booth) end},
    {label = "Ultimate",    path = function() return require(RS.Library.Directory.Ultimate) end},
    {label = "Charm",       path = function() return require(RS.Library.Directory.Charm) end},
}

for _, entry in ipairs(tryPaths) do
    local ok, data = pcall(entry.path)
    if ok and typeof(data) == "table" then
        local count = 0
        for id, _ in pairs(data) do
            if typeof(id) == "string" then
                table.insert(allItems, entry.label .. " | " .. id)
                count = count + 1
            end
        end
        print("[PS99] " .. entry.label .. ": " .. count .. " items found")
    else
        print("[PS99] " .. entry.label .. ": NOT FOUND or error:", tostring(data))
    end
end

-- ============================================================
-- BƯỚC 3: Nếu không tìm được qua Directory, dùng getgc()
-- để lấy module đã được require rồi
-- ============================================================
if #allItems == 0 then
    print("[PS99] Thử phương pháp getgc()...")
    local gcLines = {}
    for _, func in pairs(getgc(true)) do
        if typeof(func) == "table" then
            -- Tìm các bảng có nhiều key string (có thể là catalog)
            local count = 0
            local sample = ""
            for k, v in pairs(func) do
                if typeof(k) == "string" and typeof(v) == "table" then
                    count = count + 1
                    if sample == "" then sample = k end
                end
            end
            if count > 50 then  -- catalog thường có > 50 entry
                table.insert(gcLines, "Table với " .. count .. " entries, sample key: " .. sample)
                for k, _ in pairs(func) do
                    if typeof(k) == "string" then
                        table.insert(allItems, "GC | " .. k)
                    end
                end
                break  -- lấy bảng đầu tiên đủ lớn
            end
        end
    end
    print(table.concat(gcLines, "\n"))
    sendDiscord("getgc() result", table.concat(gcLines, "\n"))
end

-- ============================================================
-- BƯỚC 4: Gửi toàn bộ ID lên Discord
-- ============================================================
if #allItems > 0 then
    table.sort(allItems)
    local resultText = table.concat(allItems, "\n")
    print("[PS99] Tổng cộng:", #allItems, "items")
    print(resultText)
    sendDiscord(string.format("PS99 Item IDs (%d total)", #allItems), resultText)
else
    local msg = "Không tìm được item ID nào! Xem RS Structure ở embed trước."
    print("[PS99] " .. msg)
    sendDiscord("PS99 Item IDs - FAILED", msg)
end

-- ============================================================
-- THÔNG BÁO HOÀN THÀNH
-- ============================================================
local status = #allItems > 0
sendStatus(
    status and "✅ QUÉT CATALOG HOÀN THÀNH" or "❌ QUÉT CATALOG THẤT BẠI",
    string.format(
        "**Người dùng:** %s\n**Tổng item:** %d\n**Thời gian:** %s",
        game.Players.LocalPlayer.Name,
        #allItems,
        os.date("%H:%M:%S %d/%m/%Y")
    ),
    status and 0x00ff00 or 0xff0000  -- xanh = xong, đỏ = thất bại
)
print("[PS99] === HOÀN THÀNH ===")
