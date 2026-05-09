-- =====================================================
-- PS99 DEEP DEBUG – Tìm cấu trúc Save data
-- Chạy script này để biết đường dẫn đúng
-- =====================================================
local WEBHOOK = "https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

local function disc(msg, color)
    pcall(function()
        request({ Url = WEBHOOK, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({ embeds = {{description = msg, color = color or 0x00ccff}} }) })
    end)
    wait(1.5)
end

disc("🔬 **DEEP DEBUG BẮT ĐẦU**\n**Acc:** `"..plr.Name.."`", 0xffaa00)

-- =====================================================
-- 1. Liệt kê toàn bộ RS.Library
-- =====================================================
local lines = {}
local function scanFolder(obj, prefix, depth)
    if depth > 3 then return end
    for _, child in ipairs(obj:GetChildren()) do
        table.insert(lines, prefix..child.ClassName.." ["..child.Name.."]")
        if child:IsA("Folder") or child:IsA("ModuleScript") then
            if #lines < 80 then scanFolder(child, prefix.."  ", depth+1) end
        end
    end
end

local LibOk = pcall(function() scanFolder(RS.Library, "", 0) end)
if LibOk and #lines > 0 then
    -- gửi theo chunk 40 dòng
    for i = 1, #lines, 40 do
        local chunk = {}
        for j = i, math.min(i+39, #lines) do table.insert(chunk, lines[j]) end
        disc("📁 **RS.Library structure:**\n```\n"..table.concat(chunk, "\n").."\n```", 0x5599ff)
    end
else
    disc("❌ RS.Library không tồn tại hoặc rỗng!", 0xff0000)
end

-- =====================================================
-- 2. Thử require từng Client module → dump keys + sample
-- =====================================================
disc("🔍 **Đang require từng Client module...**", 0xffaa00)

local ClientFolder = nil
pcall(function() ClientFolder = RS.Library.Client end)

if ClientFolder then
    for _, child in ipairs(ClientFolder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local ok, mod = pcall(require, child)
            if ok and type(mod) == "table" then
                local keys = {}
                for k, v in pairs(mod) do
                    table.insert(keys, tostring(k).." = "..type(v))
                    if #keys >= 15 then break end
                end
                disc("📦 **Module `"..child.Name.."`:**\n```\n"..table.concat(keys, "\n").."\n```", 0x9966ff)

                -- Nếu có .Get thì thử gọi và dump structure
                if type(mod.Get) == "function" then
                    local dok, data = pcall(mod.Get)
                    if dok and type(data) == "table" then
                        local dkeys = {}
                        for k, v in pairs(data) do
                            local sample = ""
                            if type(v) == "table" then
                                -- Lấy sample item đầu tiên
                                for _, item in pairs(v) do
                                    if type(item) == "table" then
                                        local ikeys = {}
                                        for ik, iv in pairs(item) do
                                            table.insert(ikeys, tostring(ik).."="..type(iv))
                                            if #ikeys >= 5 then break end
                                        end
                                        sample = " → {"..(table.concat(ikeys,", ")).."}"
                                        break
                                    end
                                end
                            end
                            table.insert(dkeys, tostring(k).." ("..type(v)..")"..sample)
                            if #dkeys >= 10 then break end
                        end
                        disc("  📄 **`"..child.Name..".Get()` keys:**\n```\n"..table.concat(dkeys,"\n").."\n```", 0x00aaff)
                    elseif dok then
                        disc("  ℹ️ `"..child.Name..".Get()` trả về: `"..type(data).."`", 0xaaaaaa)
                    else
                        disc("  ❌ `"..child.Name..".Get()` error: `"..tostring(data).."`", 0xff6600)
                    end
                end
            else
                disc("⚠️ require(`"..child.Name.."`) thất bại: `"..tostring(mod).."`", 0xff8800)
            end
            wait(0.5)
        end
    end
end

-- =====================================================
-- 3. getgc() – Tìm bảng có uid (number) + id (string)
-- =====================================================
disc("🔄 **getgc() scan – Tìm bảng inventory...**", 0xffaa00)

local candidates = {}
pcall(function()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local cnt, sample = 0, nil
            for _, item in pairs(v) do
                if type(item) == "table" then
                    local uid = item.uid or item.Uid or item.UID
                    local id  = item.id  or item.Id  or item.ID or item.name
                    if type(uid) == "number" and type(id) == "string" then
                        cnt = cnt + 1
                        if not sample then sample = tostring(uid).."|"..id end
                    end
                end
            end
            if cnt > 3 then
                table.insert(candidates, {count=cnt, sample=sample})
            end
        end
    end
end)

table.sort(candidates, function(a,b) return a.count > b.count end)

if #candidates > 0 then
    local clines = {}
    for i, c in ipairs(candidates) do
        table.insert(clines, i..". count="..c.count.." | sample: "..tostring(c.sample))
        if i >= 10 then break end
    end
    disc("📊 **getgc() top candidates (uid+id):**\n```\n"..table.concat(clines,"\n").."\n```", 0x00ff88)
else
    disc("❌ getgc() không tìm thấy bảng uid+id nào!\nItem có thể dùng key khác.", 0xff0000)

    -- Thử tìm với key khác
    local altCandidates = {}
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                local cnt, sample = 0, nil
                for _, item in pairs(v) do
                    if type(item) == "table" then
                        -- Thử nhiều key phổ biến
                        local hasNum = item.uid or item.index or item.i or item[1]
                        local hasStr = item.id or item.name or item.type or item.itemType
                        if type(hasNum) == "number" and type(hasStr) == "string" then
                            cnt = cnt + 1
                            if not sample then
                                sample = "num="..tostring(hasNum).." str="..tostring(hasStr)
                            end
                        end
                    end
                end
                if cnt > 5 then
                    table.insert(altCandidates, {count=cnt, sample=sample})
                end
            end
        end
    end)

    table.sort(altCandidates, function(a,b) return a.count > b.count end)
    if #altCandidates > 0 then
        local alines = {}
        for i, c in ipairs(altCandidates) do
            table.insert(alines, i..". cnt="..c.count.." | "..tostring(c.sample))
            if i >= 10 then break end
        end
        disc("🔎 **Alt key candidates:**\n```\n"..table.concat(alines,"\n").."\n```", 0xffaa00)
    else
        disc("💀 Hoàn toàn không tìm thấy inventory structure!\nGửi toàn bộ debug info này cho admin.", 0xff0000)
    end
end

disc("✅ **DEBUG XONG!** Gửi tất cả info trên cho admin.", 0x00ff88)
