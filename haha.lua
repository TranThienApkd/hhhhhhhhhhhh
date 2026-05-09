-- PS99_DumpIDs.lua
-- Quét toàn bộ item ID trong PS99
-- Hiện tiến trình qua Discord + lưu file để tải về

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

local WEBHOOK = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU"

-- ====================================================
-- Hàm gửi Discord (hiện tiến trình)
-- ====================================================
local function discord(msg, color)
    pcall(function()
        request({
            Url = WEBHOOK, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{description = msg, color = color or 0xffaa00}}
            }),
        })
    end)
end

-- ====================================================
-- BẮT ĐẦU
-- ====================================================
discord("🟡 **BẮT ĐẦU**\n**User:** "..plr.Name.."\nĐang quét catalog PS99...", 0xffaa00)
print("[PS99] BẮT ĐẦU")
wait(0.5)

-- ====================================================
-- QUÉT CATALOG
-- ====================================================
local allLines = {}
local total = 0

-- Lấy tất cả module bên trong RS.Library.Directory
local ok, err = pcall(function()
    local dir = RS.Library.Directory
    local modules = dir:GetChildren()
    discord("🔍 **Tìm thấy "..#modules.." module**\nĐang require từng cái...", 0xffaa00)
    wait(0.5)

    for i, child in ipairs(modules) do
        if child:IsA("ModuleScript") then
            local mOk, data = pcall(require, child)
            if mOk and typeof(data) == "table" then
                local count = 0
                for id, _ in pairs(data) do
                    if typeof(id) == "string" then
                        table.insert(allLines, child.Name.."|"..id)
                        count = count + 1
                        total = total + 1
                    end
                end
                -- Tiến trình từng module
                discord(string.format("📦 **%s** → %d items (tổng: %d)", child.Name, count, total), 0x5555ff)
                print("[PS99]", child.Name, "->", count, "items")
                wait(0.8) -- tránh rate-limit Discord
            else
                discord("⚠️ **"..child.Name.."** → Không require được:\n`"..tostring(data).."`", 0xff8800)
                print("[PS99] FAIL:", child.Name, tostring(data))
                wait(0.5)
            end
        end
    end
end)

if not ok then
    discord("❌ **Lỗi khi quét Directory:**\n`"..tostring(err).."`\n\nThử getgc()...", 0xff0000)
    print("[PS99] Directory fail:", err)
    wait(0.5)

    -- Fallback: dùng getgc()
    discord("🔄 **Đang quét getgc()...**\nTìm bảng lớn nhất...", 0xffaa00)
    local candidates = {}
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" then
            local c = 0
            local s = nil
            for k, val in pairs(v) do
                if typeof(k) == "string" and typeof(val) == "table" then
                    c = c + 1
                    if not s then s = k end
                end
            end
            if c > 30 then
                table.insert(candidates, {t = v, count = c, sample = s})
            end
        end
    end
    table.sort(candidates, function(a,b) return a.count > b.count end)
    discord("🔎 **Tìm thấy "..#candidates.." bảng ứng viên**\nLấy top 5...", 0xffaa00)
    wait(0.5)
    for i = 1, math.min(5, #candidates) do
        local c = candidates[i]
        for k, _ in pairs(c.t) do
            if typeof(k) == "string" then
                table.insert(allLines, "GC_"..i.."|"..k)
                total = total + 1
            end
        end
        discord(string.format("📦 **GC Table #%d** → %d entries\nSample: `%s`", i, c.count, tostring(c.sample)), 0x5555ff)
        print("[PS99] GC #"..i, c.count, c.sample)
        wait(0.8)
    end
end

-- ====================================================
-- KẾT QUẢ
-- ====================================================
print("[PS99] Tổng:", total, "items")

if total == 0 then
    discord("❌ **THẤT BẠI**\nKhông tìm được item nào!\nThử chạy lại hoặc báo admin.", 0xff0000)
    return
end

-- Sắp xếp
table.sort(allLines)
local content = table.concat(allLines, "\n")

-- ====================================================
-- LƯU FILE (writefile – hoạt động trên hầu hết executor)
-- ====================================================
local filePath = "PS99_ItemIDs.txt"
local saveOk, saveErr = pcall(writefile, filePath, content)
if saveOk then
    discord("💾 **Đã lưu file!**\n`"..filePath.."`\n*(Tìm trong thư mục script của executor)*", 0x00aaff)
    print("[PS99] File saved:", filePath)
else
    discord("⚠️ **writefile thất bại:** `"..tostring(saveErr).."`", 0xff8800)
    print("[PS99] writefile fail:", saveErr)
end
wait(0.8)

-- ====================================================
-- UPLOAD LÊN PASTE.EE để tải về bằng link
-- ====================================================
discord("🌐 **Đang upload lên paste.ee...**", 0xffaa00)
local linkUrl = ""
local uploadOk, uploadResp = pcall(function()
    return request({
        Url = "https://api.paste.ee/v1/pastes",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-Auth-Token"] = "public", -- không cần key cho paste public
        },
        Body = HttpService:JSONEncode({
            sections = {{
                name = "PS99 Item IDs",
                syntax = "text",
                contents = content
            }}
        })
    })
end)

if uploadOk and uploadResp and uploadResp.Body then
    local parsed = pcall(function()
        local j = HttpService:JSONDecode(uploadResp.Body)
        if j and j.link then
            linkUrl = j.link
        end
    end)
end

-- Nếu paste.ee không ra thì thử hastebin
if linkUrl == "" then
    local hasteOk, hasteResp = pcall(function()
        return request({
            Url = "https://hastebin.com/documents",
            Method = "POST",
            Headers = {["Content-Type"] = "text/plain"},
            Body = content
        })
    end)
    if hasteOk and hasteResp and hasteResp.Body then
        pcall(function()
            local j = HttpService:JSONDecode(hasteResp.Body)
            if j and j.key then
                linkUrl = "https://hastebin.com/"..j.key..".txt"
            end
        end)
    end
end
wait(0.5)

-- ====================================================
-- TIN NHẮN CUỐI
-- ====================================================
local linkText = linkUrl ~= "" and linkUrl or "*(Upload thất bại - dùng file local)*"
discord(
    "✅ **HOÀN THÀNH!**\n"..
    "**User:** "..plr.Name.."\n"..
    "**Tổng item:** "..total.."\n"..
    "**Tải file:** "..linkText.."\n"..
    "**File local:** `"..filePath.."`",
    0x00ff00
)
print("[PS99] DONE! Total:", total)
print("[PS99] Link:", linkUrl)
