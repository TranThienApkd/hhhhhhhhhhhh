-- PS99_DumpIDs.lua  (gửi tất cả qua Discord, không cần lưu file)

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

local WEBHOOK = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU"

-- Hàm gửi một embed đơn
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
    wait(0.5)
end

-- Hàm gửi danh sách dài theo từng block (chia 30 dòng / embed)
local function sendList(title, lines)
    local LINES_PER_MSG = 30
    local total = #lines
    local pages = math.ceil(total / LINES_PER_MSG)

    for p = 1, pages do
        local from = (p - 1) * LINES_PER_MSG + 1
        local to   = math.min(p * LINES_PER_MSG, total)
        local chunk = {}
        for i = from, to do
            table.insert(chunk, lines[i])
        end
        local body = table.concat(chunk, "\n")
        pcall(function()
            request({
                Url = WEBHOOK, Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = string.format("%s (%d/%d)", title, p, pages),
                        description = "```\n"..body.."\n```",
                        footer = {text = string.format("Items %d–%d / %d", from, to, total)},
                        color = 0x00ccff,
                    }}
                }),
            })
        end)
        wait(1.2) -- tránh rate-limit Discord
    end
end

-- =====================================================
-- BẮT ĐẦU
-- =====================================================
discord("🟡 **BẮT ĐẦU**\n**User:** "..plr.Name.."\nĐang quét catalog PS99...", 0xffaa00)

local allLines = {}
local total = 0

-- =====================================================
-- CÁCH 1: RS.Library.Directory
-- =====================================================
local dirOk, dirErr = pcall(function()
    local dir = RS.Library.Directory
    local mods = dir:GetChildren()
    discord("🔍 Tìm thấy **"..#mods.." module** – đang quét...", 0xffaa00)

    for _, child in ipairs(mods) do
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
                discord("📦 **"..child.Name.."** → "..count.." items  *(tổng: "..total..")*", 0x5599ff)
            else
                discord("⚠️ **"..child.Name.."** → fail: `"..tostring(data).."`", 0xff8800)
            end
        end
    end
end)

-- =====================================================
-- CÁCH 2 (fallback): getgc()
-- =====================================================
if not dirOk or total == 0 then
    discord("⚠️ Directory fail: `"..tostring(dirErr).."`\nThử **getgc()**...", 0xff8800)

    local candidates = {}
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" then
            local c, s = 0, nil
            for k, val in pairs(v) do
                if typeof(k) == "string" and typeof(val) == "table" then
                    c = c + 1
                    if not s then s = k end
                end
            end
            if c > 30 then table.insert(candidates, {t=v, count=c, sample=s}) end
        end
    end
    table.sort(candidates, function(a,b) return a.count > b.count end)
    discord("🔎 **"..#candidates.." bảng ứng viên** – lấy top 5...", 0xffaa00)

    for i = 1, math.min(5, #candidates) do
        local c = candidates[i]
        local cnt = 0
        for k, _ in pairs(c.t) do
            if typeof(k) == "string" then
                table.insert(allLines, "GC_"..i.."|"..k)
                total = total + 1
                cnt = cnt + 1
            end
        end
        discord("📦 **GC Table #"..i.."** → "..cnt.." items  sample: `"..tostring(c.sample).."`", 0x5599ff)
    end
end

-- =====================================================
-- GỬI TOÀN BỘ DANH SÁCH QUA DISCORD
-- =====================================================
if total == 0 then
    discord("❌ **THẤT BẠI** – Không tìm thấy item nào!\nBáo admin.", 0xff0000)
    return
end

table.sort(allLines)
discord("✅ Quét xong! **"..total.." items** – đang gửi danh sách qua Discord...", 0x00ff00)
wait(0.5)

sendList("PS99 Item IDs", allLines)

discord(
    "🏁 **HOÀN THÀNH!**\n"..
    "**User:** "..plr.Name.."\n"..
    "**Tổng item:** "..total.."\n"..
    "*(Xem các embed phía trên để lấy danh sách)*",
    0x00ff00
)
print("[PS99] DONE! Total:", total)
