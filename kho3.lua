-- =====================================================
-- PS99 INVENTORY SCANNER - Full Scan
-- Quét toàn bộ kho đồ → gửi uid|id qua Discord
-- =====================================================
local WEBHOOK = "https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

local function disc(msg, color)
    pcall(function()
        request({Url=WEBHOOK, Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=Http:JSONEncode({embeds={{description=msg, color=color or 0x00ccff}}})})
    end)
    wait(1)
end

local function sendList(title, lines)
    local N = 30
    local pages = math.ceil(#lines / N)
    for p = 1, pages do
        local from = (p-1)*N+1
        local to = math.min(p*N, #lines)
        local chunk = {}
        for i = from, to do table.insert(chunk, lines[i]) end
        local payload = Http:JSONEncode({embeds={{
            title = string.format("%s (%d/%d)", title, p, pages),
            description = "```\n"..table.concat(chunk,"\n").."\n```",
            footer = {text = string.format("%d-%d / %d", from, to, #lines)},
            color = 0x00ff88
        }}})
        for _ = 1, 3 do
            local ok = pcall(function()
                request({Url=WEBHOOK, Method="POST",
                    Headers={["Content-Type"]="application/json"}, Body=payload})
            end)
            if ok then break end
            wait(3)
        end
        wait(2.5)
    end
end

disc("🟡 **QUÉT KHO ĐỒ (Full Scan)**\n**Acc:** `"..plr.Name.."`", 0xffaa00)

-- =====================================================
-- Dùng getgc() – quét TẤT CẢ bảng có uid+id
-- Không break, không threshold – lấy hết
-- =====================================================
local seen = {}       -- chống duplicate uid
local uidLines = {}
local total = 0
local tablesFound = 0

pcall(function()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local tableItems = {}
            for _, item in pairs(v) do
                if type(item) == "table" then
                    local uid = item.uid or item.Uid or item.UID or item.uniqueId
                    local id  = item.id  or item.Id  or item.ID  or item.name or item.itemId
                    if type(uid) == "number" and type(id) == "string"
                       and uid > 0 and #id > 0 and not seen[uid] then
                        table.insert(tableItems, {uid=uid, id=id})
                    end
                end
            end
            if #tableItems > 0 then
                tablesFound = tablesFound + 1
                for _, entry in ipairs(tableItems) do
                    if not seen[entry.uid] then
                        seen[entry.uid] = true
                        table.insert(uidLines, tostring(entry.uid).."|"..entry.id)
                        total = total + 1
                    end
                end
            end
        end
    end
end)

-- =====================================================
-- Gửi kết quả
-- =====================================================
if total == 0 then
    disc("❌ **Không tìm thấy item nào!**\nThử đứng in-game 15s rồi chạy lại.", 0xff0000)
    return
end

-- Sắp xếp theo tên item
table.sort(uidLines, function(a, b)
    local _, an = a:match("^([^|]+)|(.+)$")
    local _, bn = b:match("^([^|]+)|(.+)$")
    return (an or a) < (bn or b)
end)

disc("✅ **Tìm thấy "..total.." items** (từ "..tablesFound.." bảng)\nĐang gửi...", 0x00ff00)
wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
disc("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Tổng:** "..total.." items\n**Format:** `uid|id`", 0x00ff88)
print("[INV] Done! Total:", total, "| Tables:", tablesFound)
