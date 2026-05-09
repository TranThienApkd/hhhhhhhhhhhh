-- Kho v12 FINAL - Scan NGAY khi mở Storage GUI
-- Script chạy liên tục, phát hiện khi data load vào memory
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end
local function sendList(title,lines)
    local N=40; local pages=math.ceil(#lines/N)
    for p=1,pages do
        local from=(p-1)*N+1; local to=math.min(p*N,#lines); local chunk={}
        for i=from,to do table.insert(chunk,lines[i]) end
        pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},
            Body=Http:JSONEncode({embeds={{title=string.format("%s (%d/%d)",title,p,pages),
            description="```\n"..table.concat(chunk,"\n").."\n```",
            footer={text=string.format("%d-%d/%d",from,to,#lines)},color=0x00ff88}}})}) end)
        wait(2.5)
    end
end

-- =====================================================
-- BƯỚC 1: Lấy Equipped ngay (baseline)
-- =====================================================
local seen={} local uidLines={} local total=0
local function addItem(uid,id)
    uid=tostring(uid or ""); id=tostring(id or "")
    if #uid>3 and #id>0 and not seen[uid] then
        seen[uid]=true; table.insert(uidLines, uid.."|"..id); total=total+1
    end
end

local ok,PPC=pcall(require, RS.Library.Client.PlayerProfileCmds)
if ok then
    local _,data=pcall(PPC.GetPlayerData, plr.UserId)
    if type(data)=="table" and type(data.Equipped)=="table" then
        for _,item in pairs(data.Equipped) do
            if type(item)=="table" then
                addItem(item.uid, type(item.data)=="table" and item.data.id or item.data)
            end
        end
    end
end

local baseTotal = total
d("✅ Equipped: "..baseTotal.." unique pets\n\n**⚠️ LÀM THEO THỨ TỰ:**\n1️⃣ Mở Pet List / Storage GUI trong game\n2️⃣ **Scroll CHẬM từ trên xuống dưới** để load hết\n3️⃣ Script tự detect và gửi (chờ tối đa 120s)\n⏱️ Dừng tự động sau 15s không có item mới", 0xffaa00)

-- =====================================================
-- BƯỚC 2: Scan getgc() liên tục, so sánh với baseline
-- =====================================================
local function gcScan()
    local newCount = 0
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                local cnt = 0
                local items = {}
                for _, item in pairs(v) do
                    if type(item) == "table" then
                        -- Tìm uid (cả string lẫn number)
                        local uid = item.uid or item.Uid or item.UID or item.uniqueId
                        -- Tìm id
                        local id  = (type(item.data)=="table" and item.data.id)
                                 or item.id or item.Id or item.name or item.Name
                        if uid ~= nil and id ~= nil then
                            cnt = cnt + 1
                            table.insert(items, {uid=uid, id=id})
                        end
                    end
                end
                -- Thêm item mới vào danh sách
                for _, entry in ipairs(items) do
                    local before = total
                    addItem(tostring(entry.uid), tostring(entry.id))
                    if total > before then newCount = newCount + 1 end
                end
            end
        end
    end)
    return newCount
end

-- Poll mỗi 2s, dừng sau 15s không có item mới
local elapsed = 0
local lastTotal = baseTotal
local idleTime = 0
local started = false

while elapsed < 120 do
    wait(2)
    elapsed = elapsed + 2
    gcScan()

    if total > lastTotal then
        local newFound = total - lastTotal
        d("🔍 **+"..newFound.." items** (t="..elapsed.."s, tổng="..total..")\nTiếp tục scroll...", 0x00ff88)
        lastTotal = total
        idleTime = 0
        started = true
    elseif started then
        idleTime = idleTime + 2
        if idleTime >= 15 then
            d("✅ Không có item mới trong 15s → **Hoàn tất scan!**", 0x00ff88)
            break
        end
    end
end

if not started then
    d("⏰ Hết 120s, không phát hiện storage items\n→ Đảm bảo đã mở Pet List và scroll hết trang", 0xff8800)
end

-- =====================================================
-- Kết quả
-- =====================================================
if total == 0 then d("❌ Không có item!", 0xff0000) return end

table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

d("📦 **"..total.." items** (equipped="..baseTotal..", storage="..(total-baseTotal)..") – gửi...", 0x00ccff)
wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Tổng:** "..total.." | **Storage:** "..(total-baseTotal), 0x00ff88)
