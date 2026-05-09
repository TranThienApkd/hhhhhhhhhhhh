-- PS99 Inventory Scanner - FINAL (kho7)
-- Dùng GetPlayerData(UserId) với đúng cấu trúc
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

local function sendList(title,lines)
    local N=30; local pages=math.ceil(#lines/N)
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

d("🟡 **KHO v7** | `"..plr.Name.."`", 0xffaa00)

local ok, PPC = pcall(require, RS.Library.Client.PlayerProfileCmds)
if not ok then d("❌ require fail", 0xff0000) return end

local dok, data = pcall(PPC.GetPlayerData, plr.UserId)
if not dok or type(data)~="table" then
    d("❌ GetPlayerData fail: `"..tostring(data).."`", 0xff0000) return
end

local seen={} local uidLines={} local total=0

local function addItem(uid, id)
    if type(uid)=="string" and #uid>5 and type(id)=="string" and #id>0 and not seen[uid] then
        seen[uid]=true
        table.insert(uidLines, uid.."|"..id)
        total=total+1
    end
end

-- =====================================================
-- Equipped pets: item.uid (hex string) + item.data.id
-- =====================================================
if type(data.Equipped)=="table" then
    for _, item in pairs(data.Equipped) do
        if type(item)=="table" then
            local uid = item.uid
            local id  = type(item.data)=="table" and item.data.id or item.data
            addItem(tostring(uid or ""), tostring(id or ""))
        end
    end
    d("✅ **Equipped pets:** "..total.." items", 0x00ff00)
end

-- =====================================================
-- Thử hook StorageGui.Update để lấy kho đầy đủ
-- StorageGui.Update() được gọi khi server gửi storage data
-- =====================================================
d("🔄 **Hook StorageGui để lấy full storage...**\n(Mở túi đồ trong game ngay bây giờ!)", 0xffaa00)

local storageTotal = 0
local sgOk, SG = pcall(require, RS.Library.Client.StorageGui)
if sgOk and type(SG)=="table" then
    -- Hook Update function
    local origUpdate = SG.Update
    SG.Update = function(newData, ...)
        -- Khi StorageGui nhận data từ server → extract ngay
        if type(newData)=="table" then
            for _, item in pairs(newData) do
                if type(item)=="table" then
                    local uid = item.uid or item.Uid
                    local id  = (type(item.data)=="table" and item.data.id)
                             or item.id or item.Id or item.name
                    if uid and id then
                        addItem(tostring(uid), tostring(id))
                        storageTotal=storageTotal+1
                    end
                end
            end
        end
        -- Gọi hàm gốc
        if type(origUpdate)=="function" then
            return origUpdate(newData, ...)
        end
    end

    -- Start GUI để trigger server gửi data
    if type(SG.Start)=="function" then pcall(SG.Start) end

    -- Đợi server respond (tối đa 10s)
    local waited = 0
    while storageTotal == 0 and waited < 10 do
        wait(1); waited=waited+1
    end

    -- Restore
    SG.Update = origUpdate

    if storageTotal > 0 then
        d("✅ **Storage hooked:** +"..storageTotal.." items thêm vào!", 0x00ff88)
    else
        d("⚠️ Storage hook timeout – StorageGui không nhận data\n→ Thử mở túi đồ trong game rồi chạy lại", 0xff8800)
    end
end

-- =====================================================
-- Kết quả
-- =====================================================
if total==0 then
    d("❌ Không có item nào!", 0xff0000) return
end

table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

d("📦 **"..total.." items** (equipped+"..storageTotal.." storage) – gửi...", 0x00ccff)
wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Equipped:** "..(total-storageTotal).."\n**Storage:** "..storageTotal.."\n**Tổng:** "..total, 0x00ff88)
