-- =====================================================
-- PS99 INVENTORY SCANNER
-- Quét kho đồ → gửi uid|id qua Discord
-- =====================================================
local WEBHOOK = "https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

local function discord(msg, color)
    pcall(function()
        request({
            Url = WEBHOOK, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{description = msg, color = color or 0x00ccff}}
            }),
        })
    end)
    wait(1)
end

local function sendList(title, lines)
    local LINES_PER_MSG = 30
    local total = #lines
    local pages = math.ceil(total / LINES_PER_MSG)
    for p = 1, pages do
        local from = (p - 1) * LINES_PER_MSG + 1
        local to   = math.min(p * LINES_PER_MSG, total)
        local chunk = {}
        for i = from, to do table.insert(chunk, lines[i]) end
        local payload = HttpService:JSONEncode({
            embeds = {{
                title = string.format("%s (%d/%d)", title, p, pages),
                description = "```\n"..table.concat(chunk, "\n").."\n```",
                footer = {text = string.format("Items %d-%d / %d", from, to, total)},
                color = 0x00ff88,
            }}
        })
        for attempt = 1, 3 do
            local ok, resp = pcall(function()
                return request({ Url = WEBHOOK, Method = "POST",
                    Headers = {["Content-Type"] = "application/json"}, Body = payload })
            end)
            if ok and resp and (resp.StatusCode == 204 or resp.StatusCode == 200 or not resp.StatusCode) then break end
            wait(3)
        end
        wait(2.5)
    end
end

-- =====================================================
-- BƯỚC 1: DEBUG – Xem RS.Library.Client có gì
-- =====================================================
discord("🔍 **DEBUG: Quét RS.Library.Client...**", 0xffaa00)

local debugLines = {}
local ClientFolder = nil
pcall(function()
    ClientFolder = RS.Library.Client
end)

if ClientFolder then
    for _, child in ipairs(ClientFolder:GetChildren()) do
        table.insert(debugLines, child.ClassName .. " | " .. child.Name)
    end
    discord("📁 **RS.Library.Client children:**\n```\n"..table.concat(debugLines, "\n").."\n```", 0x5599ff)
else
    discord("❌ RS.Library.Client không tìm thấy!", 0xff0000)
end
wait(1)

-- =====================================================
-- BƯỚC 2: Thử require từng module trong Client
-- =====================================================
local uidLines = {}
local total = 0
-- Thử nhiều cách để lấy Save module
local saveOk = pcall(function()
    local SaveModule = nil

    -- Thử từng đường dẫn
    local tries = {
        function() return require(RS.Library.Client.Save) end,
        function() return require(RS.Library.Client:FindFirstChild("Save")) end,
        function()
            local lib = RS:FindFirstChild("Library")
            local cli = lib and lib:FindFirstChild("Client")
            local sav = cli and cli:FindFirstChild("Save")
            return sav and require(sav)
        end,
    }

    for _, fn in ipairs(tries) do
        local ok, mod = pcall(fn)
        if ok and mod and type(mod) == "table" then
            SaveModule = mod
            break
        end
    end

    if not SaveModule then
        error("Không tìm được Save module")
    end

    -- Lấy data
    local data = nil
    if type(SaveModule.Get) == "function" then
        data = SaveModule.Get()
    elseif SaveModule.Data then
        data = SaveModule.Data
    elseif SaveModule.Inventory or SaveModule.Pets then
        data = SaveModule
    end

    if not data then error("Không đọc được data") end

    -- Tìm inventory table
    -- PS99 thường lưu pets trong data.Inventory hoặc data.Pets
    local inv = data.Inventory or data.Pets

    if not inv then
        -- Thử scan toàn bộ data để tìm table chứa uid
        for k, v in pairs(data) do
            if type(v) == "table" then
                for _, item in pairs(v) do
                    if type(item) == "table" and (item.uid or item.id) then
                        inv = v
                        break
                    end
                end
                if inv then break end
            end
        end
    end

    if not inv then error("Không tìm được Inventory") end

    -- Lấy uid + id từ từng item
    for _, item in pairs(inv) do
        if type(item) == "table" then
            local uid = item.uid or item.Uid or item.UID or item.uniqueId
            local id  = item.id  or item.Id  or item.ID  or item.name or item.itemId

            if uid ~= nil and id ~= nil then
                table.insert(uidLines, tostring(uid).."|"..tostring(id))
                total = total + 1
            end
        end
    end

    if total == 0 then error("Inventory rỗng hoặc cấu trúc khác") end
end)

if not saveOk then
    -- Fallback: thử getgc() để tìm inventory trong memory
    discord("⚠️ Save module thất bại – thử getgc() fallback...", 0xff8800)
    wait(1)

    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                local cnt = 0
                local hasUid = false
                for _, item in pairs(v) do
                    if type(item) == "table" and (item.uid or item.id) then
                        hasUid = true
                        cnt = cnt + 1
                    end
                end
                if hasUid and cnt > 10 then -- ít nhất 10 item mới tính là inventory
                    for _, item in pairs(v) do
                        if type(item) == "table" then
                            local uid = item.uid or item.Uid or item.UID
                            local id  = item.id  or item.Id  or item.ID or item.name
                            if uid and id then
                                table.insert(uidLines, tostring(uid).."|"..tostring(id))
                                total = total + 1
                            end
                        end
                    end
                    if total > 0 then break end
                end
            end
        end
    end)
end

-- Gửi kết quả
if total == 0 then
    discord(
        "❌ **THẤT BẠI** – Không đọc được kho đồ!\n"..
        "Có thể do:\n"..
        "• Game chưa load xong (thử đứng in-game 10s rồi chạy lại)\n"..
        "• Save module bị đổi path\n"..
        "• Inventory đang trống",
        0xff0000
    )
    return
end

-- Sắp xếp theo tên item cho dễ đọc
table.sort(uidLines, function(a, b)
    local _, aName = a:match("^(%d+)|(.+)$")
    local _, bName = b:match("^(%d+)|(.+)$")
    return (aName or a) < (bName or b)
end)

discord(
    "✅ **Tìm thấy "..total.." items trong kho!**\n"..
    "Đang gửi danh sách...\n"..
    "Format: `uid|id`",
    0x00ff00
)
wait(1)

sendList("Inventory ["..plr.Name.."]", uidLines)

discord(
    "🏁 **XONG!**\n"..
    "**Acc:** `"..plr.Name.."`\n"..
    "**Tổng items trong kho:** "..total.."\n"..
    "*(Copy toàn bộ embed trên để lưu vào web)*",
    0x00ff88
)
print("[INV] Done! Total:", total)
